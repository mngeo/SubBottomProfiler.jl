"""
    InstantaneousFreqParams

Instantaneous frequency attribute configuration.

Example: `InstantaneousFreqParams()`
"""
Base.@kwdef struct InstantaneousFreqParams
    sample_interval_seconds::Float64 = 2.5e-4
end

function process(traces::Vector{Trace}, params::InstantaneousFreqParams)::Vector{Trace}
    params.sample_interval_seconds > 0.0 || throw(DomainError(params.sample_interval_seconds, "sample interval must be positive"))
    outputs = Trace[]
    for trace in traces
        phase = hilbert_phase(trace.samples)
        frequency = vcat(0.0, diff(phase)) ./ (2pi * params.sample_interval_seconds)
        push!(outputs, Trace(trace.header, frequency, trace.metadata))
    end
    return outputs
end

@register_step :instantaneous_freq InstantaneousFreqParams
