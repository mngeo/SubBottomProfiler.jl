"""
    BandpassParams

Bandpass smoothing configuration in hertz and samples.

Example: `BandpassParams(lowcut_hz=500.0, highcut_hz=3500.0, smoothing_samples=9)`
"""
Base.@kwdef struct BandpassParams
    lowcut_hz::Float64 = 500.0
    highcut_hz::Float64 = 3500.0
    smoothing_samples::Int = 9
end

function process(traces::Vector{Trace}, params::BandpassParams)::Vector{Trace}
    params.lowcut_hz >= 0.0 || throw(DomainError(params.lowcut_hz, "lowcut_hz must be non-negative"))
    params.highcut_hz > params.lowcut_hz || throw(DomainError(params.highcut_hz, "highcut_hz must exceed lowcut_hz"))
    return [Trace(trace.header, trace.samples .- moving_average(trace.samples, params.smoothing_samples), trace.metadata) for trace in traces]
end

@register_step :bandpass BandpassParams
