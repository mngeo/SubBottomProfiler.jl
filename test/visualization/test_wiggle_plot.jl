@testset "Visualization" begin
    dataset = synthetic_dataset(trace_count=12, sample_count=48)
    plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500)
    annotated = annotation_overlay(plot, ["water bottom", "reflector"])
    picks = [HorizonPick(index, 12 + mod(index, 4), 1.0, "test") for index in 1:length(dataset.traces)]
    overlayed = seabed_overlay(plot, picks; color="#dc2626", label="Synthetic seabed")
    path = joinpath(@__DIR__, "..", "fixtures", "wiggle.svg")
    export_figure(path, overlayed)
    content = read(path, String)
    @test plot.kind == :wiggle
    @test plot.format == :svg
    @test plot.metadata[:shade_side] == "positive"
    @test occursin("<svg", content)
    @test occursin("<path", content)
    @test occursin("<polyline", content)
    @test occursin("Synthetic seabed", content)
    @test overlayed.metadata[:seabed_overlay] == "true"
    @test_throws ArgumentError seabed_overlay(plot, picks[1:end-1])
    negative_plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500, shade_side=:negative)
    @test negative_plot.metadata[:shade_side] == "negative"
    @test occursin("fill=\"#8fb8d8\"", negative_plot.content)
    unfilled_plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500, shade_side=:none)
    @test unfilled_plot.metadata[:shade_side] == "none"
    @test !occursin("fill=\"#8fb8d8\"", unfilled_plot.content)
    @test_throws ArgumentError wiggle_plot(dataset.traces; scale=1.0, shade_side=:both)

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
