function run_view(args::Vector{String})::Int
    length(args) in (1, 2) || return 1
    input_path = args[1]
    output_path = length(args) == 2 ? args[2] : _default_view_output(input_path)
    dataset = SubBottomProfiler.read_segy(input_path)
    plot = SubBottomProfiler.seismic_section(dataset.traces)
    SubBottomProfiler.export_figure(output_path, plot)
    println(output_path)
    println(length(dataset.traces))
    return 0
end

function _default_view_output(input_path::AbstractString)::String
    directory = dirname(input_path)
    stem = splitext(basename(input_path))[1]
    filename = string(stem, "_quicklook.svg")
    return directory == "" ? filename : joinpath(directory, filename)
end
