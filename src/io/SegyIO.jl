module SegyIO

using Dates
using Logging

using ..SegyModel: TraceHeader, BinaryHeader, ExtendedTextHeader, Trace, Dataset, SurveyGeometry, NavigationPoint

include("data_sample_format.jl")
include("binary_header.jl")
include("trace_header.jl")
include("extended_header.jl")
include("nav_parser.jl")
include("segy_reader.jl")
include("segy_writer.jl")

export ibm2ieee, ieee2ibm
export validate_binary_header, parse_binary_header, write_binary_header
export validate_trace_header, parse_trace_header, write_trace_header
export parse_extended_headers
export parse_navigation
export read_segy, write_segy

end
