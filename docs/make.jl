using Documenter
using JCGEExamples

makedocs(
    sitename = "JCGEExamples",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        mathengine = MathJax(),
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
        "API" => "api.md",
        "Citation" => "citation.md",
        "Models" => "models.md",
        "Model Pages" => [
            "StandardCGE" => "models/StandardCGE.md",
            "SimpleCGE" => "models/SimpleCGE.md",
            "LargeCountryCGE" => "models/LargeCountryCGE.md",
            "TwoCountryCGE" => "models/TwoCountryCGE.md",
            "MonopolyCGE" => "models/MonopolyCGE.md",
            "QuotaCGE" => "models/QuotaCGE.md",
            "ScaleEconomyCGE" => "models/ScaleEconomyCGE.md",
            "DynCGE" => "models/DynCGE.md",
            "CamCGE" => "models/CamCGE.md",
            "CamMGE" => "models/CamMGE.md",
            "CamMCP" => "models/CamMCP.md",
            "KEHOMGE" => "models/KEHOMGE.md",
            "KorCGE" => "models/KorCGE.md",
            "KorMCP" => "models/KorMCP.md",
        ],
    ],
)


deploydocs(
    repo = "github.com/equicirco/JCGEExamples.jl",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
)
