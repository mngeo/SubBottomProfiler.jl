module SegyModel

using Dates

include("header_model.jl")
include("geometry_model.jl")
include("trace_model.jl")
include("dataset_model.jl")

export TraceHeader, BinaryHeader, ExtendedTextHeader
export HeaderFieldInfo, TRACE_HEADER_FIELDS, BINARY_HEADER_FIELDS
export NavigationPoint, SurveyGeometry
export Trace, Dataset

end
