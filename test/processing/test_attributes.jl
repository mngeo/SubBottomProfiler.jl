@testset "Attributes" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, EnvelopeParams())) == length(dataset.traces)
    @test length(process(dataset.traces, InstantaneousPhaseParams())) == length(dataset.traces)
    @test length(process(dataset.traces, InstantaneousFreqParams())) == length(dataset.traces)
    @test length(process(dataset.traces, RmsAmplitudeParams())) == length(dataset.traces)
    @test length(process(dataset.traces, ReflectionStrengthParams())) == length(dataset.traces)
end
