using JCGECore
using JCGEExamples

specs = JCGECore.RunSpec[
    JCGEExamples.StandardCGE.model(sam_path=joinpath(JCGEExamples.StandardCGE.datadir(), "sam_2_2.csv")),
    JCGEExamples.SimpleCGE.model(),
    JCGEExamples.LargeCountryCGE.model(),
    JCGEExamples.TwoCountryCGE.model(),
    JCGEExamples.MonopolyCGE.model(),
    JCGEExamples.QuotaCGE.model(),
    JCGEExamples.ScaleEconomyCGE.model(),
    JCGEExamples.KorCGE.model(),
    JCGEExamples.KorMCP.model(),
]

for spec in specs
    JCGECore.validate(spec)
end

println("Integration specs validated.")
