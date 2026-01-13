"""
JCGEExamples.TwoCountryCGE defines the TwoCountryCGE example model.
"""
module TwoCountryCGE

using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using Ipopt

export model, baseline, scenario, datadir, solve

const REGIONS = [:JPN, :USA]

region_sym(base::Symbol, region::Symbol) = Symbol(string(base), "_", region)

function region_symbols(bases::Vector{Symbol}, region::Symbol)
    return [region_sym(b, region) for b in bases]
end

function build_region_mapping(bases::Vector{Symbol}, regions::Vector{Symbol})
    mapping = Dict{Tuple{Symbol,Symbol},Symbol}()
    for r in regions
        for b in bases
            mapping[(b, r)] = region_sym(b, r)
        end
    end
    return mapping
end

"""
    model(; kwargs...) -> RunSpec

Return a RunSpec for the two-country CGE model (Chapter 10.3).
"""
function model(; sam_paths::Dict{Symbol,String}=Dict(
        :JPN => joinpath(@__DIR__, "data", "sam_jpn.csv"),
        :USA => joinpath(@__DIR__, "data", "sam_usa.csv"),
    ),
    goods::Vector{String} = ["BRD", "MLK"],
    factors::Vector{String} = ["CAP", "LAB"],
    numeraire_factor_label::String = "LAB",
    indirectTax_label::String = "IDT",
    tariff_label::String = "TRF",
    households_label::String = "HOH",
    government_label::String = "GOV",
    investment_label::String = "INV",
    restOfTheWorld_label::String = "EXT")
    goods_sym = Symbol.(goods)
    factors_sym = Symbol.(factors)

    sam_tables = Dict{Symbol,JCGECalibrate.SAMTable}()
    starts = Dict{Symbol,JCGECalibrate.StartingValues}()
    params = Dict{Symbol,JCGECalibrate.ModelParameters}()

    for r in REGIONS
        sam_path = sam_paths[r]
        sam_tables[r] = JCGECalibrate.load_sam_table(sam_path;
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
        starts[r] = JCGECalibrate.compute_starting_values(sam_tables[r])
        params[r] = JCGECalibrate.compute_calibration_params(sam_tables[r], starts[r])
    end

    commodities = Symbol[]
    activities = Symbol[]
    factors_r = Symbol[]
    institutions = Symbol[]

    for r in REGIONS
        append!(commodities, region_symbols(goods_sym, r))
        append!(activities, region_symbols(goods_sym, r))
        append!(factors_r, region_symbols(factors_sym, r))
        append!(institutions, region_symbols(Symbol.([households_label, government_label, investment_label, restOfTheWorld_label]), r))
    end

    sets = JCGECore.Sets(commodities, activities, factors_r, institutions)
    mappings = JCGECore.Mappings(Dict(a => a for a in activities))

    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    goods_map = build_region_mapping(goods_sym, REGIONS)
    goods_by_region = Dict(r => region_symbols(goods_sym, r) for r in REGIONS)

    for r in REGIONS
        goods_r = goods_by_region[r]
        factors_rr = region_symbols(factors_sym, r)
        start = starts[r]
        param = params[r]

        b = Dict{Symbol,Float64}()
        beta = Dict{Tuple{Symbol,Symbol},Float64}()
        ay = Dict{Symbol,Float64}()
        ax = Dict{Tuple{Symbol,Symbol},Float64}()

        for g in goods_sym
            gsym = goods_map[(g, r)]
            b[gsym] = param.b[g]
            ay[gsym] = param.ay[g]
            for h in factors_sym
                hsym = region_sym(h, r)
                beta[(hsym, gsym)] = param.beta[h, g]
            end
            for i in goods_sym
                isym = goods_map[(i, r)]
                ax[(isym, gsym)] = param.ax[i, g]
            end
        end

        prod_params = (b = b, beta = beta, ay = ay, ax = ax)
        push!(section_blocks[:production], JCGEBlocks.production(:prod, goods_r, factors_rr, goods_r; form=:cd_leontief, params=prod_params))
        ff_vals = Dict{Symbol,Float64}()
        for h in factors_sym
            hsym = region_sym(h, r)
            ff_vals[hsym] = start.FF[h]
        end
        push!(section_blocks[:factors], JCGEBlocks.factor_market_clearing(:factor_market, goods_r, factors_rr; params=(FF = ff_vals,)))

        tau_z = Dict{Symbol,Float64}()
        tau_m = Dict{Symbol,Float64}()
        mu = Dict{Symbol,Float64}()
        alpha = Dict{Symbol,Float64}()
        lambda = Dict{Symbol,Float64}()
        gamma = Dict{Symbol,Float64}()
        delta_m = Dict{Symbol,Float64}()
        delta_d = Dict{Symbol,Float64}()
        theta = Dict{Symbol,Float64}()
        xie = Dict{Symbol,Float64}()
        xid = Dict{Symbol,Float64}()
        eta = Dict{Symbol,Float64}()
        phi = Dict{Symbol,Float64}()

        for g in goods_sym
            gsym = goods_map[(g, r)]
            tau_z[gsym] = start.tau_z[g]
            tau_m[gsym] = start.tau_m[g]
            mu[gsym] = param.mu[g]
            alpha[gsym] = param.alpha[g]
            lambda[gsym] = param.lambda[g]
            gamma[gsym] = param.gamma[g]
            delta_m[gsym] = param.delta_m[g]
            delta_d[gsym] = param.delta_d[g]
            theta[gsym] = param.theta[g]
            xie[gsym] = param.xie[g]
            xid[gsym] = param.xid[g]
            eta[gsym] = param.eta[g]
            phi[gsym] = param.phi[g]
        end

        gov_params = (
            tau_d = param.tau_d,
            tau_z = tau_z,
            tau_m = tau_m,
            mu = mu,
            ssg = param.ssg,
            FF = ff_vals,
        )
        push!(section_blocks[:government], JCGEBlocks.government_regional(:government, goods_r, factors_rr, r, gov_params))
        push!(section_blocks[:savings], JCGEBlocks.private_saving_regional(:private_saving, factors_rr, r, (ssp = param.ssp, FF = ff_vals)))
        push!(section_blocks[:households], JCGEBlocks.household_demand_regional(:household, goods_r, factors_rr, r; params=(alpha = alpha, FF = ff_vals)))
        push!(section_blocks[:savings], JCGEBlocks.investment_regional(:investment, goods_r, r, (lambda = lambda, Sf = start.Sf)))
        push!(section_blocks[:prices], JCGEBlocks.exchange_rate_link_region(:prices, goods_r, r))
        push!(section_blocks[:external], JCGEBlocks.external_balance_var_price(:bop, goods_r, (Sf = start.Sf,)))
        push!(section_blocks[:trade], JCGEBlocks.armington(:armington, goods_r, (gamma = gamma, delta_m = delta_m, delta_d = delta_d, eta = eta, tau_m = tau_m)))
        push!(section_blocks[:trade], JCGEBlocks.transformation(:transformation, goods_r, (theta = theta, xie = xie, xid = xid, phi = phi, tau_z = tau_z)))
        push!(section_blocks[:markets], JCGEBlocks.composite_market_clearing(:market, goods_r, goods_r))
    end

    push!(section_blocks[:external], JCGEBlocks.international_market(:world, goods_sym, REGIONS, goods_map))
    alpha_reg = Dict{Symbol,Float64}()
    for r in REGIONS
        for g in goods_sym
            alpha_reg[goods_map[(g, r)]] = params[r].alpha[g]
        end
    end
    push!(section_blocks[:objective], JCGEBlocks.utility_regional(:utility, goods_by_region, (alpha = alpha_reg,)))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    fixed_vals = Dict{Symbol,Float64}()

    for r in REGIONS
        start = starts[r]
        goods_r = goods_by_region[r]
        for g in goods_sym
            gsym = goods_map[(g, r)]
            start_vals[JCGEBlocks.global_var(:Y, gsym)] = start.Y0[g]
            start_vals[JCGEBlocks.global_var(:Z, gsym)] = start.Z0[g]
            start_vals[JCGEBlocks.global_var(:Xp, gsym)] = start.Xp0[g]
            start_vals[JCGEBlocks.global_var(:Xg, gsym)] = start.Xg0[g]
            start_vals[JCGEBlocks.global_var(:Xv, gsym)] = start.Xv0[g]
            start_vals[JCGEBlocks.global_var(:E, gsym)] = start.E0[g]
            start_vals[JCGEBlocks.global_var(:M, gsym)] = start.M0[g]
            start_vals[JCGEBlocks.global_var(:Q, gsym)] = start.Q0[g]
            start_vals[JCGEBlocks.global_var(:D, gsym)] = start.D0[g]
            start_vals[JCGEBlocks.global_var(:py, gsym)] = start.py0[g]
            start_vals[JCGEBlocks.global_var(:pz, gsym)] = start.pz0[g]
            start_vals[JCGEBlocks.global_var(:pq, gsym)] = start.pq0[g]
            start_vals[JCGEBlocks.global_var(:pe, gsym)] = start.pe0[g]
            start_vals[JCGEBlocks.global_var(:pm, gsym)] = start.pm0[g]
            start_vals[JCGEBlocks.global_var(:pd, gsym)] = start.pd0[g]
            start_vals[JCGEBlocks.global_var(:pWe, gsym)] = start.pWe[g]
            start_vals[JCGEBlocks.global_var(:pWm, gsym)] = start.pWm[g]
            start_vals[JCGEBlocks.global_var(:Tz, gsym)] = start.Tz0[g]
            start_vals[JCGEBlocks.global_var(:Tm, gsym)] = start.Tm0[g]
        end
        for h in factors_sym
            hsym = region_sym(h, r)
            start_vals[JCGEBlocks.global_var(:pf, hsym)] = start.pf0[h]
            for g in goods_sym
                gsym = goods_map[(g, r)]
                start_vals[JCGEBlocks.global_var(:F, hsym, gsym)] = start.F0[h, g]
            end
        end
        for i in goods_sym, j in goods_sym
            isym = goods_map[(i, r)]
            jsym = goods_map[(j, r)]
            start_vals[JCGEBlocks.global_var(:X, isym, jsym)] = start.X0[i, j]
        end
        start_vals[JCGEBlocks.global_var(:epsilon, r)] = 1.0
        start_vals[JCGEBlocks.global_var(:Sp, r)] = start.Sp0
        start_vals[JCGEBlocks.global_var(:Sg, r)] = start.Sg0
        start_vals[JCGEBlocks.global_var(:Td, r)] = start.Td0
    end

    for (name, value) in start_vals
        lower_vals[name] = 1.0e-5
    end
    for r in REGIONS
        for g in goods_sym
            gsym = goods_map[(g, r)]
            lower_vals[JCGEBlocks.global_var(:Tz, gsym)] = 0.0
            lower_vals[JCGEBlocks.global_var(:Tm, gsym)] = 0.0
        end
    end

    for r in REGIONS
        lab_sym = region_sym(Symbol(numeraire_factor_label), r)
        fixed_vals[JCGEBlocks.global_var(:pf, lab_sym)] = 1.0
    end
    fixed_vals[JCGEBlocks.global_var(:epsilon, :USA)] = 1.0

    push!(section_blocks[:init], JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals, fixed = fixed_vals)))

    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    closure = JCGECore.ClosureSpec(Symbol(numeraire_factor_label))
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    return JCGECore.build_spec(
        "TwoCountryCGE",
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
Return the baseline RunSpec for TwoCountryCGE.
"""
baseline() = model()

"""
Solve the TwoCountryCGE model and return the run result.
"""
function solve(; optimizer=Ipopt.Optimizer, kwargs...)
    return JCGERuntime.run!(model(; kwargs...); optimizer=optimizer)
end

"""
Create a scenario placeholder for TwoCountryCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

"""
Return the data directory for TwoCountryCGE.
"""
datadir() = joinpath(@__DIR__, "data")

end # module
