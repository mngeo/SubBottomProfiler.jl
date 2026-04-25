"""
    velocity_panel(values::Vector{Float64}; axis=nothing, width=900, height=500) -> PlotSpec

Create a rendered velocity-panel SVG specification.

Example: `velocity_panel([1500.0, 1600.0])`
"""
function velocity_panel(values::Vector{Float64}; axis=nothing, width::Int=900, height::Int=500)::PlotSpec
    isempty(values) && throw(ArgumentError("values must be non-empty"))
    width > 0 || throw(ArgumentError("width must be positive"))
    height > 0 || throw(ArgumentError("height must be positive"))
    content = _render_velocity_panel_svg(values, width, height)
    return PlotSpec(
        kind=:velocity_panel,
        format=:svg,
        content=content,
        width=width,
        height=height,
        metadata=Dict(:axis => string(axis), :values => string(values), :count => string(length(values))),
    )
end

function _render_velocity_panel_svg(values::Vector{Float64}, width::Int, height::Int)::String
    left = 70.0
    right = 30.0
    top = 40.0
    bottom = 60.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    vmin = minimum(values)
    vmax = maximum(values)
    span = max(vmax - vmin, eps(Float64))
    step = plot_width / max(length(values) - 1, 1)
    path = IOBuffer()
    svg = IOBuffer()
    write(svg, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(width)\" height=\"$(height)\" viewBox=\"0 0 $(width) $(height)\">\n")
    write(svg, "<rect width=\"100%\" height=\"100%\" fill=\"#f8f6ef\"/>\n")
    write(svg, "<rect x=\"$(_fmt(left))\" y=\"$(_fmt(top))\" width=\"$(_fmt(plot_width))\" height=\"$(_fmt(plot_height))\" fill=\"white\" stroke=\"#cbd2d9\" stroke-width=\"1\"/>\n")
    for grid_index in 0:4
        y = top + grid_index * plot_height / 4
        write(svg, "<line x1=\"$(_fmt(left))\" y1=\"$(_fmt(y))\" x2=\"$(_fmt(left + plot_width))\" y2=\"$(_fmt(y))\" stroke=\"#e9eef2\" stroke-width=\"1\"/>\n")
    end
    for index in eachindex(values)
        x = left + (index - 1) * step
        y = top + plot_height - ((values[index] - vmin) / span) * plot_height
        if index == firstindex(values)
            write(path, "M $(_fmt(x)) $(_fmt(y)) ")
        else
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        end
        write(svg, "<circle cx=\"$(_fmt(x))\" cy=\"$(_fmt(y))\" r=\"4\" fill=\"#0b3c5d\"/>\n")
    end
    write(svg, "<path d=\"$(String(take!(path)))\" fill=\"none\" stroke=\"#ef9f27\" stroke-width=\"2\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"26\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"20\" fill=\"#102a43\">SubBottomProfiler velocity panel</text>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"$(_fmt(height - 20))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Pick index</text>\n")
    write(svg, "<text x=\"20\" y=\"$(_fmt(top + plot_height / 2))\" transform=\"rotate(-90 20 $(_fmt(top + plot_height / 2)))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Velocity</text>\n")
    write(svg, "</svg>\n")
    return String(take!(svg))
end
