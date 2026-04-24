"""
    read_segy(path::AbstractString) -> Dataset

Read a SEG-Y file containing float or integer trace samples.

Example: `read_segy("line.segy")`
"""
function read_segy(path::AbstractString)::Dataset
    open(path, "r") do io
        textual_header = String(read(io, 3200))
        binary_header = parse_binary_header(read(io, 400))
        extended_header = parse_extended_headers(io, binary_header.extended_text_header_count)
        traces = Trace[]
        while !eof(io)
            remaining = bytesavailable(io)
            remaining == 0 && break
            remaining < 240 && break
            header = parse_trace_header(read(io, 240))
            sample_count = header.sample_count
            samples = Vector{Float64}(undef, sample_count)
            if binary_header.data_sample_format == 5
                raw = read(io, sample_count * 4)
                for i in 1:sample_count
                    offset = (i - 1) * 4 + 1
                    word = reinterpret(UInt32, reverse(raw[offset:(offset + 3)]))[1]
                    samples[i] = reinterpret(Float32, [word])[1]
                end
            elseif binary_header.data_sample_format == 1
                raw = read(io, sample_count * 4)
                for i in 1:sample_count
                    offset = (i - 1) * 4 + 1
                    word = reinterpret(UInt32, reverse(raw[offset:(offset + 3)]))[1]
                    samples[i] = ibm2ieee(word)
                end
            elseif binary_header.data_sample_format == 3
                raw = read(io, sample_count * 2)
                for i in 1:sample_count
                    offset = (i - 1) * 2 + 1
                    samples[i] = reinterpret(Int16, reverse(raw[offset:(offset + 1)]))[1]
                end
            else
                throw(ArgumentError("unsupported SEG-Y sample format $(binary_header.data_sample_format)"))
            end
            push!(traces, Trace(header, samples))
        end
        geometry = SurveyGeometry(
            line_name=basename(path),
            offsets_meters=[trace.header.offset_meters for trace in traces],
        )
        return Dataset(binary_header, textual_header, extended_header, traces, geometry)
    end
end
