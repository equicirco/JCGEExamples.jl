"""
JCGEExamples.DynCGE defines the DynCGE example model.
"""
module DynCGE

using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using JuMP
using Ipopt

export model, baseline, scenario, datadir, run_recursive, solve

"""
    model(; sam_path, kwargs...) -> RunSpec

Return a RunSpec for the recursive-dynamic standard CGE model port.
"""
function model(; sam_path::Union{Nothing,AbstractString} = nothing,
    goods::Vector{String} = ["AGR", "LMN", "HMN", "SRV"],
    factors::Vector{String} = ["CAP", "LAB"],
    mobile_factors::Vector{String} = ["LAB"],
    stock_factor::String = "CAP",
    pop::Real = 0.02,
    dep::Real = 0.04,
    ror::Real = 0.05,
    zeta::Real = 1.0)
    sam_path === nothing && (sam_path = joinpath(@__DIR__, "data", "sam.csv"))
    sam_table = JCGECalibrate.load_sam_table(sam_path;
        goods = goods,
        factors = factors,
        numeraire_factor_label = mobile_factors[1],
        indirectTax_label = "IDT",
        tariff_label = "TRF",
        households_label = "HOH",
        government_label = "GOV",
        investment_label = "INV",
        restOfTheWorld_label = "EXT",
    )
    sam = sam_table.sam

    commodities = sam_table.goods
    activities = sam_table.goods
    factors_sym = sam_table.factors
    mobile_sym = Symbol.(mobile_factors)
    stock_sym = Symbol(stock_factor)
    stock_sym in factors_sym || error("stock_factor must be one of the model factors")
    for mf in mobile_sym
        mf in factors_sym || error("mobile_factors must be a subset of the model factors")
    end

    idt = sam_table.indirectTax_label
    trf = sam_table.tariff_label
    hoh = sam_table.households_label
    gov = sam_table.government_label
    inv = sam_table.investment_label
    ext = sam_table.restOfTheWorld_label

    Tz00_vals = Float64.(sam[idt, commodities])
    Tm00_vals = Float64.(sam[trf, commodities])
    F00 = LabeledMatrix(Matrix{Float64}(sam[factors_sym, commodities]), factors_sym, commodities)
    X00 = LabeledMatrix(Matrix{Float64}(sam[commodities, commodities]), commodities, commodities)
    Y00_vals = vec(sum(F00.data, dims = 1))
    Y00 = LabeledVector(Y00_vals, commodities)
    Z00_vals = Y00_vals .+ vec(sum(X00.data, dims = 1))
    Z00 = LabeledVector(Z00_vals, commodities)
    M00_vals = Float64.(sam[ext, commodities])
    E00_vals = Float64.(sam[commodities, ext])
    tauz00_vals = Tz00_vals ./ Z00_vals
    taum00_vals = Tm00_vals ./ M00_vals
    Xp00_vals = Float64.(sam[commodities, hoh])
    FF00_vals = Float64.(sam[hoh, factors_sym])
    Xg_raw = Float64.(sam[commodities, gov])
    Xv_raw = Float64.(sam[commodities, inv])
    Sf00 = Float64(sam[inv, ext])

    D00_vals = (1 .+ tauz00_vals) .* Z00_vals .- E00_vals
    Q00_vals = (1 .+ taum00_vals) .* M00_vals .+ D00_vals
    CC00 = sum(Xp00_vals)

    III_ASS = (pop + dep) / ror * FF00_vals[findfirst(==(stock_sym), factors_sym)]
    III_SAM = sum(Xv_raw)
    adj = III_ASS / III_SAM

    Xv00_vals = Xv_raw .* adj
    Xg00_vals = Xg_raw .- (Xv00_vals .- Xv_raw)
    Td00 = sum(Xg00_vals) - sum(Tz00_vals .+ Tm00_vals)
    Sp00 = sum(FF00_vals) - (sum(Xp00_vals) + Td00)
    III00 = sum(Xv00_vals)
    cap_col = findfirst(==(stock_sym), factors_sym)
    F_cap = F00.data[cap_col, :]
    II00_vals = (Sp00 + Sf00) .* F_cap ./ sum(F_cap)
    KK00_vals = F_cap ./ ror

    Xp00 = LabeledVector(Xp00_vals, commodities)
    Xg00 = LabeledVector(Xg00_vals, commodities)
    Xv00 = LabeledVector(Xv00_vals, commodities)
    E00 = LabeledVector(E00_vals, commodities)
    M00 = LabeledVector(M00_vals, commodities)
    Q00 = LabeledVector(Q00_vals, commodities)
    D00 = LabeledVector(D00_vals, commodities)
    FF00 = LabeledVector(FF00_vals, factors_sym)
    Tz00 = LabeledVector(Tz00_vals, commodities)
    Tm00 = LabeledVector(Tm00_vals, commodities)
    tauz00 = LabeledVector(tauz00_vals, commodities)
    taum00 = LabeledVector(taum00_vals, commodities)
    II00 = LabeledVector(II00_vals, commodities)
    KK00 = LabeledVector(KK00_vals, commodities)

    sigma_vals = fill(2.0, length(commodities))
    psi_vals = fill(2.0, length(commodities))
    eta_vals = (sigma_vals .- 1) ./ sigma_vals
    phi_vals = (psi_vals .+ 1) ./ psi_vals

    alpha_vals = Xp00_vals ./ sum(Xp00_vals)
    a = CC00 / prod(Xp00_vals .^ alpha_vals)
    beta_vals = similar(F00.data)
    for j in eachindex(commodities)
        denom = sum(F00.data[:, j])
        for h in eachindex(factors_sym)
            beta_vals[h, j] = F00.data[h, j] / denom
        end
    end
    b_vals = similar(Y00_vals)
    for j in eachindex(commodities)
        b_vals[j] = Y00_vals[j] / prod(F00.data[:, j] .^ beta_vals[:, j])
    end
    ax_vals = X00.data ./ Z00_vals'
    ay_vals = Y00_vals ./ Z00_vals
    lambda_vals = Xv00_vals ./ sum(Xv00_vals)
    iota = III00 / prod(Xv00_vals .^ lambda_vals)
    deltam_vals = (1 .+ taum00_vals) .* M00_vals .^ (1 .- eta_vals) ./
        ((1 .+ taum00_vals) .* M00_vals .^ (1 .- eta_vals) .+ D00_vals .^ (1 .- eta_vals))
    deltad_vals = D00_vals .^ (1 .- eta_vals) ./
        ((1 .+ taum00_vals) .* M00_vals .^ (1 .- eta_vals) .+ D00_vals .^ (1 .- eta_vals))
    gamma_vals = Q00_vals ./ (deltam_vals .* M00_vals .^ eta_vals .+ deltad_vals .* D00_vals .^ eta_vals) .^ (1 ./ eta_vals)
    xie_vals = E00_vals .^ (1 .- phi_vals) ./ (E00_vals .^ (1 .- phi_vals) .+ D00_vals .^ (1 .- phi_vals))
    xid_vals = D00_vals .^ (1 .- phi_vals) ./ (E00_vals .^ (1 .- phi_vals) .+ D00_vals .^ (1 .- phi_vals))
    theta_vals = Z00_vals ./ (xie_vals .* E00_vals .^ phi_vals .+ xid_vals .* D00_vals .^ phi_vals) .^ (1 ./ phi_vals)
    ssp = Sp00 / (sum(F00.data) - Td00)

    alpha = LabeledVector(alpha_vals, commodities)
    beta = LabeledMatrix(beta_vals, factors_sym, commodities)
    b = LabeledVector(b_vals, commodities)
    ax = LabeledMatrix(ax_vals, commodities, commodities)
    ay = LabeledVector(ay_vals, commodities)
    lambda = LabeledVector(lambda_vals, commodities)
    deltam = LabeledVector(deltam_vals, commodities)
    deltad = LabeledVector(deltad_vals, commodities)
    gamma = LabeledVector(gamma_vals, commodities)
    xie = LabeledVector(xie_vals, commodities)
    xid = LabeledVector(xid_vals, commodities)
    theta = LabeledVector(theta_vals, commodities)
    eta = LabeledVector(eta_vals, commodities)
    phi = LabeledVector(phi_vals, commodities)

    prod_params = (b = b, beta = beta, ay = ay, ax = ax)
    prod_block = JCGEBlocks.production_sector_pf(:prod, activities, factors_sym, commodities; params = prod_params)

    gov_params = (tauz = tauz00, taum = taum00)
    gov_block = JCGEBlocks.government_budget_balance(:government, commodities, gov_params)

    saving_block = JCGEBlocks.private_saving_income(:private_saving, factors_sym, activities, (ssp = ssp,))

    hh_params = (alpha = alpha,)
    household_block = JCGEBlocks.household_demand_income(:household, commodities, factors_sym, activities; params = hh_params)

    pwe = LabeledVector(fill(1.0, length(commodities)), commodities)
    pwm = LabeledVector(fill(1.0, length(commodities)), commodities)
    price_block = JCGEBlocks.price_link(:prices, commodities, (pWe = pwe, pWm = pwm))
    bop_block = JCGEBlocks.external_balance(:bop, commodities, (pWe = pwe, pWm = pwm, Sf = Sf00))

    arm_params = (gamma = gamma, delta_m = deltam, delta_d = deltad, eta = eta, tau_m = taum00)
    arm_block = JCGEBlocks.armington(:armington, commodities, arm_params)

    trans_params = (theta = theta, xie = xie, xid = xid, phi = phi, tau_z = tauz00)
    trans_block = JCGEBlocks.transformation(:transformation, commodities, trans_params)

    market_block = JCGEBlocks.composite_market_clearing(:market, commodities, activities)

    mobile_block = JCGEBlocks.mobile_factor_market(:mobile_factor, mobile_sym, activities)
    capital_block = JCGEBlocks.capital_stock_return(:capital, stock_sym, activities, (ror = ror,))

    inv_block = JCGEBlocks.composite_investment(:investment, commodities, activities, (lambda = lambda, iota = iota))
    inv_alloc_block = JCGEBlocks.investment_allocation(:investment_alloc, stock_sym, activities, (zeta = zeta,))

    util_block = JCGEBlocks.composite_consumption(:utility, commodities, (alpha = alpha, a = a))

    weights = LabeledVector(Q00_vals ./ sum(Q00_vals), commodities)
    price_level_block = JCGEBlocks.price_level(:price_level, commodities, (w = weights,))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    fixed_vals = Dict{Symbol,Float64}()

    for j in commodities
        start_vals[JCGEBlocks.global_var(:Y, j)] = Y00[j]
        start_vals[JCGEBlocks.global_var(:Z, j)] = Z00[j]
        start_vals[JCGEBlocks.global_var(:Xp, j)] = Xp00[j]
        start_vals[JCGEBlocks.global_var(:Xg, j)] = Xg00[j]
        start_vals[JCGEBlocks.global_var(:Xv, j)] = Xv00[j]
        start_vals[JCGEBlocks.global_var(:E, j)] = E00[j]
        start_vals[JCGEBlocks.global_var(:M, j)] = M00[j]
        start_vals[JCGEBlocks.global_var(:Q, j)] = Q00[j]
        start_vals[JCGEBlocks.global_var(:D, j)] = D00[j]
        start_vals[JCGEBlocks.global_var(:py, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pz, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pq, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pe, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pm, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:pd, j)] = 1.0
        start_vals[JCGEBlocks.global_var(:Tz, j)] = Tz00[j]
        start_vals[JCGEBlocks.global_var(:Tm, j)] = Tm00[j]
        start_vals[JCGEBlocks.global_var(:II, j)] = II00[j]
        start_vals[JCGEBlocks.global_var(:KK, j)] = KK00[j]
    end
    for h in factors_sym, j in commodities
        start_vals[JCGEBlocks.global_var(:F, h, j)] = F00[h, j]
        start_vals[JCGEBlocks.global_var(:pf, h, j)] = 1.0
    end
    for i in commodities, j in commodities
        start_vals[JCGEBlocks.global_var(:X, i, j)] = X00[i, j]
    end
    for h in factors_sym
        start_vals[JCGEBlocks.global_var(:FF, h)] = FF00[h]
    end
    start_vals[:epsilon] = 1.0
    start_vals[:Sp] = Sp00
    start_vals[:Td] = Td00
    start_vals[:pk] = 1.0
    start_vals[:III] = III00
    start_vals[:CC] = CC00
    start_vals[:PRICE] = 1.0
    start_vals[:Sf] = Sf00

    for (name, value) in start_vals
        if name == :Td || name == :Sf || startswith(string(name), "Xg_")
            continue
        end
        lower_vals[name] = 1.0e-5
    end
    lower_vals[:Td] = -1.0e12
    lower_vals[:Sf] = -1.0e12
    for j in commodities
        lower_vals[JCGEBlocks.global_var(:Xg, j)] = -1.0e12
    end
    for j in commodities
        lower_vals[JCGEBlocks.global_var(:Tz, j)] = 0.0
        lower_vals[JCGEBlocks.global_var(:Tm, j)] = 0.0
    end

    fixed_vals[:PRICE] = 1.0
    fixed_vals[:Sf] = Sf00
    for h in mobile_sym
        fixed_vals[JCGEBlocks.global_var(:FF, h)] = FF00[h]
    end
    for j in commodities
        fixed_vals[JCGEBlocks.global_var(:KK, j)] = KK00[j]
        fixed_vals[JCGEBlocks.global_var(:Xg, j)] = Xg00[j]
    end

    init_block = JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals, fixed = fixed_vals))

    institutions = [hoh, gov, inv, ext]
    sets = JCGECore.Sets(commodities, activities, factors_sym, institutions)
    mappings = JCGECore.Mappings(Dict(a => a for a in activities))
    closure = JCGECore.ClosureSpec(:PRICE)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], prod_block)
    push!(section_blocks[:factors], mobile_block, capital_block)
    push!(section_blocks[:government], gov_block)
    push!(section_blocks[:savings], saving_block, inv_block, inv_alloc_block)
    push!(section_blocks[:households], household_block)
    push!(section_blocks[:prices], price_block, price_level_block)
    push!(section_blocks[:external], bop_block)
    push!(section_blocks[:trade], arm_block, trans_block)
    push!(section_blocks[:markets], market_block)
    push!(section_blocks[:objective], util_block)
    push!(section_blocks[:init], init_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    return JCGECore.build_spec(
        "DynCGE",
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
Return the baseline RunSpec for DynCGE.
"""
baseline() = model()

"""
Solve the DynCGE model and return the run result.
"""
function solve(; periods=30, optimizer=Ipopt.Optimizer, kwargs...)
    return run_recursive(; periods=periods, optimizer=optimizer, kwargs...)
end

"""
Create a scenario placeholder for DynCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

"""
Return the data directory for DynCGE.
"""
datadir() = joinpath(@__DIR__, "data")

"""
    run_recursive(; periods=30, optimizer=Ipopt.Optimizer, kwargs...) -> Vector

Solve the DynCGE model recursively for `periods` steps, updating state variables
between solves (capital stock and mobile factors), and returning a vector of
results for each period starting at t=0.
"""
function run_recursive(; periods::Int=30, optimizer=Ipopt.Optimizer,
    sam_path::Union{Nothing,AbstractString} = nothing,
    goods::Vector{String} = ["AGR", "LMN", "HMN", "SRV"],
    factors::Vector{String} = ["CAP", "LAB"],
    mobile_factors::Vector{String} = ["LAB"],
    stock_factor::String = "CAP",
    pop::Real = 0.02,
    dep::Real = 0.04,
    ror::Real = 0.05,
    zeta::Real = 1.0)
    spec = model(;
        sam_path=sam_path,
        goods=goods,
        factors=factors,
        mobile_factors=mobile_factors,
        stock_factor=stock_factor,
        pop=pop,
        dep=dep,
        ror=ror,
        zeta=zeta,
    )

    sam_path === nothing && (sam_path = joinpath(@__DIR__, "data", "sam.csv"))
    sam_table = JCGECalibrate.load_sam_table(sam_path;
        goods = goods,
        factors = factors,
        numeraire_factor_label = mobile_factors[1],
        indirectTax_label = "IDT",
        tariff_label = "TRF",
        households_label = "HOH",
        government_label = "GOV",
        investment_label = "INV",
        restOfTheWorld_label = "EXT",
    )
    sam = sam_table.sam
    commodities = sam_table.goods

    idt = sam_table.indirectTax_label
    trf = sam_table.tariff_label
    hoh = sam_table.households_label
    gov = sam_table.government_label
    inv = sam_table.investment_label
    ext = sam_table.restOfTheWorld_label
    factors_sym = sam_table.factors
    stock_sym = Symbol(stock_factor)
    cap_idx = findfirst(==(stock_sym), factors_sym)

    Tz00_vals = Float64.(sam[idt, commodities])
    Tm00_vals = Float64.(sam[trf, commodities])
    F00 = Matrix{Float64}(sam[factors_sym, commodities])
    X00 = Matrix{Float64}(sam[commodities, commodities])
    Y00_vals = vec(sum(F00, dims = 1))
    Z00_vals = Y00_vals .+ vec(sum(X00, dims = 1))
    M00_vals = Float64.(sam[ext, commodities])
    tauz00_vals = Tz00_vals ./ Z00_vals
    taum00_vals = Tm00_vals ./ M00_vals
    Xp00_vals = Float64.(sam[commodities, hoh])
    FF00_vals = Float64.(sam[hoh, factors_sym])
    Xg_raw = Float64.(sam[commodities, gov])
    Xv_raw = Float64.(sam[commodities, inv])
    Sf00 = Float64(sam[inv, ext])

    III_ASS = (pop + dep) / ror * FF00_vals[cap_idx]
    III_SAM = sum(Xv_raw)
    adj = III_ASS / III_SAM

    Xv00_vals = Xv_raw .* adj
    Xg00_vals = Xg_raw .- (Xv00_vals .- Xv_raw)

    xg_path = [Xg00_vals .* (1 + pop) ^ t for t in 0:periods]
    sf_path = [Sf00 * (1 + pop) ^ t for t in 0:periods]

    results = Vector{Any}(undef, periods + 1)
    results[1] = JCGERuntime.run!(spec; optimizer=optimizer, dataset_id="dyncge_t0")

    mobile_sym = Symbol.(mobile_factors)
    activities = commodities
    for t in 1:periods
        prev = results[t]
        state = JCGERuntime.snapshot_state(prev)
        fixed = Dict{Symbol,Float64}()
        fixed[:PRICE] = 1.0
        fixed[:Sf] = sf_path[t + 1]
        for (idx, i) in enumerate(commodities)
            fixed[JCGEBlocks.global_var(:Xg, i)] = xg_path[t + 1][idx]
        end

        for h in mobile_sym
            name = JCGEBlocks.global_var(:FF, h)
            fixed[name] = JuMP.value(prev.context.variables[name]) * (1 + pop)
        end
        for j in activities
            kk_name = JCGEBlocks.global_var(:KK, j)
            ii_name = JCGEBlocks.global_var(:II, j)
            kk_val = JuMP.value(prev.context.variables[kk_name])
            ii_val = JuMP.value(prev.context.variables[ii_name])
            fixed[kk_name] = (1 - dep) * kk_val + ii_val
        end

        spec = JCGEBlocks.apply_start(spec, state.start; lower=state.lower, upper=state.upper, fixed=fixed)
        results[t + 1] = JCGERuntime.run!(spec; optimizer=optimizer, dataset_id="dyncge_t$(t)")
    end

    return results
end

end # module
