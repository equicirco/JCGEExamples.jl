"""
Collection of example CGE models built with JCGE blocks.
"""
module JCGEExamples

export StandardCGE
export SimpleCGE
export LargeCountryCGE
export TwoCountryCGE
export MonopolyCGE
export QuotaCGE
export ScaleEconomyCGE
export DynCGE
export CamCGE
export CamMGE
export CamMCP
export KEHOMGE
export KorCGE
export KorMCP

include("../models/StandardCGE/StandardCGE.jl")
include("../models/SimpleCGE/SimpleCGE.jl")
include("../models/LargeCountryCGE/LargeCountryCGE.jl")
include("../models/TwoCountryCGE/TwoCountryCGE.jl")
include("../models/MonopolyCGE/MonopolyCGE.jl")
include("../models/QuotaCGE/QuotaCGE.jl")
include("../models/ScaleEconomyCGE/ScaleEconomyCGE.jl")
include("../models/DynCGE/DynCGE.jl")
include("../models/CamCGE/CamCGE.jl")
include("../models/CamMGE/CamMGE.jl")
include("../models/CamMCP/CamMCP.jl")
include("../models/KEHOMGE/KEHOMGE.jl")
include("../models/KorCGE/KorCGE.jl")
include("../models/KorMCP/KorMCP.jl")

end # module
