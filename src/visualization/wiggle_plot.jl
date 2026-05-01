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
    wiggle_plot(traces::Vector{Trace}; axis=nothing, scale=1.0, width=1400, height=900, fill_positive=true, shade_side=:positive, horizontal_axis=:trace_index, vertical_axis=:sample_index, sound_speed_m_per_s=1500.0, distance_positions_m=nothing)

Create a wiggle plot from `traces`.

When `axis === nothing`, this returns a rendered SVG-backed [`PlotSpec`](@ref).
When `axis` is a `Makie.Axis` and the optional `Makie` extension is loaded, the
same function renders interactively into that axis and returns the axis.

`shade_side` selects which lobe is filled for variable-area display and must be
`:positive`, `:negative`, or `:none`. `horizontal_axis` may be `:trace_index` or
`:distance`. `vertical_axis` may be `:sample_index` or `:depth`. When
`vertical_axis == :depth`, `sound_speed_m_per_s` is used to convert two-way travel
time to depth in meters. When `horizontal_axis == :distance`, the plot uses either
the supplied `distance_positions_m` or distances derived from SEG-Y navigation.

Example:
`wiggle_plot(traces; horizontal_axis=:distance, vertical_axis=:depth, sound_speed_m_per_s=1520.0)`
"""
function wiggle_plot(
    traces::Vector{Trace};
    axis=nothing,
    scale::Float64=1.0,
    width::Int=1400,
    height::Int=900,
    fill_positive::Bool=true,
    shade_side::Symbol=:positive,
    horizontal_axis::Symbol=:trace_index,
    vertical_axis::Symbol=:sample_index,
    sound_speed_m_per_s::Float64=1500.0,
    distance_positions_m::Union{Nothing, Vector{Float64}}=nothing,
)
    resolved_shade_side = _resolve_shade_side(fill_positive, shade_side)
    _validate_axis_modes(horizontal_axis, vertical_axis, sound_speed_m_per_s)
    if axis !== nothing
        return wiggle_plot!(
            axis,
            traces;
            scale=scale,
            fill_positive=fill_positive,
            shade_side=resolved_shade_side,
            horizontal_axis=horizontal_axis,
            vertical_axis=vertical_axis,
            sound_speed_m_per_s=sound_speed_m_per_s,
            distance_positions_m=distance_positions_m,
        )
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
    x_values, x_label, title_prefix = _wiggle_x_values(traces, horizontal_axis; distance_positions_m=distance_positions_m)
    y_values, y_label = _wiggle_y_values(traces, sample_count, vertical_axis; sound_speed_m_per_s=sound_speed_m_per_s)
    x_positions_px = _scale_positions(x_values, left, plot_width)
    y_positions_px = _scale_positions(y_values, top, plot_height)
    amplitude_scale = 0.45 * _wiggle_nominal_trace_spacing(x_positions_px) * scale / max_amplitude

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
        x_positions_px,
        y_positions_px,
        amplitude_scale,
        resolved_shade_side,
        x_values,
        y_values,
        x_label,
        y_label,
        title_prefix,
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
            :shade_side => string(resolved_shade_side),
            :horizontal_axis => string(horizontal_axis),
            :vertical_axis => string(vertical_axis),
            :sound_speed_m_per_s => string(sound_speed_m_per_s),
            :x_values => _join_floats(x_values),
            :y_values => _join_floats(y_values),
        ),
    )
end

"""
    wiggle_plot!(axis, traces::Vector{Trace}; scale=1.0, fill_positive=true, shade_side=:positive, line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0, horizontal_axis=:trace_index, vertical_axis=:sample_index, sound_speed_m_per_s=1500.0, distance_positions_m=nothing)

Render `traces` as an interactive wiggle plot into an existing `Makie.Axis`.
This method requires loading `Makie` and a display backend such as `GLMakie`.

Returns the input `axis`.

Example:
`wiggle_plot!(ax, traces; horizontal_axis=:distance, vertical_axis=:depth, sound_speed_m_per_s=1520.0)`
"""
function wiggle_plot!(
    axis,
    traces::Vector{Trace};
    scale::Float64=1.0,
    fill_positive::Bool=true,
    shade_side::Symbol=:positive,
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
    horizontal_axis::Symbol=:trace_index,
    vertical_axis::Symbol=:sample_index,
    sound_speed_m_per_s::Float64=1500.0,
    distance_positions_m::Union{Nothing, Vector{Float64}}=nothing,
)
    _prepare_wiggle_samples(traces; scale=scale)
    resolved_shade_side = _resolve_shade_side(fill_positive, shade_side)
    _validate_axis_modes(horizontal_axis, vertical_axis, sound_speed_m_per_s)
    return _wiggle_plot_axis(
        axis,
        traces;
        scale=scale,
        shade_side=resolved_shade_side,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
        horizontal_axis=horizontal_axis,
        vertical_axis=vertical_axis,
        sound_speed_m_per_s=sound_speed_m_per_s,
        distance_positions_m=distance_positions_m,
    )
end

"""
    display_wiggle(path::AbstractString; stride=1, scale=1.0, fill_positive=true, shade_side=:positive, figure_size=(1400, 900), line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0, horizontal_axis=:trace_index, vertical_axis=:sample_index, sound_speed_m_per_s=1500.0)

Read a SEG-Y file at `path`, render a decimated wiggle plot into a new
`Makie.Figure`, and display it on screen.
"""
function display_wiggle(
    path::AbstractString;
    stride::Int=1,
    scale::Float64=1.0,
    fill_positive::Bool=true,
    shade_side::Symbol=:positive,
    figure_size::Tuple{Int, Int}=(1400, 900),
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
    horizontal_axis::Symbol=:trace_index,
    vertical_axis::Symbol=:sample_index,
    sound_speed_m_per_s::Float64=1500.0,
)
    dataset = read_segy(path)
    return display_wiggle(
        dataset.traces;
        stride=stride,
        scale=scale,
        fill_positive=fill_positive,
        shade_side=shade_side,
        figure_size=figure_size,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
        horizontal_axis=horizontal_axis,
        vertical_axis=vertical_axis,
        sound_speed_m_per_s=sound_speed_m_per_s,
    )
end

"""
    display_wiggle(traces::Vector{Trace}; stride=1, scale=1.0, fill_positive=true, shade_side=:positive, figure_size=(1400, 900), line_color=:navy, fill_color=(:steelblue, 0.35), line_width=1.0, horizontal_axis=:trace_index, vertical_axis=:sample_index, sound_speed_m_per_s=1500.0)

Render `traces` into a new interactive `Makie.Figure` and display it on screen.
"""
function display_wiggle(
    traces::Vector{Trace};
    stride::Int=1,
    scale::Float64=1.0,
    fill_positive::Bool=true,
    shade_side::Symbol=:positive,
    figure_size::Tuple{Int, Int}=(1400, 900),
    line_color=:navy,
    fill_color=(:steelblue, 0.35),
    line_width::Float64=1.0,
    horizontal_axis::Symbol=:trace_index,
    vertical_axis::Symbol=:sample_index,
    sound_speed_m_per_s::Float64=1500.0,
)
    stride > 0 || throw(ArgumentError("stride must be positive"))
    figure_size[1] > 0 || throw(ArgumentError("figure_size width must be positive"))
    figure_size[2] > 0 || throw(ArgumentError("figure_size height must be positive"))
    selected_traces = traces[1:stride:end]
    isempty(selected_traces) && throw(ArgumentError("selected traces must be non-empty"))
    _prepare_wiggle_samples(selected_traces; scale=scale)
    resolved_shade_side = _resolve_shade_side(fill_positive, shade_side)
    _validate_axis_modes(horizontal_axis, vertical_axis, sound_speed_m_per_s)
    ext = Base.get_extension(parentmodule(@__MODULE__), :SubBottomProfilerMakieExt)
    return _display_wiggle_figure(
        ext,
        selected_traces;
        scale=scale,
        shade_side=resolved_shade_side,
        figure_size=figure_size,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
        horizontal_axis=horizontal_axis,
        vertical_axis=vertical_axis,
        sound_speed_m_per_s=sound_speed_m_per_s,
    )
end

function _wiggle_plot_axis(
    axis,
    traces::Vector{Trace};
    scale::Float64,
    shade_side::Symbol,
    line_color,
    fill_color,
    line_width::Float64,
    horizontal_axis::Symbol,
    vertical_axis::Symbol,
    sound_speed_m_per_s::Float64,
    distance_positions_m::Union{Nothing, Vector{Float64}},
)
    throw(ArgumentError("Makie backend not available. Load `Makie` and a backend such as `GLMakie` before calling `wiggle_plot!`."))
end

function _display_wiggle_figure(
    ::Nothing,
    traces::Vector{Trace};
    scale::Float64,
    shade_side::Symbol,
    figure_size::Tuple{Int, Int},
    line_color,
    fill_color,
    line_width::Float64,
    horizontal_axis::Symbol,
    vertical_axis::Symbol,
    sound_speed_m_per_s::Float64,
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
    x_positions_px::Vector{Float64},
    y_positions_px::Vector{Float64},
    amplitude_scale::Float64,
    shade_side::Symbol,
    x_values::Vector{Float64},
    y_values::Vector{Float64},
    x_label::String,
    y_label::String,
    title_prefix::String,
)::String
    svg = IOBuffer()
    write(svg, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(width)\" height=\"$(height)\" viewBox=\"0 0 $(width) $(height)\">\n")
    write(svg, "<rect width=\"100%\" height=\"100%\" fill=\"#f8f6ef\"/>\n")
    write(svg, "<rect x=\"$(_fmt(left))\" y=\"$(_fmt(top))\" width=\"$(_fmt(plot_width))\" height=\"$(_fmt(plot_height))\" fill=\"white\" stroke=\"#cbd2d9\" stroke-width=\"1\"/>\n")
    for grid_index in 0:4
        y = top + grid_index * plot_height / 4
        x = left + grid_index * plot_width / 4
        write(svg, "<line x1=\"$(_fmt(left))\" y1=\"$(_fmt(y))\" x2=\"$(_fmt(left + plot_width))\" y2=\"$(_fmt(y))\" stroke=\"#e9eef2\" stroke-width=\"1\"/>\n")
        write(svg, "<line x1=\"$(_fmt(x))\" y1=\"$(_fmt(top))\" x2=\"$(_fmt(x))\" y2=\"$(_fmt(top + plot_height))\" stroke=\"#f8fafc\" stroke-width=\"0.8\"/>\n")
    end
    for trace_index in eachindex(traces)
        x0 = x_positions_px[trace_index]
        write(svg, "<line x1=\"$(_fmt(x0))\" y1=\"$(_fmt(top))\" x2=\"$(_fmt(x0))\" y2=\"$(_fmt(top + plot_height))\" stroke=\"#f1f5f9\" stroke-width=\"0.5\"/>\n")
        if shade_side != :none
            fill_path = _wiggle_fill_path(traces[trace_index], x0, y_positions_px, amplitude_scale, shade_side)
            write(svg, "<path d=\"$(fill_path)\" fill=\"#8fb8d8\" fill-opacity=\"0.35\" stroke=\"none\"/>\n")
        end
        trace_path = _wiggle_line_path(traces[trace_index], x0, y_positions_px, amplitude_scale)
        write(svg, "<path d=\"$(trace_path)\" fill=\"none\" stroke=\"#0b3c5d\" stroke-width=\"0.9\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>\n")
    end
    _write_axis_ticks!(svg, left, top, plot_width, plot_height, x_values, y_values)
    write(svg, "<text x=\"$(_fmt(left))\" y=\"26\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"20\" fill=\"#102a43\">$(title_prefix) wiggle plot</text>\n")
    write(svg, "<text x=\"$(_fmt(left + plot_width / 2))\" y=\"$(_fmt(height - 18))\" text-anchor=\"middle\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">$(x_label)</text>\n")
    write(svg, "<text x=\"20\" y=\"$(_fmt(top + plot_height / 2))\" transform=\"rotate(-90 20 $(_fmt(top + plot_height / 2)))\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\" fill=\"#486581\">$(y_label)</text>\n")
    write(svg, "</svg>\n")
    return String(take!(svg))
end

function _wiggle_line_path(samples::Vector{Float64}, x0::Float64, y_positions_px::Vector{Float64}, amplitude_scale::Float64)::String
    path = IOBuffer()
    for index in eachindex(samples)
        x = x0 + samples[index] * amplitude_scale
        y = y_positions_px[index]
        if index == firstindex(samples)
            write(path, "M $(_fmt(x)) $(_fmt(y)) ")
        else
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        end
    end
    return String(take!(path))
end

function _wiggle_fill_path(
    samples::Vector{Float64},
    x0::Float64,
    y_positions_px::Vector{Float64},
    amplitude_scale::Float64,
    shade_side::Symbol,
)::String
    path = IOBuffer()
    started = false
    previous_filled = false
    for index in eachindex(samples)
        amplitude = _filled_amplitude(samples[index], shade_side)
        x = x0 + amplitude * amplitude_scale
        y = y_positions_px[index]
        if amplitude != 0.0 && !started
            write(path, "M $(_fmt(x0)) $(_fmt(y)) L $(_fmt(x)) $(_fmt(y)) ")
            started = true
        elseif amplitude != 0.0
            write(path, "L $(_fmt(x)) $(_fmt(y)) ")
        elseif started && previous_filled
            write(path, "L $(_fmt(x0)) $(_fmt(y)) ")
        end
        previous_filled = amplitude != 0.0
    end
    if started
        last_y = last(y_positions_px)
        write(path, "L $(_fmt(x0)) $(_fmt(last_y)) Z")
    end
    return String(take!(path))
end

function _validate_axis_modes(horizontal_axis::Symbol, vertical_axis::Symbol, sound_speed_m_per_s::Float64)
    horizontal_axis in (:trace_index, :distance) || throw(ArgumentError("horizontal_axis must be :trace_index or :distance"))
    vertical_axis in (:sample_index, :depth) || throw(ArgumentError("vertical_axis must be :sample_index or :depth"))
    sound_speed_m_per_s > 0.0 || throw(DomainError(sound_speed_m_per_s, "sound_speed_m_per_s must be positive"))
    return nothing
end

function _wiggle_x_values(
    traces::Vector{Trace},
    horizontal_axis::Symbol;
    distance_positions_m::Union{Nothing, Vector{Float64}}=nothing,
)::Tuple{Vector{Float64}, String, String}
    if horizontal_axis == :trace_index
        return collect(1.0:length(traces)), "Trace index", "SubBottomProfiler"
    end
    if distance_positions_m !== nothing
        length(distance_positions_m) == length(traces) || throw(ArgumentError("distance_positions_m must match trace count"))
        return Float64.(distance_positions_m), "Along-track distance (km)", "SubBottomProfiler distance"
    end
    return _trace_distances_m(traces), "Along-track distance (km)", "SubBottomProfiler distance"
end

function _wiggle_y_values(
    traces::Vector{Trace},
    sample_count::Int,
    vertical_axis::Symbol;
    sound_speed_m_per_s::Float64,
)::Tuple{Vector{Float64}, String}
    if vertical_axis == :sample_index
        return collect(1.0:sample_count), "Sample index"
    end
    dt_s = first(traces).header.sample_interval_microseconds * 1e-6
    return [twtt_to_depth((index - 1) * dt_s, sound_speed_m_per_s) for index in 1:sample_count], "Depth below sea surface (m)"
end

function _scale_positions(values::Vector{Float64}, start_px::Float64, span_px::Float64)::Vector{Float64}
    length(values) == 1 && return [start_px + span_px / 2]
    min_value = minimum(values)
    max_value = maximum(values)
    max_value > min_value || return fill(start_px + span_px / 2, length(values))
    return [start_px + span_px * (value - min_value) / (max_value - min_value) for value in values]
end

function _wiggle_nominal_trace_spacing(x_positions_px::Vector{Float64})::Float64
    length(x_positions_px) == 1 && return 1.0
    spacings = diff(x_positions_px)
    positive_spacings = filter(>(0.0), spacings)
    isempty(positive_spacings) && return 1.0
    return median(positive_spacings)
end

function _trace_distances_m(traces::Vector{Trace})::Vector{Float64}
    distances = zeros(Float64, length(traces))
    last_lon = NaN
    last_lat = NaN
    last_distance = 0.0
    have_last = false
    for index in eachindex(traces)
        x = traces[index].header.source_x
        y = traces[index].header.source_y
        if x == 0 && y == 0
            distances[index] = last_distance
            continue
        end
        lon = _scaled_coordinate(x, traces[index].header.scalco) / 3600.0
        lat = _scaled_coordinate(y, traces[index].header.scalco) / 3600.0
        if have_last
            last_distance += _haversine_m(last_lon, last_lat, lon, lat)
        end
        distances[index] = last_distance
        last_lon = lon
        last_lat = lat
        have_last = true
    end
    return distances
end

function _scaled_coordinate(value::Integer, scalco::Integer)::Float64
    scale = scalco > 0 ? Float64(scalco) : scalco < 0 ? 1.0 / abs(Float64(scalco)) : 1.0
    return Float64(value) * scale
end

function _haversine_m(lon1_deg::Float64, lat1_deg::Float64, lon2_deg::Float64, lat2_deg::Float64)::Float64
    r = 6371000.0
    deg2rad = pi / 180.0
    ϕ1 = lat1_deg * deg2rad
    ϕ2 = lat2_deg * deg2rad
    dϕ = (lat2_deg - lat1_deg) * deg2rad
    dλ = (lon2_deg - lon1_deg) * deg2rad
    a = sin(dϕ / 2)^2 + cos(ϕ1) * cos(ϕ2) * sin(dλ / 2)^2
    return 2r * asin(min(1.0, sqrt(a)))
end

function _write_axis_ticks!(
    svg::IO,
    left::Float64,
    top::Float64,
    plot_width::Float64,
    plot_height::Float64,
    x_values::Vector{Float64},
    y_values::Vector{Float64},
)
    for fraction in 0.0:0.25:1.0
        x = left + fraction * plot_width
        x_value = _interpolate_axis_value(x_values, fraction)
        x_label = maximum(x_values) > 1000 ? "$(round(x_value / 1000, digits=2)) km" : string(round(x_value, digits=1))
        write(svg, "<line x1=\"$(_fmt(x))\" y1=\"$(_fmt(top + plot_height))\" x2=\"$(_fmt(x))\" y2=\"$(_fmt(top + plot_height + 6))\" stroke=\"#486581\" stroke-width=\"1\"/>\n")
        write(svg, "<text x=\"$(_fmt(x))\" y=\"$(_fmt(top + plot_height + 24))\" text-anchor=\"middle\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"11\" fill=\"#486581\">$(x_label)</text>\n")
    end
    for fraction in 0.0:0.25:1.0
        y = top + fraction * plot_height
        y_value = _interpolate_axis_value(y_values, fraction)
        label = maximum(y_values) > 50 ? string(round(y_value, digits=1)) : string(round(y_value, digits=2))
        write(svg, "<line x1=\"$(_fmt(left - 6))\" y1=\"$(_fmt(y))\" x2=\"$(_fmt(left))\" y2=\"$(_fmt(y))\" stroke=\"#486581\" stroke-width=\"1\"/>\n")
        write(svg, "<text x=\"$(_fmt(left - 10))\" y=\"$(_fmt(y + 4))\" text-anchor=\"end\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"11\" fill=\"#486581\">$(label)</text>\n")
    end
    return nothing
end

function _interpolate_axis_value(values::Vector{Float64}, fraction::Float64)::Float64
    length(values) == 1 && return values[1]
    index = 1 + fraction * (length(values) - 1)
    lo = floor(Int, index)
    hi = ceil(Int, index)
    lo == hi && return values[lo]
    α = index - lo
    return (1.0 - α) * values[lo] + α * values[hi]
end

function _join_floats(values::Vector{Float64})::String
    return join((string(value) for value in values), ",")
end

function _resolve_shade_side(fill_positive::Bool, shade_side::Symbol)::Symbol
    if shade_side == :positive && !fill_positive
        return :none
    end
    shade_side in (:positive, :negative, :none) || throw(ArgumentError("shade_side must be :positive, :negative, or :none"))
    return shade_side
end

_filled_amplitude(sample::Float64, ::Val{:positive}) = max(sample, 0.0)
_filled_amplitude(sample::Float64, ::Val{:negative}) = min(sample, 0.0)
_filled_amplitude(sample::Float64, ::Val{:none}) = 0.0

function _filled_amplitude(sample::Float64, shade_side::Symbol)::Float64
    return _filled_amplitude(sample, Val(shade_side))
end

_fmt(value::Real)::String = string(round(Float64(value); digits=2))
