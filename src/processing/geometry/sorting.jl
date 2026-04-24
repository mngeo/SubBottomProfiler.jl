"""
    SortingParams

Trace sorting configuration.

Example: `SortingParams(key=:trace_sequence_line)`
"""
Base.@kwdef struct SortingParams
    key::Symbol = :trace_sequence_line
end

function process(traces::Vector{Trace}, params::SortingParams)::Vector{Trace}
    return sort(traces; by=trace -> getproperty(trace.header, params.key))
end

@register_step :sorting SortingParams
