"""
    TvgParams

Time-varying gain configuration based on two-way travel time and sound velocity.

Arguments:
- `sound_velocity_m_per_s`: propagation velocity in meters/second.
- `reference_depth_m`: minimum reference depth in meters used to avoid singular gain at zero time.
- `amplitude_spreading_power`: amplitude spreading compensation power. A value of `1.0`
  compensates spherical amplitude loss proportional to `1 / r`.
- `absorption_db_per_m`: additional amplitude compensation in decibels per meter.
- `max_gain`: maximum multiplicative gain factor applied to any sample.

Returns:
- `TvgParams`

Example:
`TvgParams(sound_velocity_m_per_s=1520.0, reference_depth_m=0.5, amplitude_spreading_power=1.0)`
"""
Base.@kwdef struct TvgParams
    sound_velocity_m_per_s::Float64 = 1500.0
    reference_depth_m::Float64 = 0.5
    amplitude_spreading_power::Float64 = 1.0
    absorption_db_per_m::Float64 = 0.0
    max_gain::Float64 = 1.0e6
end

"""
    process(traces::Vector{Trace}, params::TvgParams) -> Vector{Trace}

Apply physical time-varying gain to `traces` using each trace's sample interval.

Example:
`process(traces, TvgParams(sound_velocity_m_per_s=1520.0))`
"""
function process(traces::Vector{Trace}, params::TvgParams)::Vector{Trace}
    params.sound_velocity_m_per_s > 0.0 || throw(DomainError(params.sound_velocity_m_per_s, "sound_velocity_m_per_s must be positive"))
    params.reference_depth_m > 0.0 || throw(DomainError(params.reference_depth_m, "reference_depth_m must be positive"))
    params.amplitude_spreading_power >= 0.0 || throw(DomainError(params.amplitude_spreading_power, "amplitude_spreading_power must be non-negative"))
    params.max_gain >= 1.0 || throw(DomainError(params.max_gain, "max_gain must be at least 1.0"))
    return [Trace(trace.header, _apply_tvg(trace, params), trace.metadata) for trace in traces]
end

function _apply_tvg(trace::Trace, params::TvgParams)::Vector{Float64}
    dt_seconds = trace.header.sample_interval_microseconds * 1.0e-6
    dt_seconds > 0.0 || throw(DomainError(trace.header.sample_interval_microseconds, "trace sample_interval_microseconds must be positive"))

    samples = trace.samples
    output = similar(samples)
    reference_depth_m = params.reference_depth_m

    # Safe because the output vector matches the input sample count exactly.
    @inbounds @simd for sample_index in eachindex(samples)
        twtt_seconds = (sample_index - 1) * dt_seconds
        depth_m = max(reference_depth_m, 0.5 * params.sound_velocity_m_per_s * twtt_seconds)
        spreading_gain = (depth_m / reference_depth_m)^params.amplitude_spreading_power
        absorption_gain = 10.0^(params.absorption_db_per_m * (depth_m - reference_depth_m) / 20.0)
        gain = min(params.max_gain, spreading_gain * absorption_gain)
        output[sample_index] = samples[sample_index] * gain
    end
    return output
end

@register_step :tvg TvgParams
