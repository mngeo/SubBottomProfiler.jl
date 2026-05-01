module Visualization

using Statistics
using ..Utils: twtt_to_depth
using ..SegyModel: Trace
using ..SegyIO: read_segy
using ..Interpretation: HorizonPick, WaterBottomPickResult

include("colormaps.jl")
include("wiggle_plot.jl")
include("seismic_section.jl")
include("spectrum_plot.jl")
include("velocity_panel.jl")
include("annotation_overlay.jl")
include("seabed_overlay.jl")
include("export_figure.jl")

export SBP_SEISMIC_COLORMAP, SBP_DEPTH_COLORMAP
export PlotSpec, wiggle_plot, wiggle_plot!, display_wiggle, seismic_section, spectrum_plot, velocity_panel, annotation_overlay, seabed_overlay, export_figure

end
