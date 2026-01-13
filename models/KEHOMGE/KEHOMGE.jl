"""
JCGEExamples.KEHOMGE defines the KEHOMGE example model.
"""
module KEHOMGE

using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using PATHSolver

export model, baseline, scenario, solve, mpsge_model

include("mpsge_model.jl")

"""
Load model data tables from the local data directory.
"""
function _load_data()
    datadir = joinpath(@__DIR__, "data")
    a_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "a.csv"))
    alpha_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "alpha.csv"))
    endow_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "e.csv"))

    goods = a_mat.row_labels
    sectors = a_mat.col_labels
    consumers = alpha_mat.col_labels

    a_out = zeros(length(goods), length(sectors))
    a_in = zeros(length(goods), length(sectors))
    for (gi, g) in pairs(goods), (si, s) in pairs(sectors)
        aval = a_mat[g, s]
        if aval > 0
            a_out[gi, si] = aval
        elseif aval < 0
            a_in[gi, si] = -aval
        end
    end

    a_out_mat = JCGECalibrate.LabeledMatrix(a_out, goods, sectors)
    a_in_mat = JCGECalibrate.LabeledMatrix(a_in, goods, sectors)

    return (
        goods=goods,
        sectors=sectors,
        consumers=consumers,
        a_out=a_out_mat,
        a_in=a_in_mat,
        alpha=alpha_mat,
        endow=endow_mat,
    )
end

"""
    model(; eq=:EQ1) -> RunSpec

Return a RunSpec for the KEHOMGE MCP model.
"""
function model(; eq::Symbol=:EQ1)
    data = _load_data()

    sets = JCGECore.Sets(data.goods, data.sectors, data.goods, data.consumers)
    mappings = JCGECore.Mappings(Dict(s => data.goods[1] for s in data.sectors))

    params = (a_out=data.a_out, a_in=data.a_in, alpha=data.alpha, endowment=data.endow, mcp=true)

    prod_block = JCGEBlocks.activity_analysis(:activity, data.sectors, data.goods; params=params)
    cons_block = JCGEBlocks.consumer_endowment_cd(:consumers, data.consumers, data.goods; params=params)
    market_block = JCGEBlocks.commodity_market_clearing(:markets, data.goods, data.sectors, data.consumers; params=params)
    numeraire_block = JCGEBlocks.numeraire(:numeraire, :commodity, data.goods[1], 1.0)

    closure = JCGECore.ClosureSpec(data.goods[1])
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())

    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], prod_block)
    push!(section_blocks[:households], cons_block)
    push!(section_blocks[:markets], market_block)
    push!(section_blocks[:closure], numeraire_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    required_nonempty = [:production, :households, :markets]

    return JCGECore.build_spec(
        "KEHOMGE",
        sets,
        mappings,
        sections;
        closure=closure,
        scenario=scenario,
        required_sections=allowed_sections,
        allowed_sections=allowed_sections,
        required_nonempty=required_nonempty,
    )
end

"""
Return the baseline RunSpec for KEHOMGE.
"""
baseline(; eq::Symbol=:EQ1) = model(eq=eq)
scenario(; eq::Symbol=:EQ1) = model(eq=eq)

"""
Solve the KEHOMGE model and return the run result.
"""
function solve(; optimizer=PATHSolver.Optimizer, eq::Symbol=:EQ1)
    return JCGERuntime.run!(model(eq=eq); optimizer=optimizer, compile_ast=true, compile_objective=false)
end

end # module
