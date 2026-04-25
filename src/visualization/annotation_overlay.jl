"""
    annotation_overlay(base::PlotSpec, annotations::Vector{String}; axis=nothing) -> PlotSpec

Attach annotations to a plot specification.

Example: `annotation_overlay(plot, ["water bottom"])`
"""
function annotation_overlay(base::PlotSpec, annotations::Vector{String}; axis=nothing)::PlotSpec
    metadata = copy(base.metadata)
    metadata[:axis] = axis === nothing ? get(metadata, :axis, "nothing") : string(axis)
    metadata[:annotations] = string(annotations)
    content = if base.format == :svg && occursin("</svg>", base.content)
        annotation_svg = IOBuffer()
        y = 70
        for annotation in annotations
            write(annotation_svg, "<text x=\"24\" y=\"$(_fmt(y))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#7c2d12\">$(annotation)</text>\n")
            y += 18
        end
        replace(base.content, "</svg>" => String(take!(annotation_svg)) * "</svg>")
    else
        base.content * "annotations=$(annotations)\n"
    end
    return PlotSpec(
        kind=Symbol(base.kind, :_annotated),
        format=base.format,
        content=content,
        width=base.width,
        height=base.height,
        metadata=metadata,
    )
end
