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
