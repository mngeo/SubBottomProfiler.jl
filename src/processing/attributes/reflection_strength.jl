"""
    ReflectionStrengthParams

Reflection-strength attribute configuration.

Example: `ReflectionStrengthParams()`
"""
Base.@kwdef struct ReflectionStrengthParams
    power::Float64 = 2.0
end

function process(traces::Vector{Trace}, params::ReflectionStrengthParams)::Vector{Trace}
    return [Trace(trace.header, abs.(trace.samples) .^ params.power, merge(trace.metadata, Dict(:reflection_strength_peak => maximum(abs.(trace.samples) .^ params.power)))) for trace in traces]
end

@register_step :reflection_strength ReflectionStrengthParams
