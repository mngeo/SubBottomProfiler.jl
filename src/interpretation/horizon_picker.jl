"""
    HorizonPick

Structured horizon pick with provenance and confidence.

Example: `HorizonPick(1, 12, 0.8, "auto")`
"""
struct HorizonPick
    trace_index::Int
    sample_index::Int
    confidence::Float64
    provenance::String
end

"""
    HorizonPickerParams

Horizon picking configuration.

Example: `HorizonPickerParams(search_start_sample=1)`
"""
Base.@kwdef struct HorizonPickerParams
    search_start_sample::Int = 1
    search_end_sample::Int = typemax(Int)
end

"""
    pick_horizon(traces::Vector{Trace}, params::HorizonPickerParams) -> Vector{HorizonPick}

Pick the strongest reflector in each trace within the search window.

Example: `pick_horizon(traces, HorizonPickerParams())`
"""
function pick_horizon(traces::Vector{Trace}, params::HorizonPickerParams)::Vector{HorizonPick}
    picks = HorizonPick[]
    for (index, trace) in enumerate(traces)
        lo = max(1, params.search_start_sample)
        hi = min(length(trace.samples), params.search_end_sample)
        window = abs.(trace.samples[lo:hi])
        sample = argmax(window) + lo - 1
        confidence = maximum(window) / (mean(window) + eps(Float64))
        push!(picks, HorizonPick(index, sample, confidence, "auto"))
    end
    return picks
end
