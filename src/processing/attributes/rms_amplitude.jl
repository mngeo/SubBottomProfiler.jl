"""
    RmsAmplitudeParams

RMS amplitude attribute configuration.

Example: `RmsAmplitudeParams(window_samples=8)`
"""
Base.@kwdef struct RmsAmplitudeParams
    window_samples::Int = 8
end

function process(traces::Vector{Trace}, params::RmsAmplitudeParams)::Vector{Trace}
    params.window_samples > 0 || throw(ArgumentError("window_samples must be positive"))
    outputs = Trace[]
    for trace in traces
        values = Float64[]
        for i in eachindex(trace.samples)
            lo = max(1, i - div(params.window_samples, 2))
            hi = min(length(trace.samples), i + div(params.window_samples, 2))
            push!(values, rms(trace.samples[lo:hi]))
        end
        push!(outputs, Trace(trace.header, values, merge(trace.metadata, Dict(:rms_peak => maximum(values)))))
    end
    return outputs
end

@register_step :rms_amplitude RmsAmplitudeParams
