"""
    WaveletEstimationParams

Wavelet estimation configuration.

Example: `WaveletEstimationParams(window_samples=16)`
"""
Base.@kwdef struct WaveletEstimationParams
    window_samples::Int = 16
end

function process(traces::Vector{Trace}, params::WaveletEstimationParams)::Vector{Trace}
    params.window_samples > 0 || throw(ArgumentError("window_samples must be positive"))
    return [Trace(trace.header, moving_average(trace.samples, params.window_samples), merge(trace.metadata, Dict(:wavelet_peak => maximum(abs.(trace.samples)))),) for trace in traces]
end

@register_step :wavelet_estimation WaveletEstimationParams
