using TOML

function load_cli_config(path::AbstractString)::Dict{String, Any}
    return TOML.parsefile(path)
end
