"""
    LayerTrackerParams

Layer-tracking configuration.

Example: `LayerTrackerParams(max_jump_samples=4)`
"""
Base.@kwdef struct LayerTrackerParams
    max_jump_samples::Int = 4
end

"""
    track_layers(picks::Vector{HorizonPick}, params::LayerTrackerParams) -> Vector{HorizonPick}

Smooth horizon picks by limiting inter-trace jumps.

Example: `track_layers(picks, LayerTrackerParams())`
"""
function track_layers(picks::Vector{HorizonPick}, params::LayerTrackerParams)::Vector{HorizonPick}
    isempty(picks) && return HorizonPick[]
    tracked = HorizonPick[picks[1]]
    for pick in picks[2:end]
        previous = tracked[end]
        delta = clamp(pick.sample_index - previous.sample_index, -params.max_jump_samples, params.max_jump_samples)
        push!(tracked, HorizonPick(pick.trace_index, previous.sample_index + delta, pick.confidence, "tracked"))
    end
    return tracked
end
