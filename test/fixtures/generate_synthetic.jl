function synthetic_dataset(; trace_count::Int=6, sample_count::Int=64)
    traces = Trace[]
    for trace_index in 1:trace_count
        samples = [sin(0.15 * sample_index) + (sample_index == 12 + trace_index ? 2.0 : 0.0) for sample_index in 1:sample_count]
        header = TraceHeader(
            trace_sequence_line=trace_index,
            trace_sequence_file=trace_index,
            field_record=1,
            trace_number_within_field_record=trace_index,
            source_x=100 * trace_index,
            source_y=200 * trace_index,
            group_x=100 * trace_index + 10,
            group_y=200 * trace_index + 20,
            sample_count=sample_count,
            sample_interval_microseconds=250,
        )
        push!(traces, Trace(header, samples))
    end
    binary_header = BinaryHeader(samples_per_trace=sample_count, original_samples_per_trace=sample_count, sample_interval_microseconds=250)
    return Dataset(binary_header, rpad("C 1 SYNTHETIC", 3200), SegyModel.ExtendedTextHeader(String[]), traces, SurveyGeometry(line_name="synthetic"))
end

function generate_fixture(path::AbstractString)
    write_segy(path, synthetic_dataset())
    return path
end
