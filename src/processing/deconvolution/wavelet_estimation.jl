"""
    WaveletEstimationParams

Wavelet estimation configuration.

Arguments:
- `window_samples`: extracted wavelet window length in samples.
- `search_start_sample`: start of the search window for the reference arrival.
- `search_end_sample`: end of the search window for the reference arrival.
- `normalize`: normalize the estimated wavelet to unit peak amplitude.

Example: `WaveletEstimationParams(window_samples=16)`
"""
Base.@kwdef struct WaveletEstimationParams
    window_samples::Int = 17
    search_start_sample::Int = 1
    search_end_sample::Int = 256
    normalize::Bool = true
end

"""
    EstimatedWavelet

Estimated source wavelet sampled in the trace time domain.

Example: `EstimatedWavelet([0.0, 1.0, 0.0], 62, 2, 10)`
"""
struct EstimatedWavelet
    samples::Vector{Float64}
    sample_interval_microseconds::Int
    center_index::Int
    contributing_traces::Int
end

"""
    deconvolve_with_wavelet(traces::Vector{Trace}, wavelet::EstimatedWavelet; stabilization=0.01) -> Vector{Trace}

Apply stabilized wavelet deconvolution using an estimated source wavelet.

Example: `deconvolve_with_wavelet(traces, wavelet; stabilization=0.02)`
"""
function deconvolve_with_wavelet(traces::Vector{Trace}, wavelet::EstimatedWavelet; stabilization::Float64=0.01)::Vector{Trace}
    isempty(traces) && return Trace[]
    stabilization > 0.0 || throw(DomainError(stabilization, "stabilization must be positive"))
    wavelet.sample_interval_microseconds > 0 || throw(ArgumentError("wavelet sample interval must be positive"))

    outputs = Trace[]
    for trace in traces
        trace.header.sample_interval_microseconds == wavelet.sample_interval_microseconds || throw(ArgumentError("trace and wavelet sample intervals must match"))
        deconvolved = _deconvolve_samples(trace.samples, wavelet.samples, stabilization)
        push!(
            outputs,
            Trace(
                trace.header,
                deconvolved,
                merge(trace.metadata, Dict(:deconvolution_stabilization => stabilization, :wavelet_length => Float64(length(wavelet.samples)))),
            ),
        )
    end
    return outputs
end

function _deconvolve_samples(samples::Vector{Float64}, wavelet_samples::Vector{Float64}, stabilization::Float64)::Vector{Float64}
    n = length(samples)
    wavelet_padded = zeros(Float64, n)
    copy_count = min(length(wavelet_samples), n)
    wavelet_padded[1:copy_count] .= wavelet_samples[1:copy_count]
    spectrum = rfft(samples)
    wavelet_spectrum = rfft(wavelet_padded)
    power = abs2.(wavelet_spectrum)
    λ = stabilization * maximum(power)
    inverse_filter = conj.(wavelet_spectrum) ./ (power .+ λ)
    deconvolved = irfft(spectrum .* inverse_filter, n)
    return collect(real(deconvolved))
end

"""
    estimate_wavelet(traces::Vector{Trace}, params::WaveletEstimationParams) -> EstimatedWavelet

Estimate a representative source wavelet by aligning short windows around the
strongest arrival in each trace, correcting polarity, and stacking the windows.

Example: `estimate_wavelet(traces, WaveletEstimationParams(window_samples=21))`
"""
function estimate_wavelet(traces::Vector{Trace}, params::WaveletEstimationParams)::EstimatedWavelet
    isempty(traces) && throw(ArgumentError("traces must be non-empty"))
    params.window_samples > 1 || throw(ArgumentError("window_samples must be greater than one"))
    isodd(params.window_samples) || throw(ArgumentError("window_samples must be odd to preserve a wavelet center"))
    params.search_start_sample >= 1 || throw(ArgumentError("search_start_sample must be positive"))
    params.search_end_sample >= params.search_start_sample || throw(ArgumentError("search_end_sample must be greater than or equal to search_start_sample"))

    radius = div(params.window_samples - 1, 2)
    sample_interval = first(traces).header.sample_interval_microseconds
    all(trace.header.sample_interval_microseconds == sample_interval for trace in traces) || throw(ArgumentError("all traces must share the same sample interval"))

    accumulator = zeros(Float64, params.window_samples)
    contributing = 0
    for trace in traces
        lo = max(1, params.search_start_sample)
        hi = min(length(trace.samples), params.search_end_sample)
        hi - lo + 1 >= params.window_samples || continue
        window = trace.samples[lo:hi]
        local_peak = argmax(abs.(window))
        peak_index = lo + local_peak - 1
        segment_lo = peak_index - radius
        segment_hi = peak_index + radius
        if segment_lo < 1 || segment_hi > length(trace.samples)
            continue
        end
        segment = copy(trace.samples[segment_lo:segment_hi])
        if segment[radius + 1] < 0.0
            segment .*= -1.0
        end
        accumulator .+= segment
        contributing += 1
    end
    contributing > 0 || throw(ArgumentError("no traces contributed to the wavelet estimate"))
    estimate = accumulator ./ contributing
    if params.normalize
        estimate ./= max(maximum(abs.(estimate)), eps(Float64))
    end
    return EstimatedWavelet(estimate, sample_interval, radius + 1, contributing)
end

function process(traces::Vector{Trace}, params::WaveletEstimationParams)::Vector{Trace}
    estimate = estimate_wavelet(traces, params)
    return [
        Trace(
            trace.header,
            trace.samples,
            merge(
                trace.metadata,
                Dict(
                    :wavelet_peak => maximum(abs.(estimate.samples)),
                    :wavelet_length => Float64(length(estimate.samples)),
                    :wavelet_contributors => Float64(estimate.contributing_traces),
                ),
            ),
        ) for trace in traces
    ]
end

@register_step :wavelet_estimation WaveletEstimationParams
