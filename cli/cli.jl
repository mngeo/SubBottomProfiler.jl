include("config.jl")
include("commands/cmd_info.jl")
include("commands/cmd_process.jl")
include("commands/cmd_view.jl")
include("commands/cmd_export.jl")

using .SubBottomProfiler

function run_cli(args::Vector{String})::Int
    isempty(args) && return _print_usage()
    command = first(args)
    tail = args[2:end]
    if command == "info"
        return run_info(tail)
    elseif command == "process"
        return run_process(tail)
    elseif command == "view"
        return run_view(tail)
    elseif command == "export"
        return run_export(tail)
    end
    return _print_usage()
end

function _print_usage()::Int
    println("usage: sbp <info|process|view|export> [args]")
    return 1
end
