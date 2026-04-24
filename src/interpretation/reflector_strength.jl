"""
    ReflectorStrengthParams

Reflector strength and continuity configuration.

Example: `ReflectorStrengthParams(window_samples=8)`
"""
Base.@kwdef struct ReflectorStrengthParams
    window_samples::Int = 8
end

"""
    reflector_strength(traces::Vector{Trace}, picks::Vector{HorizonPick}, params::ReflectorStrengthParams) -> Vector{Float64}

Measure RMS strength around each pick.

Example: `reflector_strength(traces, picks, ReflectorStrengthParams())`
"""
function reflector_strength(traces::Vector{Trace}, picks::Vector{HorizonPick}, params::ReflectorStrengthParams)::Vector{Float64}
    strengths = Float64[]
    radius = div(params.window_samples, 2)
    for pick in picks
        trace = traces[pick.trace_index]
        lo = max(1, pick.sample_index - radius)
        hi = min(length(trace.samples), pick.sample_index + radius)
        push!(strengths, rms(trace.samples[lo:hi]))
    end
    return strengths
end
