@testset "Visualization" begin
    dataset = synthetic_dataset(trace_count=12, sample_count=48)
    plot = wiggle_plot(dataset.traces; scale=1.0, width=800, height=500)
    annotated = annotation_overlay(plot, ["water bottom", "reflector"])
    path = joinpath(@__DIR__, "..", "fixtures", "wiggle.svg")
    export_figure(path, annotated)
    content = read(path, String)
    @test plot.kind == :wiggle
    @test plot.format == :svg
    @test occursin("<svg", content)
    @test occursin("<path", content)
    @test occursin("water bottom", content)

    struct DummyAxis end
    @test_throws ArgumentError wiggle_plot!(DummyAxis(), dataset.traces; scale=1.0)
    @test_throws ArgumentError display_wiggle(dataset.traces; stride=2, scale=1.0)
    @test_throws ArgumentError display_wiggle(dataset.traces; stride=0, scale=1.0)

    local makie_loaded = false
    try
        @eval using Makie
        makie_loaded = true
    catch
        makie_loaded = false
    end
    if makie_loaded
        fig = Makie.Figure()
        ax = Makie.Axis(fig[1, 1])
        rendered_axis = wiggle_plot!(ax, dataset.traces; scale=1.0, fill_positive=true)
        @test rendered_axis === ax
        @test wiggle_plot(dataset.traces; axis=ax, scale=1.0) === ax
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
