"""
    PlotSpec

Lightweight plotting specification with optional rendered output content.

Example: `PlotSpec(kind=:wiggle, content="<svg />")`
"""
Base.@kwdef struct PlotSpec
    kind::Symbol
    format::Symbol = :text
    content::String = ""
    width::Int = 1200
    height::Int = 800
    metadata::Dict{Symbol, String} = Dict{Symbol, String}()
end

"""
    wiggle_plot(traces::Vector{Trace}; axis=nothing, scale=1.0, width=1400, height=900, fill_positive=true)

Create a wiggle plot from `traces`.

When `axis === nothing`, this returns a rendered SVG-backed [`PlotSpec`](@ref).
When `axis` is a `Makie.Axis` and the optional `Makie` extension is loaded, the
same function renders interactively into that axis and returns the axis.

Example: `wiggle_plot(traces; scale=1.5)`
"""
function wiggle_plot(
    traces::Vector{Trace};
    axis=nothing,
    scale::Float64=1.0,
    width::Int=1400,
    height::Int=900,
    fill_positive::Bool=true,
) 
    if axis !== nothing
        return wiggle_plot!(axis, traces; scale=scale, fill_positive=fill_positive)
    end

    sample_count, centered, max_amplitude = _prepare_wiggle_samples(traces; scale=scale)
    width > 0 || throw(ArgumentError("width must be positive"))
    height > 0 || throw(ArgumentError("height must be positive"))

    left = 80.0
    right = 40.0
    top = 40.0
    bottom = 70.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    trace_spacing = plot_width / max(length(traces) - 1, 1)
    sample_spacing = plot_height / max(sample_count - 1, 1)
    amplitude_scale = 0.45 * trace_spacing * scale / max_amplitude

    content = _render_wiggle_svg(
        centered,
        width,
        height,
        left,
        right,
        top,
        bottom,
        plot_width,
        plot_height,
        trace_spacing,
        sample_spacing,
        amplitude_scale,
        fill_positive,
    )
    return PlotSpec(
        kind=:wiggle,
        format=:svg,
        content=content,
        width=width,
        height=height,
        metadata=Dict(
            :axis => string(axis),
            :scale => string(scale),
            :trace_count => string(length(traces)),
            :sample_count => string(sample_count),
            :fill_positive => string(fill_positive),
        ),
    )
end

"""
    wiggle_plot!(axis, traces::Vector{Trace}; scale=1.0, fill_positive=true, line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0)

Render `traces` as an interactive wiggle plot into an existing `Makie.Axis`.
This method requires loading `Makie` and a display backend such as `GLMakie`.

Returns the input `axis`.

Example:
`wiggle_plot!(ax, traces; scale=1.2, fill_positive=true)`
"""
function wiggle_plot!(
    axis,
    traces::Vector{Trace};
    scale::Float64=1.0,
    fill_positive::Bool=true,
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
)
    _prepare_wiggle_samples(traces; scale=scale)
    return _wiggle_plot_axis(
        axis,
        traces;
        scale=scale,
        fill_positive=fill_positive,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
    )
end

"""
    display_wiggle(path::AbstractString; stride=1, scale=1.0, fill_positive=true, figure_size=(1400, 900), line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0)

Read a SEG-Y file at `path`, render a decimated wiggle plot into a new `Makie.Figure`,
and display it on screen.

This method requires loading `Makie` and a display backend such as `GLMakie`.
`stride` keeps every `stride`-th trace for interactive display.

Example:
`display_wiggle("Data/example.segy"; stride=40, scale=1.2)`
"""
function display_wiggle(
    path::AbstractString;
    stride::Int=1,
    scale::Float64=1.0,
    fill_positive::Bool=true,
    figure_size::Tuple{Int, Int}=(1400, 900),
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
)
    dataset = read_segy(path)
    return display_wiggle(
        dataset.traces;
        stride=stride,
        scale=scale,
        fill_positive=fill_positive,
        figure_size=figure_size,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
    )
end

"""
    display_wiggle(traces::Vector{Trace}; stride=1, scale=1.0, fill_positive=true, figure_size=(1400, 900), line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0)

Render `traces` into a new interactive `Makie.Figure` and display it on screen.
`stride` keeps every `stride`-th trace for interactive display.

This method requires loading `Makie` and a display backend such as `GLMakie`.

Example:
`display_wiggle(traces; stride=20, scale=1.1)`
"""
function display_wiggle(
    traces::Vector{Trace};
    stride::Int=1,
    scale::Float64=1.0,
    fill_positive::Bool=true,
    figure_size::Tuple{Int, Int}=(1400, 900),
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
)
    stride > 0 || throw(ArgumentError("stride must be positive"))
    figure_size[1] > 0 || throw(ArgumentError("figure_size width must be positive"))
    figure_size[2] > 0 || throw(ArgumentError("figure_size height must be positive"))
    selected_traces = traces[1:stride:end]
    isempty(selected_traces) && throw(ArgumentError("selected traces must be non-empty"))
    _prepare_wiggle_samples(selected_traces; scale=scale)
    ext = Base.get_extension(parentmodule(@__MODULE__), :SubBottomProfilerMakieExt)
    return _display_wiggle_figure(
        ext,
        selected_traces;
        scale=scale,
        fill_positive=fill_positive,
        figure_size=figure_size,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
    )
end

function _wiggle_plot_axis(
    axis,
    traces::Vector{Trace};
    scale::Float64,
    fill_positive::Bool,
    line_color,
    fill_color,
    line_width::Float64,
)
    throw(ArgumentError("Makie backend not available. Load `Makie` and a backend such as `GLMakie` before calling `wiggle_plot!`."))
end

function _display_wiggle_figure(
    ::Nothing,
    traces::Vector{Trace};
    scale::Float64,
    fill_positive::Bool,
    figure_size::Tuple{Int, Int},
    line_color,
    fill_color,
    line_width::Float64,
)
    throw(ArgumentError("Makie display backend not available. Load `Makie` and a display backend such as `GLMakie` before calling `display_wiggle`."))
end

function _prepare_wiggle_samples(traces::Vector{Trace}; scale::Float64)::Tuple{Int, Vector{Vector{Float64}}, Float64}
    isempty(traces) && throw(ArgumentError("traces must be non-empty"))
    scale > 0.0 || throw(DomainError(scale, "scale must be positive"))
    sample_count = length(first(traces).samples)
    all(length(trace.samples) == sample_count for trace in traces) || throw(ArgumentError("all traces must have the same sample count"))

    centered = [trace.samples .- mean(trace.samples) for trace in traces]
    max_amplitude = maximum(maximum(abs.(samples)) for samples in centered)
    max_amplitude > 0.0 || (max_amplitude = 1.0)
    return sample_count, centered, max_amplitude
end

function _render_wiggle_svg(
    traces::Vector{Vector{Float64}},
    width::Int,
    height::Int,
    left::Float64,
    right::Float64,
    top::Float64,
    bottom::Float64,
    plot_width::Float64,
    plot_height::Float64,
    trace_spacing::Float64,
    sample_spacing::Float64,
    amplitude_scale::Float64,
    fill_positive::Bool,
)::String
    svg = IOBuffer()
    write(svg, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(width)\" height=\"$(height)\" viewBox=\"0 0 $(width) $(height)\">\n")
    write(svg, "<rect width=\"100%\" height=\"100%\" fill=\"#f8f6ef\"/>\n")
    write(svg, "<rect x=\"$(_fmt(left))\" y=\"$(_fmt(top))\" width=\"$(_fmt(plot_width))\" height=\"$(_fmt(plot_height))\" fill=\"white\" stroke=\"#cbd2d9\" stroke-width=\"1\"/>\n")
    for grid_index in 0:4
        y = top + grid_index * plot_height / 4
        write(svg, "<line x1=\"$(_fmt(left))\" y1=\"$(_fmt(y))\" x2=\"$(_fmt(left + plot_width))\" y2=\"$(_fmt(y))\" stroke=\"#e9eef2\" stroke-width=\"1\"/>\n")
    end
    for trace_index in eachindex(traces)
        x0 = left + (trace_index - 1) * trace_spacing
        write(svg, "<line x1=\"$(_fmt(x0))\" y1=\"$(_fmt(top))\" x2=\"$(_fmt(x0))\" y2=\"$(_fmt(top + plot_height))\" stroke=\"#f1f5f9\" stroke-width=\"0.5\"/>\n")
        if fill_positive
            fill_path = _wiggle_fill_path(traces[trace_index], x0, top, sample_spacing, amplitude_scale)
            write(svg, "<path d=\"$(fill_path)\" fill=\"#8fb8d8\" fill-opacity=\"0.35\" stroke=\"none\"/>\n")
        end
        trace_path = _wiggle_line_path(traces[trace_index], x0, top, sample_spacing, amplitude_scale)
        write(svg, "<path d=\"$(trace_path)\" fill=\"none\" stroke=\"#0b3c5d\" stroke-width=\"0.9\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>\n")
    end
    write(svg, "<text x=\"$(_fmt(left))\" y=\"26\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"20\" fill=\"#102a43\">SubBottomProfiler wiggle plot</text>\n")
    write(svg, "<text x=\"$(_fmt(left))\" y=\"$(_fmt(height - 24))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Trace index</text>\n")
    write(svg, "<text x=\"20\" y=\"$(_fmt(top + plot_height / 2))\" transform=\"rotate(-90 20 $(_fmt(top + plot_height / 2)))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">Sample index</text>\n")
    write(svg, "</svg>\n")
    return String(take!(svg))
end

function _wiggle_line_path(samples::Vector{Float64}, x0::Float64, top::Float64, sample_spacing::Float64, amplitude_scale::Float64)::String
    path = IOBuffer()
    for index in eachindex(samples)
        x = x0 + samples[index] * amplitude_scale
        y = top + (index - 1) * sample_spacing
        if index == firstindex(samples)
            write(path, "M $(_fmt(x)) $(_fmt(y)) ")
        else
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        end
    end
    return String(take!(path))
end

function _wiggle_fill_path(samples::Vector{Float64}, x0::Float64, top::Float64, sample_spacing::Float64, amplitude_scale::Float64)::String
    path = IOBuffer()
    started = false
    previous_positive = false
    for index in eachindex(samples)
        amplitude = max(samples[index], 0.0)
        x = x0 + amplitude * amplitude_scale
        y = top + (index - 1) * sample_spacing
        if amplitude > 0.0 && !started
            write(path, "M $(_fmt(x0)) $(_fmt(y)) L $(_fmt(x)) $(_fmt(y)) ")
            started = true
        elseif amplitude > 0.0
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        elseif started && previous_positive
            write(path, "L $(_fmt(x0)) $(_fmt(y)) ")
        end
        previous_positive = amplitude > 0.0
    end
    if started
        last_y = top + (length(samples) - 1) * sample_spacing
        write(path, "L $(_fmt(x0)) $(_fmt(last_y)) Z")
    end
    return String(take!(path))
end

_fmt(value::Real)::String = string(round(Float64(value); digits=2))
