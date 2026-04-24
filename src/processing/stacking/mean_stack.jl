"""
    MeanStackParams

Stacking configuration.

Example: `MeanStackParams(method="mean")`
"""
Base.@kwdef struct MeanStackParams
    method::String = "mean"
end

function process(traces::Vector{Trace}, params::MeanStackParams)::Vector{Trace}
    isempty(traces) && return Trace[]
    samples = if params.method == "median"
        [median([trace.samples[i] for trace in traces]) for i in eachindex(first(traces).samples)]
    else
        [mean([trace.samples[i] for trace in traces]) for i in eachindex(first(traces).samples)]
    end
    header = first(traces).header
    return [Trace(header, samples, Dict(:stack_fold => Float64(length(traces))))]
end

@register_step :mean_stack MeanStackParams
