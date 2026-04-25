"""
    seismic_section(traces::Vector{Trace}; axis=nothing, colormap=SBP_SEISMIC_COLORMAP, width=1200, height=900, max_columns=400, max_rows=400) -> PlotSpec

Create a rendered seismic-section SVG specification.

Example: `seismic_section(traces)`
"""
function seismic_section(
    traces::Vector{Trace};
    axis=nothing,
    colormap=SBP_SEISMIC_COLORMAP,
    width::Int=1200,
    height::Int=900,
    max_columns::Int=400,
    max_rows::Int=400,
)::PlotSpec
    isempty(traces) && throw(ArgumentError("traces must be non-empty"))
    matrix = isempty(traces) ? Matrix{Float64}(undef, 0, 0) : reduce(hcat, [trace.samples for trace in traces])
    width > 0 || throw(ArgumentError("width must be positive"))
    height > 0 || throw(ArgumentError("height must be positive"))
    max_columns > 0 || throw(ArgumentError("max_columns must be positive"))
    max_rows > 0 || throw(ArgumentError("max_rows must be positive"))
    content, rendered_columns, rendered_rows = _render_section_svg(matrix, width, height, max_columns, max_rows, colormap)
    return PlotSpec(
        kind=:section,
        format=:svg,
        content=content,
        width=width,
        height=height,
        metadata=Dict(
            :axis => string(axis),
            :colormap => string(colormap),
            :trace_count => string(size(matrix, 2)),
            :sample_count => string(size(matrix, 1)),
            :rendered_columns => string(rendered_columns),
            :rendered_rows => string(rendered_rows),
        ),
    )
end

function _render_section_svg(
    matrix::Matrix{Float64},
    width::Int,
    height::Int,
    max_columns::Int,
    max_rows::Int,
    colormap,
)::Tuple{String, Int, Int}
    rows, columns = size(matrix)
    row_stride = max(1, ceil(Int, rows / max_rows))
    column_stride = max(1, ceil(Int, columns / max_columns))
    row_indices = collect(1:row_stride:rows)
    column_indices = collect(1:column_stride:columns)
    decimated = matrix[row_indices, column_indices]
    rendered_rows, rendered_columns = size(decimated)

    left = 80.0
    right = 40.0
    top = 40.0
    bottom = 70.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    cell_width = plot_width / max(rendered_columns, 1)
    cell_height = plot_height / max(rendered_rows, 1)

    clipped = clamp.(decimated ./ max(maximum(abs.(decimated)), eps(Float64)), -1.0, 1.0)
    svg = IOBuffer()
    write(svg, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(width)\" height=\"$(height)\" viewBox=\"0 0 $(width) $(height)\">\n")
    write(svg, "<rect width=\"100%\" height=\"100%\" fill=\"#f8f6ef\"/>\n")
    write(svg, "<rect x=\"$(_fmt(left))\" y=\"$(_fmt(top))\" width=\"$(_fmt(plot_width))\" height=\"$(_fmt(plot_height))\" fill=\"white\" stroke=\"#cbd2d9\" stroke-width=\"1\"/>\n")
    for row in 1:rendered_rows
        y = top + (row - 1) * cell_height
        for column in 1:rendered_columns
            x = left + (column - 1) * cell_width
            fill = _section_color(clipped[row, column], colormap)
            write(
                svg,
                "<rect x=\"$(_fmt(x))\" y=\"$(_fmt(y))\" width=\"$(_fmt(cell_width + 0.2))\" height=\"$(_fmt(cell_height + 0.2))\" fill=\"$(fill)\" stroke=\"none\"/>\n",
            )
        end
    end
    write(svg, "<text x=\"$(_fmt(left))\" y=\"26\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"20\" fill=\"#102a43\">SubBottomProfiler seismic section</text>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"$(_fmt(height - 24))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Trace index (decimated)</text>\n")
    write(svg, "<text x=\"20\" y=\"$(_fmt(top + plot_height / 2))\" transform=\"rotate(-90 20 $(_fmt(top + plot_height / 2)))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Sample index (decimated)</text>\n")
    write(svg, "</svg>\n")
    return String(take!(svg)), rendered_columns, rendered_rows
end

function _section_color(value::Float64, colormap)::String
    palette = isempty(colormap) ? SBP_SEISMIC_COLORMAP : colormap
    anchors = range(-1.0, 1.0; length=length(palette))
    if value <= first(anchors)
        return palette[1]
    elseif value >= last(anchors)
        return palette[end]
    end
    upper = findfirst(anchor -> anchor >= value, anchors)
    lower = upper - 1
    t = (value - anchors[lower]) / (anchors[upper] - anchors[lower])
    return _lerp_hex(palette[lower], palette[upper], t)
end

function _lerp_hex(a::AbstractString, b::AbstractString, t::Float64)::String
    ar, ag, ab = _hex_rgb(a)
    br, bg, bb = _hex_rgb(b)
    r = round(Int, ar + t * (br - ar))
    g = round(Int, ag + t * (bg - ag))
    bvalue = round(Int, ab + t * (bb - ab))
    return "#" * _hex2(r) * _hex2(g) * _hex2(bvalue)
end

function _hex_rgb(hex::AbstractString)::NTuple{3, Int}
    cleaned = replace(String(hex), "#" => "")
    return (
        parse(Int, cleaned[1:2]; base=16),
        parse(Int, cleaned[3:4]; base=16),
        parse(Int, cleaned[5:6]; base=16),
    )
end

_hex2(value::Int)::String = lowercase(string(value, base=16, pad=2))
