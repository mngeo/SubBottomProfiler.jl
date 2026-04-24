"""
    NotchFilterParams

Simple notch filter configuration.

Example: `NotchFilterParams(noise_period_samples=4)`
"""
Base.@kwdef struct NotchFilterParams
    noise_period_samples::Int = 4
end

function process(traces::Vector{Trace}, params::NotchFilterParams)::Vector{Trace}
    params.noise_period_samples > 1 || throw(ArgumentError("noise_period_samples must be greater than one"))
    kernel = zeros(Float64, params.noise_period_samples)
    kernel[1] = 1.0
    kernel[end] = -1.0
    return [Trace(trace.header, convolve_same(trace.samples, kernel), trace.metadata) for trace in traces]
end

@register_step :notch_filter NotchFilterParams
