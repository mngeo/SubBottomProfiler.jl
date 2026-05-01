using Logging: @warn

"""
    WaterBottomWindow

Estimated local water-bottom search window for a contiguous trace block.

Arguments:
- `trace_range`: contiguous trace indices covered by this local window.
- `search_start_sample`: first sample in the local search window.
- `search_end_sample`: last sample in the local search window.
- `center_sample`: representative center sample of the local reflector band.
- `representative_stack_size`: stack size that produced the strongest coarse estimate.
- `confidence`: coarse normalized confidence in the estimated window.
- `refinement_level`: recursive refinement depth used to obtain this window.

Example:
`WaterBottomWindow(trace_range=1:50, search_start_sample=100, search_end_sample=160, center_sample=130)`
"""
Base.@kwdef struct WaterBottomWindow
    trace_range::UnitRange{Int} = 1:0
    search_start_sample::Int = 1
    search_end_sample::Int = 1
    center_sample::Int = 1
    representative_stack_size::Int = 1
    confidence::Float64 = 0.0
    refinement_level::Int = 0
end

"""
    WaterBottomPickResult

Diagnostic result for water-bottom picking with primary picks, optional alternative
deeper candidates, and warning messages.

Example: `WaterBottomPickResult(primary_picks = picks, alternative_picks = HorizonPick[])`
"""
Base.@kwdef struct WaterBottomPickResult
    primary_picks::Vector{HorizonPick} = HorizonPick[]
    alternative_picks::Vector{HorizonPick} = HorizonPick[]
    warnings::Vector{String} = String[]
    segment_break_after::Vector{Int} = Int[]
end

"""
    WaterBottomPickerParams

Water-bottom picking configuration.

Arguments:
- `search_start_sample`: first sample considered for the water-bottom search.
- `search_end_sample`: last sample considered for the water-bottom search.
- `max_jump_samples`: maximum allowed inter-trace jump in samples.
- `continuity_penalty`: penalty per sample jump between adjacent traces.
- `low_confidence_threshold`: normalized amplitude threshold below which the tracked
  reflector is treated as unreliable.
- `reacquire_after_low_confidence_traces`: number of consecutive low-confidence
  traces before trying to reacquire a later reflector.
- `later_reflection_ratio`: minimum ratio by which a later reflector must exceed the
  tracked local reflector before a reacquisition jump is accepted.
- `reacquire_max_jump_samples`: maximum deeper jump, in samples, allowed during a
  low-confidence reacquisition.
- `max_extrapolated_traces`: maximum number of consecutive extrapolated traces
  allowed before the picker stops extending the horizon and emits warnings.

Example: `WaterBottomPickerParams(search_start_sample=64, search_end_sample=128, max_jump_samples=4)`
"""
Base.@kwdef struct WaterBottomPickerParams
    search_start_sample::Int = 1
    search_end_sample::Int = 128
    max_jump_samples::Int = 4
    continuity_penalty::Float64 = 0.08
    low_confidence_threshold::Float64 = 0.1
    reacquire_after_low_confidence_traces::Int = 3
    later_reflection_ratio::Float64 = 1.5
    reacquire_max_jump_samples::Int = 48
    max_extrapolated_traces::Int = 5
end

"""
    WaterBottomWindowEstimatorParams

Configuration for adaptive local water-bottom window estimation.

Arguments:
- `stack_sizes`: blind-stack sizes used for coarse reflector localization.
- `search_start_sample`: first sample considered during coarse window estimation.
- `search_end_sample`: last sample considered during coarse window estimation.
- `window_half_width`: minimum half-width, in samples, of each local window.
- `window_padding_samples`: extra padding added around the estimated center/spread.
- `profile_smoothing_samples`: moving-average length used to smooth stacked energy profiles.
- `split_segment_count`: number of child blocks created when a coarse block fails validation.
- `min_block_traces`: smallest block length eligible for recursive splitting.
- `max_refinement_depth`: maximum recursive split depth.
- `extrapolation_trigger_count`: minimum extrapolated-pick count that triggers block refinement.
- `extrapolation_fraction_threshold`: extrapolated-pick fraction that triggers block refinement.
- `unresolved_fraction_threshold`: unresolved-pick fraction that triggers block refinement.
- `later_energy_ratio_threshold`: split a block when a later reflector outside the current
  window is at least this strong relative to the strongest energy inside the window.

Example:
`WaterBottomWindowEstimatorParams(stack_sizes=[10, 25, 50, 100], window_half_width=24)`
"""
Base.@kwdef struct WaterBottomWindowEstimatorParams
    stack_sizes::Vector{Int} = [10, 25, 50, 100]
    search_start_sample::Int = 1
    search_end_sample::Int = typemax(Int)
    window_half_width::Int = 24
    window_padding_samples::Int = 8
    profile_smoothing_samples::Int = 9
    split_segment_count::Int = 2
    min_block_traces::Int = 20
    max_refinement_depth::Int = 3
    extrapolation_trigger_count::Int = 1
    extrapolation_fraction_threshold::Float64 = 0.1
    unresolved_fraction_threshold::Float64 = 0.15
    later_energy_ratio_threshold::Float64 = 1.0
end

"""
    SegmentedWaterBottomPickerParams

Configuration for segmented water-bottom picking.

Arguments:
- `segment_count`: number of contiguous trace segments to process independently.
- `base_params`: picker parameters used within each segment.
- `stitch_max_jump_samples`: maximum allowed mismatch, in samples, between
  adjacent segment boundary picks for a successful stitch.
- `stitch_confidence_threshold`: minimum confidence required on both sides of a
  segment boundary before stitching is accepted.

Example:
`SegmentedWaterBottomPickerParams(segment_count=5, stitch_max_jump_samples=8)`
"""
Base.@kwdef struct SegmentedWaterBottomPickerParams
    segment_count::Int = 5
    base_params::WaterBottomPickerParams = WaterBottomPickerParams()
    stitch_max_jump_samples::Int = 8
    stitch_confidence_threshold::Float64 = 0.05
end

"""
    pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams) -> Vector{HorizonPick}

Pick a laterally continuous water-bottom horizon using dynamic programming.

Example: `pick_water_bottom(traces, WaterBottomPickerParams())`
"""
function pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams)::Vector{HorizonPick}
    return pick_water_bottom_result(traces, params).primary_picks
end

"""
    pick_water_bottom_segmented(traces::Vector{Trace}, params::SegmentedWaterBottomPickerParams) -> Vector{HorizonPick}

Pick water bottom independently on contiguous trace segments and attempt a final
stitch across segment boundaries. When stitching fails, disconnected patches are
left in the output result provenance.

Example:
`pick_water_bottom_segmented(traces, SegmentedWaterBottomPickerParams())`
"""
function pick_water_bottom_segmented(
    traces::Vector{Trace},
    params::SegmentedWaterBottomPickerParams,
)::Vector{HorizonPick}
    return pick_water_bottom_segmented_result(traces, params).primary_picks
end

"""
    estimate_water_bottom_windows(
        traces::Vector{Trace},
        picker_params::WaterBottomPickerParams,
        params::WaterBottomWindowEstimatorParams,
    ) -> Vector{WaterBottomWindow}

Estimate one or more local water-bottom search windows across the track. The
estimator first scans stacked traces at multiple blind-stack sizes, then
recursively refines blocks whose coarse windows still lead to extrapolated or
unresolved picks.

Example:
`estimate_water_bottom_windows(traces, WaterBottomPickerParams(), WaterBottomWindowEstimatorParams())`
"""
function estimate_water_bottom_windows(
    traces::Vector{Trace},
    picker_params::WaterBottomPickerParams,
    params::WaterBottomWindowEstimatorParams,
)::Vector{WaterBottomWindow}
    isempty(traces) && return WaterBottomWindow[]
    _validate_window_estimator_params(params)
    sample_count = length(first(traces).samples)
    all(length(trace.samples) == sample_count for trace in traces) || throw(ArgumentError("all traces must have the same sample count"))
    search_start = max(1, params.search_start_sample)
    search_end = min(sample_count, params.search_end_sample)
    search_start <= search_end || throw(ArgumentError("window-estimator search range must overlap the trace sample range"))
    return _estimate_water_bottom_windows_recursive(
        traces,
        1:length(traces),
        picker_params,
        params,
        search_start,
        search_end,
        0,
    )
end

"""
    estimate_water_bottom_windows(
        traces::Vector{Trace},
        params::WaterBottomWindowEstimatorParams,
    ) -> Vector{WaterBottomWindow}

Estimate local water-bottom windows using default picker validation settings.

Example:
`estimate_water_bottom_windows(traces, WaterBottomWindowEstimatorParams())`
"""
function estimate_water_bottom_windows(
    traces::Vector{Trace},
    params::WaterBottomWindowEstimatorParams,
)::Vector{WaterBottomWindow}
    return estimate_water_bottom_windows(traces, WaterBottomPickerParams(), params)
end

"""
    pick_water_bottom_adaptive(
        traces::Vector{Trace},
        picker_params::WaterBottomPickerParams,
        estimator_params::WaterBottomWindowEstimatorParams,
    ) -> Vector{HorizonPick}

Pick water bottom using adaptive local windows estimated from stacked trace
blocks.

Example:
`pick_water_bottom_adaptive(traces, WaterBottomPickerParams(), WaterBottomWindowEstimatorParams())`
"""
function pick_water_bottom_adaptive(
    traces::Vector{Trace},
    picker_params::WaterBottomPickerParams,
    estimator_params::WaterBottomWindowEstimatorParams,
)::Vector{HorizonPick}
    return pick_water_bottom_adaptive_result(traces, picker_params, estimator_params).primary_picks
end

"""
    pick_water_bottom_adaptive_result(
        traces::Vector{Trace},
        picker_params::WaterBottomPickerParams,
        estimator_params::WaterBottomWindowEstimatorParams,
    ) -> WaterBottomPickResult

Estimate local water-bottom windows, pick each block independently within its own
window, and attempt to stitch neighboring blocks. When neighboring blocks cannot
be stitched consistently, disconnected patches are preserved.

Example:
`pick_water_bottom_adaptive_result(traces, WaterBottomPickerParams(), WaterBottomWindowEstimatorParams())`
"""
function pick_water_bottom_adaptive_result(
    traces::Vector{Trace},
    picker_params::WaterBottomPickerParams,
    estimator_params::WaterBottomWindowEstimatorParams,
)::WaterBottomPickResult
    isempty(traces) && return WaterBottomPickResult()
    windows = estimate_water_bottom_windows(traces, picker_params, estimator_params)
    primary_picks = HorizonPick[]
    alternative_picks = HorizonPick[]
    warnings = String[]
    segment_break_after = Int[]
    previous_tail_pick = nothing

    for window in windows
        local_params = _picker_params_with_window(picker_params, window.search_start_sample, window.search_end_sample)
        local_result = pick_water_bottom_result(traces[window.trace_range], local_params)
        global_primary = _offset_picks(local_result.primary_picks, first(window.trace_range) - 1)
        global_alternative = _offset_picks(local_result.alternative_picks, first(window.trace_range) - 1)
        append!(alternative_picks, global_alternative)
        append!(warnings, local_result.warnings)
        append!(segment_break_after, local_result.segment_break_after .+ (first(window.trace_range) - 1))

        if previous_tail_pick !== nothing
            current_head_pick = first(global_primary)
            if !_can_stitch_adjacent_picks(previous_tail_pick, current_head_pick, picker_params)
                push!(segment_break_after, previous_tail_pick.trace_index)
                warning = "Adaptive water-bottom stitching failed between traces $(previous_tail_pick.trace_index) and $(current_head_pick.trace_index); disconnected patches were preserved."
                push!(warnings, warning)
                @warn warning
                global_primary = _mark_disconnected_segment(global_primary)
            end
        end

        append!(primary_picks, global_primary)
        previous_tail_pick = last(global_primary)
    end

    return WaterBottomPickResult(
        primary_picks=primary_picks,
        alternative_picks=alternative_picks,
        warnings=warnings,
        segment_break_after=sort!(unique!(segment_break_after)),
    )
end

"""
    pick_water_bottom_result(traces::Vector{Trace}, params::WaterBottomPickerParams) -> WaterBottomPickResult

Pick a laterally continuous water-bottom horizon and return diagnostic information
including alternative deeper candidates and extrapolation warnings.

Example: `pick_water_bottom_result(traces, WaterBottomPickerParams())`
"""
function pick_water_bottom_result(traces::Vector{Trace}, params::WaterBottomPickerParams)::WaterBottomPickResult
    isempty(traces) && return WaterBottomPickResult()
    params.search_start_sample >= 1 || throw(ArgumentError("search_start_sample must be at least 1"))
    params.search_end_sample >= params.search_start_sample || throw(ArgumentError("search_end_sample must be greater than or equal to search_start_sample"))
    params.max_jump_samples >= 0 || throw(ArgumentError("max_jump_samples must be non-negative"))
    params.continuity_penalty >= 0.0 || throw(DomainError(params.continuity_penalty, "continuity_penalty must be non-negative"))
    0.0 <= params.low_confidence_threshold <= 1.0 || throw(DomainError(params.low_confidence_threshold, "low_confidence_threshold must be between 0 and 1"))
    params.reacquire_after_low_confidence_traces >= 1 || throw(ArgumentError("reacquire_after_low_confidence_traces must be at least 1"))
    params.later_reflection_ratio >= 1.0 || throw(DomainError(params.later_reflection_ratio, "later_reflection_ratio must be at least 1"))
    params.reacquire_max_jump_samples >= params.max_jump_samples || throw(ArgumentError("reacquire_max_jump_samples must be greater than or equal to max_jump_samples"))
    params.max_extrapolated_traces >= 1 || throw(ArgumentError("max_extrapolated_traces must be at least 1"))

    sample_count = length(first(traces).samples)
    all(length(trace.samples) == sample_count for trace in traces) || throw(ArgumentError("all traces must have the same sample count"))
    lo = params.search_start_sample
    hi = min(sample_count, params.search_end_sample)
    lo <= hi || throw(ArgumentError("search window must overlap the trace sample range"))

    windows = [abs.(trace.samples[lo:hi]) for trace in traces]
    global_max = maximum(maximum(window) for window in windows)
    global_max > 0.0 || (global_max = 1.0)
    normalized = [window ./ global_max for window in windows]
    states = length(first(normalized))
    trace_count = length(traces)
    scores = fill(-Inf, trace_count, states)
    parents = fill(0, trace_count, states)

    for state in 1:states
        scores[1, state] = normalized[1][state]
    end

    for trace_index in 2:trace_count
        current = normalized[trace_index]
        previous_scores = @view scores[trace_index - 1, :]
        for state in 1:states
            lower = max(1, state - params.max_jump_samples)
            upper = min(states, state + params.max_jump_samples)
            best_score = -Inf
            best_parent = state
            for parent_state in lower:upper
                candidate = previous_scores[parent_state] - params.continuity_penalty * abs(state - parent_state)
                if candidate > best_score
                    best_score = candidate
                    best_parent = parent_state
                end
            end
            scores[trace_index, state] = current[state] + best_score
            parents[trace_index, state] = best_parent
        end
    end

    picks = Vector{HorizonPick}(undef, trace_count)
    state = argmax(@view scores[end, :])
    for trace_index in trace_count:-1:1
        sample_index = lo + state - 1
        confidence = normalized[trace_index][state]
        picks[trace_index] = HorizonPick(trace_index, sample_index, confidence, "auto_continuity")
        trace_index > 1 && (state = parents[trace_index, state])
    end
    return _reacquire_late_reflections(picks, normalized, lo, params)
end

"""
    pick_water_bottom_segmented_result(traces::Vector{Trace}, params::SegmentedWaterBottomPickerParams) -> WaterBottomPickResult

Run water-bottom picking independently on `segment_count` contiguous trace
segments, then attempt to stitch neighboring segments if their boundary picks can
be traced consistently. If stitching fails, disconnected patches are preserved.

Example:
`pick_water_bottom_segmented_result(traces, SegmentedWaterBottomPickerParams(segment_count=5))`
"""
function pick_water_bottom_segmented_result(
    traces::Vector{Trace},
    params::SegmentedWaterBottomPickerParams,
)::WaterBottomPickResult
    isempty(traces) && return WaterBottomPickResult()
    params.segment_count >= 1 || throw(ArgumentError("segment_count must be at least 1"))
    params.stitch_max_jump_samples >= 0 || throw(ArgumentError("stitch_max_jump_samples must be non-negative"))
    params.stitch_confidence_threshold >= 0.0 || throw(DomainError(params.stitch_confidence_threshold, "stitch_confidence_threshold must be non-negative"))

    segments = _segment_ranges(length(traces), params.segment_count)
    primary_picks = HorizonPick[]
    alternative_picks = HorizonPick[]
    warnings = String[]
    segment_break_after = Int[]
    previous_tail_pick = nothing
    previous_segment_last_trace = 0

    for segment in segments
        local_result = pick_water_bottom_result(traces[segment], params.base_params)
        global_primary = _offset_picks(local_result.primary_picks, first(segment) - 1)
        global_alternative = _offset_picks(local_result.alternative_picks, first(segment) - 1)
        append!(alternative_picks, global_alternative)
        append!(warnings, local_result.warnings)
        append!(segment_break_after, local_result.segment_break_after .+ (first(segment) - 1))

        if !isempty(primary_picks)
            current_head_pick = first(global_primary)
            if !_can_stitch_segments(previous_tail_pick, current_head_pick, params)
                push!(segment_break_after, previous_segment_last_trace)
                warning = "Segmented water-bottom stitching failed between traces $(previous_segment_last_trace) and $(current_head_pick.trace_index); disconnected patches were preserved."
                push!(warnings, warning)
                @warn warning
                global_primary = _mark_disconnected_segment(global_primary)
            end
        end

        append!(primary_picks, global_primary)
        previous_tail_pick = last(global_primary)
        previous_segment_last_trace = last(segment)
    end

    return WaterBottomPickResult(
        primary_picks=primary_picks,
        alternative_picks=alternative_picks,
        warnings=warnings,
        segment_break_after=sort!(unique!(segment_break_after)),
    )
end

function _reacquire_late_reflections(
    picks::Vector{HorizonPick},
    normalized::Vector{Vector{Float64}},
    lo::Int,
    params::WaterBottomPickerParams,
)::WaterBottomPickResult
    trace_count = length(picks)
    trace_count == 0 && return WaterBottomPickResult()
    sample_indices = [pick.sample_index for pick in picks]
    confidences = [pick.confidence for pick in picks]
    provenances = [pick.provenance for pick in picks]
    states = length(first(normalized))
    low_confidence_run = 0
    extrapolation_run = 0
    suppress_primary = false
    alternative_picks = HorizonPick[]
    warnings = String[]

    for trace_index in 2:trace_count
        current = normalized[trace_index]
        current_state = sample_indices[trace_index] - lo + 1
        current_strength = current[current_state]
        recovery_mode = provenances[trace_index - 1] in ("auto_continuity_reacquired", "auto_continuity_extrapolated")
        if current_strength <= params.low_confidence_threshold
            low_confidence_run += 1
        else
            low_confidence_run = 0
            recovery_mode || (extrapolation_run = 0)
        end

        if low_confidence_run < params.reacquire_after_low_confidence_traces && !recovery_mode
            continue
        end

        previous_state = sample_indices[trace_index - 1] - lo + 1
        local_lower = max(1, previous_state - params.max_jump_samples)
        local_upper = min(states, previous_state + params.max_jump_samples)
        local_state, local_strength = _strongest_state(current, local_lower, local_upper)
        if local_strength >= params.low_confidence_threshold &&
           local_strength >= params.later_reflection_ratio * max(current_strength, eps(Float64))
            sample_indices[trace_index] = lo + local_state - 1
            confidences[trace_index] = local_strength
            provenances[trace_index] = "auto_continuity_reacquired"
            low_confidence_run = 0
            extrapolation_run = 0
            suppress_primary = false
            continue
        end

        later_lower = previous_state + params.max_jump_samples + 1
        later_upper = min(states, previous_state + params.reacquire_max_jump_samples)
        later_state = later_lower
        later_strength = -Inf
        if later_lower <= later_upper
            later_state, later_strength = _strongest_state(current, later_lower, later_upper)
        end
        baseline_strength = max(local_strength, current_strength, eps(Float64))
        if later_strength >= params.low_confidence_threshold &&
           later_strength >= params.later_reflection_ratio * baseline_strength
            sample_indices[trace_index] = lo + later_state - 1
            confidences[trace_index] = later_strength
            provenances[trace_index] = "auto_continuity_reacquired"
            push!(alternative_picks, HorizonPick(trace_index, lo + later_state - 1, later_strength, "auto_alternative"))
            low_confidence_run = 0
            extrapolation_run = 0
            suppress_primary = false
            continue
        end

        if suppress_primary
            confidences[trace_index] = 0.0
            provenances[trace_index] = "auto_continuity_unresolved"
            continue
        end

        if recovery_mode &&
           sample_indices[trace_index - 1] > sample_indices[trace_index]
            push!(alternative_picks, HorizonPick(trace_index, max(lo, min(lo + states - 1, lo + later_state - 1)), max(later_strength, 0.0), "auto_alternative"))
            if extrapolation_run >= params.max_extrapolated_traces
                warning = "Water-bottom track remained unresolved after $(params.max_extrapolated_traces) extrapolated traces near trace $(trace_index); further extrapolation was suppressed."
                push!(warnings, warning)
                @warn warning
                low_confidence_run = 0
                confidences[trace_index] = 0.0
                provenances[trace_index] = "auto_continuity_unresolved"
                suppress_primary = true
                continue
            end
            previous_sample = sample_indices[trace_index - 1]
            previous_previous_sample = trace_index >= 3 ? sample_indices[trace_index - 2] : previous_sample
            downward_slope = max(previous_sample - previous_previous_sample, 0)
            sample_indices[trace_index] = clamp(previous_sample + downward_slope, lo, lo + states - 1)
            confidences[trace_index] = 0.0
            provenances[trace_index] = "auto_continuity_extrapolated"
            extrapolation_run += 1
            low_confidence_run = 0
            continue
        end

        extrapolation_run = 0
    end

    primary_picks = [
        HorizonPick(trace_index, sample_indices[trace_index], confidences[trace_index], provenances[trace_index])
        for trace_index in 1:trace_count
    ]
    return WaterBottomPickResult(
        primary_picks=primary_picks,
        alternative_picks=alternative_picks,
        warnings=warnings,
        segment_break_after=Int[],
    )
end

function _validate_window_estimator_params(params::WaterBottomWindowEstimatorParams)
    isempty(params.stack_sizes) && throw(ArgumentError("stack_sizes must be non-empty"))
    all(size > 0 for size in params.stack_sizes) || throw(ArgumentError("stack_sizes must be positive"))
    params.window_half_width >= 0 || throw(ArgumentError("window_half_width must be non-negative"))
    params.window_padding_samples >= 0 || throw(ArgumentError("window_padding_samples must be non-negative"))
    params.profile_smoothing_samples >= 1 || throw(ArgumentError("profile_smoothing_samples must be at least 1"))
    params.split_segment_count >= 2 || throw(ArgumentError("split_segment_count must be at least 2"))
    params.min_block_traces >= 1 || throw(ArgumentError("min_block_traces must be at least 1"))
    params.max_refinement_depth >= 0 || throw(ArgumentError("max_refinement_depth must be non-negative"))
    params.extrapolation_trigger_count >= 1 || throw(ArgumentError("extrapolation_trigger_count must be at least 1"))
    0.0 <= params.extrapolation_fraction_threshold <= 1.0 || throw(DomainError(params.extrapolation_fraction_threshold, "extrapolation_fraction_threshold must be between 0 and 1"))
    0.0 <= params.unresolved_fraction_threshold <= 1.0 || throw(DomainError(params.unresolved_fraction_threshold, "unresolved_fraction_threshold must be between 0 and 1"))
    params.later_energy_ratio_threshold >= 1.0 || throw(DomainError(params.later_energy_ratio_threshold, "later_energy_ratio_threshold must be at least 1"))
    return nothing
end

function _estimate_water_bottom_windows_recursive(
    traces::Vector{Trace},
    trace_range::UnitRange{Int},
    picker_params::WaterBottomPickerParams,
    estimator_params::WaterBottomWindowEstimatorParams,
    search_start::Int,
    search_end::Int,
    refinement_level::Int,
)::Vector{WaterBottomWindow}
    block_traces = traces[trace_range]
    window = _estimate_block_window(
        block_traces,
        trace_range,
        estimator_params,
        search_start,
        search_end,
        refinement_level,
    )
    local_params = _picker_params_with_window(picker_params, window.search_start_sample, window.search_end_sample)
    local_result = pick_water_bottom_result(block_traces, local_params)
    needs_refinement =
        _should_refine_window_block(local_result, estimator_params) ||
        _later_energy_outside_window(block_traces, window, estimator_params, search_end) ||
        _block_has_variable_peaks(block_traces, estimator_params, search_start, search_end)
    if needs_refinement &&
       refinement_level < estimator_params.max_refinement_depth &&
       length(trace_range) >= 2 * estimator_params.min_block_traces
        windows = WaterBottomWindow[]
        for local_range in _segment_ranges(length(block_traces), estimator_params.split_segment_count)
            global_start = first(trace_range) + first(local_range) - 1
            global_stop = first(trace_range) + last(local_range) - 1
            append!(
                windows,
                _estimate_water_bottom_windows_recursive(
                    traces,
                    global_start:global_stop,
                    picker_params,
                    estimator_params,
                    search_start,
                    search_end,
                    refinement_level + 1,
                ),
            )
        end
        return windows
    end
    return WaterBottomWindow[window]
end

function _estimate_block_window(
    traces::Vector{Trace},
    trace_range::UnitRange{Int},
    params::WaterBottomWindowEstimatorParams,
    search_start::Int,
    search_end::Int,
    refinement_level::Int,
)::WaterBottomWindow
    sample_count = length(first(traces).samples)
    centers = Int[]
    strengths = Float64[]
    chosen_stack_sizes = Int[]

    for stack_size in params.stack_sizes
        local_stack_size = min(stack_size, length(traces))
        local_stack_size >= 1 || continue
        stacked = process(traces, MeanStackParams(method="mean", mode="blind", stack_size=local_stack_size))
        profile = _mean_abs_profile(stacked, sample_count)
        smoothed = moving_average(profile, params.profile_smoothing_samples)
        state = argmax(@view smoothed[search_start:search_end])
        center_sample = search_start + state - 1
        local_strength = smoothed[center_sample]
        push!(centers, center_sample)
        push!(strengths, local_strength)
        push!(chosen_stack_sizes, local_stack_size)
    end

    if isempty(centers)
        center_sample = clamp(div(search_start + search_end, 2), search_start, search_end)
        return WaterBottomWindow(
            trace_range=trace_range,
            search_start_sample=center_sample,
            search_end_sample=center_sample,
            center_sample=center_sample,
            representative_stack_size=1,
            confidence=0.0,
            refinement_level=refinement_level,
        )
    end

    center_sample = round(Int, median(centers))
    spread = maximum(abs.(centers .- center_sample))
    half_width = max(params.window_half_width, spread + params.window_padding_samples)
    best_index = argmax(strengths)
    representative_stack_size = chosen_stack_sizes[best_index]
    peak_strength = strengths[best_index]
    reference_strength = max(maximum(strengths), eps(Float64))
    confidence = clamp(peak_strength / reference_strength, 0.0, 1.0)

    return WaterBottomWindow(
        trace_range=trace_range,
        search_start_sample=max(search_start, center_sample - half_width),
        search_end_sample=min(search_end, center_sample + half_width),
        center_sample=clamp(center_sample, search_start, search_end),
        representative_stack_size=representative_stack_size,
        confidence=confidence,
        refinement_level=refinement_level,
    )
end

function _mean_abs_profile(traces::Vector{Trace}, sample_count::Int)::Vector{Float64}
    profile = zeros(Float64, sample_count)
    for trace in traces
        @inbounds for sample_index in 1:sample_count
            profile[sample_index] += abs(trace.samples[sample_index])
        end
    end
    scale = max(length(traces), 1)
    @inbounds for sample_index in 1:sample_count
        profile[sample_index] /= scale
    end
    return profile
end

function _should_refine_window_block(
    result::WaterBottomPickResult,
    params::WaterBottomWindowEstimatorParams,
)::Bool
    primary = result.primary_picks
    isempty(primary) && return false
    extrapolated_count = count(pick -> occursin("extrapolated", pick.provenance), primary)
    unresolved_count = count(pick -> occursin("unresolved", pick.provenance), primary)
    pick_count = length(primary)
    return extrapolated_count >= params.extrapolation_trigger_count ||
           extrapolated_count / pick_count >= params.extrapolation_fraction_threshold ||
           unresolved_count / pick_count >= params.unresolved_fraction_threshold
end

function _later_energy_outside_window(
    traces::Vector{Trace},
    window::WaterBottomWindow,
    params::WaterBottomWindowEstimatorParams,
    search_end::Int,
)::Bool
    later_start = window.search_end_sample + 1
    later_start <= search_end || return false
    profile = moving_average(
        _mean_abs_profile(traces, length(first(traces).samples)),
        params.profile_smoothing_samples,
    )
    inside_max = maximum(@view profile[window.search_start_sample:window.search_end_sample])
    later_max = maximum(@view profile[later_start:search_end])
    return later_max >= params.later_energy_ratio_threshold * max(inside_max, eps(Float64))
end

function _block_has_variable_peaks(
    traces::Vector{Trace},
    params::WaterBottomWindowEstimatorParams,
    search_start::Int,
    search_end::Int,
)::Bool
    spread_trigger = max(2 * params.window_half_width + 2 * params.window_padding_samples, 2)
    for stack_size in params.stack_sizes
        local_stack_size = min(stack_size, length(traces))
        stacked = process(traces, MeanStackParams(method="mean", mode="blind", stack_size=local_stack_size))
        length(stacked) >= 2 || continue
        peak_samples = Int[]
        for trace in stacked
            smoothed = moving_average(abs.(trace.samples), params.profile_smoothing_samples)
            state = argmax(@view smoothed[search_start:search_end])
            push!(peak_samples, search_start + state - 1)
        end
        maximum(peak_samples) - minimum(peak_samples) >= spread_trigger && return true
    end
    return false
end

function _picker_params_with_window(
    params::WaterBottomPickerParams,
    search_start_sample::Int,
    search_end_sample::Int,
)::WaterBottomPickerParams
    return WaterBottomPickerParams(
        search_start_sample=search_start_sample,
        search_end_sample=search_end_sample,
        max_jump_samples=params.max_jump_samples,
        continuity_penalty=params.continuity_penalty,
        low_confidence_threshold=params.low_confidence_threshold,
        reacquire_after_low_confidence_traces=params.reacquire_after_low_confidence_traces,
        later_reflection_ratio=params.later_reflection_ratio,
        reacquire_max_jump_samples=params.reacquire_max_jump_samples,
        max_extrapolated_traces=params.max_extrapolated_traces,
    )
end

function _can_stitch_adjacent_picks(
    left_pick::HorizonPick,
    right_pick::HorizonPick,
    params::WaterBottomPickerParams,
)::Bool
    left_pick.provenance != "auto_continuity_unresolved" || return false
    right_pick.provenance != "auto_continuity_unresolved" || return false
    max_allowed_jump = max(params.max_jump_samples, params.reacquire_max_jump_samples)
    return abs(left_pick.sample_index - right_pick.sample_index) <= max_allowed_jump
end

function _segment_ranges(trace_count::Int, segment_count::Int)::Vector{UnitRange{Int}}
    actual_segments = min(trace_count, segment_count)
    ranges = UnitRange{Int}[]
    start_index = 1
    for segment_index in 1:actual_segments
        remaining_traces = trace_count - start_index + 1
        remaining_segments = actual_segments - segment_index + 1
        segment_length = cld(remaining_traces, remaining_segments)
        stop_index = min(trace_count, start_index + segment_length - 1)
        push!(ranges, start_index:stop_index)
        start_index = stop_index + 1
    end
    return ranges
end

function _offset_picks(picks::Vector{HorizonPick}, offset::Int)::Vector{HorizonPick}
    return [
        HorizonPick(pick.trace_index + offset, pick.sample_index, pick.confidence, pick.provenance)
        for pick in picks
    ]
end

function _can_stitch_segments(
    left_pick::HorizonPick,
    right_pick::HorizonPick,
    params::SegmentedWaterBottomPickerParams,
)::Bool
    left_pick.provenance != "auto_continuity_unresolved" || return false
    right_pick.provenance != "auto_continuity_unresolved" || return false
    left_pick.confidence >= params.stitch_confidence_threshold || return false
    right_pick.confidence >= params.stitch_confidence_threshold || return false
    return abs(left_pick.sample_index - right_pick.sample_index) <= params.stitch_max_jump_samples
end

function _mark_disconnected_segment(picks::Vector{HorizonPick})::Vector{HorizonPick}
    return [
        HorizonPick(
            pick.trace_index,
            pick.sample_index,
            pick.confidence,
            pick.provenance == "auto_continuity_unresolved" ? pick.provenance : "auto_segmented_disconnected",
        )
        for pick in picks
    ]
end

function _strongest_state(window::Vector{Float64}, lower::Int, upper::Int)::Tuple{Int, Float64}
    best_state = lower
    best_strength = window[lower]
    @inbounds for state in (lower + 1):upper
        strength = window[state]
        if strength > best_strength
            best_strength = strength
            best_state = state
        end
    end
    return best_state, best_strength
end
