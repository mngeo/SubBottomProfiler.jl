"""
    seabed_overlay(base::PlotSpec, picks::Vector{HorizonPick}; color="#b91c1c", stroke_width=2.0, label="Water bottom pick") -> PlotSpec

Overlay a picked seabed horizon on a rendered wiggle-plot SVG.

The number of `picks` must match the plotted trace count stored in `base.metadata`.

Example:
`seabed_overlay(plot, picks; color="#dc2626")`
"""
function seabed_overlay(
    base::PlotSpec,
    picks::Vector{HorizonPick};
    color::String="#b91c1c",
    stroke_width::Float64=2.0,
    label::String="Water bottom pick",
)::PlotSpec
    base.format == :svg || throw(ArgumentError("seabed_overlay requires an SVG-backed PlotSpec"))
    startswith(String(base.kind), "wiggle") || throw(ArgumentError("seabed_overlay currently supports wiggle plots only"))
    occursin("</svg>", base.content) || throw(ArgumentError("plot content does not contain a closing SVG tag"))
    stroke_width > 0.0 || throw(DomainError(stroke_width, "stroke_width must be positive"))

    trace_count = parse(Int, get(base.metadata, :trace_count, "0"))
    sample_count = parse(Int, get(base.metadata, :sample_count, "0"))
    length(picks) == trace_count || throw(ArgumentError("pick count must match plot trace count"))
    sample_count > 0 || throw(ArgumentError("plot sample_count metadata must be positive"))
    all(1 <= pick.sample_index <= sample_count for pick in picks) || throw(ArgumentError("pick sample_index values must fall within the plotted sample range"))

    left = 80.0
    right = 40.0
    top = 40.0
    bottom = 70.0
    plot_width = base.width - left - right
    plot_height = base.height - top - bottom
    trace_spacing = plot_width / max(trace_count - 1, 1)
    sample_spacing = plot_height / max(sample_count - 1, 1)

    points = IOBuffer()
    for (index, pick) in enumerate(picks)
        x = left + (index - 1) * trace_spacing
        y = top + (pick.sample_index - 1) * sample_spacing
        write(points, "$(_fmt(x)),$(_fmt(y)) ")
    end
    overlay = "<polyline points=\"$(String(take!(points)))\" fill=\"none\" stroke=\"$(color)\" stroke-width=\"$(_fmt(stroke_width))\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>\n" *
              "<text x=\"24\" y=\"88\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"$(color)\">$(label)</text>\n"

    metadata = copy(base.metadata)
    metadata[:seabed_overlay] = "true"
    metadata[:seabed_overlay_color] = color
    metadata[:seabed_overlay_label] = label
    return PlotSpec(
        kind=Symbol(base.kind, :_seabed),
        format=base.format,
        content=replace(base.content, "</svg>" => overlay * "</svg>"),
        width=base.width,
        height=base.height,
        metadata=metadata,
    )
end
