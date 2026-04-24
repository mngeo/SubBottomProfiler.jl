function run_process(args::Vector{String})::Int
    length(args) == 3 || return 1
    dataset = SubBottomProfiler.read_segy(args[1])
    processed = SubBottomProfiler.run_workflow(dataset, args[2])
    SubBottomProfiler.write_segy(args[3], processed)
    return 0
end
