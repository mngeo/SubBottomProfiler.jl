@testset "Visualization" begin
    dataset = synthetic_dataset(trace_count=12, sample_count=48)
    plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500)
    annotated = annotation_overlay(plot, ["water bottom", "reflector"])
    picks = [HorizonPick(index, 12 + mod(index, 4), 1.0, "test") for index in 1:length(dataset.traces)]
    overlayed = seabed_overlay(plot, picks; color="#dc2626", label="Synthetic seabed")
    diagnostic = WaterBottomPickResult(
        primary_picks=[
            HorizonPick(index, 12 + mod(index, 4), 1.0, index <= 8 ? "auto_continuity" : "auto_continuity_extrapolated")
            for index in 1:length(dataset.traces)
        ],
        alternative_picks=[HorizonPick(index, 18 + mod(index, 3), 0.5, "auto_alternative") for index in 9:length(dataset.traces)],
        warnings=["Synthetic extrapolation warning"],
        segment_break_after=[6],
    )
    diagnostic_overlay = seabed_overlay(plot, diagnostic)
    path = joinpath(@__DIR__, "..", "fixtures", "wiggle.svg")
    export_figure(path, overlayed)
    content = read(path, String)
    diagnostic_path = joinpath(@__DIR__, "..", "fixtures", "wiggle_diagnostic.svg")
    export_figure(diagnostic_path, diagnostic_overlay)
    diagnostic_content = read(diagnostic_path, String)
    @test plot.kind == :wiggle
    @test plot.format == :svg
    @test plot.metadata[:shade_side] == "positive"
    @test occursin("<svg", content)
    @test occursin("<path", content)
    @test occursin("<polyline", content)
    @test occursin("Synthetic seabed", content)
    @test overlayed.metadata[:seabed_overlay] == "true"
    @test diagnostic_overlay.metadata[:seabed_overlay_mode] == "diagnostic"
    @test occursin("stroke-dasharray=\"8 6\"", diagnostic_content)
    @test occursin("stroke-dasharray=\"3 5\"", diagnostic_content)
    @test occursin("Synthetic extrapolation warning", diagnostic_content)
    @test length(split(diagnostic_content, "<polyline")) - 1 >= 4
    crowded = WaterBottomPickResult(
        primary_picks=diagnostic.primary_picks,
        alternative_picks=diagnostic.alternative_picks,
        warnings=["warning $(index)" for index in 1:7],
        segment_break_after=diagnostic.segment_break_after,
    )
    crowded_overlay = seabed_overlay(plot, crowded)
    @test crowded_overlay.metadata[:seabed_overlay_warning_count] == "7"
    @test crowded_overlay.metadata[:seabed_overlay_warning_display_count] == "4"
    @test occursin("warning 1", crowded_overlay.content)
    @test occursin("warning 4", crowded_overlay.content)
    @test !occursin("warning 5", crowded_overlay.content)
    @test occursin("3 more warnings suppressed", crowded_overlay.content)
    @test_throws ArgumentError seabed_overlay(plot, picks[1:end-1])
    negative_plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500, shade_side=:negative)
    @test negative_plot.metadata[:shade_side] == "negative"
    @test occursin("fill=\"#8fb8d8\"", negative_plot.content)
    unfilled_plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500, shade_side=:none)
    @test unfilled_plot.metadata[:shade_side] == "none"
    @test !occursin("fill=\"#8fb8d8\"", unfilled_plot.content)
    nav_traces = [
        Trace(
            TraceHeader(
                trace_sequence_line=Int32(index),
                trace_sequence_file=Int32(index),
                source_x=Int32(round((-80.0 - 0.001 * (index - 1)) * 3600 * 1000)),
                source_y=Int32(round((28.0 + 0.001 * (index - 1)) * 3600 * 1000)),
                sample_count=48,
                sample_interval_microseconds=250,
                scalco=Int16(-1000),
                coordinate_units=Int16(2),
            ),
            dataset.traces[index].samples,
        )
        for index in 1:length(dataset.traces)
    ]
    distance_depth_plot = wiggle_plot(nav_traces; scale=1.0, width=800, height=500, horizontal_axis=:distance, vertical_axis=:depth, sound_speed_m_per_s=1520.0)
    distance_depth_overlay = seabed_overlay(distance_depth_plot, picks)
    @test distance_depth_plot.metadata[:horizontal_axis] == "distance"
    @test distance_depth_plot.metadata[:vertical_axis] == "depth"
    @test occursin("Along-track distance (km)", distance_depth_plot.content)
    @test occursin("Depth below sea surface (m)", distance_depth_plot.content)
    @test distance_depth_overlay.metadata[:seabed_overlay] == "true"
    @test_throws ArgumentError wiggle_plot(dataset.traces; scale=1.0, shade_side=:both)
    @test_throws DomainError wiggle_plot(dataset.traces; horizontal_axis=:distance, vertical_axis=:depth, sound_speed_m_per_s=0.0)

    struct DummyAxis end
    @test_throws ArgumentError wiggle_plot!(DummyAxis(), dataset.traces; scale=1.0)
    @test_throws ArgumentError display_wiggle(dataset.traces; stride=2, scale=1.0)
    @test_throws ArgumentError display_wiggle(dataset.traces; stride=0, scale=1.0)

    local makie_loaded = false
    try
        @eval using Makie
        makie_loaded = Base.get_extension(SubBottomProfiler, :SubBottomProfilerMakieExt) !== nothing
    catch
        makie_loaded = false
    end
    if makie_loaded
        fig = Makie.Figure()
        ax = Makie.Axis(fig[1, 1])
        rendered_axis = wiggle_plot!(ax, dataset.traces; scale=1.0, fill_positive=true)
        @test rendered_axis === ax
        @test wiggle_plot(dataset.traces; axis=ax, scale=1.0) === ax
        ax_negative = Makie.Axis(fig[1, 2])
        @test wiggle_plot!(ax_negative, dataset.traces; scale=1.0, shade_side=:negative) === ax_negative
        ax_distance = Makie.Axis(fig[2, 1])
        @test wiggle_plot!(ax_distance, nav_traces; scale=1.0, horizontal_axis=:distance, vertical_axis=:depth, sound_speed_m_per_s=1520.0) === ax_distance
        displayed = display_wiggle(dataset.traces; stride=3, scale=1.0, figure_size=(800, 500))
        @test displayed isa Makie.Figure
    end

    section = seismic_section(dataset.traces; width=700, height=400, max_columns=16, max_rows=24)
    section_path = joinpath(@__DIR__, "..", "fixtures", "section_rendered.svg")
    export_figure(section_path, section)
    section_content = read(section_path, String)
    @test section.kind == :section
    @test section.format == :svg
    @test section.metadata[:rendered_columns] == "12"
    @test occursin("<svg", section_content)
    @test occursin("<rect", section_content)
    @test_throws ArgumentError seabed_overlay(section, picks)

    spectrum = spectrum_plot(dataset.traces[1]; width=700, height=400, max_bins=32)
    spectrum_path = joinpath(@__DIR__, "..", "fixtures", "spectrum.svg")
    export_figure(spectrum_path, spectrum)
    spectrum_content = read(spectrum_path, String)
    @test spectrum.kind == :spectrum
    @test spectrum.format == :svg
    @test spectrum.metadata[:rendered_bins] == "24"
    @test occursin("<svg", spectrum_content)
    @test occursin("<path", spectrum_content)

    panel = velocity_panel([1450.0, 1500.0, 1550.0, 1490.0]; width=700, height=400)
    panel_path = joinpath(@__DIR__, "..", "fixtures", "velocity_panel.svg")
    export_figure(panel_path, panel)
    panel_content = read(panel_path, String)
    @test panel.kind == :velocity_panel
    @test panel.format == :svg
    @test panel.metadata[:count] == "4"
    @test occursin("<svg", panel_content)
    @test occursin("<circle", panel_content)
end
