"""
    BandpassParams

FFT-based bandpass configuration in hertz.

Arguments:
- `lowcut_hz`: low cutoff frequency in hertz.
- `highcut_hz`: high cutoff frequency in hertz.
- `smoothing_samples`: cosine taper half-width in frequency bins.

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
    params.smoothing_samples >= 0 || throw(ArgumentError("smoothing_samples must be non-negative"))
    return [Trace(trace.header, _bandpass_trace(trace, params), trace.metadata) for trace in traces]
end

function _bandpass_trace(trace::Trace, params::BandpassParams)::Vector{Float64}
    dt = trace.header.sample_interval_microseconds * 1.0e-6
    dt > 0.0 || throw(DomainError(dt, "trace sample interval must be positive"))
    samples = trace.samples .- mean(trace.samples)
    spectrum = rfft(samples)
    freqs = FFTW.rfftfreq(length(samples), 1.0 / dt)
    weights = _bandpass_weights(freqs, params.lowcut_hz, params.highcut_hz, params.smoothing_samples)
    filtered = irfft(spectrum .* weights, length(samples))
    return collect(real(filtered))
end

function _bandpass_weights(freqs, lowcut_hz::Float64, highcut_hz::Float64, smoothing_samples::Int)::Vector{Float64}
    weights = zeros(Float64, length(freqs))
    inband = findall(freq -> lowcut_hz <= freq <= highcut_hz, freqs)
    isempty(inband) && return weights
    first_inband = first(inband)
    last_inband = last(inband)
    weights[first_inband:last_inband] .= 1.0
    if smoothing_samples > 0
        taper = collect(range(0.0, 1.0; length=smoothing_samples + 2))[2:(end - 1)]
        for (offset, weight) in enumerate(taper)
            lower_index = first_inband - smoothing_samples - 1 + offset
            upper_index = last_inband + offset
            if 1 <= lower_index < first_inband
                weights[lower_index] = max(weights[lower_index], 0.5 * (1.0 - cos(pi * weight)))
            end
            if last_inband < upper_index <= length(weights)
                weights[upper_index] = max(weights[upper_index], 0.5 * (1.0 + cos(pi * weight)))
            end
        end
    end
    return weights
end

@register_step :bandpass BandpassParams
