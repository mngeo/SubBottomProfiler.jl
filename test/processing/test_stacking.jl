@testset "Stacking" begin
    dataset = synthetic_dataset()
    stacked = process(dataset.traces, MeanStackParams())
    robust = process(dataset.traces, DiversityStackParams())
    @test length(stacked) == length(dataset.traces)
    @test stacked[1].metadata[:stack_fold] == 1.0
    @test length(robust) == 1

    blind = process(dataset.traces, MeanStackParams(mode="blind", stack_size=2))
    @test length(blind) == 3
    @test blind[1].metadata[:stack_fold] == 2.0
    @test blind[end].metadata[:stack_fold] == 2.0
    @test blind[1].metadata[:stack_start_trace] == 1.0
    @test blind[1].metadata[:stack_end_trace] == 2.0

    running = process(dataset.traces, MeanStackParams(mode="running", stack_size=3, step_size=1))
    @test length(running) == 4
    @test running[1].metadata[:stack_fold] == 3.0
    @test running[1].metadata[:stack_start_trace] == 1.0
    @test running[1].metadata[:stack_end_trace] == 3.0
    @test running[end].metadata[:stack_start_trace] == 4.0
    @test running[end].metadata[:stack_end_trace] == 6.0

    @test_throws ArgumentError process(dataset.traces, MeanStackParams(mode="unknown"))
end
