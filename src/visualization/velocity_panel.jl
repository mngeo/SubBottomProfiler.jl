"""
    velocity_panel(values::Vector{Float64}; axis=nothing) -> PlotSpec

Create a velocity-panel specification.

Example: `velocity_panel([1500.0, 1600.0])`
"""
function velocity_panel(values::Vector{Float64}; axis=nothing)::PlotSpec
    return PlotSpec(:velocity_panel, Dict(:axis => string(axis), :values => string(values)))
end
