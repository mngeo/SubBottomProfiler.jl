"""
    SpikingDeconParams

Spiking deconvolution configuration.

Example: `SpikingDeconParams(prewhitening=0.01)`
"""
Base.@kwdef struct SpikingDeconParams
    prewhitening::Float64 = 0.01
end

function process(traces::Vector{Trace}, params::SpikingDeconParams)::Vector{Trace}
    return [Trace(trace.header, vcat(trace.samples[1], diff(trace.samples)) ./ (1.0 + params.prewhitening), trace.metadata) for trace in traces]
end

@register_step :spiking_decon SpikingDeconParams
