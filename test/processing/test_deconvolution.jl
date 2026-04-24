@testset "Deconvolution" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, SpikingDeconParams())) == length(dataset.traces)
    @test length(process(dataset.traces, PredictiveDeconParams())) == length(dataset.traces)
    @test length(process(dataset.traces, WienerFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, WaveletEstimationParams())) == length(dataset.traces)
end
