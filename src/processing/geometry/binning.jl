"""
    BinningParams

CDP binning configuration in meters.

Example: `BinningParams(bin_size_meters=1.0)`
"""
Base.@kwdef struct BinningParams
    bin_size_meters::Float64 = 1.0
end

function process(traces::Vector{Trace}, params::BinningParams)::Vector{Trace}
    params.bin_size_meters > 0.0 || throw(DomainError(params.bin_size_meters, "bin size must be positive"))
    return [Trace(trace.header, trace.samples, merge(trace.metadata, Dict(:cdp_bin => floor(Float64(i - 1) / params.bin_size_meters)))) for (i, trace) in enumerate(traces)]
end

@register_step :binning BinningParams
