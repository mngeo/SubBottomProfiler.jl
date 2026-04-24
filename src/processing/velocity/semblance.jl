"""
    SemblanceParams

Semblance analysis configuration.

Example: `SemblanceParams(window_samples=8)`
"""
Base.@kwdef struct SemblanceParams
    window_samples::Int = 8
end

function process(traces::Vector{Trace}, params::SemblanceParams)::Vector{Trace}
    params.window_samples > 0 || throw(ArgumentError("window_samples must be positive"))
    outputs = Trace[]
    for trace in traces
        numer = moving_average(abs.(trace.samples), params.window_samples)
        denom = moving_average(trace.samples .^ 2, params.window_samples) .+ eps(Float64)
        semblance = numer .^ 2 ./ denom
        push!(outputs, Trace(trace.header, semblance, merge(trace.metadata, Dict(:semblance_peak => maximum(semblance)))))
    end
    return outputs
end

@register_step :semblance SemblanceParams
