function run_info(args::Vector{String})::Int
    length(args) == 1 || return 1
    dataset = SubBottomProfiler.read_segy(args[1])
    println("traces: $(length(dataset.traces))")
    println("samples_per_trace: $(dataset.binary_header.samples_per_trace)")
    return 0
end
