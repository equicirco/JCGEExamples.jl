"""
JCGEExamples.QuotaCGE defines the QuotaCGE example model.
"""
module QuotaCGE

using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using Ipopt

export model, baseline, scenario, datadir, solve

"""
    model(; sam_path, kwargs...) -> RunSpec

Return a RunSpec for the import-quota CGE model port (Chapter 10.5).
"""
function model(; sam_path::Union{Nothing,AbstractString} = nothing,
    goods::Vector{String} = ["BRD", "MLK"],
    factors::Vector{String} = ["CAP", "LAB"],
    numeraire_factor_label::String = "LAB",
    indirectTax_label::String = "IDT",
    tariff_label::String = "TRF",
    households_label::String = "HOH",
    government_label::String = "GOV",
    investment_label::String = "INV",
    restOfTheWorld_label::String = "EXT")

    sam_path === nothing && (sam_path = joinpath(@__DIR__, "data", "sam_2_2.csv"))
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

    sam = sam_table.sam
    commodities = sam_table.goods
    activities = sam_table.goods
    factors_sym = sam_table.factors
    sets = JCGECore.Sets(commodities, activities, factors_sym, [
        sam_table.households_label,
        sam_table.government_label,
        sam_table.investment_label,
        sam_table.restOfTheWorld_label,
    ])
    mappings = JCGECore.Mappings(Dict(a => a for a in activities))

    idt = sam_table.indirectTax_label
    trf = sam_table.tariff_label
    hoh = sam_table.households_label
    gov = sam_table.government_label
    inv = sam_table.investment_label
    ext = sam_table.restOfTheWorld_label

    sigma = Dict(i => 2.0 for i in commodities)
    psi = Dict(i => 2.0 for i in commodities)
    eta = Dict(i => (sigma[i] - 1.0) / sigma[i] for i in commodities)
    phi = Dict(i => (psi[i] + 1.0) / psi[i] for i in commodities)

    Td0 = sam[gov, hoh]
    Tz0 = Dict(i => sam[idt, i] for i in commodities)
    Tm0 = Dict(i => sam[trf, i] for i in commodities)
    F0 = Dict((h, j) => sam[h, j] for h in factors_sym for j in activities)
    Y0 = Dict(j => sum(F0[(h, j)] for h in factors_sym) for j in activities)
    X0 = Dict((i, j) => sam[i, j] for i in commodities for j in activities)
    Z0 = Dict(j => Y0[j] + sum(X0[(i, j)] for i in commodities) for j in activities)
    M0 = Dict(i => sam[ext, i] for i in commodities)
    tau_z = Dict(j => Tz0[j] / Z0[j] for j in activities)
    tau_m = Dict(i => Tm0[i] / M0[i] for i in commodities)
    Mquota = Dict(i => M0[i] * 100.0 for i in commodities)
    Xp0 = Dict(i => sam[i, hoh] for i in commodities)
    FF = Dict(h => sam[hoh, h] for h in factors_sym)
    Xg0 = Dict(i => sam[i, gov] for i in commodities)
    Xv0 = Dict(i => sam[i, inv] for i in commodities)
    E0 = Dict(i => sam[i, ext] for i in commodities)
    Q0 = Dict(i => Xp0[i] + Xg0[i] + Xv0[i] + sum(X0[(i, j)] for j in activities) for i in commodities)
    D0 = Dict(i => (1.0 + tau_z[i]) * Z0[i] - E0[i] for i in commodities)
    Sp0 = sam[inv, hoh]
    Sg0 = sam[inv, gov]
    Sf = sam[inv, ext]
    pWe0 = Dict(i => 1.0 for i in commodities)
    pWm0 = Dict(i => 1.0 for i in commodities)

    alpha = Dict(i => Xp0[i] / sum(values(Xp0)) for i in commodities)
    beta = Dict((h, j) => F0[(h, j)] / sum(F0[(k, j)] for k in factors_sym) for h in factors_sym for j in activities)
    b = Dict(j => Y0[j] / prod(F0[(h, j)] ^ beta[(h, j)] for h in factors_sym) for j in activities)
    ax = Dict((i, j) => X0[(i, j)] / Z0[j] for i in commodities for j in activities)
    ay = Dict(j => Y0[j] / Z0[j] for j in activities)
    mu = Dict(i => Xg0[i] / sum(values(Xg0)) for i in commodities)
    lambda = Dict(i => Xv0[i] / (Sp0 + Sg0 + Sf) for i in commodities)
    deltam = Dict(i => (1.0 + tau_m[i]) * M0[i] ^ (1.0 - eta[i]) /
        ((1.0 + tau_m[i]) * M0[i] ^ (1.0 - eta[i]) + D0[i] ^ (1.0 - eta[i])) for i in commodities)
    deltad = Dict(i => D0[i] ^ (1.0 - eta[i]) /
        ((1.0 + tau_m[i]) * M0[i] ^ (1.0 - eta[i]) + D0[i] ^ (1.0 - eta[i])) for i in commodities)
    gamma = Dict(i => Q0[i] / (deltam[i] * M0[i] ^ eta[i] + deltad[i] * D0[i] ^ eta[i]) ^ (1.0 / eta[i]) for i in commodities)
    xie = Dict(i => E0[i] ^ (1.0 - phi[i]) / (E0[i] ^ (1.0 - phi[i]) + D0[i] ^ (1.0 - phi[i])) for i in commodities)
    xid = Dict(i => D0[i] ^ (1.0 - phi[i]) / (E0[i] ^ (1.0 - phi[i]) + D0[i] ^ (1.0 - phi[i])) for i in commodities)
    theta = Dict(i => Z0[i] / (xie[i] * E0[i] ^ phi[i] + xid[i] * D0[i] ^ phi[i]) ^ (1.0 / phi[i]) for i in commodities)
    ssp = Sp0 / sum(values(FF))
    ssg = Sg0 / (Td0 + sum(values(Tz0)) + sum(values(Tm0)))
    tau_d = Td0 / sum(values(FF))

    prod_params = (b = b, beta = beta, ay = ay, ax = ax)
    prod_block = JCGEBlocks.production(:prod, activities, factors_sym, commodities; form=:cd_leontief, params=prod_params)

    factor_market_block = JCGEBlocks.factor_market_clearing(:factor_market, activities, factors_sym; params=(FF = FF,))

    gov_params = (
        tau_d = tau_d,
        tau_z = tau_z,
        tau_m = tau_m,
        mu = mu,
        ssg = ssg,
        FF = FF,
        include_rent = true,
    )
    gov_block = JCGEBlocks.government(:government, commodities, factors_sym, gov_params)

    saving_block = JCGEBlocks.private_saving(:private_saving, factors_sym, (ssp = ssp, FF = FF, include_rent = true))

    hh_params = (alpha = alpha, FF = FF, include_rent = true)
    household_block = JCGEBlocks.household_demand(:household, Symbol[], commodities, factors_sym; form=:cd, consumption_var=:Xp, params=hh_params)

    invest_block = JCGEBlocks.investment(:investment, commodities, (lambda = lambda, Sf = Sf))

    price_block = JCGEBlocks.price_link(:prices, commodities, (pWe = pWe0, pWm = pWm0))

    bop_block = JCGEBlocks.external_balance(:bop, commodities, (pWe = pWe0, pWm = pWm0, Sf = Sf))

    arm_params = (
        gamma = gamma,
        delta_m = deltam,
        delta_d = deltad,
        eta = eta,
        tau_m = tau_m,
        include_chi = true,
    )
    arm_block = JCGEBlocks.armington(:armington, commodities, arm_params)

    trans_params = (
        theta = theta,
        xie = xie,
        xid = xid,
        phi = phi,
        tau_z = tau_z,
    )
    trans_block = JCGEBlocks.transformation(:transformation, commodities, trans_params)

    quota_block = JCGEBlocks.import_quota(:quota, commodities, (Mquota = Mquota,))

    market_block = JCGEBlocks.composite_market_clearing(:market, commodities, activities)

    util_block = JCGEBlocks.utility(:utility, Symbol[], commodities; form=:cd, consumption_var=:Xp, params=(alpha = alpha,))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    for j in commodities
        start_vals[JCGEBlocks.global_var(:Y, j)] = Y0[j]
        start_vals[JCGEBlocks.global_var(:Z, j)] = Z0[j]
        start_vals[JCGEBlocks.global_var(:Xp, j)] = Xp0[j]
        start_vals[JCGEBlocks.global_var(:Xg, j)] = Xg0[j]
        start_vals[JCGEBlocks.global_var(:Xv, j)] = Xv0[j]
        start_vals[JCGEBlocks.global_var(:E, j)] = E0[j]
        start_vals[JCGEBlocks.global_var(:M, j)] = M0[j]
        start_vals[JCGEBlocks.global_var(:Q, j)] = Q0[j]
        start_vals[JCGEBlocks.global_var(:D, j)] = D0[j]
        start_vals[JCGEBlocks.global_var(:py, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pz, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pq, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pe, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pm, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pd, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:Tz, j)] = Tz0[j]
        start_vals[JCGEBlocks.global_var(:Tm, j)] = Tm0[j]
        start_vals[JCGEBlocks.global_var(:RT, j)] = 0.0
        start_vals[JCGEBlocks.global_var(:chi, j)] = 0.0
    end
    for h in factors_sym
        start_vals[JCGEBlocks.global_var(:pf, h)] = 1.0
    end
    for h in factors_sym, j in commodities
        start_vals[JCGEBlocks.global_var(:F, h, j)] = F0[(h, j)]
    end
    for i in commodities, j in commodities
        start_vals[JCGEBlocks.global_var(:X, i, j)] = X0[(i, j)]
    end
    start_vals[:epsilon] = 1.0
    start_vals[:Sp] = Sp0
    start_vals[:Sg] = Sg0
    start_vals[:Td] = Td0

    for (name, value) in start_vals
        lower_vals[name] = 1.0e-5
    end
    for j in commodities
        lower_vals[JCGEBlocks.global_var(:Tz, j)] = 0.0
        lower_vals[JCGEBlocks.global_var(:Tm, j)] = 0.0
        lower_vals[JCGEBlocks.global_var(:RT, j)] = 0.0
        lower_vals[JCGEBlocks.global_var(:chi, j)] = 0.0
    end
    init_block = JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals))

    numeraire_block = JCGEBlocks.numeraire(:numeraire, :factor, sam_table.numeraire_factor_label, 1.0)

    closure = JCGECore.ClosureSpec(sam_table.numeraire_factor_label)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], prod_block)
    push!(section_blocks[:factors], factor_market_block)
    push!(section_blocks[:government], gov_block)
    push!(section_blocks[:savings], saving_block, invest_block)
    push!(section_blocks[:households], household_block)
    push!(section_blocks[:prices], price_block)
    push!(section_blocks[:external], bop_block)
    push!(section_blocks[:trade], arm_block, trans_block, quota_block)
    push!(section_blocks[:markets], market_block)
    push!(section_blocks[:objective], util_block)
    push!(section_blocks[:init], init_block)
    push!(section_blocks[:closure], numeraire_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    return JCGECore.build_spec(
        "QuotaCGE",
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
Return the baseline RunSpec for QuotaCGE.
"""
baseline() = model()

"""
Solve the QuotaCGE model and return the run result.
"""
function solve(; optimizer=Ipopt.Optimizer, kwargs...)
    return JCGERuntime.run!(model(; kwargs...); optimizer=optimizer)
end

"""
Create a scenario placeholder for QuotaCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

"""
Return the data directory for QuotaCGE.
"""
datadir() = joinpath(@__DIR__, "data")

end # module
