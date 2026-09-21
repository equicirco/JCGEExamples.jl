"""
`JCGEExamples.GTAP7` provides an independent, data-driven implementation of
the core economic structure of the GTAP Standard 7 model.

The bundled data are a small open synthetic fixture. Full GTAP data are not
distributed by this package; see `schema.md` for the normalized input contract
for a user-supplied, licensed aggregation.
"""
module GTAP7

using CSV
using DataFrames
using Ipopt
using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using JCGECore: EAdd, EConst, EDiv, EEq, EIndex, EMul, ENeg, EParam, EPow, ESum, EVar

export baseline, datadir, load_data, model, scenario, solve

const POSITIVE_LOWER = 1.0e-6
const GTAPTradeRoute = typeof(JCGEBlocks.trade_route(:GTAP7_ROUTE, :GTAP7_PRODUCT, :ROW, :GTAP7_DESTINATION))

"""A normalized, model-ready GTAP-shaped dataset."""
struct GTAP7Data
    regions::Vector{Symbol}
    products::Vector{Symbol}
    factors::Vector{Symbol}
    sam_tables::Dict{Symbol,JCGECalibrate.SAMTable}
    routes::Vector{GTAPTradeRoute}
    route_value::Dict{Symbol,Float64}
    delivery_wedge::Dict{Symbol,Float64}
    armington_elasticity::Dict{Tuple{Symbol,Symbol},Float64}
    cet_elasticity::Dict{Tuple{Symbol,Symbol},Float64}
    substitution_parameter::Dict{Tuple{Symbol,Symbol},Float64}
    expansion_parameter::Dict{Tuple{Symbol,Symbol},Float64}
end

"""
GTAP's private-demand system is a constant-difference-of-elasticities (CDE)
system. This model-local block keeps the GTAP-specific formulation in the
example while its use with larger licensed datasets is established.
"""
struct CDEPrivateDemandBlock <: JCGECore.AbstractBlock
    name::Symbol
    regions::Vector{Symbol}
    goods_by_region::Dict{Symbol,Vector{Symbol}}
    factors_by_region::Dict{Symbol,Vector{Symbol}}
    activities_by_region::Dict{Symbol,Vector{Symbol}}
    params::NamedTuple
end

"""
Global saving--investment closure for the GTAP7 example. Aggregate regional
saving finances a global investment total, which is allocated across regions
and investment goods at calibrated expenditure shares.
"""
struct GlobalInvestmentAllocationBlock <: JCGECore.AbstractBlock
    name::Symbol
    regions::Vector{Symbol}
    goods_by_region::Dict{Symbol,Vector{Symbol}}
    params::NamedTuple
end

function _register_gtap7_equation!(ctx::JCGERuntime.KernelContext,
    block, tag::Symbol, idxs::Symbol...;
    info::String, expr=nothing, index_names=nothing,
    objective_expr=nothing, objective_sense=nothing)
    payload = (
        indices=idxs,
        index_names=index_names,
        params=block.params,
        info=info,
        expr=expr,
        constraint=nothing,
    )
    if objective_expr !== nothing
        payload = merge(payload, (objective_expr=objective_expr, objective_sense=objective_sense))
    end
    JCGERuntime.register_equation!(ctx; tag=tag, block=block.name, payload=payload)
    return nothing
end

function _cde_weight_expr(good, region)
    exponent = EMul([
        EParam(:cde_subpar, Any[good, region]),
        EParam(:cde_incpar, Any[good, region]),
    ])
    return EMul([
        EParam(:cde_a, Any[good, region]),
        EParam(:cde_subpar, Any[good, region]),
        EPow(EVar(:U_PRIV, Any[region]), exponent),
        EPow(
            EDiv(EVar(:pq, Any[good]), EVar(:P_PRIV, Any[region])),
            EParam(:cde_subpar, Any[good, region]),
        ),
    ])
end

function _cde_weight_expr(index::Symbol, region::Symbol, index_name::Symbol)
    component = EIndex(index_name)
    exponent = EMul([
        EParam(:cde_subpar, Any[component, region]),
        EParam(:cde_incpar, Any[component, region]),
    ])
    return EMul([
        EParam(:cde_a, Any[component, region]),
        EParam(:cde_subpar, Any[component, region]),
        EPow(EVar(:U_PRIV, Any[region]), exponent),
        EPow(
            EDiv(EVar(:pq, Any[component]), EVar(:P_PRIV, Any[region])),
            EParam(:cde_subpar, Any[component, region]),
        ),
    ])
end

function JCGECore.build!(block::CDEPrivateDemandBlock,
    ctx::JCGERuntime.KernelContext,
    spec::JCGECore.RunSpec)
    model = ctx.model
    lower = Float64(block.params.positive_lower)
    for region in block.regions
        goods = block.goods_by_region[region]
        factors = block.factors_by_region[region]
        activities = block.activities_by_region[region]
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:P_PRIV, region); lower=lower)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:U_PRIV, region); lower=lower)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Sp, region); lower=-Inf)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Td, region); lower=-Inf)
        for factor in factors, activity in activities
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:pf, factor); lower=lower)
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:F, factor, activity); lower=0.0)
        end
        for good in goods
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:pq, good); lower=lower)
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Xp, good); lower=0.0)
        end

        expenditure = EEq(
            EVar(:P_PRIV, Any[region]),
            EAdd([
                ESum(:factor, factors, ESum(:activity, activities, EMul([
                    EVar(:pf, Any[EIndex(:factor)]),
                    EVar(:F, Any[EIndex(:factor), EIndex(:activity)]),
                ]))),
                ENeg(EVar(:Sp, Any[region])),
                ENeg(EVar(:Td, Any[region])),
            ]),
        )
        _register_gtap7_equation!(ctx, block, :private_expenditure, region;
            info="private consumption expenditure equals regional disposable factor income",
            expr=expenditure, index_names=(:region,))

        utility = EEq(
            ESum(:component, goods, EMul([
                EParam(:cde_a, Any[EIndex(:component), region]),
                EPow(
                    EVar(:U_PRIV, Any[region]),
                    EMul([
                        EParam(:cde_subpar, Any[EIndex(:component), region]),
                        EParam(:cde_incpar, Any[EIndex(:component), region]),
                    ]),
                ),
                EPow(
                    EDiv(EVar(:pq, Any[EIndex(:component)]), EVar(:P_PRIV, Any[region])),
                    EParam(:cde_subpar, Any[EIndex(:component), region]),
                ),
            ])),
            EConst(1.0),
        )
        _register_gtap7_equation!(ctx, block, :cde_utility, region;
            info="GTAP CDE private-consumption utility identity",
            expr=utility, index_names=(:region,))

        denominator = ESum(:component, goods, _cde_weight_expr(:component, region, :component))
        for good in goods
            demand = EEq(
                EMul([
                    EVar(:pq, Any[EIndex(:good)]),
                    EVar(:Xp, Any[EIndex(:good)]),
                ]),
                EDiv(
                    EMul([
                        EVar(:P_PRIV, Any[region]),
                        _cde_weight_expr(EIndex(:good), region),
                    ]),
                    denominator,
                ),
            )
            _register_gtap7_equation!(ctx, block, :cde_private_demand, good, region;
                info="GTAP CDE demand allocates private expenditure across composite commodities",
                expr=demand, index_names=(:good, :region))
        end
    end
    _register_gtap7_equation!(ctx, block, :objective;
        info="maximize aggregate regional private-consumption utility",
        objective_expr=ESum(:region, block.regions, EVar(:U_PRIV, Any[EIndex(:region)])),
        objective_sense=:Max)
    return nothing
end

function JCGECore.build!(block::GlobalInvestmentAllocationBlock,
    ctx::JCGERuntime.KernelContext,
    spec::JCGECore.RunSpec)
    model = ctx.model
    lower = Float64(block.params.positive_lower)
    JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:GLOBAL_INV); lower=lower)

    for region in block.regions
        goods = block.goods_by_region[region]
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:INV, region); lower=lower)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Sp, region); lower=-Inf)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Sg, region); lower=-Inf)
        JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:FSAV, region); lower=-Inf)

        regional_investment = EEq(
            EVar(:INV, Any[region]),
            EMul([
                EParam(:regional_investment_share, Any[region]),
                EVar(:GLOBAL_INV, Any[]),
            ]),
        )
        _register_gtap7_equation!(ctx, block, :regional_investment_allocation, region;
            info="regional investment receives its calibrated share of global investment",
            expr=regional_investment, index_names=(:region,))

        for good in goods
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:Xv, good); lower=0.0)
            JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(:pq, good); lower=lower)
            investment_demand = EEq(
                EVar(:Xv, Any[EIndex(:good)]),
                EDiv(
                    EMul([
                        EParam(:investment_good_share, Any[EIndex(:good), region]),
                        EVar(:INV, Any[region]),
                    ]),
                    EVar(:pq, Any[EIndex(:good)]),
                ),
            )
            _register_gtap7_equation!(ctx, block, :regional_investment_demand, good, region;
                info="investment spending is allocated across regional composite goods at calibrated shares",
                expr=investment_demand, index_names=(:good, :region))
        end
    end

    global_balance = EEq(
        EVar(:GLOBAL_INV, Any[]),
        ESum(:region, block.regions, EAdd([
            EVar(:Sp, Any[EIndex(:region)]),
            EVar(:Sg, Any[EIndex(:region)]),
            EVar(:FSAV, Any[EIndex(:region)]),
        ])),
    )
    _register_gtap7_equation!(ctx, block, :global_saving_investment_balance;
        info="global investment equals the sum of regional private, government, and foreign saving",
        expr=global_balance)
    return nothing
end

"""Return the directory containing the open synthetic GTAP-shaped fixture."""
datadir() = joinpath(@__DIR__, "data", "synthetic")

function _set_members(path::AbstractString, name::Symbol)
    table = DataFrame(CSV.File(path))
    :set in Symbol.(names(table)) || error("sets.csv must contain a set column.")
    :item in Symbol.(names(table)) || error("sets.csv must contain an item column.")
    members = Symbol.(table[table.set .== String(name), :item])
    isempty(members) && error("sets.csv has no members for $(name).")
    return members
end

function _sam_table(data_dir::AbstractString, region::Symbol,
    products::Vector{Symbol}, factors::Vector{Symbol})
    path = joinpath(data_dir, "sam_$(region).csv")
    isfile(path) || error("Missing regional SAM: $(path)")
    return JCGECalibrate.load_sam_table(path;
        goods=String.(products),
        factors=String.(factors),
        numeraire_factor_label=String(first(factors)),
        indirectTax_label="IDT",
        tariff_label="TRF",
        households_label="HOH",
        government_label="GOV",
        investment_label="INV",
        restOfTheWorld_label="EXT",
    )
end

"""
    load_data(data_dir=datadir()) -> GTAP7Data

Load the normalized GTAP-shaped data contract. The function only accepts the
portable tables documented in `schema.md`; it does not read GTAP distribution
files or invoke third-party model implementations.
"""
function load_data(data_dir::AbstractString=datadir())
    sets_path = joinpath(data_dir, "sets.csv")
    isfile(sets_path) || error("Missing sets.csv in $(data_dir)")
    regions = _set_members(sets_path, :region)
    products = _set_members(sets_path, :product)
    factors = _set_members(sets_path, :factor)

    sam_tables = Dict(
        region => _sam_table(data_dir, region, products, factors)
        for region in regions
    )

    trade_path = joinpath(data_dir, "trade.csv")
    isfile(trade_path) || error("Missing trade.csv in $(data_dir)")
    trade = DataFrame(CSV.File(trade_path))
    required_trade_columns = (
        :id,
        :product,
        :origin,
        :destination,
        :value,
        :delivery_wedge,
    )
    all(col in Symbol.(names(trade)) for col in required_trade_columns) ||
        error("trade.csv must contain $(join(string.(required_trade_columns), ", ")).")

    routes = GTAPTradeRoute[]
    route_value = Dict{Symbol,Float64}()
    delivery_wedge = Dict{Symbol,Float64}()
    for row in eachrow(trade)
        id = Symbol(row.id)
        product = Symbol(row.product)
        origin = Symbol(row.origin)
        destination = Symbol(row.destination)
        product in products || error("Trade route $(id) uses unknown product $(product).")
        origin == :ROW || origin in regions || error("Trade route $(id) uses unknown origin $(origin).")
        destination == :ROW || destination in regions || error("Trade route $(id) uses unknown destination $(destination).")
        value = Float64(row.value)
        wedge = Float64(row.delivery_wedge)
        value > 0.0 || error("Trade route $(id) must have a strictly positive value.")
        wedge > 0.0 || error("Trade route $(id) must have a strictly positive delivery wedge.")
        haskey(route_value, id) && error("Duplicate trade-route identifier $(id).")
        push!(routes, JCGEBlocks.trade_route(id, product, origin, destination))
        route_value[id] = value
        delivery_wedge[id] = wedge
    end

    elasticity_path = joinpath(data_dir, "elasticities.csv")
    isfile(elasticity_path) || error("Missing elasticities.csv in $(data_dir)")
    elasticities = DataFrame(CSV.File(elasticity_path))
    required_elasticity_columns = (
        :product,
        :region,
        :armington_elasticity,
        :cet_elasticity,
        :subpar,
        :incpar,
    )
    all(col in Symbol.(names(elasticities)) for col in required_elasticity_columns) ||
        error("elasticities.csv must contain $(join(string.(required_elasticity_columns), ", ")).")
    armington_elasticity = Dict{Tuple{Symbol,Symbol},Float64}()
    cet_elasticity = Dict{Tuple{Symbol,Symbol},Float64}()
    substitution_parameter = Dict{Tuple{Symbol,Symbol},Float64}()
    expansion_parameter = Dict{Tuple{Symbol,Symbol},Float64}()
    for row in eachrow(elasticities)
        product = Symbol(row.product)
        region = Symbol(row.region)
        product in products || error("Elasticity data use unknown product $(product).")
        region in regions || error("Elasticity data use unknown region $(region).")
        armington = Float64(row.armington_elasticity)
        cet = Float64(row.cet_elasticity)
        subpar = Float64(row.subpar)
        incpar = Float64(row.incpar)
        armington > 0.0 || error("Armington elasticity for $(product), $(region) must be positive.")
        cet > 0.0 || error("CET elasticity for $(product), $(region) must be positive.")
        subpar > 0.0 || error("CDE SUBPAR for $(product), $(region) must be positive.")
        incpar > 0.0 || error("CDE INCPAR for $(product), $(region) must be positive.")
        armington_elasticity[(product, region)] = armington
        cet_elasticity[(product, region)] = cet
        substitution_parameter[(product, region)] = subpar
        expansion_parameter[(product, region)] = incpar
    end
    for product in products, region in regions
        haskey(armington_elasticity, (product, region)) ||
            error("Missing Armington elasticity for $(product), $(region).")
        haskey(cet_elasticity, (product, region)) ||
            error("Missing CET elasticity for $(product), $(region).")
        haskey(substitution_parameter, (product, region)) ||
            error("Missing CDE SUBPAR for $(product), $(region).")
        haskey(expansion_parameter, (product, region)) ||
            error("Missing CDE INCPAR for $(product), $(region).")
    end

    return GTAP7Data(
        regions,
        products,
        factors,
        sam_tables,
        routes,
        route_value,
        delivery_wedge,
        armington_elasticity,
        cet_elasticity,
        substitution_parameter,
        expansion_parameter,
    )
end

_regional_symbol(base::Symbol, region::Symbol) = Symbol(base, "_", region)

function _regional_mapping(items::Vector{Symbol}, regions::Vector{Symbol})
    return Dict((item, region) => _regional_symbol(item, region)
        for item in items for region in regions)
end

function _calibrate_ces(flows::Vector{Float64}, aggregate::Float64, exponent::Float64)
    aggregate > 0.0 || error("CES aggregate must be positive.")
    all(>(0.0), flows) || error("CES calibration requires strictly positive flows.")
    exponent < 1.0 || error("CES/CET exponent must be less than one.")
    if iszero(exponent)
        shares = flows ./ sum(flows)
        scale = aggregate / prod(flow ^ share for (flow, share) in zip(flows, shares))
        return shares, scale
    end
    denominator = sum(flow ^ (1.0 - exponent) for flow in flows)
    shares = [flow ^ (1.0 - exponent) / denominator for flow in flows]
    scale = (denominator / aggregate ^ (1.0 - exponent)) ^ (1.0 / exponent)
    return shares, scale
end

function _regional_calibration(sam_table::JCGECalibrate.SAMTable)
    start = JCGECalibrate.compute_starting_values(sam_table)
    goods = sam_table.goods
    factors = sam_table.factors

    b = Dict{Symbol,Float64}()
    beta = Dict{Tuple{Symbol,Symbol},Float64}()
    ay = Dict{Symbol,Float64}()
    ax = Dict{Tuple{Symbol,Symbol},Float64}()
    for good in goods
        value_added = start.Y0[good]
        value_added > 0.0 || error("Value added must be positive for $(good).")
        factor_values = [start.F0[factor, good] for factor in factors]
        all(>(0.0), factor_values) || error("All factors must be positive for $(good) in the initial GTAP7 fixture.")
        for factor in factors
            beta[(factor, good)] = start.F0[factor, good] / value_added
        end
        b[good] = value_added / prod(start.F0[factor, good] ^ beta[(factor, good)] for factor in factors)
        ay[good] = value_added / start.Z0[good]
        for input in goods
            ax[(input, good)] = start.X0[input, good] / start.Z0[good]
        end
    end

    factor_income = sum(start.FF.data)
    direct_tax = start.Td0
    disposable_income = factor_income - direct_tax
    disposable_income > 0.0 || error("Disposable household income must be positive.")
    private_saving = start.Sp0
    alpha = Dict(good => start.Xp0[good] / sum(start.Xp0.data) for good in goods)
    mu = Dict(good => start.Xg0[good] / sum(start.Xg0.data) for good in goods)
    ssp = private_saving / disposable_income
    public_revenue = direct_tax + sum(start.Tz0.data)
    ssg = iszero(public_revenue) ? 0.0 : start.Sg0 / public_revenue

    return (
        start=start,
        b=b,
        beta=beta,
        ay=ay,
        ax=ax,
        alpha=alpha,
        mu=mu,
        tau_d=direct_tax / factor_income,
        tau_z=Dict(good => start.Tz0[good] / start.Z0[good] for good in goods),
        ssp=ssp,
        ssg=ssg,
        investment=Dict(good => start.Xv0[good] for good in goods),
    )
end

function _route_groups(routes::Vector{GTAPTradeRoute})
    supply = Dict{Tuple{Symbol,Symbol},Vector{GTAPTradeRoute}}()
    demand = Dict{Tuple{Symbol,Symbol},Vector{GTAPTradeRoute}}()
    for route in routes
        route.origin == :ROW || push!(get!(supply, (route.product, route.origin), GTAPTradeRoute[]), route)
        route.destination == :ROW || push!(get!(demand, (route.product, route.destination), GTAPTradeRoute[]), route)
    end
    return supply, demand
end

function _trade_parameters(data::GTAP7Data, calibrations, good_map)
    supply, demand = _route_groups(data.routes)
    armington_scale = Dict{Tuple{Symbol,Symbol},Float64}()
    armington_share = Dict{Symbol,Float64}()
    armington_exponent = Dict{Tuple{Symbol,Symbol},Float64}()
    cet_scale = Dict{Tuple{Symbol,Symbol},Float64}()
    cet_share = Dict{Symbol,Float64}()
    cet_exponent = Dict{Tuple{Symbol,Symbol},Float64}()
    world_price = Dict{Symbol,Float64}()

    for product in data.products, region in data.regions
        haskey(supply, (product, region)) || error("No supply routes for $(product), $(region).")
        haskey(demand, (product, region)) || error("No demand routes for $(product), $(region).")
        good = good_map[(product, region)]
        cal = calibrations[region]

        armington_rho = JCGECalibrate.rho_from_sigma(data.armington_elasticity[(product, region)])
        demand_routes = demand[(product, region)]
        demand_flows = [data.route_value[route.id] for route in demand_routes]
        armington_shares, armington_scale_value = _calibrate_ces(demand_flows, cal.start.Q0[product], armington_rho)
        armington_scale[(product, region)] = armington_scale_value
        armington_exponent[(product, region)] = armington_rho
        for (route, share) in zip(demand_routes, armington_shares)
            armington_share[route.id] = share
        end

        cet_rho = JCGECalibrate.rho_from_sigma(data.cet_elasticity[(product, region)])
        supply_routes = supply[(product, region)]
        supply_flows = [data.route_value[route.id] for route in supply_routes]
        cet_shares, cet_scale_value = _calibrate_ces(supply_flows, cal.start.Z0[product], cet_rho)
        cet_scale[(product, region)] = cet_scale_value
        cet_exponent[(product, region)] = cet_rho
        for (route, share) in zip(supply_routes, cet_shares)
            cet_share[route.id] = share
        end
    end

    for route in data.routes
        if route.origin == :ROW || route.destination == :ROW
            world_price[route.id] = 1.0
        end
    end

    return (
        armington_scale=armington_scale,
        armington_share=armington_share,
        armington_exponent=armington_exponent,
        cet_scale=cet_scale,
        cet_share=cet_share,
        cet_exponent=cet_exponent,
        world_price=world_price,
    )
end

function _cde_parameters(data::GTAP7Data, calibrations, good_map;
    preference_multiplier::Dict{Tuple{Symbol,Symbol},Float64}=Dict{Tuple{Symbol,Symbol},Float64}())
    cde_a = Dict{Tuple{Symbol,Symbol},Float64}()
    cde_subpar = Dict{Tuple{Symbol,Symbol},Float64}()
    cde_incpar = Dict{Tuple{Symbol,Symbol},Float64}()
    cde_share = Dict{Tuple{Symbol,Symbol},Float64}()
    for region in data.regions
        cal = calibrations[region]
        private_expenditure = sum(cal.start.Xp0.data)
        private_expenditure > 0.0 || error("Private expenditure must be positive in $(region).")
        raw_shares = Dict(product => cal.alpha[product] *
            get(preference_multiplier, (product, region), 1.0) for product in data.products)
        total_share = sum(values(raw_shares))
        total_share > 0.0 || error("Private-demand preference weights must sum to a positive value in $(region).")
        shares = Dict(product => raw_shares[product] / total_share for product in data.products)
        all(>(0.0), values(shares)) || error("CDE calibration requires positive private-expenditure shares in $(region).")
        normalization = sum(shares[product] / data.substitution_parameter[(product, region)] for product in data.products)
        normalization > 0.0 || error("CDE calibration normalization must be positive in $(region).")
        for product in data.products
            good = good_map[(product, region)]
            subpar = data.substitution_parameter[(product, region)]
            cde_a[(good, region)] = shares[product] * private_expenditure ^ subpar / (subpar * normalization)
            cde_subpar[(good, region)] = subpar
            cde_incpar[(good, region)] = data.expansion_parameter[(product, region)]
            cde_share[(good, region)] = shares[product]
        end
    end
    return (cde_a=cde_a, cde_subpar=cde_subpar, cde_incpar=cde_incpar, cde_share=cde_share)
end

function _validate_cde_calibration(data::GTAP7Data, calibrations, cde_parameters, good_map)
    for region in data.regions
        cal = calibrations[region]
        private_expenditure = sum(cal.start.Xp0.data)
        weights = Dict{Symbol,Float64}()
        cde_identity = 0.0
        for product in data.products
            good = good_map[(product, region)]
            subpar = cde_parameters.cde_subpar[(good, region)]
            cde_identity += cde_parameters.cde_a[(good, region)] *
                (1.0 / private_expenditure) ^ subpar
            weights[product] = cde_parameters.cde_a[(good, region)] * subpar *
                (1.0 / private_expenditure) ^ subpar
        end
        isapprox(cde_identity, 1.0; atol=1.0e-10, rtol=1.0e-10) ||
            error("CDE utility calibration does not reproduce the base-year identity in $(region).")
        weight_total = sum(values(weights))
        for product in data.products
            good = good_map[(product, region)]
            observed_share = cde_parameters.cde_share[(good, region)]
            isapprox(weights[product] / weight_total, observed_share; atol=1.0e-10, rtol=1.0e-10) ||
                error("CDE calibration does not reproduce the private-expenditure share for $(product), $(region).")
        end
    end
    return nothing
end

function _validate_flow_totals(data::GTAP7Data, calibrations)
    supply, demand = _route_groups(data.routes)
    for product in data.products, region in data.regions
        output = calibrations[region].start.Z0[product]
        composite = calibrations[region].start.Q0[product]
        supply_total = sum(data.route_value[route.id] for route in supply[(product, region)])
        demand_total = sum(data.route_value[route.id] for route in demand[(product, region)])
        isapprox(output, supply_total; atol=1.0e-8, rtol=1.0e-8) ||
            error("Trade supply routes for $(product), $(region) sum to $(supply_total), not SAM output $(output).")
        isapprox(composite, demand_total; atol=1.0e-8, rtol=1.0e-8) ||
            error("Trade demand routes for $(product), $(region) sum to $(demand_total), not SAM composite demand $(composite).")
    end
    return nothing
end

"""
    model(; data_dir=datadir(), scenario_name=:baseline, ...) -> RunSpec

Build the equality/NLP formulation of the independently implemented GTAP
Standard 7 core. It covers regional production and demand, GTAP's CDE
private-demand system, bilateral source differentiation, destination
transformation, regional external accounts, and global saving--investment
allocation.

The declared counterfactuals are regional factor-endowment and productivity
changes; regional output- and direct-tax changes; regional private- and
government-demand preference changes; regional private-saving changes; and a
delivery-cost change on one declared trade route. A delivery-cost shock changes
the calibrated delivery wedge only: tariff and transport-margin accounts are
not represented in this core example.
"""
function model(; data_dir::AbstractString=datadir(), scenario_name::Symbol=:baseline,
    endowment_region::Union{Nothing,Symbol}=nothing,
    endowment_factor::Union{Nothing,Symbol}=nothing,
    endowment_multiplier::Float64=1.10,
    productivity_region::Union{Nothing,Symbol}=nothing,
    productivity_product::Union{Nothing,Symbol}=nothing,
    productivity_multiplier::Float64=1.10,
    output_tax_region::Union{Nothing,Symbol}=nothing,
    output_tax_product::Union{Nothing,Symbol}=nothing,
    output_tax_change::Float64=0.05,
    direct_tax_region::Union{Nothing,Symbol}=nothing,
    direct_tax_change::Float64=0.05,
    private_preference_region::Union{Nothing,Symbol}=nothing,
    private_preference_product::Union{Nothing,Symbol}=nothing,
    private_preference_multiplier::Float64=1.10,
    government_preference_region::Union{Nothing,Symbol}=nothing,
    government_preference_product::Union{Nothing,Symbol}=nothing,
    government_preference_multiplier::Float64=1.10,
    private_saving_region::Union{Nothing,Symbol}=nothing,
    private_saving_multiplier::Float64=1.10,
    trade_route::Union{Nothing,Symbol}=nothing,
    trade_cost_multiplier::Float64=1.10)
    data = load_data(data_dir)
    calibrations = Dict(region => _regional_calibration(data.sam_tables[region]) for region in data.regions)
    _validate_flow_totals(data, calibrations)
    scenario_name in (
        :baseline,
        :factor_endowment,
        :productivity,
        :output_tax,
        :direct_tax,
        :private_preference,
        :government_preference,
        :private_saving,
        :trade_cost,
    ) || error("Unsupported GTAP7 scenario $(scenario_name).")

    require_region(region, description) = region in data.regions ||
        error("A $(description) scenario requires a modelled region.")
    require_product(product, description) = product in data.products ||
        error("A $(description) scenario requires a modelled product.")

    if scenario_name == :factor_endowment
        require_region(endowment_region, "factor-endowment")
        endowment_factor in data.factors ||
            error("A factor-endowment scenario requires a modelled endowment_factor.")
        endowment_multiplier > 0.0 ||
            error("endowment_multiplier must be strictly positive.")
    elseif scenario_name == :productivity
        require_region(productivity_region, "productivity")
        require_product(productivity_product, "productivity")
        productivity_multiplier > 0.0 ||
            error("productivity_multiplier must be strictly positive.")
    elseif scenario_name == :output_tax
        require_region(output_tax_region, "output-tax")
        require_product(output_tax_product, "output-tax")
        calibrations[output_tax_region].tau_z[output_tax_product] + output_tax_change > -1.0 ||
            error("The output-tax rate after output_tax_change must be greater than -1.")
    elseif scenario_name == :direct_tax
        require_region(direct_tax_region, "direct-tax")
        calibrations[direct_tax_region].tau_d + direct_tax_change >= 0.0 ||
            error("The direct-tax rate after direct_tax_change must be non-negative.")
    elseif scenario_name == :private_preference
        require_region(private_preference_region, "private-preference")
        require_product(private_preference_product, "private-preference")
        private_preference_multiplier > 0.0 ||
            error("private_preference_multiplier must be strictly positive.")
    elseif scenario_name == :government_preference
        require_region(government_preference_region, "government-preference")
        require_product(government_preference_product, "government-preference")
        government_preference_multiplier > 0.0 ||
            error("government_preference_multiplier must be strictly positive.")
    elseif scenario_name == :private_saving
        require_region(private_saving_region, "private-saving")
        private_saving_multiplier >= 0.0 ||
            error("private_saving_multiplier must be non-negative.")
        calibrations[private_saving_region].ssp * private_saving_multiplier < 1.0 ||
            error("The private-saving rate after private_saving_multiplier must remain below one.")
    elseif scenario_name == :trade_cost
        trade_route in keys(data.delivery_wedge) ||
            error("A trade-cost scenario requires a declared trade_route.")
        trade_cost_multiplier > 0.0 ||
            error("trade_cost_multiplier must be strictly positive.")
    end

    good_map = _regional_mapping(data.products, data.regions)
    factor_map = _regional_mapping(data.factors, data.regions)
    goods_by_region = Dict(region => [good_map[(product, region)] for product in data.products] for region in data.regions)
    activities_by_region = Dict(region => copy(goods_by_region[region]) for region in data.regions)
    factors_by_region = Dict(region => [factor_map[(factor, region)] for factor in data.factors] for region in data.regions)

    commodities = reduce(vcat, values(goods_by_region))
    activities = reduce(vcat, values(activities_by_region))
    factors = reduce(vcat, values(factors_by_region))
    institutions = Symbol[]
    for region in data.regions
        append!(institutions, (_regional_symbol(:HOUSEHOLD, region), _regional_symbol(:GOVERNMENT, region), _regional_symbol(:INVESTMENT, region), _regional_symbol(:EXTERNAL, region)))
    end
    sets = JCGECore.Sets(commodities, activities, factors, institutions)
    mappings = JCGECore.Mappings(Dict(activity => activity for activity in activities))

    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(section => Any[] for section in allowed_sections)

    alpha = Dict{Tuple{Symbol,Symbol},Float64}()
    mu = Dict{Tuple{Symbol,Symbol},Float64}()
    tau_d = Dict{Symbol,Float64}()
    tau_z = Dict{Symbol,Float64}()
    ssp = Dict{Symbol,Float64}()
    ssg = Dict{Symbol,Float64}()
    investment_good_share = Dict{Tuple{Symbol,Symbol},Float64}()
    regional_investment = Dict{Symbol,Float64}()
    start_vals = Dict{Symbol,Float64}()
    inventory_change = Dict(good => 0.0 for good in commodities)
    output_tax_by_origin = Dict{Tuple{Symbol,Symbol},Float64}()
    private_preference_multipliers = Dict(
        (product, region) => 1.0 for product in data.products for region in data.regions)
    government_preference_multipliers = Dict(
        (product, region) => 1.0 for product in data.products for region in data.regions)
    delivery_wedge = copy(data.delivery_wedge)

    if scenario_name == :private_preference
        private_preference_multipliers[(private_preference_product, private_preference_region)] =
            private_preference_multiplier
    elseif scenario_name == :government_preference
        government_preference_multipliers[(government_preference_product, government_preference_region)] =
            government_preference_multiplier
    elseif scenario_name == :trade_cost
        delivery_wedge[trade_route] *= trade_cost_multiplier
    end

    for region in data.regions
        cal = calibrations[region]
        goods = goods_by_region[region]
        regional_factors = factors_by_region[region]

        b = Dict{Symbol,Float64}()
        beta = Dict{Tuple{Symbol,Symbol},Float64}()
        ay = Dict{Symbol,Float64}()
        ax = Dict{Tuple{Symbol,Symbol},Float64}()
        factor_endowment = Dict{Symbol,Float64}()
        investment = Dict{Symbol,Float64}()
        government_weight_total = sum(cal.mu[product] *
            government_preference_multipliers[(product, region)] for product in data.products)
        government_weight_total > 0.0 ||
            error("Government-demand preference weights must sum to a positive value in $(region).")
        for product in data.products
            good = good_map[(product, region)]
            productivity = scenario_name == :productivity &&
                region == productivity_region && product == productivity_product ?
                productivity_multiplier : 1.0
            b[good] = productivity * cal.b[product]
            ay[good] = cal.ay[product]
            alpha[(good, region)] = cal.alpha[product]
            mu[(good, region)] = cal.mu[product] *
                government_preference_multipliers[(product, region)] / government_weight_total
            output_tax_change_here = scenario_name == :output_tax &&
                region == output_tax_region && product == output_tax_product ?
                output_tax_change : 0.0
            tau_z[good] = cal.tau_z[product] + output_tax_change_here
            output_tax_by_origin[(product, region)] = tau_z[good]
            investment[good] = cal.investment[product]
            for factor in data.factors
                factor_symbol = factor_map[(factor, region)]
                beta[(factor_symbol, good)] = cal.beta[(factor, product)]
                start_vals[JCGEBlocks.global_var(:F, factor_symbol, good)] = cal.start.F0[factor, product]
            end
            for input in data.products
                input_good = good_map[(input, region)]
                ax[(input_good, good)] = cal.ax[(input, product)]
                start_vals[JCGEBlocks.global_var(:X, input_good, good)] = cal.start.X0[input, product]
            end
            start_vals[JCGEBlocks.global_var(:Y, good)] = cal.start.Y0[product]
            start_vals[JCGEBlocks.global_var(:Z, good)] = cal.start.Z0[product]
            start_vals[JCGEBlocks.global_var(:Xp, good)] = cal.start.Xp0[product]
            start_vals[JCGEBlocks.global_var(:Xg, good)] = cal.start.Xg0[product]
            start_vals[JCGEBlocks.global_var(:Xv, good)] = cal.start.Xv0[product]
            start_vals[JCGEBlocks.global_var(:Tz, good)] = cal.start.Tz0[product]
            start_vals[JCGEBlocks.global_var(:py, good)] = 1.0
            start_vals[JCGEBlocks.global_var(:pz, good)] = 1.0
            start_vals[JCGEBlocks.global_var(:pq, good)] = 1.0
        end
        for factor in data.factors
            factor_symbol = factor_map[(factor, region)]
            multiplier = scenario_name == :factor_endowment &&
                region == endowment_region && factor == endowment_factor ?
                endowment_multiplier : 1.0
            factor_endowment[factor_symbol] = multiplier * cal.start.FF[factor]
            start_vals[JCGEBlocks.global_var(:pf, factor_symbol)] = 1.0
        end
        tau_d[region] = cal.tau_d + (scenario_name == :direct_tax &&
            region == direct_tax_region ? direct_tax_change : 0.0)
        ssp[region] = cal.ssp * (scenario_name == :private_saving &&
            region == private_saving_region ? private_saving_multiplier : 1.0)
        regional_investment[region] = sum(values(investment))
        for good in goods
            investment_good_share[(good, region)] = investment[good] / regional_investment[region]
        end
        public_revenue = cal.start.Td0 + sum(cal.start.Tz0.data)
        ssg[region] = iszero(public_revenue) ? 0.0 : cal.start.Sg0 / public_revenue
        start_vals[JCGEBlocks.global_var(:Td, region)] = cal.start.Td0
        start_vals[JCGEBlocks.global_var(:Sp, region)] = cal.start.Sp0
        start_vals[JCGEBlocks.global_var(:Sg, region)] = ssg[region] * public_revenue
        start_vals[JCGEBlocks.global_var(:FSAV, region)] = 0.0
        start_vals[JCGEBlocks.global_var(:INV, region)] = sum(values(investment))
        start_vals[JCGEBlocks.global_var(:P_PRIV, region)] = sum(cal.start.Xp0.data)
        start_vals[JCGEBlocks.global_var(:U_PRIV, region)] = 1.0

        production_parameters = (b=b, beta=beta, ay=ay, ax=ax, positive_lower=POSITIVE_LOWER)
        push!(section_blocks[:production], JCGEBlocks.production(Symbol(:production_, region), goods, regional_factors, goods; form=:cd_leontief, params=production_parameters))
        push!(section_blocks[:factors], JCGEBlocks.factor_market_clearing(Symbol(:factor_market_, region), goods, regional_factors; params=(FF=factor_endowment,)))
    end

    push!(section_blocks[:government], JCGEBlocks.regional_government_demand(
        :government,
        data.regions,
        goods_by_region,
        factors_by_region,
        activities_by_region,
        params=(tau_d=tau_d, tau_z=tau_z, mu=mu, ssg=ssg,
            positive_lower=POSITIVE_LOWER),
    ))
    push!(section_blocks[:savings], JCGEBlocks.regional_private_saving_income(
        :private_saving,
        data.regions,
        factors_by_region,
        activities_by_region;
        params=(ssp=ssp, positive_lower=POSITIVE_LOWER),
    ))
    total_investment = sum(values(regional_investment))
    regional_investment_share = Dict(region => regional_investment[region] / total_investment
        for region in data.regions)
    start_vals[JCGEBlocks.global_var(:GLOBAL_INV)] = total_investment
    push!(section_blocks[:savings], GlobalInvestmentAllocationBlock(
        :global_investment,
        data.regions,
        goods_by_region,
        (regional_investment_share=regional_investment_share,
            investment_good_share=investment_good_share,
            positive_lower=POSITIVE_LOWER),
    ))
    cde_parameters = _cde_parameters(data, calibrations, good_map;
        preference_multiplier=private_preference_multipliers)
    _validate_cde_calibration(data, calibrations, cde_parameters, good_map)
    push!(section_blocks[:households], CDEPrivateDemandBlock(
        :cde_households,
        data.regions,
        goods_by_region,
        factors_by_region,
        activities_by_region,
        (; cde_parameters..., positive_lower=POSITIVE_LOWER),
    ))

    trade_parameters = _trade_parameters(data, calibrations, good_map)
    push!(section_blocks[:trade], JCGEBlocks.multiregion_trade(
        :bilateral_trade,
        data.regions,
        data.routes,
        good_map;
        params=(
            armington_scale=trade_parameters.armington_scale,
            armington_share=trade_parameters.armington_share,
            armington_exponent=trade_parameters.armington_exponent,
            cet_scale=trade_parameters.cet_scale,
            cet_share=trade_parameters.cet_share,
            cet_exponent=trade_parameters.cet_exponent,
            output_tax=output_tax_by_origin,
            delivery_wedge=delivery_wedge,
            world_price=trade_parameters.world_price,
            inventory_change=inventory_change,
            positive_lower=POSITIVE_LOWER,
        ),
    ))
    push!(section_blocks[:external], JCGEBlocks.regional_external_account(:external, data.regions, data.routes))
    push!(section_blocks[:markets], JCGEBlocks.regional_composite_market_clearing(
        :composite_market,
        data.regions,
        goods_by_region,
        activities_by_region;
        params=(inventory_change=inventory_change, positive_lower=POSITIVE_LOWER),
    ))

    for route in data.routes
        start_vals[JCGEBlocks.global_var(:T, route.id)] = data.route_value[route.id]
        start_vals[JCGEBlocks.global_var(:pS, route.id)] = 1.0
        start_vals[JCGEBlocks.global_var(:pD, route.id)] = delivery_wedge[route.id]
    end
    numeraire_product = first(data.products)
    numeraire_region = first(data.regions)
    first_good = good_map[(numeraire_product, numeraire_region)]
    push!(section_blocks[:closure], JCGEBlocks.numeraire(:numeraire, :commodity, first_good, 1.0))
    push!(section_blocks[:init], JCGEBlocks.initial_values(:initial_values, (start=start_vals,)))

    sections = [JCGECore.section(section, section_blocks[section]) for section in allowed_sections]
    condition_roles = Dict(
        JCGECore.ClosureCondition(:composite_market, :regional_composite_market, first_good, numeraire_region) => :accounting_check,
    )
    return JCGECore.build_spec(
        "GTAP7",
        sets,
        mappings,
        sections;
        closure=JCGECore.ClosureSpec(first_good, :commodity; condition_roles=condition_roles),
        scenario=JCGECore.ScenarioSpec(scenario_name, Dict(
            :endowment_region => endowment_region,
            :endowment_factor => endowment_factor,
            :endowment_multiplier => endowment_multiplier,
            :productivity_region => productivity_region,
            :productivity_product => productivity_product,
            :productivity_multiplier => productivity_multiplier,
            :output_tax_region => output_tax_region,
            :output_tax_product => output_tax_product,
            :output_tax_change => output_tax_change,
            :direct_tax_region => direct_tax_region,
            :direct_tax_change => direct_tax_change,
            :private_preference_region => private_preference_region,
            :private_preference_product => private_preference_product,
            :private_preference_multiplier => private_preference_multiplier,
            :government_preference_region => government_preference_region,
            :government_preference_product => government_preference_product,
            :government_preference_multiplier => government_preference_multiplier,
            :private_saving_region => private_saving_region,
            :private_saving_multiplier => private_saving_multiplier,
            :trade_route => trade_route,
            :trade_cost_multiplier => trade_cost_multiplier,
        )),
        required_sections=allowed_sections,
        allowed_sections=allowed_sections,
        required_nonempty=[:production, :households, :trade, :markets],
    )
end

"""Return the GTAP7 baseline `RunSpec`."""
baseline(; kwargs...) = model(; kwargs...)

"""Return a declared GTAP7 baseline or supported counterfactual scenario."""
scenario(name::Symbol=:baseline; kwargs...) = model(; scenario_name=name, kwargs...)

"""Solve the GTAP7 equality/NLP formulation."""
solve(; optimizer=Ipopt.Optimizer, kwargs...) = JCGERuntime.run!(model(; kwargs...); optimizer=optimizer)

end # module
