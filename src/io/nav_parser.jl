"""
    parse_navigation(lines::Vector{String}) -> Vector{NavigationPoint}

Parse simplified CSV navigation records of the form `trace,lon,lat,iso8601`.

Example: `parse_navigation(["1,12.0,54.0,2024-01-01T00:00:00"])`
"""
function parse_navigation(lines::Vector{String})::Vector{NavigationPoint}
    points = NavigationPoint[]
    for line in lines
        isempty(strip(line)) && continue
        fields = split(line, ',')
        length(fields) == 4 || @warn "Skipping malformed navigation line" line
        length(fields) == 4 || continue
        push!(
            points,
            NavigationPoint(
                parse(Int, strip(fields[1])),
                parse(Float64, strip(fields[2])),
                parse(Float64, strip(fields[3])),
                DateTime(strip(fields[4])),
            ),
        )
    end
    return points
end
