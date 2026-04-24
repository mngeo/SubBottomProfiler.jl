"""
    NmoCorrectionParams

Normal moveout correction configuration.

Arguments:
- `velocity_m_per_s`: reference velocity in meters per second.
- `stretch_mute_limit`: maximum fractional stretch.

Example: `NmoCorrectionParams(velocity_m_per_s=1500.0)`
"""
Base.@kwdef struct NmoCorrectionParams
    velocity_m_per_s::Float64 = 1500.0
    stretch_mute_limit::Float64 = 0.3
end

function process(traces::Vector{Trace}, params::NmoCorrectionParams)::Vector{Trace}
    params.velocity_m_per_s > 0.0 || throw(DomainError(params.velocity_m_per_s, "velocity must be positive"))
    outputs = Trace[]
    for trace in traces
        dt = trace.header.sample_interval_microseconds * 1.0e-6
        corrected = zeros(Float64, length(trace.samples))
        for i in eachindex(trace.samples)
            t0 = (i - 1) * dt
            tn = sqrt(t0^2 + (trace.header.offset_meters / params.velocity_m_per_s)^2)
            stretch = t0 == 0.0 ? 0.0 : abs(tn - t0) / t0
            if stretch <= params.stretch_mute_limit || i == 1
                index = clamp(round(Int, tn / dt) + 1, 1, length(trace.samples))
                corrected[i] = trace.samples[index]
            end
        end
        push!(outputs, Trace(trace.header, corrected, trace.metadata))
    end
    return outputs
end

@register_step :nmo_correction NmoCorrectionParams
