function run_view(args::Vector{String})::Int
    length(args) == 1 || return 1
    dataset = SubBottomProfiler.read_segy(args[1])
    plot = SubBottomProfiler.seismic_section(dataset.traces)
    println(plot.kind)
    println(length(dataset.traces))
    return 0
end
