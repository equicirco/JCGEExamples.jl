"""
JCGEExamples.StandardCGE defines the StandardCGE example model.
"""
module StandardCGE

using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using Ipopt

export model, baseline, scenario, datadir, solve

"""
    model(; sam_table, sam_path, kwargs...) -> RunSpec

Return a RunSpec for the StandardCGE model port.
"""
function model(; sam_table::Union{Nothing,JCGECalibrate.SAMTable} = nothing,
    sam_path::Union{Nothing,AbstractString} = nothing,
    goods::Vector{String} = ["BRD", "MLK"],
    factors::Vector{String} = ["CAP", "LAB"],
    numeraire_factor_label::String = "LAB",
    indirectTax_label::String = "IDT",
    tariff_label::String = "TRF",
    households_label::String = "HOH",
    government_label::String = "GOV",
    investment_label::String = "INV",
    restOfTheWorld_label::String = "EXT")
    if sam_table === nothing
        sam_path === nothing && error("Provide sam_table or sam_path to StandardCGE.model()")
        sam_table = JCGECalibrate.load_sam_table(sam_path;
            goods = goods,
            factors = factors,
            numeraire_factor_label = numeraire_factor_label,
            indirectTax_label = indirectTax_label,
            tariff_label = tariff_label,
            households_label = households_label,
            government_label = government_label,
            investment_label = investment_label,
            restOfTheWorld_label = restOfTheWorld_label,
        )
    end
    start = JCGECalibrate.compute_starting_values(sam_table)
    params = JCGECalibrate.compute_calibration_params(sam_table, start)

    commodities = sam_table.goods
    activities = sam_table.goods
    factors_sym = sam_table.factors
    institutions = [
        sam_table.households_label,
        sam_table.government_label,
        sam_table.investment_label,
        sam_table.restOfTheWorld_label,
    ]
    sets = JCGECore.Sets(commodities, activities, factors_sym, institutions)
    mappings = JCGECore.Mappings(Dict(a => a for a in activities))

    prod_params = (b = params.b, beta = params.beta, ay = params.ay, ax = params.ax)
    prod_block = JCGEBlocks.production(:prod, activities, factors_sym, commodities; form=:cd_leontief, params=prod_params)

    factor_market_block = JCGEBlocks.factor_market_clearing(:factor_market, activities, factors_sym; params=(FF = start.FF,))

    gov_params = (
        tau_d = params.tau_d,
        tau_z = start.tau_z,
        tau_m = start.tau_m,
        mu = params.mu,
        ssg = params.ssg,
        FF = start.FF,
    )
    gov_block = JCGEBlocks.government(:government, commodities, factors_sym, gov_params)

    saving_block = JCGEBlocks.private_saving(:private_saving, factors_sym, (ssp = params.ssp, FF = start.FF))

    hh_params = (alpha = params.alpha, FF = start.FF)
    household_block = JCGEBlocks.household_demand(:household, Symbol[], commodities, factors_sym; form=:cd, consumption_var=:Xp, params=hh_params)

    invest_block = JCGEBlocks.investment(:investment, commodities, (lambda = params.lambda, Sf = start.Sf))

    price_params = (pWe = start.pWe, pWm = start.pWm)
    price_block = JCGEBlocks.price_link(:prices, commodities, price_params)

    bop_params = (pWe = start.pWe, pWm = start.pWm, Sf = start.Sf)
    bop_block = JCGEBlocks.external_balance(:bop, commodities, bop_params)

    arm_params = (
        gamma = params.gamma,
        delta_m = params.delta_m,
        delta_d = params.delta_d,
        eta = params.eta,
        tau_m = start.tau_m,
    )
    arm_block = JCGEBlocks.armington(:armington, commodities, arm_params)

    trans_params = (
        theta = params.theta,
        xie = params.xie,
        xid = params.xid,
        phi = params.phi,
        tau_z = start.tau_z,
    )
    trans_block = JCGEBlocks.transformation(:transformation, commodities, trans_params)

    market_block = JCGEBlocks.composite_market_clearing(:market, commodities, activities)

    util_block = JCGEBlocks.utility(:utility, Symbol[], commodities; form=:cd, consumption_var=:Xp, params=(alpha = params.alpha,))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    for j in commodities
        start_vals[JCGEBlocks.global_var(:Y, j)] = start.Y0[j]
        start_vals[JCGEBlocks.global_var(:Z, j)] = start.Z0[j]
        start_vals[JCGEBlocks.global_var(:Xp, j)] = start.Xp0[j]
        start_vals[JCGEBlocks.global_var(:Xg, j)] = start.Xg0[j]
        start_vals[JCGEBlocks.global_var(:Xv, j)] = start.Xv0[j]
        start_vals[JCGEBlocks.global_var(:E, j)] = start.E0[j]
        start_vals[JCGEBlocks.global_var(:M, j)] = start.M0[j]
        start_vals[JCGEBlocks.global_var(:Q, j)] = start.Q0[j]
        start_vals[JCGEBlocks.global_var(:D, j)] = start.D0[j]
        start_vals[JCGEBlocks.global_var(:py, j)] = start.py0[j]
        start_vals[JCGEBlocks.global_var(:pz, j)] = start.pz0[j]
        start_vals[JCGEBlocks.global_var(:pq, j)] = start.pq0[j]
        start_vals[JCGEBlocks.global_var(:pe, j)] = start.pe0[j]
        start_vals[JCGEBlocks.global_var(:pm, j)] = start.pm0[j]
        start_vals[JCGEBlocks.global_var(:pd, j)] = start.pd0[j]
        start_vals[JCGEBlocks.global_var(:Tz, j)] = start.Tz0[j]
        start_vals[JCGEBlocks.global_var(:Tm, j)] = start.Tm0[j]
    end
    for h in factors_sym
        start_vals[JCGEBlocks.global_var(:pf, h)] = start.pf0[h]
    end
    for h in factors_sym, j in commodities
        start_vals[JCGEBlocks.global_var(:F, h, j)] = start.F0[h, j]
    end
    for i in commodities, j in commodities
        start_vals[JCGEBlocks.global_var(:X, i, j)] = start.X0[i, j]
    end
    start_vals[:epsilon] = start.epsilon0
    start_vals[:Sp] = start.Sp0
    start_vals[:Sg] = start.Sg0
    start_vals[:Td] = start.Td0

    for (name, value) in start_vals
        lower_vals[name] = 1.0e-5
    end
    for j in commodities
        lower_vals[JCGEBlocks.global_var(:Tz, j)] = 0.0
        lower_vals[JCGEBlocks.global_var(:Tm, j)] = 0.0
    end
    init_block = JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals))

    numeraire_block = JCGEBlocks.numeraire(:numeraire, :factor, sam_table.numeraire_factor_label, 1.0)

    closure = JCGECore.ClosureSpec(sam_table.numeraire_factor_label)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    sections = [
        JCGECore.section(:production, Any[prod_block]),
        JCGECore.section(:factors, Any[factor_market_block]),
        JCGECore.section(:government, Any[gov_block]),
        JCGECore.section(:savings, Any[saving_block, invest_block]),
        JCGECore.section(:households, Any[household_block]),
        JCGECore.section(:prices, Any[price_block]),
        JCGECore.section(:external, Any[bop_block]),
        JCGECore.section(:trade, Any[arm_block, trans_block]),
        JCGECore.section(:markets, Any[market_block]),
        JCGECore.section(:objective, Any[util_block]),
        JCGECore.section(:init, Any[init_block]),
        JCGECore.section(:closure, Any[numeraire_block]),
    ]
    allowed_sections = JCGECore.allowed_sections()
    required_nonempty = [:production, :households, :markets]
    return JCGECore.build_spec(
        "StandardCGE",
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
Return the baseline RunSpec for StandardCGE.
"""
baseline() = model()

"""
Solve the StandardCGE model and return the run result.
"""
function solve(; optimizer=Ipopt.Optimizer, kwargs...)
    return JCGERuntime.run!(model(; kwargs...); optimizer=optimizer)
end

"""
Create a scenario placeholder for StandardCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

"""
Return the data directory for StandardCGE.
"""
datadir() = joinpath(@__DIR__, "data")

end # module
