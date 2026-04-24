"""
    FkFilterParams

F-K style spatial coherence filter configuration.

Example: `FkFilterParams(spatial_window=3)`
"""
Base.@kwdef struct FkFilterParams
    spatial_window::Int = 3
end

function process(traces::Vector{Trace}, params::FkFilterParams)::Vector{Trace}
    params.spatial_window > 0 || throw(ArgumentError("spatial_window must be positive"))
    isempty(traces) && return Trace[]
    sample_count = length(first(traces).samples)
    stacked = [mean([trace.samples[i] for trace in traces[max(1, j - params.spatial_window):min(end, j + params.spatial_window)]]) for j in eachindex(traces), i in 1:sample_count]
    return [Trace(traces[j].header, vec(stacked[j, :]), traces[j].metadata) for j in eachindex(traces)]
end

@register_step :fk_filter FkFilterParams
