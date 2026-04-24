"""
    annotation_overlay(base::PlotSpec, annotations::Vector{String}; axis=nothing) -> PlotSpec

Attach annotations to a plot specification.

Example: `annotation_overlay(plot, ["water bottom"])`
"""
function annotation_overlay(base::PlotSpec, annotations::Vector{String}; axis=nothing)::PlotSpec
    payload = copy(base.payload)
    payload[:axis] = axis === nothing ? get(payload, :axis, "nothing") : string(axis)
    payload[:annotations] = string(annotations)
    return PlotSpec(Symbol(base.kind, :_annotated), payload)
end
