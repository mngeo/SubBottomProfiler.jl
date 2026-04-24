"""
    schedule_pipeline(pipeline::ProcessingPipeline) -> Vector{Symbol}

Return the execution order of pipeline steps.

Example: `schedule_pipeline(pipeline)`
"""
schedule_pipeline(pipeline::ProcessingPipeline)::Vector{Symbol} = [step.name for step in pipeline.steps]
