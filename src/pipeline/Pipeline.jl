module Pipeline

using Logging
using TOML

using ..SegyModel: Dataset
using ..Processing: process_dataset, instantiate_registered_step, describe_registered_steps

include("pipeline.jl")
include("workflow.jl")
include("scheduler.jl")
include("progress.jl")

export PipelineStep, ProcessingPipeline, run_pipeline, load_workflow, run_workflow, log_progress

end
