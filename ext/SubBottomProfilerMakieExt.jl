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
)
    sample_count, centered, max_amplitude = SBP.Visualization._prepare_wiggle_samples(traces; scale=scale)
    trace_count = length(traces)
    y = collect(1:sample_count)
    amplitude_scale = 0.45 * scale / max_amplitude

    for trace_index in eachindex(centered)
        x0 = Float64(trace_index)
        samples = centered[trace_index]
        x = x0 .+ samples .* amplitude_scale
        if shade_side == :positive
            positive_x = x0 .+ max.(samples, 0.0) .* amplitude_scale
            Makie.band!(axis, fill(x0, sample_count), positive_x, y; color=fill_color)
        elseif shade_side == :negative
            negative_x = x0 .+ min.(samples, 0.0) .* amplitude_scale
            Makie.band!(axis, fill(x0, sample_count), negative_x, y; color=fill_color)
        end
        Makie.lines!(axis, x, y; color=line_color, linewidth=line_width)
    end

    axis.xlabel = "Trace index"
    axis.ylabel = "Sample index"
    axis.title = "SubBottomProfiler wiggle plot"
    Makie.xlims!(axis, 0.5, trace_count + 0.5)
    Makie.ylims!(axis, sample_count, 1)
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
    )
    display(fig)
    return fig
end

end
