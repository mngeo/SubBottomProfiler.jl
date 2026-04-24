"""
    NavMergeParams

Navigation-merge configuration.

Example: `NavMergeParams()`
"""
Base.@kwdef struct NavMergeParams
    overwrite_existing::Bool = true
end

function process(traces::Vector{Trace}, params::NavMergeParams)::Vector{Trace}
    return [Trace(trace.header, trace.samples, merge(trace.metadata, Dict(:nav_merged => params.overwrite_existing ? 1.0 : 0.0))) for trace in traces]
end

@register_step :nav_merge NavMergeParams
