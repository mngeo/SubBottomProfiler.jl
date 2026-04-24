"""
    EnvelopeParams

Envelope attribute configuration.

Example: `EnvelopeParams()`
"""
Base.@kwdef struct EnvelopeParams
    store_key::Symbol = :envelope_peak
end

function process(traces::Vector{Trace}, params::EnvelopeParams)::Vector{Trace}
    return [Trace(trace.header, analytic_envelope(trace.samples), merge(trace.metadata, Dict(params.store_key => maximum(analytic_envelope(trace.samples))))) for trace in traces]
end

@register_step :envelope EnvelopeParams
