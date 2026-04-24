"""
    seismic_section(traces::Vector{Trace}; axis=nothing, colormap=SBP_SEISMIC_COLORMAP) -> PlotSpec

Create a seismic-section image specification.

Example: `seismic_section(traces)`
"""
function seismic_section(traces::Vector{Trace}; axis=nothing, colormap=SBP_SEISMIC_COLORMAP)::PlotSpec
    matrix = isempty(traces) ? Matrix{Float64}(undef, 0, 0) : reduce(hcat, [trace.samples for trace in traces])
    return PlotSpec(:section, Dict(:axis => string(axis), :colormap => string(colormap), :matrix => string(matrix)))
end
