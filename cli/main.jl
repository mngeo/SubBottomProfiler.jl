#!/usr/bin/env julia
include("../src/SubBottomProfiler.jl")
include("cli.jl")

exit(run_cli(ARGS))
