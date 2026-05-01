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

    x_positions_px, y_positions_px = _seabed_overlay_positions(base, trace_count, sample_count)

    points = IOBuffer()
    for (index, pick) in enumerate(picks)
        x = x_positions_px[index]
        y = y_positions_px[pick.sample_index]
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

"""
    seabed_overlay(base::PlotSpec, result::WaterBottomPickResult; primary_color="#b91c1c", extrapolated_color="#f59e0b", alternative_color="#2563eb", stroke_width=2.0, label="Water bottom pick") -> PlotSpec

Overlay a diagnostic water-bottom result on a rendered wiggle-plot SVG. Measured
primary picks, extrapolated primary picks, and alternative deeper candidates are
drawn with distinct styles.

Example:
`seabed_overlay(plot, result; alternative_color="#1d4ed8")`
"""
function seabed_overlay(
    base::PlotSpec,
    result::WaterBottomPickResult;
    primary_color::String="#b91c1c",
    extrapolated_color::String="#f59e0b",
    alternative_color::String="#2563eb",
    stroke_width::Float64=2.0,
    label::String="Water bottom pick",
)::PlotSpec
    _validate_seabed_overlay_base(base, result.primary_picks, stroke_width)
    overlay = IOBuffer()
    write(overlay, _pick_polyline_svg(base, [pick for pick in result.primary_picks if !occursin("extrapolated", pick.provenance) && !occursin("unresolved", pick.provenance)]; color=primary_color, stroke_width=stroke_width, break_after=result.segment_break_after))
    write(overlay, _pick_polyline_svg(base, [pick for pick in result.primary_picks if occursin("extrapolated", pick.provenance)]; color=extrapolated_color, stroke_width=stroke_width, stroke_dasharray="8 6", break_after=result.segment_break_after))
    write(overlay, _pick_polyline_svg(base, result.alternative_picks; color=alternative_color, stroke_width=max(1.2, 0.8 * stroke_width), stroke_dasharray="3 5"))
    write(overlay, "<text x=\"24\" y=\"88\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"$(primary_color)\">$(label)</text>\n")
    write(overlay, "<text x=\"24\" y=\"106\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"11\" fill=\"$(extrapolated_color)\">Extrapolated continuation</text>\n")
    write(overlay, "<text x=\"24\" y=\"124\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"11\" fill=\"$(alternative_color)\">Alternative deeper candidate</text>\n")
    warning_count = length(result.warnings)
    displayed_warning_count = _write_overlay_warnings!(overlay, result.warnings)

    metadata = copy(base.metadata)
    metadata[:seabed_overlay] = "true"
    metadata[:seabed_overlay_mode] = "diagnostic"
    metadata[:seabed_overlay_primary_color] = primary_color
    metadata[:seabed_overlay_extrapolated_color] = extrapolated_color
    metadata[:seabed_overlay_alternative_color] = alternative_color
    metadata[:seabed_overlay_warning_count] = string(warning_count)
    metadata[:seabed_overlay_warning_display_count] = string(displayed_warning_count)
    return PlotSpec(
        kind=Symbol(base.kind, :_seabed),
        format=base.format,
        content=replace(base.content, "</svg>" => String(take!(overlay)) * "</svg>"),
        width=base.width,
        height=base.height,
        metadata=metadata,
    )
end

function _write_overlay_warnings!(overlay::IO, warnings::Vector{String})::Int
    isempty(warnings) && return 0
    max_rendered_warnings = 4
    warning_y = 142
    displayed = min(length(warnings), max_rendered_warnings)
    for warning in warnings[1:displayed]
        write(overlay, "<text x=\"24\" y=\"$(_fmt(warning_y))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"10\" fill=\"#9f1239\">$(warning)</text>\n")
        warning_y += 16
    end
    hidden = length(warnings) - displayed
    if hidden > 0
        summary = hidden == 1 ? "1 more warning suppressed" : "$(hidden) more warnings suppressed"
        write(overlay, "<text x=\"24\" y=\"$(_fmt(warning_y))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"10\" fill=\"#9f1239\">$(summary)</text>\n")
    end
    return displayed
end

function _validate_seabed_overlay_base(base::PlotSpec, picks::Vector{HorizonPick}, stroke_width::Float64)
    base.format == :svg || throw(ArgumentError("seabed_overlay requires an SVG-backed PlotSpec"))
    startswith(String(base.kind), "wiggle") || throw(ArgumentError("seabed_overlay currently supports wiggle plots only"))
    occursin("</svg>", base.content) || throw(ArgumentError("plot content does not contain a closing SVG tag"))
    stroke_width > 0.0 || throw(DomainError(stroke_width, "stroke_width must be positive"))

    trace_count = parse(Int, get(base.metadata, :trace_count, "0"))
    sample_count = parse(Int, get(base.metadata, :sample_count, "0"))
    length(picks) == trace_count || throw(ArgumentError("pick count must match plot trace count"))
    sample_count > 0 || throw(ArgumentError("plot sample_count metadata must be positive"))
    all(1 <= pick.sample_index <= sample_count for pick in picks) || throw(ArgumentError("pick sample_index values must fall within the plotted sample range"))
    return nothing
end

function _seabed_overlay_dimensions(base::PlotSpec)::Tuple{Int, Int}
    return (
        parse(Int, get(base.metadata, :trace_count, "0")),
        parse(Int, get(base.metadata, :sample_count, "0")),
    )
end

function _seabed_overlay_positions(base::PlotSpec, trace_count::Int, sample_count::Int)::Tuple{Vector{Float64}, Vector{Float64}}
    left = 80.0
    right = 40.0
    top = 40.0
    bottom = 70.0
    plot_width = base.width - left - right
    plot_height = base.height - top - bottom
    if haskey(base.metadata, :x_values)
        x_values = _parse_float_list(base.metadata[:x_values])
        length(x_values) == trace_count || throw(ArgumentError("plot x_values metadata must match trace count"))
        x_positions = _scale_positions(x_values, left, plot_width)
    else
        trace_spacing = plot_width / max(trace_count - 1, 1)
        x_positions = [left + (index - 1) * trace_spacing for index in 1:trace_count]
    end
    if haskey(base.metadata, :y_values)
        y_values = _parse_float_list(base.metadata[:y_values])
        length(y_values) == sample_count || throw(ArgumentError("plot y_values metadata must match sample count"))
        y_positions = _scale_positions(y_values, top, plot_height)
    else
        sample_spacing = plot_height / max(sample_count - 1, 1)
        y_positions = [top + (index - 1) * sample_spacing for index in 1:sample_count]
    end
    return x_positions, y_positions
end

function _pick_polyline_svg(
    base::PlotSpec,
    picks::Vector{HorizonPick};
    color::String,
    stroke_width::Float64,
    stroke_dasharray::String="",
    break_after::Vector{Int}=Int[],
)::String
    isempty(picks) && return ""
    trace_count, sample_count = _seabed_overlay_dimensions(base)
    x_positions_px, y_positions_px = _seabed_overlay_positions(base, trace_count, sample_count)

    trace_to_pick = Dict(pick.trace_index => pick for pick in picks)
    break_after_set = Set(break_after)
    paths = IOBuffer()
    current_points = IOBuffer()
    in_segment = false
    for trace_index in 1:trace_count
        if haskey(trace_to_pick, trace_index)
            pick = trace_to_pick[trace_index]
            x = x_positions_px[trace_index]
            y = y_positions_px[pick.sample_index]
            write(current_points, "$(_fmt(x)),$(_fmt(y)) ")
            in_segment = true
            if trace_index in break_after_set
                write(paths, _polyline_markup(String(take!(current_points)), color, stroke_width, stroke_dasharray))
                in_segment = false
            end
        elseif in_segment
            write(paths, _polyline_markup(String(take!(current_points)), color, stroke_width, stroke_dasharray))
            in_segment = false
        end
    end
    if in_segment
        write(paths, _polyline_markup(String(take!(current_points)), color, stroke_width, stroke_dasharray))
    end
    return String(take!(paths))
end

function _parse_float_list(values::String)::Vector{Float64}
    isempty(values) && return Float64[]
    return parse.(Float64, split(values, ","))
end

function _polyline_markup(points::String, color::String, stroke_width::Float64, stroke_dasharray::String)::String
    isempty(strip(points)) && return ""
    dash = isempty(stroke_dasharray) ? "" : " stroke-dasharray=\"$(stroke_dasharray)\""
    return "<polyline points=\"$(points)\" fill=\"none\" stroke=\"$(color)\" stroke-width=\"$(_fmt(stroke_width))\" stroke-linejoin=\"round\" stroke-linecap=\"round\"$(dash)/>\n"
end
