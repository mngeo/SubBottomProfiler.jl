"""
    PlotSpec

Lightweight plotting specification for environments without a Makie dependency.

Example: `PlotSpec(:wiggle, Dict(:trace_count => 10))`
"""
struct PlotSpec
    kind::Symbol
    payload::Dict{Symbol, String}
end

"""
    wiggle_plot(traces::Vector{Trace}; axis=nothing, scale=1.0) -> PlotSpec

Create a wiggle-plot specification. `axis` may be a `Makie.Axis` when available.

Example: `wiggle_plot(traces; scale=1.5)`
"""
function wiggle_plot(traces::Vector{Trace}; axis=nothing, scale::Float64=1.0)::PlotSpec
    return PlotSpec(
        :wiggle,
        Dict(
            :axis => string(axis),
            :scale => string(scale),
            :trace_count => string(length(traces)),
            :samples => string([trace.samples for trace in traces]),
        ),
    )
end
