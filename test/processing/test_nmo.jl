@testset "Velocity" begin
    dataset = synthetic_dataset()
    offsets = process(dataset.traces, OffsetCalculationParams())
    corrected = process(offsets, NmoCorrectionParams(velocity_m_per_s=1500.0))
    semblance = process(dataset.traces, SemblanceParams(window_samples=8))
    @test length(corrected) == length(dataset.traces)
    @test all(trace.header.offset_meters > 0.0 for trace in offsets)
    @test all(maximum(trace.samples) >= 0.0 for trace in semblance)
end
