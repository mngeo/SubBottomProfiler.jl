module Interpretation

using Statistics
using Dates
using ..Utils: rms
using ..SegyModel: Trace, Dataset
using ..Processing: process, SemblanceParams

include("horizon_picker.jl")
include("layer_tracker.jl")
include("reflector_strength.jl")
include("seismic_facies.jl")
include("water_bottom_picker.jl")
include("velocity_analysis.jl")
include("export_interpretation.jl")

export HorizonPick, HorizonPickerParams, LayerTrackerParams, ReflectorStrengthParams
export SeismicFaciesParams, WaterBottomPickerParams, VelocityAnalysisParams
export pick_horizon, track_layers, reflector_strength, classify_facies, pick_water_bottom, analyse_velocity
export export_interpretation

end
