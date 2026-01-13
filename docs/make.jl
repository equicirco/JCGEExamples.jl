using Documenter
using JCGEExamples

makedocs(
    sitename = "JCGEExamples",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        assets = [
        "assets/logo.css",
        "assets/deepwiki-chat.css",
        "assets/deepwiki-chat.js",
        "assets/logo-theme.js",
    ]
    ),
    pages = [
        "Home" => "index.md",
        "Usage" => "usage.md",
        "API" => "api.md"
    ],
)


deploydocs(
    repo = "github.com/equicirco/JCGEExamples.jl",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
)
