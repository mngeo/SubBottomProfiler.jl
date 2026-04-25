@testset "Deconvolution" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, SpikingDeconParams())) == length(dataset.traces)
    @test length(process(dataset.traces, PredictiveDeconParams())) == length(dataset.traces)
    @test length(process(dataset.traces, WienerFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, WaveletEstimationParams())) == length(dataset.traces)

    wavelet = [-0.2, 0.3, 1.0, 0.3, -0.2]
    traces = Trace[]
    sample_count = 64
    for peak_index in 16:20
        samples = zeros(Float64, sample_count)
        for (offset, value) in enumerate(wavelet)
            samples[peak_index - 3 + offset] = value
        end
        header = TraceHeader(sample_count=sample_count, sample_interval_microseconds=100)
        push!(traces, Trace(header, samples))
    end
    estimate = estimate_wavelet(traces, WaveletEstimationParams(window_samples=5, search_start_sample=8, search_end_sample=32))
    @test estimate.contributing_traces == 5
    @test estimate.center_index == 3
    @test isapprox(estimate.samples[3], 1.0; atol=1e-6)
    @test isapprox(estimate.samples[1], -0.2; atol=0.05)
    @test isapprox(estimate.samples[5], -0.2; atol=0.05)

    reflectivity = zeros(Float64, 64)
    reflectivity[16] = 1.0
    reflectivity[30] = -0.5
    wavelet_samples = estimate.samples
    synthesized = zeros(Float64, 64)
    for i in eachindex(reflectivity)
        if reflectivity[i] == 0.0
            continue
        end
        for j in eachindex(wavelet_samples)
            k = i + j - estimate.center_index
            if 1 <= k <= length(synthesized)
                synthesized[k] += reflectivity[i] * wavelet_samples[j]
            end
        end
    end
    deconvolved = deconvolve_with_wavelet(
        [Trace(TraceHeader(sample_count=64, sample_interval_microseconds=100), synthesized)],
        estimate;
        stabilization=0.01,
    )[1]
    @test abs(deconvolved.samples[16]) > abs(deconvolved.samples[10])
    @test abs(deconvolved.samples[16]) > abs(deconvolved.samples[22])
    negative_window = deconvolved.samples[28:32]
    @test abs(minimum(negative_window)) >= abs(negative_window[1])
    @test minimum(negative_window) < 0.0
end
