@testset "Gain" begin
    dataset = synthetic_dataset()
    output = process(dataset.traces, GainParams(mode="linear", slope_per_sample=0.01))
    @test length(output) == length(dataset.traces)
    @test output[1].samples[10] != dataset.traces[1].samples[10]
end
