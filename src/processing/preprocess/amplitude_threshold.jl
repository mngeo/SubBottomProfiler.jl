"""
    AmplitudeThresholdParams

Per-sample amplitude thresholding configuration.

Arguments:
- `mode`: threshold mode (`"hard"` or `"soft"`).
- `threshold_percent`: threshold as a percentage of the chosen reference amplitude.
- `reference`: threshold reference (`"trace_max"` or `"trace_rms"`).

Returns:
- `AmplitudeThresholdParams`

Example:
`AmplitudeThresholdParams(mode="hard", threshold_percent=2.0, reference="trace_max")`
"""
Base.@kwdef struct AmplitudeThresholdParams
    mode::String = "hard"
    threshold_percent::Float64 = 2.0
    reference::String = "trace_max"
end

"""
    process(traces::Vector{Trace}, params::AmplitudeThresholdParams) -> Vector{Trace}

Apply per-sample amplitude thresholding to `traces`.

In `"hard"` mode, samples below the threshold are set to exactly zero.
In `"soft"` mode, samples are shrunk toward zero by the threshold amount.

Example:
`process(traces, AmplitudeThresholdParams(threshold_percent=1.5))`
"""
function process(traces::Vector{Trace}, params::AmplitudeThresholdParams)::Vector{Trace}
    0.0 <= params.threshold_percent <= 100.0 || throw(DomainError(params.threshold_percent, "threshold_percent must be in [0, 100]"))
    return [Trace(trace.header, _apply_amplitude_threshold(trace.samples, params), trace.metadata) for trace in traces]
end

function _apply_amplitude_threshold(samples::Vector{Float64}, params::AmplitudeThresholdParams)::Vector{Float64}
    reference_value = _threshold_reference(samples, params.reference)
    threshold = reference_value * params.threshold_percent / 100.0
    if params.mode == "hard"
        return [abs(sample) < threshold ? 0.0 : sample for sample in samples]
    elseif params.mode == "soft"
        return [sign(sample) * max(abs(sample) - threshold, 0.0) for sample in samples]
    end
    throw(ArgumentError("unsupported threshold mode $(params.mode)"))
end

function _threshold_reference(samples::Vector{Float64}, reference::String)::Float64
    if reference == "trace_max"
        return maximum(abs.(samples))
    elseif reference == "trace_rms"
        return rms(samples)
    end
    throw(ArgumentError("unsupported threshold reference $(reference)"))
end

@register_step :amplitude_threshold AmplitudeThresholdParams
