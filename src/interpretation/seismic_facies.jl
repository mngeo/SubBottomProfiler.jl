"""
    SeismicFaciesParams

Rules-based seismic facies configuration.

Example: `SeismicFaciesParams(envelope_threshold=0.5)`
"""
Base.@kwdef struct SeismicFaciesParams
    envelope_threshold::Float64 = 0.5
end

"""
    classify_facies(traces::Vector{Trace}, params::SeismicFaciesParams; model=nothing) -> Vector{String}

Classify traces into simple facies labels, or delegate to a Flux-compatible `model`.

Example: `classify_facies(traces, SeismicFaciesParams())`
"""
function classify_facies(traces::Vector{Trace}, params::SeismicFaciesParams; model=nothing)::Vector{String}
    if model !== nothing
        return [String(model(trace.samples)) for trace in traces]
    end
    labels = String[]
    for trace in traces
        amplitude = maximum(abs.(trace.samples))
        push!(labels, amplitude >= params.envelope_threshold ? "reflective" : "transparent")
    end
    return labels
end
