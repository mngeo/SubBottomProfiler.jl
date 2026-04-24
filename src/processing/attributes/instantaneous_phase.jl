"""
    InstantaneousPhaseParams

Instantaneous phase attribute configuration.

Example: `InstantaneousPhaseParams()`
"""
Base.@kwdef struct InstantaneousPhaseParams
    unwrap_phase::Bool = false
end

function process(traces::Vector{Trace}, params::InstantaneousPhaseParams)::Vector{Trace}
    return [Trace(trace.header, hilbert_phase(trace.samples), trace.metadata) for trace in traces]
end

@register_step :instantaneous_phase InstantaneousPhaseParams
