"""
    export_figure(path::AbstractString, plot::PlotSpec) -> String

Export a plot specification to PNG, SVG, or PDF output. SVG-backed plots such as
`wiggle_plot` are written as rendered SVG content.

Example: `export_figure("section.svg", plot)`
"""
function export_figure(path::AbstractString, plot::PlotSpec)::String
    extension = lowercase(splitext(path)[2])
    extension in [".png", ".svg", ".pdf"] || throw(ArgumentError("unsupported figure format"))
    open(path, "w") do io
        if extension == ".svg" && plot.format == :svg
            write(io, plot.content)
        else
            write(io, isempty(plot.content) ? "SubBottomProfiler export $(plot.kind)\n" : plot.content)
            if extension != ".svg"
                write(io, "requested_extension=$(extension)\n")
            end
            for (key, value) in pairs(plot.metadata)
                write(io, "$(key)=$(value)\n")
            end
        end
    end
    return path
end
