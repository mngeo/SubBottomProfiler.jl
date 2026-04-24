"""
    Trace

A single SBP trace containing a typed header, amplitude samples, and metadata.

Example: `Trace(TraceHeader(sample_count=3), [0.0, 1.0, 0.0])`
"""
struct Trace
    header::TraceHeader
    samples::Vector{Float64}
    metadata::Dict{Symbol, Float64}

    function Trace(header::TraceHeader, samples::AbstractVector{<:Real}, metadata::Dict{Symbol, Float64}=Dict{Symbol, Float64}())
        length(samples) == header.sample_count || throw(ArgumentError("trace sample count does not match header"))
        return new(header, Float64.(samples), copy(metadata))
    end
end
