"""
    export_figure(path::AbstractString, plot::PlotSpec) -> String

Export a plot specification to PNG, SVG, or PDF placeholder output.

Example: `export_figure("section.svg", plot)`
"""
function export_figure(path::AbstractString, plot::PlotSpec)::String
    extension = lowercase(splitext(path)[2])
    extension in [".png", ".svg", ".pdf"] || throw(ArgumentError("unsupported figure format"))
    open(path, "w") do io
        write(io, "SubBottomProfiler export $(plot.kind)\n")
        for (key, value) in pairs(plot.payload)
            write(io, "$(key)=$(value)\n")
        end
    end
    return path
end
