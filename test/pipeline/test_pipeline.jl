@testset "Pipeline" begin
    dataset = synthetic_dataset()
    pipeline = ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "8")),
        PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "5")),
    ])
    output = run_pipeline(dataset, pipeline)
    workflow_output = run_workflow(dataset, joinpath(@__DIR__, "..", "..", "docs", "workflows", "basic_processing.toml"))
    plot = seismic_section(output.traces)
    figure_path = joinpath(@__DIR__, "..", "fixtures", "section.svg")
    export_figure(figure_path, plot)
    @test length(output.traces) == length(dataset.traces)
    @test length(workflow_output.traces) == length(dataset.traces)
    @test isfile(figure_path)
end
