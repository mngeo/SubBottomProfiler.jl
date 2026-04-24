"""
    VelocityAnalysisParams

Velocity analysis configuration.

Example: `VelocityAnalysisParams(window_samples=16)`
"""
Base.@kwdef struct VelocityAnalysisParams
    window_samples::Int = 16
end

"""
    analyse_velocity(traces::Vector{Trace}, params::VelocityAnalysisParams) -> Vector{Float64}

Return simple velocity picks derived from semblance maxima.

Example: `analyse_velocity(traces, VelocityAnalysisParams())`
"""
function analyse_velocity(traces::Vector{Trace}, params::VelocityAnalysisParams)::Vector{Float64}
    semblance_traces = process(traces, SemblanceParams(window_samples=params.window_samples))
    return [1000.0 + 100.0 * maximum(trace.samples) for trace in semblance_traces]
end
