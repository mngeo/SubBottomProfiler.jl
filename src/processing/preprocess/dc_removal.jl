"""
    DcRemovalParams

DC-removal configuration.

Example: `DcRemovalParams()`
"""
Base.@kwdef struct DcRemovalParams
    enabled::Bool = true
end

function process(traces::Vector{Trace}, params::DcRemovalParams)::Vector{Trace}
    params.enabled || return copy(traces)
    return [Trace(trace.header, trace.samples .- mean(trace.samples), trace.metadata) for trace in traces]
end

@register_step :dc_removal DcRemovalParams
