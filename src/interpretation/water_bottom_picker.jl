"""
    WaterBottomPickerParams

Water-bottom picking configuration.

Arguments:
- `search_start_sample`: first sample considered for the water-bottom search.
- `search_end_sample`: last sample considered for the water-bottom search.
- `max_jump_samples`: maximum allowed inter-trace jump in samples.
- `continuity_penalty`: penalty per sample jump between adjacent traces.

Example: `WaterBottomPickerParams(search_start_sample=64, search_end_sample=128, max_jump_samples=4)`
"""
Base.@kwdef struct WaterBottomPickerParams
    search_start_sample::Int = 1
    search_end_sample::Int = 128
    max_jump_samples::Int = 4
    continuity_penalty::Float64 = 0.08
end

"""
    pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams) -> Vector{HorizonPick}

Pick a laterally continuous water-bottom horizon using dynamic programming.

Example: `pick_water_bottom(traces, WaterBottomPickerParams())`
"""
function pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams)::Vector{HorizonPick}
    isempty(traces) && return HorizonPick[]
    params.search_start_sample >= 1 || throw(ArgumentError("search_start_sample must be at least 1"))
    params.search_end_sample >= params.search_start_sample || throw(ArgumentError("search_end_sample must be greater than or equal to search_start_sample"))
    params.max_jump_samples >= 0 || throw(ArgumentError("max_jump_samples must be non-negative"))
    params.continuity_penalty >= 0.0 || throw(DomainError(params.continuity_penalty, "continuity_penalty must be non-negative"))

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
    return picks
end
