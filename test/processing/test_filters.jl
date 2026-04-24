@testset "Filters" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, BandpassParams())) == length(dataset.traces)
    @test length(process(dataset.traces, NotchFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, FkFilterParams())) == length(dataset.traces)
    @test length(process(dataset.traces, MedianFilterParams())) == length(dataset.traces)
end
