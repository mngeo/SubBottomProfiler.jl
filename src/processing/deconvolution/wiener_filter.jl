"""
    WienerFilterParams

Wiener smoothing configuration.

Example: `WienerFilterParams(window_samples=5)`
"""
Base.@kwdef struct WienerFilterParams
    window_samples::Int = 5
end

function process(traces::Vector{Trace}, params::WienerFilterParams)::Vector{Trace}
    params.window_samples > 0 || throw(ArgumentError("window_samples must be positive"))
    return [Trace(trace.header, moving_average(trace.samples, params.window_samples), trace.metadata) for trace in traces]
end

@register_step :wiener_filter WienerFilterParams
