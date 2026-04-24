"""
    WaterBottomPickerParams

Water-bottom picking configuration.

Example: `WaterBottomPickerParams(search_end_sample=128)`
"""
Base.@kwdef struct WaterBottomPickerParams
    search_end_sample::Int = 128
end

"""
    pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams) -> Vector{HorizonPick}

Pick the first strong arrival in each trace.

Example: `pick_water_bottom(traces, WaterBottomPickerParams())`
"""
function pick_water_bottom(traces::Vector{Trace}, params::WaterBottomPickerParams)::Vector{HorizonPick}
    return pick_horizon(traces, HorizonPickerParams(search_start_sample=1, search_end_sample=params.search_end_sample))
end
