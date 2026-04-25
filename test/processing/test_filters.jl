@testset "Filters" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, BandpassParams())) == length(dataset.traces)
    @test length(process(dataset.traces, NotchFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, FkFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, MedianFilterParams())) == length(dataset.traces)

    sample_count = 256
    dt_us = 100
    times = (0:(sample_count - 1)) .* (dt_us * 1.0e-6)
    signal = sin.(2pi .* 200 .* times) .+ 0.8 .* sin.(2pi .* 2000 .* times)
    trace = Trace(TraceHeader(sample_count=sample_count, sample_interval_microseconds=dt_us), signal)
    filtered = process([trace], BandpassParams(lowcut_hz=1000.0, highcut_hz=3000.0, smoothing_samples=4))[1]
    low_ref = sin.(2pi .* 200 .* times)
    high_ref = sin.(2pi .* 2000 .* times)
    low_energy = abs(sum(filtered.samples .* low_ref))
    high_energy = abs(sum(filtered.samples .* high_ref))
    @test high_energy > 3 * low_energy
end
