"""
    MedianFilterParams

Spatial median filter configuration across neighbouring traces.

Example: `MedianFilterParams(spatial_window=1)`
"""
Base.@kwdef struct MedianFilterParams
    spatial_window::Int = 1
end

function process(traces::Vector{Trace}, params::MedianFilterParams)::Vector{Trace}
    params.spatial_window >= 0 || throw(ArgumentError("spatial_window must be non-negative"))
    isempty(traces) && return Trace[]
    sample_count = length(first(traces).samples)
    filtered = Trace[]
    for j in eachindex(traces)
        lo = max(1, j - params.spatial_window)
        hi = min(length(traces), j + params.spatial_window)
        samples = [median([traces[k].samples[i] for k in lo:hi]) for i in 1:sample_count]
        push!(filtered, Trace(traces[j].header, samples, traces[j].metadata))
    end
    return filtered
end

@register_step :median_filter MedianFilterParams
