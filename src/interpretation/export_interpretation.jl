"""
    export_interpretation(path::AbstractString, picks::Vector{HorizonPick}) -> String

Export picks to CSV, GeoJSON, or a plain JSON placeholder for shapefile requests.

Example: `export_interpretation("picks.csv", picks)`
"""
function export_interpretation(path::AbstractString, picks::Vector{HorizonPick})::String
    if endswith(lowercase(path), ".csv")
        open(path, "w") do io
            write(io, "trace_index,sample_index,confidence,provenance\n")
            for pick in picks
                write(io, "$(pick.trace_index),$(pick.sample_index),$(pick.confidence),$(pick.provenance)\n")
            end
        end
    elseif endswith(lowercase(path), ".geojson")
        open(path, "w") do io
            write(io, "{\"type\":\"FeatureCollection\",\"features\":[")
            for (index, pick) in enumerate(picks)
                index > 1 && write(io, ",")
                write(io, "{\"type\":\"Feature\",\"properties\":{\"trace_index\":$(pick.trace_index),\"sample_index\":$(pick.sample_index),\"confidence\":$(pick.confidence)}}")
            end
            write(io, "]}")
        end
    elseif endswith(lowercase(path), ".shp")
        open(path, "w") do io
            write(io, "Shapefile export placeholder with $(length(picks)) picks.\n")
        end
    else
        throw(ArgumentError("unsupported interpretation export format"))
    end
    return path
end

"""
    export_interpretation(path::AbstractString, result::WaterBottomPickResult) -> String

Export a diagnostic water-bottom picking result. CSV exports include alternative
candidate picks when present.

Example: `export_interpretation("water_bottom.csv", result)`
"""
function export_interpretation(path::AbstractString, result::WaterBottomPickResult)::String
    if endswith(lowercase(path), ".csv")
        alternative_by_trace = Dict(pick.trace_index => pick for pick in result.alternative_picks)
        open(path, "w") do io
            write(io, "trace_index,primary_sample_index,primary_confidence,primary_provenance,alternative_sample_index,alternative_confidence,alternative_provenance\n")
            for pick in result.primary_picks
                alternative = get(alternative_by_trace, pick.trace_index, nothing)
                primary_sample = pick.provenance == "auto_continuity_unresolved" ? "" : string(pick.sample_index)
                primary_confidence = pick.provenance == "auto_continuity_unresolved" ? "" : string(pick.confidence)
                if isnothing(alternative)
                    write(io, "$(pick.trace_index),$(primary_sample),$(primary_confidence),$(pick.provenance),,,\n")
                else
                    write(io, "$(pick.trace_index),$(primary_sample),$(primary_confidence),$(pick.provenance),$(alternative.sample_index),$(alternative.confidence),$(alternative.provenance)\n")
                end
            end
        end
        return path
    end
    return export_interpretation(path, result.primary_picks)
end
