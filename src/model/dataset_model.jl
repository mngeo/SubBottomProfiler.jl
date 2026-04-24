"""
    Dataset

Collection of traces with their SEG-Y file-level headers and survey geometry.

Example: `Dataset(BinaryHeader(), Trace[], SurveyGeometry())`
"""
struct Dataset
    binary_header::BinaryHeader
    textual_header::String
    extended_header::ExtendedTextHeader
    traces::Vector{Trace}
    geometry::SurveyGeometry
end
