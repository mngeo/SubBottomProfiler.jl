"""
    spectrum_plot(trace::Trace; axis=nothing, width=900, height=500, max_bins=256) -> PlotSpec

Create a rendered spectrum-display SVG specification.

Example: `spectrum_plot(trace)`
"""
function spectrum_plot(
    trace::Trace;
    axis=nothing,
    width::Int=900,
    height::Int=500,
    max_bins::Int=256,
)::PlotSpec
    width > 0 || throw(ArgumentError("width must be positive"))
    height > 0 || throw(ArgumentError("height must be positive"))
    max_bins > 0 || throw(ArgumentError("max_bins must be positive"))
    amplitude = abs.(trace.samples)
    stride = max(1, ceil(Int, length(amplitude) / max_bins))
    bins = collect(1:stride:length(amplitude))
    sampled = amplitude[bins]
    max_amplitude = max(maximum(sampled), eps(Float64))
    content = _render_spectrum_svg(sampled, width, height, max_amplitude)
    return PlotSpec(
        kind=:spectrum,
        format=:svg,
        content=content,
        width=width,
        height=height,
        metadata=Dict(
            :axis => string(axis),
            :mean_amplitude => string(mean(amplitude)),
            :rendered_bins => string(length(sampled)),
            :sample_stride => string(stride),
        ),
    )
end

function _render_spectrum_svg(samples::Vector{Float64}, width::Int, height::Int, max_amplitude::Float64)::String
    left = 70.0
    right = 30.0
    top = 40.0
    bottom = 60.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    bar_width = plot_width / max(length(samples), 1)
    svg = IOBuffer()
    write(svg, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(width)\" height=\"$(height)\" viewBox=\"0 0 $(width) $(height)\">\n")
    write(svg, "<rect width=\"100%\" height=\"100%\" fill=\"#f8f6ef\"/>\n")
    write(svg, "<rect x=\"$(_fmt(left))\" y=\"$(_fmt(top))\" width=\"$(_fmt(plot_width))\" height=\"$(_fmt(plot_height))\" fill=\"white\" stroke=\"#cbd2d9\" stroke-width=\"1\"/>\n")
    for grid_index in 0:4
        y = top + grid_index * plot_height / 4
        write(svg, "<line x1=\"$(_fmt(left))\" y1=\"$(_fmt(y))\" x2=\"$(_fmt(left + plot_width))\" y2=\"$(_fmt(y))\" stroke=\"#e9eef2\" stroke-width=\"1\"/>\n")
    end
    path = IOBuffer()
    for index in eachindex(samples)
        x = left + (index - 0.5) * bar_width
        y = top + plot_height - (samples[index] / max_amplitude) * plot_height
        if index == firstindex(samples)
            write(path, "M $(_fmt(x)) $(_fmt(y)) ")
        else
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        end
        write(
            svg,
            "<rect x=\"$(_fmt(left + (index - 1) * bar_width))\" y=\"$(_fmt(y))\" width=\"$(_fmt(max(bar_width - 0.5, 0.5)))\" height=\"$(_fmt(top + plot_height - y))\" fill=\"#8fb8d8\" fill-opacity=\"0.55\" stroke=\"none\"/>\n",
        )
    end
    write(svg, "<path d=\"$(String(take!(path)))\" fill=\"none\" stroke=\"#0b3c5d\" stroke-width=\"1.5\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"26\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"20\" fill=\"#102a43\">SubBottomProfiler spectrum</text>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"$(_fmt(height - 20))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Sample bin</text>\n")
    write(svg, "<text x=\"20\" y=\"$(_fmt(top + plot_height / 2))\" transform=\"rotate(-90 20 $(_fmt(top + plot_height / 2)))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Amplitude</text>\n")
    write(svg, "</svg>\n")
    return String(take!(svg))
end
