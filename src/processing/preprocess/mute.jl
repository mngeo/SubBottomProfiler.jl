"""
    MuteParams

Mute configuration in trace samples.

Example: `MuteParams(top_samples=16, taper_fraction=0.1)`
"""
Base.@kwdef struct MuteParams
    top_samples::Int = 0
    bottom_samples::Int = 0
    taper_fraction::Float64 = 0.05
end

function process(traces::Vector{Trace}, params::MuteParams)::Vector{Trace}
    params.top_samples >= 0 || throw(ArgumentError("top_samples must be non-negative"))
    params.bottom_samples >= 0 || throw(ArgumentError("bottom_samples must be non-negative"))
    return [Trace(trace.header, _apply_mute(trace.samples, params), trace.metadata) for trace in traces]
end

function _apply_mute(samples::Vector{Float64}, params::MuteParams)::Vector{Float64}
    result = copy(samples)
    n = length(result)
    top = min(params.top_samples, n)
    bottom = min(params.bottom_samples, n)
    if top > 0
        taper = cosine_taper(top; fraction=min(params.taper_fraction, 0.5))
        for i in 1:top
            result[i] *= taper[i]
        end
    end
    if bottom > 0
        taper = cosine_taper(bottom; fraction=min(params.taper_fraction, 0.5))
        for i in 1:bottom
            idx = n - bottom + i
            result[idx] *= taper[bottom - i + 1]
        end
    end
    return result
end

@register_step :mute MuteParams
