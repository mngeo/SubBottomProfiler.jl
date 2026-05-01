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

    drop_traces = Trace[]
    expected_drop = [12, 12, 13, 13, 24, 25, 26, 27]
    for (index, sample_index) in enumerate(expected_drop)
        samples = zeros(Float64, 40)
        samples[sample_index] = 2.5
        if index >= 5
            samples[13] = 0.15
            samples[14] = 0.12
        end
        push!(drop_traces, Trace(TraceHeader(trace_sequence_line=index, trace_sequence_file=index, sample_count=40, sample_interval_microseconds=250), samples))
    end
    reacquired = pick_water_bottom(
        drop_traces,
        WaterBottomPickerParams(
            search_start_sample=8,
            search_end_sample=32,
            max_jump_samples=2,
            continuity_penalty=0.2,
            low_confidence_threshold=0.2,
            reacquire_after_low_confidence_traces=1,
            later_reflection_ratio=2.0,
            reacquire_max_jump_samples=16,
        ),
    )
    @test [pick.sample_index for pick in reacquired] == expected_drop
    @test any(pick.provenance == "auto_continuity_reacquired" for pick in reacquired)

    extrapolation_traces = Trace[]
    for (index, sample_index) in enumerate([12, 12, 13, 13, 24, 28, 13, 13])
        samples = zeros(Float64, 40)
        if index <= 6
            samples[sample_index] = 2.5
        end
        if index >= 5
            samples[13] = 0.15
            samples[14] = 0.12
        end
        push!(extrapolation_traces, Trace(TraceHeader(trace_sequence_line=index, trace_sequence_file=index, sample_count=40, sample_interval_microseconds=250), samples))
    end
    extrapolated = pick_water_bottom(
        extrapolation_traces,
        WaterBottomPickerParams(
            search_start_sample=8,
            search_end_sample=32,
            max_jump_samples=2,
            continuity_penalty=0.2,
            low_confidence_threshold=0.2,
            reacquire_after_low_confidence_traces=1,
            later_reflection_ratio=2.0,
            reacquire_max_jump_samples=20,
        ),
    )
    @test [pick.sample_index for pick in extrapolated] == [12, 12, 13, 13, 24, 28, 32, 32]
    @test any(pick.provenance == "auto_continuity_extrapolated" for pick in extrapolated)

    capped = pick_water_bottom_result(
        extrapolation_traces,
        WaterBottomPickerParams(
            search_start_sample=8,
            search_end_sample=32,
            max_jump_samples=2,
            continuity_penalty=0.2,
            low_confidence_threshold=0.2,
            reacquire_after_low_confidence_traces=1,
            later_reflection_ratio=2.0,
            reacquire_max_jump_samples=20,
            max_extrapolated_traces=1,
        ),
    )
    @test [pick.sample_index for pick in capped.primary_picks] == [12, 12, 13, 13, 24, 28, 32, 13]
    @test capped.primary_picks[end].provenance == "auto_continuity_unresolved"
    @test !isempty(capped.alternative_picks)
    @test !isempty(capped.warnings)

    path = tempname() * ".csv"
    export_interpretation(path, capped)
    content = read(path, String)
    @test occursin("primary_sample_index", content)
    @test occursin("alternative_sample_index", content)
    @test occursin(",,auto_continuity_unresolved", content)

    stitched_segmented = pick_water_bottom_segmented_result(
        traces,
        SegmentedWaterBottomPickerParams(
            segment_count=2,
            base_params=WaterBottomPickerParams(search_start_sample=8, search_end_sample=28, max_jump_samples=2, continuity_penalty=0.2),
            stitch_max_jump_samples=2,
            stitch_confidence_threshold=0.05,
        ),
    )
    @test [pick.sample_index for pick in stitched_segmented.primary_picks] == expected
    @test isempty(stitched_segmented.segment_break_after)

    disconnected_expected = [12, 12, 13, 13, 24, 24, 25, 25]
    disconnected_traces = Trace[]
    for (index, sample_index) in enumerate(disconnected_expected)
        samples = zeros(Float64, 40)
        samples[sample_index] = 2.2
        push!(disconnected_traces, Trace(TraceHeader(trace_sequence_line=index, trace_sequence_file=index, sample_count=40, sample_interval_microseconds=250), samples))
    end
    segmented_disconnected = pick_water_bottom_segmented_result(
        disconnected_traces,
        SegmentedWaterBottomPickerParams(
            segment_count=2,
            base_params=WaterBottomPickerParams(search_start_sample=8, search_end_sample=32, max_jump_samples=2, continuity_penalty=0.2),
            stitch_max_jump_samples=3,
            stitch_confidence_threshold=0.05,
        ),
    )
    @test segmented_disconnected.segment_break_after == [4]
    @test all(pick.provenance == "auto_segmented_disconnected" for pick in segmented_disconnected.primary_picks[5:end])
    @test !isempty(segmented_disconnected.warnings)

    adaptive_traces = Trace[]
    expected_adaptive = vcat(fill(12, 10), fill(30, 10))
    for (index, sample_index) in enumerate(expected_adaptive)
        samples = zeros(Float64, 48)
        samples[sample_index] = 4.0
        if index > 10
            samples[12] = 0.2
        end
        push!(adaptive_traces, Trace(TraceHeader(trace_sequence_line=index, trace_sequence_file=index, sample_count=48, sample_interval_microseconds=250), samples))
    end
    adaptive_picker_params = WaterBottomPickerParams(
        search_start_sample=8,
        search_end_sample=36,
        max_jump_samples=2,
        continuity_penalty=0.2,
        low_confidence_threshold=0.25,
        reacquire_after_low_confidence_traces=1,
        later_reflection_ratio=2.0,
        reacquire_max_jump_samples=8,
        max_extrapolated_traces=1,
    )
    adaptive_window_params = WaterBottomWindowEstimatorParams(
        stack_sizes=[2, 5, 10],
        search_start_sample=8,
        search_end_sample=36,
        window_half_width=2,
        window_padding_samples=1,
        profile_smoothing_samples=3,
        split_segment_count=2,
        min_block_traces=5,
        max_refinement_depth=2,
        extrapolation_trigger_count=1,
        extrapolation_fraction_threshold=0.05,
        unresolved_fraction_threshold=0.05,
    )
    estimated_windows = estimate_water_bottom_windows(adaptive_traces, adaptive_picker_params, adaptive_window_params)
    @test length(estimated_windows) == 2
    @test estimated_windows[1].trace_range == 1:10
    @test estimated_windows[2].trace_range == 11:20
    @test abs(estimated_windows[1].center_sample - 12) <= 1
    @test abs(estimated_windows[2].center_sample - 30) <= 1

    adaptive_result = pick_water_bottom_adaptive_result(adaptive_traces, adaptive_picker_params, adaptive_window_params)
    @test [pick.sample_index for pick in adaptive_result.primary_picks] == expected_adaptive
    @test adaptive_result.segment_break_after == [10]
    @test all(!occursin("unresolved", pick.provenance) for pick in adaptive_result.primary_picks)
end
