"""
    GainParams

Gain-processing configuration.

Arguments:
- `mode`: gain mode (`"agc"`, `"linear"`, or `"exponential"`).
- `window_samples`: AGC window length in samples.
- `slope_per_sample`: linear gain slope in amplitude per sample.
- `exponent`: exponential gain coefficient in 1/sample.

Example: `GainParams(mode="agc", window_samples=32)`
"""
Base.@kwdef struct GainParams
    mode::String = "agc"
    window_samples::Int = 32
    slope_per_sample::Float64 = 0.001
    exponent::Float64 = 0.002
end

function process(traces::Vector{Trace}, params::GainParams)::Vector{Trace}
    params.window_samples > 0 || throw(ArgumentError("window_samples must be positive"))
    return [Trace(trace.header, _apply_gain(trace.samples, params), trace.metadata) for trace in traces]
end

function _apply_gain(samples::Vector{Float64}, params::GainParams)::Vector{Float64}
    n = length(samples)
    if params.mode == "agc"
        scale = moving_average(abs.(samples), params.window_samples)
        return samples ./ max.(scale, eps(Float64))
    elseif params.mode == "linear"
        return [samples[i] * (1.0 + params.slope_per_sample * (i - 1)) for i in 1:n]
    elseif params.mode == "exponential"
        return [samples[i] * exp(params.exponent * (i - 1)) for i in 1:n]
    end
    throw(ArgumentError("unsupported gain mode $(params.mode)"))
end

@register_step :gain GainParams
