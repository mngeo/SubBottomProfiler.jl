"""
    load_workflow(path::AbstractString) -> ProcessingPipeline

Load a TOML workflow definition.

Example: `load_workflow("docs/workflows/basic_processing.toml")`
"""
function load_workflow(path::AbstractString)::ProcessingPipeline
    config = TOML.parsefile(path)
    steps = PipelineStep[]
    for entry in get(config, "steps", Any[])
        name = Symbol(entry["name"])
        kwargs = Dict{Symbol, String}()
        for (key, value) in pairs(entry)
            key == "name" && continue
            kwargs[Symbol(key)] = string(value)
        end
        push!(steps, PipelineStep(name, kwargs))
    end
    return ProcessingPipeline(steps)
end

"""
    run_workflow(dataset::Dataset, workflow_path::AbstractString) -> Dataset

Load and run a workflow TOML file.

Example: `run_workflow(dataset, "workflow.toml")`
"""
run_workflow(dataset::Dataset, workflow_path::AbstractString)::Dataset = run_pipeline(dataset, load_workflow(workflow_path))
