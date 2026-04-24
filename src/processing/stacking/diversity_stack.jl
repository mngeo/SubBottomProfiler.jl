"""
    DiversityStackParams

Robust diversity-stack configuration.

Example: `DiversityStackParams(trim_fraction=0.1)`
"""
Base.@kwdef struct DiversityStackParams
    trim_fraction::Float64 = 0.1
end

function process(traces::Vector{Trace}, params::DiversityStackParams)::Vector{Trace}
    isempty(traces) && return Trace[]
    0.0 <= params.trim_fraction < 0.5 || throw(DomainError(params.trim_fraction, "trim_fraction must be in [0, 0.5)"))
    sample_count = length(first(traces).samples)
    stacked = Float64[]
    for i in 1:sample_count
        values = sort([trace.samples[i] for trace in traces])
        trim = floor(Int, length(values) * params.trim_fraction)
        window = values[(trim + 1):(length(values) - trim)]
        push!(stacked, mean(window))
    end
    return [Trace(first(traces).header, stacked, Dict(:stack_fold => Float64(length(traces))))]
end

@register_step :diversity_stack DiversityStackParams
