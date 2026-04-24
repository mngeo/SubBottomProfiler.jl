function run_export(args::Vector{String})::Int
    length(args) == 2 || return 1
    dataset = SubBottomProfiler.read_segy(args[1])
    picks = SubBottomProfiler.pick_water_bottom(dataset.traces, SubBottomProfiler.WaterBottomPickerParams())
    SubBottomProfiler.export_interpretation(args[2], picks)
    return 0
end
