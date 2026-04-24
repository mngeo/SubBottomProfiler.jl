"""
    spectrum_plot(trace::Trace; axis=nothing) -> PlotSpec

Create a spectrum-display specification.

Example: `spectrum_plot(trace)`
"""
function spectrum_plot(trace::Trace; axis=nothing)::PlotSpec
    amplitude = abs.(trace.samples)
    return PlotSpec(:spectrum, Dict(:axis => string(axis), :amplitude => string(amplitude), :mean_amplitude => string(mean(amplitude))))
end
