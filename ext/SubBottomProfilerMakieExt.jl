module SubBottomProfilerMakieExt

using Makie
using SubBottomProfiler

const SBP = SubBottomProfiler

function SBP.Visualization._wiggle_plot_axis(
    axis::Makie.Axis,
    traces::Vector{SBP.Trace};
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
    sample_count, centered, max_amplitude = SBP.Visualization._prepare_wiggle_samples(traces; scale=scale)
    x_values, x_label, title_prefix = SBP.Visualization._wiggle_x_values(traces, horizontal_axis; distance_positions_m=distance_positions_m)
    y_values, y_label = SBP.Visualization._wiggle_y_values(traces, sample_count, vertical_axis; sound_speed_m_per_s=sound_speed_m_per_s)
    amplitude_scale = 0.45 * scale / max_amplitude

    for trace_index in eachindex(centered)
        x0 = x_values[trace_index]
        samples = centered[trace_index]
        x = x0 .+ samples .* amplitude_scale
        if shade_side == :positive
            positive_x = x0 .+ max.(samples, 0.0) .* amplitude_scale
            Makie.band!(axis, fill(x0, sample_count), positive_x, y_values; color=fill_color)
        elseif shade_side == :negative
            negative_x = x0 .+ min.(samples, 0.0) .* amplitude_scale
            Makie.band!(axis, fill(x0, sample_count), negative_x, y_values; color=fill_color)
        end
        Makie.lines!(axis, x, y_values; color=line_color, linewidth=line_width)
    end

    axis.xlabel = x_label
    axis.ylabel = y_label
    axis.title = string(title_prefix, " wiggle plot")
    Makie.xlims!(axis, minimum(x_values), maximum(x_values))
    Makie.ylims!(axis, maximum(y_values), minimum(y_values))
    return axis
end

function SBP.Visualization._display_wiggle_figure(
    ::Module,
    traces::Vector{SBP.Trace};
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
    fig = Makie.Figure(size=figure_size)
    axis = Makie.Axis(fig[1, 1])
    SBP.Visualization._wiggle_plot_axis(
        axis,
        traces;
        scale=scale,
        shade_side=shade_side,
        line_color=line_color,
        fill_color=fill_color,
        line_width=line_width,
        horizontal_axis=horizontal_axis,
        vertical_axis=vertical_axis,
        sound_speed_m_per_s=sound_speed_m_per_s,
        distance_positions_m=nothing,
    )
    display(fig)
    return fig
end

end
