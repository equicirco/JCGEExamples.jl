"""
JCGEExamples.SimpleCGE defines the SimpleCGE example model.
"""
module SimpleCGE

using JCGECore
using JCGERuntime
using Ipopt
using JCGEBlocks
using JCGECalibrate

export model, baseline, scenario, datadir, solve

"""
Return a minimal RunSpec for quick testing and development.
"""
function model(; sam_path::Union{Nothing,AbstractString}=nothing)
    sam_path === nothing && (sam_path = joinpath(@__DIR__, "data", "sam_2_2.csv"))
    sam_table = JCGECalibrate.load_sam_table(sam_path;
        goods = ["BRD", "MLK"],
        factors = ["CAP", "LAB"],
        households_label = "HOH",
    )
    sam = sam_table.sam

    goods = [:BRD, :MLK]
    factors = [:CAP, :LAB]
    hh = :HOH

    X0 = Dict(i => sam[i, hh] for i in goods)
    F0 = Dict((h, j) => sam[h, j] for h in factors for j in goods)
    Z0 = Dict(j => sum(F0[(h, j)] for h in factors) for j in goods)
    FF = Dict(h => sam[hh, h] for h in factors)

    alpha = Dict(i => X0[i] / sum(values(X0)) for i in goods)
    beta = Dict((h, j) => F0[(h, j)] / sum(F0[(k, j)] for k in factors) for h in factors for j in goods)
    b = Dict(j => Z0[j] / prod(F0[(h, j)] ^ beta[(h, j)] for h in factors) for j in goods)

    prod_params = (
        b = b,
        beta = beta,
    )
    prod_block = JCGEBlocks.production(:prod, goods, factors, Symbol[]; form=:cd, params=prod_params)

    hh_params = (
        FF = FF,
        alpha = alpha,
    )
    household_block = JCGEBlocks.household_demand(:household, Symbol[], goods, factors; form=:cd, consumption_var=:X, params=hh_params)

    goods_market_block = JCGEBlocks.goods_market_clearing(:goods_market, goods)

    factor_market_block = JCGEBlocks.factor_market_clearing(:factor_market, goods, factors; params=(FF = FF,))

    price_block = JCGEBlocks.price_equality(:price_link, goods)

    numeraire_block = JCGEBlocks.numeraire(:numeraire, :factor, :LAB, 1.0)

    util_block = JCGEBlocks.utility(:utility, Symbol[], goods; form=:cd, consumption_var=:X, params=(alpha = alpha,))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    for i in goods
        start_vals[JCGEBlocks.global_var(:X, i)] = X0[i]
        start_vals[JCGEBlocks.global_var(:Z, i)] = Z0[i]
        start_vals[JCGEBlocks.global_var(:px, i)] = 1.0
        start_vals[JCGEBlocks.global_var(:pz, i)] = 1.0
    end
    for h in factors, j in goods
        start_vals[JCGEBlocks.global_var(:F, h, j)] = F0[(h, j)]
    end
    for h in factors
        start_vals[JCGEBlocks.global_var(:pf, h)] = 1.0
    end
    for (name, value) in start_vals
        lower_vals[name] = 0.001
    end
    init_block = JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals))

    sets = JCGECore.Sets(goods, goods, factors, [hh])
    mappings = JCGECore.Mappings(Dict(j => j for j in goods))
    closure = JCGECore.ClosureSpec(:LAB)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], prod_block)
    push!(section_blocks[:factors], factor_market_block)
    push!(section_blocks[:households], household_block)
    push!(section_blocks[:prices], price_block)
    push!(section_blocks[:markets], goods_market_block)
    push!(section_blocks[:objective], util_block)
    push!(section_blocks[:init], init_block)
    push!(section_blocks[:closure], numeraire_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    return JCGECore.build_spec(
        "SimpleCGE",
        sets,
        mappings,
        sections;
        closure=closure,
        scenario=scenario,
        required_sections=allowed_sections,
        allowed_sections=allowed_sections,
        required_nonempty=[:production, :households, :markets],
    )
end

"""
Return the baseline RunSpec for SimpleCGE.
"""
baseline() = model()

"""
Solve the SimpleCGE model and return the run result.
"""
function solve(; optimizer=Ipopt.Optimizer, kwargs...)
    return JCGERuntime.run!(model(; kwargs...); optimizer=optimizer)
end

"""
Create a scenario placeholder for SimpleCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

"""
Return the data directory for SimpleCGE.
"""
datadir() = joinpath(@__DIR__, "data")

end # module
