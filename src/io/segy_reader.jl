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
            remaining = filesize(path) - position(io)
            remaining == 0 && break
            remaining < 240 && break
            parsed_header = parse_trace_header(read(io, 240))
            sample_count = parsed_header.sample_count == 0 ? binary_header.samples_per_trace : parsed_header.sample_count
            sample_interval = parsed_header.sample_interval_microseconds == 0 ? binary_header.sample_interval_microseconds : parsed_header.sample_interval_microseconds
            header = validate_trace_header(
                TraceHeader(
                    trace_sequence_line=parsed_header.trace_sequence_line,
                    trace_sequence_file=parsed_header.trace_sequence_file,
                    field_record=parsed_header.field_record,
                    trace_number_within_field_record=parsed_header.trace_number_within_field_record,
                    source_x=parsed_header.source_x,
                    source_y=parsed_header.source_y,
                    group_x=parsed_header.group_x,
                    group_y=parsed_header.group_y,
                    offset_meters=parsed_header.offset_meters,
                    sample_count=sample_count,
                    sample_interval_microseconds=sample_interval,
                    scalco=parsed_header.scalco,
                    scalel=parsed_header.scalel,
                    coordinate_units=parsed_header.coordinate_units,
                    extra=copy(parsed_header.extra),
                ),
            )
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
