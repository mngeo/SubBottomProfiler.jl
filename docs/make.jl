push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using Documenter
using SubBottomProfiler

const PAGES = [
    "Home" => "index.md",
    "Getting Started" => "getting_started.md",
    "SEG-Y Format" => "segy_format.md",
    "Processing Reference" => "processing_reference.md",
    "Interpretation Guide" => "interpretation_guide.md",
    "CLI Reference" => "cli_reference.md",
    "API Reference" => "api_reference.md",
]

makedocs(
    modules = [SubBottomProfiler],
    sitename = "SubBottomProfiler.jl",
    authors = "OpenAI Codex",
    format = Documenter.HTML(
        prettyurls = true,
        canonical = get(ENV, "DOCUMENTER_CANONICAL_URL", nothing),
        repolink = "https://github.com/mngeo/SubBottomProfiler.jl",
        edit_link = "main",
        sidebar_sitename = true,
    ),
    pages = PAGES,
    checkdocs = :exports,
    remotes = nothing,
)

if haskey(ENV, "GITHUB_ACTIONS") || haskey(ENV, "CI")
    repo = get(ENV, "DOCUMENTER_REPO", "")
    if !isempty(repo)
        deploydocs(
            repo = repo,
            devbranch = "main",
            push_preview = false,
        )
    end
end
