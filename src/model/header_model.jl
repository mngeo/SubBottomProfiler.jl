"""
    HeaderFieldInfo

Typed metadata describing a SEG-Y header field.

Example: `HeaderFieldInfo("trace_sequence_line", 1, 4, "int32")`
"""
struct HeaderFieldInfo
    name::String
    byte_start::Int
    byte_length::Int
    field_type::String
end

const TRACE_HEADER_FIELDS = Dict{Symbol, HeaderFieldInfo}(
    :trace_sequence_line => HeaderFieldInfo("trace_sequence_line", 1, 4, "int32"),
    :trace_sequence_file => HeaderFieldInfo("trace_sequence_file", 5, 4, "int32"),
    :sample_count => HeaderFieldInfo("sample_count", 115, 2, "int16"),
    :sample_interval_microseconds => HeaderFieldInfo("sample_interval_microseconds", 117, 2, "int16"),
    :source_x => HeaderFieldInfo("source_x", 73, 4, "int32"),
    :source_y => HeaderFieldInfo("source_y", 77, 4, "int32"),
)

const BINARY_HEADER_FIELDS = Dict{Symbol, HeaderFieldInfo}(
    :job_id => HeaderFieldInfo("job_id", 1, 4, "int32"),
    :line_number => HeaderFieldInfo("line_number", 5, 4, "int32"),
    :sample_interval_microseconds => HeaderFieldInfo("sample_interval_microseconds", 17, 2, "int16"),
    :samples_per_trace => HeaderFieldInfo("samples_per_trace", 21, 2, "int16"),
    :data_sample_format => HeaderFieldInfo("data_sample_format", 25, 2, "int16"),
    :segy_revision => HeaderFieldInfo("segy_revision", 301, 2, "int16"),
)

"""
    TraceHeader

Typed representation of a SEG-Y trace header.

Example: `TraceHeader(; trace_sequence_line=1, sample_count=512, sample_interval_microseconds=250)`
"""
Base.@kwdef struct TraceHeader
    trace_sequence_line::Int32 = 1
    trace_sequence_file::Int32 = 1
    field_record::Int32 = 1
    trace_number_within_field_record::Int32 = 1
    source_x::Int32 = 0
    source_y::Int32 = 0
    group_x::Int32 = 0
    group_y::Int32 = 0
    offset_meters::Float64 = 0.0
    sample_count::Int = 0
    sample_interval_microseconds::Int = 250
    scalco::Int16 = 1
    scalel::Int16 = 1
    coordinate_units::Int16 = 1
    extra::Dict{Symbol, Int64} = Dict{Symbol, Int64}()
end

"""
    BinaryHeader

Typed representation of a SEG-Y binary header.

Example: `BinaryHeader(; samples_per_trace=512, sample_interval_microseconds=250)`
"""
Base.@kwdef struct BinaryHeader
    job_id::Int32 = 0
    line_number::Int32 = 0
    reel_number::Int32 = 0
    sample_interval_microseconds::Int = 250
    original_sample_interval_microseconds::Int = 250
    samples_per_trace::Int = 0
    original_samples_per_trace::Int = 0
    data_sample_format::Int16 = 5
    ensemble_fold::Int16 = 1
    trace_sorting_code::Int16 = 1
    segy_revision::Int16 = 0x0200
    fixed_length_trace_flag::Int16 = 1
    extended_text_header_count::Int16 = 0
end

"""
    ExtendedTextHeader

Container for SEG-Y extended textual header stanzas.

Example: `ExtendedTextHeader(["C01 EXAMPLE"])`
"""
struct ExtendedTextHeader
    stanzas::Vector{String}
end
