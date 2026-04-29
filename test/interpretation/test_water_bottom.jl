@testset "Water Bottom" begin
    dataset = synthetic_dataset()
    picks = pick_water_bottom(dataset.traces, WaterBottomPickerParams(search_end_sample=24))
    @test all(pick.sample_index <= 24 for pick in picks)
    @test all(pick.provenance == "auto_continuity" for pick in picks)

    traces = Trace[]
    expected = [12, 12, 13, 13, 14, 14, 15, 15]
    for (index, sample_index) in enumerate(expected)
        samples = zeros(Float64, 32)
        samples[sample_index] = 2.0
        if index in (4, 5)
            samples[24] = 4.0
        end
        push!(traces, Trace(TraceHeader(trace_sequence_line=index, trace_sequence_file=index, sample_count=32, sample_interval_microseconds=250), samples))
    end
    constrained = pick_water_bottom(
        traces,
        WaterBottomPickerParams(search_start_sample=8, search_end_sample=28, max_jump_samples=2, continuity_penalty=0.2),
    )
    @test [pick.sample_index for pick in constrained] == expected
end
