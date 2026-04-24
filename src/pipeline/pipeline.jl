"""
    PipelineStep

Named processing step with keyword-argument parameters.

Example: `PipelineStep(:gain, Dict(:mode => "agc"))`
"""
struct PipelineStep
    name::Symbol
    kwargs::Dict{Symbol, String}
end

"""
    ProcessingPipeline

Composable collection of pipeline steps.

Example: `ProcessingPipeline([PipelineStep(:gain, Dict())])`
"""
struct ProcessingPipeline
    steps::Vector{PipelineStep}
end

"""
    run_pipeline(dataset::Dataset, pipeline::ProcessingPipeline) -> Dataset

Run a dataset through all registered pipeline steps.

Example: `run_pipeline(dataset, pipeline)`
"""
function run_pipeline(dataset::Dataset, pipeline::ProcessingPipeline)::Dataset
    current = dataset
    for step in pipeline.steps
        params = instantiate_registered_step(step.name, step.kwargs)
        current = process_dataset(current, params)
    end
    return current
end
