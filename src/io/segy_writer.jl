"""
    write_segy(path::AbstractString, dataset::Dataset) -> String

Write `dataset` to a SEG-Y file and return `path`.

Example: `write_segy("out.segy", dataset)`
"""
function write_segy(path::AbstractString, dataset::Dataset)::String
    open(path, "w") do io
        text = rpad(dataset.textual_header, 3200)[1:3200]
        write(io, codeunits(text))
        write_binary_header(io, dataset.binary_header)
        for stanza in dataset.extended_header.stanzas
            write(io, codeunits(rpad(stanza, 3200)[1:3200]))
        end
        for trace in dataset.traces
            write_trace_header(io, trace.header)
            if dataset.binary_header.data_sample_format == 5
                for sample in trace.samples
                    bytes = reinterpret(UInt8, [reinterpret(UInt32, [Float32(sample)])[1]])
                    write(io, reverse(bytes))
                end
            elseif dataset.binary_header.data_sample_format == 1
                for sample in trace.samples
                    bytes = reinterpret(UInt8, [ieee2ibm(sample)])
                    write(io, reverse(bytes))
                end
            elseif dataset.binary_header.data_sample_format == 3
                for sample in trace.samples
                    bytes = reinterpret(UInt8, [Int16(round(sample))])
                    write(io, reverse(bytes))
                end
            else
                throw(ArgumentError("unsupported SEG-Y sample format $(dataset.binary_header.data_sample_format)"))
            end
        end
    end
    return path
end
