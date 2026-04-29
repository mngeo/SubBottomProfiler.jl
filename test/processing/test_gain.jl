@testset "Gain" begin
    dataset = synthetic_dataset()
    output = process(dataset.traces, GainParams(mode="linear", slope_per_sample=0.01))
    @test length(output) == length(dataset.traces)
    @test output[1].samples[10] != dataset.traces[1].samples[10]
end

@testset "Amplitude Threshold" begin
    trace = Trace(TraceHeader(sample_count=5, sample_interval_microseconds=1000), [0.01, -0.03, 0.10, -0.40, 1.0])

    hard = process([trace], AmplitudeThresholdParams(mode="hard", threshold_percent=10.0, reference="trace_max"))
    @test hard[1].samples == [0.0, 0.0, 0.10, -0.40, 1.0]

    soft = process([trace], AmplitudeThresholdParams(mode="soft", threshold_percent=10.0, reference="trace_max"))
    @test isapprox.(soft[1].samples, [0.0, -0.0, 0.0, -0.30, 0.90], atol=1.0e-12) |> all

    rms_ref = process([trace], AmplitudeThresholdParams(mode="hard", threshold_percent=20.0, reference="trace_rms"))
    @test rms_ref[1].samples[end] == 1.0

    @test_throws DomainError process([trace], AmplitudeThresholdParams(threshold_percent=-1.0))
    @test_throws ArgumentError process([trace], AmplitudeThresholdParams(mode="bad"))
    @test_throws ArgumentError process([trace], AmplitudeThresholdParams(reference="bad"))
end

@testset "TVG" begin
    header = TraceHeader(sample_count=5, sample_interval_microseconds=1000)
    trace = Trace(header, ones(5))

    output = process([trace], TvgParams(sound_velocity_m_per_s=1500.0, reference_depth_m=0.5, amplitude_spreading_power=1.0, absorption_db_per_m=0.0))
    @test length(output) == 1
    @test isapprox(output[1].samples[1], 1.0; atol=1.0e-12)
    @test isapprox(output[1].samples[2], 1.5; atol=1.0e-12)
    @test isapprox(output[1].samples[5], 6.0; atol=1.0e-12)

    absorbed = process([trace], TvgParams(sound_velocity_m_per_s=1500.0, reference_depth_m=0.5, amplitude_spreading_power=1.0, absorption_db_per_m=0.2))
    @test absorbed[1].samples[end] > output[1].samples[end]

    limited = process([trace], TvgParams(sound_velocity_m_per_s=1500.0, reference_depth_m=0.5, amplitude_spreading_power=3.0, max_gain=4.0))
    @test maximum(limited[1].samples) <= 4.0

    bad_trace = Trace(TraceHeader(sample_count=5, sample_interval_microseconds=0), ones(5))
    @test_throws DomainError process([bad_trace], TvgParams())
    @test_throws DomainError process([trace], TvgParams(sound_velocity_m_per_s=0.0))
    @test_throws DomainError process([trace], TvgParams(reference_depth_m=0.0))
end
