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
using JuMP
using JCGEBlocks
using JCGECalibrate
using JCGECore
using JCGERuntime
using JCGECore: EAdd, EConst, EDiv, EEq, EIndex, EMul, ENeg, EParam, EPow, ESum, EVar

export baseline, datadir, load_data, load_full_data, full_model, model, scenario, solve

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

const GTAP7ParameterTable = Dict{Tuple{Vararg{Symbol}},Float64}

"""
`GTAP7FullData` holds the complete, portable parameter export required by the
GTAP Standard 7 9x10 implementation.

Products and activities remain distinct. In particular, `output_pairs` is
derived from the regional `MAKB` make matrix and may contain more than one
product for an activity. The source files are normalized tables, not GTAP HAR
or GDX distribution files.
"""
struct GTAP7FullData
    regions::Vector{Symbol}
    products::Vector{Symbol}
    activities::Vector{Symbol}
    factors::Vector{Symbol}
    mobile_factors::Vector{Symbol}
    sector_specific_factors::Vector{Symbol}
    modes::Vector{Symbol}
    margins::Vector{Symbol}
    output_pairs::Vector{Tuple{Symbol,Symbol}}
    benchmark::Dict{Symbol,GTAP7ParameterTable}
    elasticities::Dict{Symbol,GTAP7ParameterTable}
    taxes::Dict{Symbol,GTAP7ParameterTable}
    shares::Dict{Symbol,GTAP7ParameterTable}
    calibrated::Dict{Symbol,GTAP7ParameterTable}
    shifts::Dict{Symbol,GTAP7ParameterTable}
    derived::Dict{Symbol,GTAP7ParameterTable}
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

"""
The GTAP Standard 7 domestic/export allocation for each regional commodity.

This is a model-local block because it preserves the GTAP 9x10 table names and
closure conventions while the generic block library remains source-neutral.
It is the first equation block used by the full-data implementation.
"""
struct GTAP7TradeCETBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
end

function _full_table_value(tables::Dict{Symbol,GTAP7ParameterTable},
    table::Symbol, key::Tuple{Vararg{Symbol}}; default::Float64=0.0)
    values = get(tables, table, nothing)
    values === nothing && error("GTAP full data are missing parameter table $(table).")
    return get(values, key, default)
end

function _full_variable!(ctx::JCGERuntime.KernelContext, model, name::Symbol,
    indices::Symbol...; lower::Float64=0.0, start::Union{Nothing,Float64}=nothing)
    return JCGEBlocks.ensure_var!(ctx, model, JCGEBlocks.global_var(name, indices...);
        lower=lower, start=start)
end

function _register_full_equation!(ctx::JCGERuntime.KernelContext, block,
    tag::Symbol, indices::Symbol...; info::String, expr)
    JCGERuntime.register_equation!(ctx; tag=tag, block=block.name, payload=(
        indices=indices,
        index_names=nothing,
        params=nothing,
        info=info,
        expr=expr,
        constraint=nothing,
    ))
    return nothing
end

function JCGECore.build!(block::GTAP7TradeCETBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    xet_flag = data.derived[:xet_flag]
    for region in data.regions, product in data.products
        product_key = (region, product)
        output_start = sum(_full_make_start(data, region, activity, product)
            for activity in data.activities)
        domestic_start = sum(_full_table_value(data.benchmark, :makb,
            (region, activity, product)) for activity in data.activities)
        export_start = sum(_full_table_value(data.benchmark, :vxsb,
            (region, product, destination)) for destination in data.regions)
        _full_variable!(ctx, model, :xs, region, product;
            lower=0.0, start=max(output_start, 1.0e-8))
        _full_variable!(ctx, model, :xds, region, product;
            lower=0.0, start=max(domestic_start, 1.0e-8))
        _full_variable!(ctx, model, :xet, region, product;
            lower=-Inf, start=export_start)
        _full_variable!(ctx, model, :ps, region, product; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pd, region, product; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pet, region, product; lower=1.0e-3, start=1.0)

        export_active = _full_table_value(data.derived, :xet_flag, product_key) > 0.0
        gd_share = _full_table_value(data.derived, :gd_share, product_key)
        ge_share = _full_table_value(data.derived, :ge_share, product_key)
        omega = _full_table_value(data.elasticities, :omegax, product_key; default=Inf)

        xds_expr = if gd_share <= 0.0
            EEq(EVar(:xds, Any[region, product]), EConst(0.0))
        elseif isinf(omega)
            EEq(EVar(:pd, Any[region, product]), EVar(:ps, Any[region, product]))
        else
            EEq(
                EVar(:xds, Any[region, product]),
                EMul([
                    EConst(gd_share),
                    EVar(:xs, Any[region, product]),
                    EPow(
                        EDiv(EVar(:pd, Any[region, product]), EVar(:ps, Any[region, product])),
                        EConst(omega),
                    ),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :domestic_supply, region, product;
            info="GTAP domestic allocation from regional output", expr=xds_expr)

        if export_active
            xet_expr = if ge_share <= 0.0
                EEq(EVar(:xet, Any[region, product]), EConst(0.0))
            elseif isinf(omega)
                EEq(EVar(:pet, Any[region, product]), EVar(:ps, Any[region, product]))
            else
                EEq(
                    EVar(:xet, Any[region, product]),
                    EMul([
                        EConst(ge_share),
                        EVar(:xs, Any[region, product]),
                        EPow(
                            EDiv(EVar(:pet, Any[region, product]), EVar(:ps, Any[region, product])),
                            EConst(omega),
                        ),
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :export_supply, region, product;
                info="GTAP export allocation from regional output", expr=xet_expr)
        end

        supply_expr = if isinf(omega)
            EEq(
                EVar(:xs, Any[region, product]),
                EAdd([
                    EVar(:xds, Any[region, product]),
                    EVar(:xet, Any[region, product]),
                ]),
            )
        else
            exponent = 1.0 + omega
            EEq(
                EPow(EVar(:ps, Any[region, product]), EConst(exponent)),
                EAdd([
                    EMul([EConst(gd_share), EPow(EVar(:pd, Any[region, product]), EConst(exponent))]),
                    EMul([EConst(ge_share), EPow(EVar(:pet, Any[region, product]), EConst(exponent))]),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :supply_transformation, region, product;
            info="GTAP CET transformation between domestic and export supply", expr=supply_expr)
    end
    return nothing
end

"""GTAP Standard 7 nested production and multi-output supply block."""
struct GTAP7ProductionSupplyBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
end

_full_sum(terms::Vector{<:JCGECore.EquationExpr}) =
    isempty(terms) ? EConst(0.0) : EAdd(terms)

_full_product(terms::Vector{<:JCGECore.EquationExpr}) =
    isempty(terms) ? EConst(1.0) : foldl((left, right) -> EMul([left, right]), terms)

function _full_outputs_by_activity(data::GTAP7FullData)
    outputs = Dict(activity => Symbol[] for activity in data.activities)
    for (activity, product) in data.output_pairs
        push!(outputs[activity], product)
    end
    return outputs
end

function _full_activities_by_product(data::GTAP7FullData)
    activities = Dict(product => Symbol[] for product in data.products)
    for (activity, product) in data.output_pairs
        push!(activities[product], activity)
    end
    return activities
end

function _full_vom_start(data::GTAP7FullData, region::Symbol, activity::Symbol)
    intermediate = sum(
        _full_table_value(data.benchmark, :vdfp, (region, product, activity)) +
        _full_table_value(data.benchmark, :vmfp, (region, product, activity))
        for product in data.products)
    value_added = sum(_full_table_value(data.benchmark, :evfb, (region, factor, activity);
        default=_full_table_value(data.benchmark, :vfm, (region, factor, activity)))
        for factor in data.factors)
    total = intermediate + value_added
    return total > 0.0 ? total : _full_table_value(data.benchmark, :vom, (region, activity))
end

function _full_make_start(data::GTAP7FullData, region::Symbol,
    activity::Symbol, product::Symbol)
    (activity, product) in data.output_pairs || return 0.0
    share = _full_table_value(data.derived, :gx_param, (region, activity, product))
    share > 0.0 || return 0.0
    omega = _full_table_value(data.elasticities, :omegas, (region, activity); default=Inf)
    make_value = _full_table_value(data.benchmark, :makb, (region, activity, product))
    isinf(omega) && return max(make_value, 1.0e-8)
    production_tax = _full_table_value(data.derived, :prdtx_rai, (region, activity, product))
    producer_price = max(1.0 / max(1.0 + production_tax, 1.0e-12), 1.0e-8)
    return max(share * _full_vom_start(data, region, activity) * producer_price ^ omega, 1.0e-8)
end

function JCGECore.build!(block::GTAP7ProductionSupplyBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    outputs_by_activity = _full_outputs_by_activity(data)
    activities_by_product = _full_activities_by_product(data)

    for region in data.regions, activity in data.activities
        region_activity = (region, activity)
        xscale = _full_table_value(data.derived, :xscale, region_activity; default=1.0)
        xscale > 0.0 || error("GTAP xscale must be positive for $(region_activity).")
        value_added = _full_table_value(data.derived, :va_bench, region_activity; default=1.0e-8)
        intermediate = _full_table_value(data.derived, :nd_bench, region_activity; default=1.0e-8)
        activity_output = _full_vom_start(data, region, activity)
        _full_variable!(ctx, model, :xp, region, activity;
            lower=0.0, start=max(activity_output, 1.0e-8))
        _full_variable!(ctx, model, :px, region, activity; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pp, region, activity; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :va, region, activity;
            lower=0.0, start=max(value_added, 1.0e-8))
        _full_variable!(ctx, model, :nd, region, activity;
            lower=0.0, start=max(intermediate, 1.0e-8))
        _full_variable!(ctx, model, :pva, region, activity; lower=1.0e-8,
            start=max(_full_table_value(data.calibrated, :pva_bench, region_activity; default=1.0), 1.0e-8))
        _full_variable!(ctx, model, :pnd, region, activity; lower=1.0e-8,
            start=max(_full_table_value(data.calibrated, :pnd_bench, region_activity; default=1.0), 1.0e-8))

        for factor in data.factors
            _full_variable!(ctx, model, :pfa, region, factor, activity;
                lower=1.0e-8, start=1.0)
        end
        for product in data.products
            _full_variable!(ctx, model, :pa, region, product, activity;
                lower=1.0e-8, start=1.0)
            _full_variable!(ctx, model, :x, region, activity, product;
                lower=0.0, start=_full_make_start(data, region, activity, product))
            # The GTAP declaration is dense in activity--commodity space.  Most
            # cells are inactive make pairs, but retaining their two reporting
            # prices is part of the source model's build footprint; their
            # defining equations remain guarded by the make structure below.
            production_tax = _full_table_value(data.derived, :prdtx_rai,
                (region, activity, product))
            producer_price = max(1.0 / max(1.0 + production_tax, 1.0e-12), 1.0e-8)
            _full_variable!(ctx, model, :p_rai, region, activity, product;
                lower=1.0e-8, start=producer_price)
            _full_variable!(ctx, model, :pp_rai, region, activity, product;
                lower=1.0e-8, start=max((1.0 + production_tax) * producer_price, 1.0e-8))
            output_active = product in outputs_by_activity[activity]
            output_active || continue
        end
    end

    for region in data.regions, activity in data.activities
        region_activity = (region, activity)
        xscale = _full_table_value(data.derived, :xscale, region_activity; default=1.0)
        and_param = _full_table_value(data.derived, :and_param, region_activity)
        ava_param = _full_table_value(data.derived, :ava_param, region_activity)
        nd_share = _full_table_value(data.derived, :nd_share, region_activity)
        sigmap = _full_table_value(data.elasticities, :sigmap, region_activity; default=1.0)
        sigmand = _full_table_value(data.elasticities, :sigmand, region_activity; default=1.0)
        sigmav = _full_table_value(data.elasticities, :sigmav, region_activity; default=1.0)
        omega = _full_table_value(data.elasticities, :omegas, region_activity; default=Inf)

        if and_param > 0.0
            nd_expr = EEq(
                EVar(:nd, Any[region, activity]),
                EMul([
                    EConst(and_param),
                    EVar(:xp, Any[region, activity]),
                    EPow(
                        EDiv(EVar(:px, Any[region, activity]), EVar(:pnd, Any[region, activity])),
                        EConst(sigmap),
                    ),
                ]),
            )
            _register_full_equation!(ctx, block, :intermediate_demand, region, activity;
                info="GTAP nested-demand quantity for intermediate inputs", expr=nd_expr)
        end
        if ava_param > 0.0
            va_expr = EEq(
                EVar(:va, Any[region, activity]),
                EMul([
                    EConst(ava_param),
                    EVar(:xp, Any[region, activity]),
                    EPow(
                        EDiv(EVar(:px, Any[region, activity]), EVar(:pva, Any[region, activity])),
                        EConst(sigmap),
                    ),
                ]),
            )
            _register_full_equation!(ctx, block, :value_added_demand, region, activity;
                info="GTAP nested-demand quantity for value added", expr=va_expr)
        end

        production_exponent = 1.0 - sigmap
        price_expr = if abs(production_exponent) < 1.0e-8
            EEq(
                EVar(:px, Any[region, activity]),
                EMul([
                    EPow(EVar(:pnd, Any[region, activity]), EConst(nd_share)),
                    EPow(EVar(:pva, Any[region, activity]), EConst(1.0 - nd_share)),
                ]),
            )
        else
            EEq(
                EPow(EVar(:px, Any[region, activity]), EConst(production_exponent)),
                EAdd([
                    EMul([EConst(nd_share), EPow(EVar(:pnd, Any[region, activity]), EConst(production_exponent))]),
                    EMul([EConst(1.0 - nd_share), EPow(EVar(:pva, Any[region, activity]), EConst(production_exponent))]),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :activity_price, region, activity;
            info="GTAP nested production price index", expr=price_expr)

        intermediate_terms = JCGECore.EquationExpr[]
        for product in data.products
            share = _full_table_value(data.derived, :p_io, (region, product, activity))
            share > 0.0 || continue
            push!(intermediate_terms, if abs(1.0 - sigmand) < 1.0e-8
                EPow(EVar(:pa, Any[region, product, activity]), EConst(share))
            else
                EMul([
                    EConst(share),
                    EPow(EVar(:pa, Any[region, product, activity]), EConst(1.0 - sigmand)),
                ])
            end)
        end
        if !isempty(intermediate_terms)
            intermediate_price_expr = if abs(1.0 - sigmand) < 1.0e-8
                EEq(EVar(:pnd, Any[region, activity]), _full_product(intermediate_terms))
            else
                EEq(
                    EPow(EVar(:pnd, Any[region, activity]), EConst(1.0 - sigmand)),
                    _full_sum(intermediate_terms),
                )
            end
            _register_full_equation!(ctx, block, :intermediate_price, region, activity;
                info="GTAP CES price index for intermediate inputs", expr=intermediate_price_expr)
        end

        value_added_terms = JCGECore.EquationExpr[]
        for factor in data.factors
            share = _full_table_value(data.derived, :af_param, (region, factor, activity))
            share > 0.0 || continue
            push!(value_added_terms, if abs(1.0 - sigmav) < 1.0e-8
                EPow(EVar(:pfa, Any[region, factor, activity]), EConst(share))
            else
                EMul([
                    EConst(share),
                    EPow(EVar(:pfa, Any[region, factor, activity]), EConst(1.0 - sigmav)),
                ])
            end)
        end
        if !isempty(value_added_terms)
            value_added_price_expr = if abs(1.0 - sigmav) < 1.0e-8
                EEq(EVar(:pva, Any[region, activity]), _full_product(value_added_terms))
            else
                EEq(
                    EPow(EVar(:pva, Any[region, activity]), EConst(1.0 - sigmav)),
                    _full_sum(value_added_terms),
                )
            end
            _register_full_equation!(ctx, block, :value_added_price, region, activity;
                info="GTAP CES price index for primary factors", expr=value_added_price_expr)
        end

        active_outputs = outputs_by_activity[activity]
        for product in active_outputs
            output_key = (region, activity, product)
            gx = _full_table_value(data.derived, :gx_param, output_key)
            xflag = _full_table_value(data.derived, :xflag, output_key)
            xflag > 0.0 && (gx > 0.0 || _full_table_value(data.benchmark, :makb, output_key) > 0.0) || continue
            if isinf(omega)
                output_expr = EEq(EVar(:p_rai, Any[region, activity, product]),
                    EVar(:px, Any[region, activity]))
            else
                output_expr = EEq(
                    EVar(:x, Any[region, activity, product]),
                    EMul([
                        EConst(gx),
                        EDiv(EVar(:xp, Any[region, activity]), EConst(xscale)),
                        EPow(
                            EDiv(EVar(:p_rai, Any[region, activity, product]), EVar(:px, Any[region, activity])),
                            EConst(omega),
                        ),
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :activity_output, region, activity, product;
                info="GTAP make allocation from activity output to commodity output", expr=output_expr)

            production_tax = _full_table_value(data.derived, :prdtx_rai, output_key)
            tax_price_expr = EEq(
                EVar(:pp_rai, Any[region, activity, product]),
                EMul([
                    EConst(1.0 + production_tax),
                    EVar(:p_rai, Any[region, activity, product]),
                ]),
            )
            _register_full_equation!(ctx, block, :activity_output_tax_price, region, activity, product;
                info="GTAP producer price after the activity-output tax wedge", expr=tax_price_expr)

            commodity_sigma = _full_table_value(data.elasticities, :sigmas,
                (region, product); default=Inf)
            allocation_expr = if isinf(commodity_sigma)
                EEq(EVar(:pp_rai, Any[region, activity, product]),
                    EVar(:ps, Any[region, product]))
            else
                EEq(
                    EVar(:x, Any[region, activity, product]),
                    EMul([
                        EConst(_full_table_value(data.derived, :p_ax, output_key)),
                        EVar(:xs, Any[region, product]),
                        EPow(
                            EDiv(EVar(:ps, Any[region, product]), EVar(:pp_rai, Any[region, activity, product])),
                            EConst(commodity_sigma),
                        ),
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :commodity_activity_allocation,
                region, activity, product;
                info="GTAP allocation of commodity supply across producing activities", expr=allocation_expr)
        end

        if !isempty(active_outputs)
            output_price_expr = if isinf(omega)
                EEq(
                    EDiv(EVar(:xp, Any[region, activity]), EConst(xscale)),
                    _full_sum([EVar(:x, Any[region, activity, product]) for product in active_outputs]),
                )
            else
                exponent = 1.0 + omega
                EEq(
                    EPow(EVar(:px, Any[region, activity]), EConst(exponent)),
                    _full_sum([
                        EMul([
                            EConst(_full_table_value(data.derived, :gx_param, (region, activity, product))),
                            EPow(EVar(:p_rai, Any[region, activity, product]), EConst(exponent)),
                        ])
                        for product in active_outputs
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :activity_output_price, region, activity;
                info="GTAP activity-output transformation price index", expr=output_price_expr)
        end
    end

    for region in data.regions, product in data.products
        commodity_sigma = _full_table_value(data.elasticities, :sigmas,
            (region, product); default=Inf)
        active_activities = activities_by_product[product]
        isempty(active_activities) && continue
        commodity_price_expr = if isinf(commodity_sigma)
            EEq(
                EVar(:xs, Any[region, product]),
                _full_sum([EVar(:x, Any[region, activity, product]) for activity in active_activities]),
            )
        else
            exponent = 1.0 - commodity_sigma
            EEq(
                EPow(EVar(:ps, Any[region, product]), EConst(exponent)),
                _full_sum([
                    EMul([
                        EConst(_full_table_value(data.derived, :p_ax, (region, activity, product))),
                        EPow(EVar(:pp_rai, Any[region, activity, product]), EConst(exponent)),
                    ])
                    for activity in active_activities
                ]),
            )
        end
        _register_full_equation!(ctx, block, :commodity_output_price, region, product;
            info="GTAP CES price index across producing activities", expr=commodity_price_expr)
    end
    return nothing
end

"""GTAP Standard 7 factor-demand, mobility, and capital-stock block."""
struct GTAP7FactorBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
end

function _full_kappaf(data::GTAP7FullData, region::Symbol, factor::Symbol, activity::Symbol)
    activity_rate = _full_table_value(data.taxes, :kappaf_activity,
        (region, factor, activity))
    return iszero(activity_rate) ?
        _full_table_value(data.taxes, :kappaf, (region, factor)) : activity_rate
end

function _full_factor_omega(data::GTAP7FullData, region::Symbol, factor::Symbol)
    direct = _full_table_value(data.elasticities, :omegaf, (region, factor); default=NaN)
    !isnan(direct) && return direct
    factor in data.mobile_factors && return Inf
    etrae = _full_table_value(data.elasticities, :etrae, (factor,); default=Inf)
    return isinf(etrae) ? Inf : -etrae
end

function JCGECore.build!(block::GTAP7FactorBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    for region in data.regions
        capital_stock = _full_table_value(data.benchmark, :vkb, (region,))
        investment_seed = sum(
            _full_table_value(data.benchmark, :vdip, (region, product)) +
            _full_table_value(data.benchmark, :vmip, (region, product))
            for product in data.products)
        depreciation = _full_table_value(data.derived, :depr, (region,))
        capital_factors = filter(factor -> lowercase(String(factor)) in ("capital", "cap", "k", "kap"), data.factors)
        capital_return = sum(
            (1.0 - _full_kappaf(data, region, factor, activity)) *
            _full_table_value(data.benchmark, :evfb, (region, factor, activity);
                default=_full_table_value(data.benchmark, :vfm, (region, factor, activity))) /
            _full_table_value(data.derived, :xscale, (region, activity); default=1.0)
            for factor in capital_factors for activity in data.activities)
        asset_return = capital_stock > 0.0 ? capital_return / capital_stock : 0.0
        current_return = asset_return - _full_table_value(data.derived, :fdepr, (region,))
        capital_endowment = (1.0 - depreciation) * capital_stock + investment_seed
        expected_return = capital_endowment > 0.0 ?
            current_return * (capital_stock / capital_endowment) ^
                _full_table_value(data.derived, :rorflex, (region,)) : current_return
        _full_variable!(ctx, model, :pabs, region; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pfact, region; lower=1.0e-3, start=1.0)
        _full_variable!(ctx, model, :kstock, region;
            lower=1.0e-8, start=max(capital_stock, 1.0e-8))
        _full_variable!(ctx, model, :kapEnd, region; lower=1.0e-8,
            start=max(capital_endowment, 1.0e-8))
        _full_variable!(ctx, model, :arent, region; lower=0.0, start=max(asset_return, 0.0))
        _full_variable!(ctx, model, :rorc, region; lower=-Inf, start=current_return)
        _full_variable!(ctx, model, :rore, region; lower=-Inf, start=expected_return)
        for factor in data.factors
            supply = _full_table_value(data.derived, :aft, (region, factor))
            _full_variable!(ctx, model, :xft, region, factor;
                lower=1.0e-8, start=max(supply, 1.0e-8))
            _full_variable!(ctx, model, :pft, region, factor; lower=1.0e-8, start=1.0)
            for activity in data.activities
                kappa = _full_kappaf(data, region, factor, activity)
                factor_value = _full_table_value(data.benchmark, :evfb,
                    (region, factor, activity);
                    default=_full_table_value(data.benchmark, :vfm, (region, factor, activity)))
                factor_price = max(1.0 / max(1.0 - kappa, 1.0e-8), 1.0e-8)
                _full_variable!(ctx, model, :xf, region, factor, activity;
                    lower=0.0, start=max(factor_value / factor_price, 0.0))
                _full_variable!(ctx, model, :pf, region, factor, activity;
                    lower=1.0e-8, start=factor_price)
                _full_variable!(ctx, model, :pfa, region, factor, activity;
                    lower=1.0e-8, start=max(factor_price * (1.0 +
                        _full_table_value(data.derived, :fcttx, (region, factor, activity))), 1.0e-8))
                _full_variable!(ctx, model, :pfy, region, factor, activity;
                    lower=1.0e-8, start=max(factor_price * (1.0 - kappa), 1.0e-8))
            end
        end
    end
    _full_variable!(ctx, model, :pwfact; lower=1.0e-3, start=1.0)

    for region in data.regions, factor in data.factors
        factor_key = (region, factor)
        xft_active = _full_table_value(data.derived, :xftflag, factor_key) > 0.0
        xscale_sum = _full_sum([
            EDiv(EVar(:xf, Any[region, factor, activity]),
                EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)))
            for activity in data.activities
        ])
        if xft_active
            _register_full_equation!(ctx, block, :factor_supply_total, region, factor;
                info="GTAP regional factor supply equals scaled activity demand",
                expr=EEq(EVar(:xft, Any[region, factor]), xscale_sum))
            benchmark_supply = _full_table_value(data.derived, :aft, factor_key)
            if benchmark_supply > 0.0
                factor_supply_expr = EEq(
                    EVar(:xft, Any[region, factor]),
                    EMul([
                        EConst(benchmark_supply),
                        EPow(
                            EDiv(EVar(:pft, Any[region, factor]),
                                EAdd([EVar(:pabs, Any[region]), EConst(1.0e-12)])),
                            EConst(_full_table_value(data.derived, :etaf, factor_key)),
                        ),
                    ]),
                )
                _register_full_equation!(ctx, block, :factor_supply_response, region, factor;
                    info="GTAP regional factor supply response", expr=factor_supply_expr)
            end
        end

        omega = _full_factor_omega(data, region, factor)
        active_activities = Symbol[]
        for activity in data.activities
            factor_activity = (region, factor, activity)
            xfflag = _full_table_value(data.derived, :xfflag, factor_activity)
            af_share = _full_table_value(data.derived, :af_param, factor_activity)
            xfflag > 0.0 && af_share > 0.0 || continue
            push!(active_activities, activity)
            sigmav = _full_table_value(data.elasticities, :sigmav, (region, activity); default=1.0)
            demand_expr = EEq(
                EVar(:xf, Any[region, factor, activity]),
                EMul([
                    EConst(af_share),
                    EVar(:va, Any[region, activity]),
                    EPow(
                        EDiv(EVar(:pva, Any[region, activity]),
                            EVar(:pfa, Any[region, factor, activity])),
                        EConst(sigmav),
                    ),
                ]),
            )
            _register_full_equation!(ctx, block, :factor_demand, region, factor, activity;
                info="GTAP conditional demand for a primary factor", expr=demand_expr)

            gf_share = _full_table_value(data.derived, :gf_share, factor_activity)
            gf_share > 0.0 || continue
            kappa = _full_kappaf(data, region, factor, activity)
            price_allocation_expr = if factor in data.mobile_factors || factor in data.sector_specific_factors
                if isinf(omega)
                    EEq(EVar(:pfy, Any[region, factor, activity]), EVar(:pft, Any[region, factor]))
                else
                    EEq(
                        EMul([
                            EPow(
                                EMul([EVar(:pf, Any[region, factor, activity]), EConst(1.0 - kappa)]),
                                EConst(omega),
                            ),
                            EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)),
                            EConst(gf_share),
                            EVar(:xft, Any[region, factor]),
                        ]),
                        EMul([
                            EPow(EVar(:pft, Any[region, factor]), EConst(omega)),
                            EVar(:xf, Any[region, factor, activity]),
                        ]),
                    )
                end
            else
                EEq(
                    EVar(:xf, Any[region, factor, activity]),
                    EMul([
                        EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)),
                        EConst(gf_share),
                        EPow(
                            EDiv(EVar(:pfy, Any[region, factor, activity]), EVar(:pabs, Any[region])),
                            EConst(_full_table_value(data.elasticities, :etaff, factor_activity)),
                        ),
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :factor_price_allocation,
                region, factor, activity;
                info="GTAP factor-price allocation across activities", expr=price_allocation_expr)

            factor_tax_expr = EEq(
                EVar(:pfa, Any[region, factor, activity]),
                EMul([
                    EVar(:pf, Any[region, factor, activity]),
                    EConst(1.0 + _full_table_value(data.derived, :fctts, factor_activity) +
                        _full_table_value(data.derived, :fcttx, factor_activity)),
                ]),
            )
            _register_full_equation!(ctx, block, :factor_purchase_price,
                region, factor, activity;
                info="GTAP factor price including activity tax and subsidy wedges", expr=factor_tax_expr)
            factor_return_expr = EEq(
                EVar(:pfy, Any[region, factor, activity]),
                EMul([
                    EVar(:pf, Any[region, factor, activity]),
                    EConst(1.0 - kappa),
                ]),
            )
            _register_full_equation!(ctx, block, :factor_return_price,
                region, factor, activity;
                info="GTAP activity factor return after ownership wedge", expr=factor_return_expr)
        end

        if xft_active && !isempty(active_activities)
            factor_price_expr = if isinf(omega)
                EEq(EVar(:xft, Any[region, factor]), _full_sum([
                    EDiv(EVar(:xf, Any[region, factor, activity]),
                        EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)))
                    for activity in active_activities
                ]))
            else
                exponent = 1.0 + omega
                EEq(
                    EVar(:pft, Any[region, factor]),
                    EPow(
                        _full_sum([
                            EMul([
                                EConst(_full_table_value(data.derived, :gf_share, (region, factor, activity))),
                                EPow(EVar(:pfy, Any[region, factor, activity]), EConst(exponent)),
                            ])
                            for activity in active_activities
                        ]),
                        EConst(1.0 / exponent),
                    ),
                )
            end
            _register_full_equation!(ctx, block, :factor_price_index, region, factor;
                info="GTAP regional factor price index", expr=factor_price_expr)
        end
    end

    capital_factors = filter(factor -> lowercase(String(factor)) in ("capital", "cap", "k", "kap"), data.factors)
    for region in data.regions
        isempty(capital_factors) && continue
        benchmark_supply = sum(_full_table_value(data.derived, :aft, (region, factor))
            for factor in capital_factors)
        capital_stock = _full_table_value(data.benchmark, :vkb, (region,))
        capital_stock > 0.0 && benchmark_supply > 0.0 || continue
        capital_expr = EEq(
            EMul([EConst(benchmark_supply / capital_stock), EVar(:kstock, Any[region])]),
            _full_sum([EVar(:xft, Any[region, factor]) for factor in capital_factors]),
        )
        _register_full_equation!(ctx, block, :capital_stock, region;
            info="GTAP capital stock is proportional to regional capital supply", expr=capital_expr)
    end
    return nothing
end

"""GTAP Standard 7 top-Armington, margin, and bilateral-trade block."""
struct GTAP7ArmingtonBilateralBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
end

const GTAP7_FINAL_AGENTS = (:hhd, :gov, :inv, :tmg)

_full_agents(data::GTAP7FullData) = vcat(data.activities, collect(GTAP7_FINAL_AGENTS))

function _full_agent_scale(data::GTAP7FullData, region::Symbol, agent::Symbol)
    return _full_table_value(data.derived, :xscale, (region, agent); default=1.0)
end

function _full_margin_demand_share(data::GTAP7FullData, region::Symbol, product::Symbol)
    product in data.margins || return 0.0
    denominator = sum(_full_table_value(data.benchmark, :vst, (origin, product))
        for origin in data.regions)
    denominator > 1.0e-12 || return 0.0
    return _full_table_value(data.benchmark, :vst, (region, product)) / denominator
end

function _full_purchaser_value(data::GTAP7FullData, region::Symbol, product::Symbol, agent::Symbol)
    if agent in data.activities
        return _full_table_value(data.benchmark, :vdfp, (region, product, agent)) +
               _full_table_value(data.benchmark, :vmfp, (region, product, agent))
    elseif agent == :hhd
        return _full_table_value(data.benchmark, :vdpp, (region, product)) +
               _full_table_value(data.benchmark, :vmpp, (region, product))
    elseif agent == :gov
        return _full_table_value(data.benchmark, :vdgp, (region, product)) +
               _full_table_value(data.benchmark, :vmgp, (region, product))
    elseif agent == :inv
        return _full_table_value(data.benchmark, :vdip, (region, product)) +
               _full_table_value(data.benchmark, :vmip, (region, product))
    end
    return _full_table_value(data.benchmark, :vst, (region, product))
end

function _full_domestic_import_values(data::GTAP7FullData, region::Symbol,
    product::Symbol, agent::Symbol)
    if agent in data.activities
        return (
            _full_table_value(data.benchmark, :vdfb, (region, product, agent)),
            _full_table_value(data.benchmark, :vmfb, (region, product, agent)),
        )
    elseif agent == :hhd
        return (
            _full_table_value(data.benchmark, :vdpb, (region, product)),
            _full_table_value(data.benchmark, :vmpb, (region, product)),
        )
    elseif agent == :gov
        return (
            _full_table_value(data.benchmark, :vdgb, (region, product)),
            _full_table_value(data.benchmark, :vmgb, (region, product)),
        )
    elseif agent == :inv
        return (
            _full_table_value(data.benchmark, :vdib, (region, product)),
            _full_table_value(data.benchmark, :vmib, (region, product)),
        )
    end
    return (_full_table_value(data.benchmark, :vst, (region, product)), 0.0)
end

function JCGECore.build!(block::GTAP7ArmingtonBilateralBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    agents = _full_agents(data)
    for region in data.regions, product in data.products
        _full_variable!(ctx, model, :xd, region, product; lower=0.0, start=1.0)
        _full_variable!(ctx, model, :xmt, region, product; lower=0.0, start=1.0)
        _full_variable!(ctx, model, :pmt, region, product; lower=1.0e-8, start=1.0)
        for agent in agents
            domestic, imported = _full_domestic_import_values(data, region, product, agent)
            _full_variable!(ctx, model, :pa, region, product, agent; lower=1.0e-8, start=1.0)
            _full_variable!(ctx, model, :dintx, region, product, agent;
                lower=-0.999, start=_full_table_value(data.derived, :dintx_target, (region, product, agent)))
            _full_variable!(ctx, model, :mintx, region, product, agent;
                lower=-0.999, start=_full_table_value(data.derived, :mintx_target, (region, product, agent)))
            _full_variable!(ctx, model, :xda, region, product, agent;
                lower=0.0, start=max(domestic, 0.0))
            _full_variable!(ctx, model, :xma, region, product, agent;
                lower=0.0, start=max(imported, 0.0))
            _full_variable!(ctx, model, :xaa, region, product, agent;
                lower=0.0, start=max(_full_purchaser_value(data, region, product, agent), 0.0))
        end
        _full_variable!(ctx, model, :xc, region, product; lower=0.0, start=1.0)
        _full_variable!(ctx, model, :xg, region, product; lower=0.0, start=1.0)
        _full_variable!(ctx, model, :xi, region, product; lower=0.0, start=1.0)
    end
    for mode in data.modes
        margin_output = sum(_full_table_value(data.benchmark, :vtwr, (origin, product, destination, mode))
            for origin in data.regions for product in data.products for destination in data.regions)
        _full_variable!(ctx, model, :xtmg, mode; lower=0.0, start=max(margin_output, 0.0))
        _full_variable!(ctx, model, :ptmg, mode; lower=1.0e-3, start=1.0)
    end
    _full_variable!(ctx, model, :pnum; lower=1.0e-3, start=1.0)
    for exporter in data.regions, product in data.products, importer in data.regions
        route = (exporter, product, importer)
        export_value = _full_table_value(data.benchmark, :vxsb, route)
        cif_value = _full_table_value(data.benchmark, :vcif, route)
        import_value = _full_table_value(data.benchmark, :vmsb, route)
        margin_value = sum(_full_table_value(data.benchmark, :vtwr, (exporter, product, importer, mode))
            for mode in data.modes)
        _full_variable!(ctx, model, :xe, exporter, product, importer;
            lower=0.0, start=max(export_value, 0.0))
        _full_variable!(ctx, model, :xw, exporter, product, importer;
            lower=-Inf, start=max(export_value, 0.0))
        _full_variable!(ctx, model, :pe, exporter, product, importer; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :xwmg, exporter, product, importer;
            lower=0.0, start=max(margin_value, 0.0))
        _full_variable!(ctx, model, :pwmg, exporter, product, importer; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pmcif, exporter, product, importer;
            lower=1.0e-8, start=max(export_value > 0.0 ? cif_value / export_value : 1.0, 1.0e-8))
        _full_variable!(ctx, model, :pm, exporter, product, importer;
            lower=1.0e-8, start=max(export_value > 0.0 ? import_value / export_value : 1.0, 1.0e-8))
        _full_variable!(ctx, model, :pefob, exporter, product, importer; lower=1.0e-8, start=1.0)
        for mode in data.modes
            _full_variable!(ctx, model, :xmgm, mode, exporter, product, importer;
                lower=0.0, start=max(_full_table_value(data.benchmark, :vtwr,
                    (exporter, product, importer, mode)), 0.0))
        end
        # `xe` is a reporting helper in the source model and is fixed at its
        # benchmark value.  The remaining inactive-route fixes reproduce the
        # GTAP conditional declarations: they prevent a zero-flow route from
        # introducing unconstrained quantities or prices into the system.
        if model isa JuMP.Model
            JuMP.fix(ctx.variables[JCGEBlocks.global_var(:xe, exporter, product, importer)],
                max(export_value, 0.0); force=true)
            if _full_table_value(data.derived, :xw_flag, route) <= 0.0
                JuMP.fix(ctx.variables[JCGEBlocks.global_var(:xw, exporter, product, importer)],
                    0.0; force=true)
                for name in (:pe, :pmcif, :pm, :pefob)
                    JuMP.fix(ctx.variables[JCGEBlocks.global_var(name, exporter, product, importer)],
                        1.0; force=true)
                end
            end
            if _full_table_value(data.derived, :tmarg, route) <= 0.0
                for name in (:xwmg, :pwmg)
                    JuMP.fix(ctx.variables[JCGEBlocks.global_var(name, exporter, product, importer)],
                        0.0; force=true)
                end
            end
            for mode in data.modes
                _full_table_value(data.derived, :amgm, (mode, exporter, product, importer)) > 0.0 && continue
                JuMP.fix(ctx.variables[JCGEBlocks.global_var(:xmgm, mode, exporter, product, importer)],
                    0.0; force=true)
            end
        end
    end

    for region in data.regions, product in data.products, agent in agents
        agent_key = (region, product, agent)
        if agent in data.activities
            share = _full_table_value(data.derived, :p_io, (region, product, agent))
            xaa_expr = share <= 0.0 ?
                EEq(EVar(:xaa, Any[region, product, agent]), EConst(0.0)) :
                EEq(
                    EVar(:xaa, Any[region, product, agent]),
                    EMul([
                        EConst(share),
                        EVar(:nd, Any[region, agent]),
                        EPow(
                            EDiv(EVar(:pnd, Any[region, agent]), EVar(:pa, Any[region, product, agent])),
                            EConst(_full_table_value(data.elasticities, :sigmand, (region, agent); default=1.0)),
                        ),
                    ]),
                )
            _register_full_equation!(ctx, block, :activity_armington_demand,
                region, product, agent;
                info="GTAP activity demand for an Armington composite", expr=xaa_expr)
        elseif agent == :hhd
            _register_full_equation!(ctx, block, :household_armington_identity, region, product;
                info="GTAP household composite demand identity",
                expr=EEq(EVar(:xaa, Any[region, product, agent]), EVar(:xc, Any[region, product])))
        elseif agent == :gov
            _register_full_equation!(ctx, block, :government_armington_identity, region, product;
                info="GTAP government composite demand identity",
                expr=EEq(EVar(:xaa, Any[region, product, agent]), EVar(:xg, Any[region, product])))
        elseif agent == :inv
            _register_full_equation!(ctx, block, :investment_armington_identity, region, product;
                info="GTAP investment composite demand identity",
                expr=EEq(EVar(:xaa, Any[region, product, agent]), EVar(:xi, Any[region, product])))
        else
            alpha = _full_margin_demand_share(data, region, product)
            if alpha <= 0.0
                if model isa JuMP.Model
                    JuMP.fix(ctx.variables[JCGEBlocks.global_var(:xaa, region, product, agent)], 0.0; force=true)
                end
            else
                sigma = _full_table_value(data.elasticities, :sigmam, (product,); default=1.0)
                isapprox(sigma, 1.0; atol=1.0e-8) && (sigma = 1.01)
                tmg_expr = EEq(
                    EVar(:xaa, Any[region, product, agent]),
                    EMul([
                        EConst(alpha),
                        EVar(:xtmg, Any[product]),
                        EPow(
                            EDiv(EVar(:ptmg, Any[product]),
                                EAdd([EVar(:pa, Any[region, product, agent]), EConst(1.0e-12)])),
                            EConst(sigma),
                        ),
                    ]),
                )
                _register_full_equation!(ctx, block, :margin_armington_identity, region, product;
                    info="GTAP transport-margin demand for an Armington composite", expr=tmg_expr)
            end
        end

        _register_full_equation!(ctx, block, :domestic_tax_wedge, region, product, agent;
            info="GTAP domestic purchaser tax wedge",
            expr=EEq(EVar(:dintx, Any[region, product, agent]),
                EConst(_full_table_value(data.derived, :dintx_target, agent_key))))
        _register_full_equation!(ctx, block, :import_tax_wedge, region, product, agent;
            info="GTAP imported purchaser tax wedge",
            expr=EEq(EVar(:mintx, Any[region, product, agent]),
                EConst(_full_table_value(data.derived, :mintx_target, agent_key))))

        alphad = _full_table_value(data.derived, :alphad, agent_key)
        alpham = _full_table_value(data.derived, :alpham, agent_key)
        if alphad <= 0.0 && alpham <= 0.0 && model isa JuMP.Model
            JuMP.fix(ctx.variables[JCGEBlocks.global_var(:pa, region, product, agent)],
                1.0; force=true)
        end
        sigma = _full_table_value(data.elasticities, :esubd, (region, product); default=2.0)
        domestic_expr = if alphad <= 0.0
            EEq(EVar(:xda, Any[region, product, agent]), EConst(0.0))
        elseif isinf(sigma)
            EEq(
                EMul([
                    EAdd([EConst(1.0), EVar(:dintx, Any[region, product, agent])]),
                    EVar(:pd, Any[region, product]),
                ]),
                EVar(:pa, Any[region, product, agent]),
            )
        else
            EEq(
                EVar(:xda, Any[region, product, agent]),
                EMul([
                    EConst(alphad),
                    EVar(:xaa, Any[region, product, agent]),
                    EPow(
                        EDiv(
                            EVar(:pa, Any[region, product, agent]),
                            EMul([
                                EAdd([EConst(1.0), EVar(:dintx, Any[region, product, agent])]),
                                EVar(:pd, Any[region, product]),
                            ]),
                        ),
                        EConst(sigma),
                    ),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :domestic_armington_demand, region, product, agent;
            info="GTAP domestic branch of top Armington demand", expr=domestic_expr)
        import_expr = if alpham <= 0.0
            EEq(EVar(:xma, Any[region, product, agent]), EConst(0.0))
        elseif isinf(sigma)
            EEq(
                EMul([
                    EAdd([EConst(1.0), EVar(:mintx, Any[region, product, agent])]),
                    EVar(:pmt, Any[region, product]),
                ]),
                EVar(:pa, Any[region, product, agent]),
            )
        else
            EEq(
                EVar(:xma, Any[region, product, agent]),
                EMul([
                    EConst(alpham),
                    EVar(:xaa, Any[region, product, agent]),
                    EPow(
                        EDiv(
                            EVar(:pa, Any[region, product, agent]),
                            EMul([
                                EAdd([EConst(1.0), EVar(:mintx, Any[region, product, agent])]),
                                EVar(:pmt, Any[region, product]),
                            ]),
                        ),
                        EConst(sigma),
                    ),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :import_armington_demand, region, product, agent;
            info="GTAP import branch of top Armington demand", expr=import_expr)

        (alphad > 0.0 || alpham > 0.0) || continue
        exponent = 1.0 - sigma
        price_expr = if abs(exponent) < 1.0e-8
            EEq(
                EVar(:pa, Any[region, product, agent]),
                EMul([
                    EPow(EMul([EAdd([EConst(1.0), EVar(:dintx, Any[region, product, agent])]),
                        EVar(:pd, Any[region, product])]), EConst(alphad)),
                    EPow(EMul([EAdd([EConst(1.0), EVar(:mintx, Any[region, product, agent])]),
                        EVar(:pmt, Any[region, product])]), EConst(alpham)),
                ]),
            )
        else
            EEq(
                EPow(EVar(:pa, Any[region, product, agent]), EConst(exponent)),
                EAdd([
                    EMul([EConst(alphad), EPow(EMul([EAdd([EConst(1.0), EVar(:dintx, Any[region, product, agent])]),
                        EVar(:pd, Any[region, product])]), EConst(exponent))]),
                    EMul([EConst(alpham), EPow(EMul([EAdd([EConst(1.0), EVar(:mintx, Any[region, product, agent])]),
                        EVar(:pmt, Any[region, product])]), EConst(exponent))]),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :armington_price, region, product, agent;
            info="GTAP top-Armington composite price", expr=price_expr)
    end

    for region in data.regions, product in data.products
        _register_full_equation!(ctx, block, :domestic_demand_aggregate, region, product;
            info="GTAP aggregate domestic demand across agents",
            expr=EEq(EVar(:xd, Any[region, product]), _full_sum([
                EDiv(EVar(:xda, Any[region, product, agent]), EConst(_full_agent_scale(data, region, agent)))
                for agent in agents
            ])))
        _register_full_equation!(ctx, block, :import_demand_aggregate, region, product;
            info="GTAP aggregate import demand across agents",
            expr=EEq(EVar(:xmt, Any[region, product]), _full_sum([
                EDiv(EVar(:xma, Any[region, product, agent]), EConst(_full_agent_scale(data, region, agent)))
                for agent in agents
            ])))
    end

    for exporter in data.regions, product in data.products, importer in data.regions
        route = (exporter, product, importer)
        margin = _full_table_value(data.derived, :tmarg, route)
        if margin > 0.0
            _register_full_equation!(ctx, block, :margin_quantity, exporter, product, importer;
                info="GTAP transport-margin quantity on a bilateral route",
                expr=EEq(EVar(:xwmg, Any[exporter, product, importer]),
                    EMul([EConst(margin), EVar(:xw, Any[exporter, product, importer])])))
            _register_full_equation!(ctx, block, :margin_price, exporter, product, importer;
                info="GTAP transport-margin price on a bilateral route",
                expr=EEq(EVar(:pwmg, Any[exporter, product, importer]), _full_sum([
                    EDiv(
                        EMul([
                            EConst(_full_table_value(data.derived, :amgm, (mode, exporter, product, importer))),
                            EVar(:ptmg, Any[mode]),
                        ]),
                        EAdd([EConst(_full_table_value(data.derived, :lambdamg,
                            (mode, exporter, product, importer); default=1.0)), EConst(1.0e-12)]),
                    )
                    for mode in data.modes
                ])))
        end
        for mode in data.modes
            share = _full_table_value(data.derived, :amgm, (mode, exporter, product, importer))
            share > 0.0 || continue
            _register_full_equation!(ctx, block, :margin_mode_quantity,
                mode, exporter, product, importer;
                info="GTAP allocation of transport margins across margin commodities",
                expr=EEq(EVar(:xmgm, Any[mode, exporter, product, importer]),
                    EDiv(EMul([EConst(share), EVar(:xwmg, Any[exporter, product, importer])]),
                        EAdd([EConst(_full_table_value(data.derived, :lambdamg,
                            (mode, exporter, product, importer); default=1.0)), EConst(1.0e-12)]))))
        end
        _full_table_value(data.derived, :xw_flag, route) > 0.0 || continue
        import_tax = _full_table_value(data.derived, :imptx, route)
        _register_full_equation!(ctx, block, :import_price, exporter, product, importer;
            info="GTAP tariff-inclusive bilateral import price",
            expr=EEq(EVar(:pm, Any[exporter, product, importer]),
                EMul([EConst(1.0 + import_tax), EVar(:pmcif, Any[exporter, product, importer])])))
        _register_full_equation!(ctx, block, :cif_price, exporter, product, importer;
            info="GTAP CIF price including bilateral transport margins",
            expr=EEq(EVar(:pmcif, Any[exporter, product, importer]), EAdd([
                EVar(:pefob, Any[exporter, product, importer]),
                EMul([EVar(:pwmg, Any[exporter, product, importer]), EConst(margin)]),
            ])))
        export_tax = _full_table_value(data.taxes, :rtxs, route)
        _register_full_equation!(ctx, block, :fob_price, exporter, product, importer;
            info="GTAP FOB price after the bilateral export tax wedge",
            expr=EEq(EVar(:pefob, Any[exporter, product, importer]),
                EMul([EConst(1.0 + export_tax), EVar(:pe, Any[exporter, product, importer])])))

        export_elasticity = _full_table_value(data.elasticities, :omegaw,
            (exporter, product); default=Inf)
        export_expr = if isinf(export_elasticity)
            EEq(EVar(:pe, Any[exporter, product, importer]), EVar(:pet, Any[exporter, product]))
        else
            EEq(
                EVar(:xw, Any[exporter, product, importer]),
                EMul([
                    EConst(_full_table_value(data.derived, :gw_share, route)),
                    EVar(:xet, Any[exporter, product]),
                    EPow(
                        EDiv(EVar(:pe, Any[exporter, product, importer]), EVar(:pet, Any[exporter, product])),
                        EConst(export_elasticity),
                    ),
                ]),
            )
        end
        _register_full_equation!(ctx, block, :bilateral_export_supply, exporter, product, importer;
            info="GTAP bilateral export allocation", expr=export_expr)
    end

    for mode in data.modes
        _register_full_equation!(ctx, block, :margin_supply, mode;
            info="GTAP global supply of a transport-margin commodity",
            expr=EEq(EVar(:xtmg, Any[mode]), _full_sum([
                EVar(:xmgm, Any[mode, exporter, product, importer])
                for exporter in data.regions for product in data.products for importer in data.regions
            ])))
        alpha_terms = [(region, _full_margin_demand_share(data, region, mode)) for region in data.regions]
        active = filter(pair -> pair[2] > 0.0, alpha_terms)
        margin_price_expr = if isempty(active)
            EEq(EVar(:ptmg, Any[mode]), EVar(:pnum, Any[]))
        else
            sigma = _full_table_value(data.elasticities, :sigmam, (mode,); default=1.0)
            isapprox(sigma, 1.0; atol=1.0e-8) && (sigma = 1.01)
            exponent = 1.0 - sigma
            EEq(
                EPow(EVar(:ptmg, Any[mode]), EConst(exponent)),
                _full_sum([
                    EMul([
                        EConst(share),
                        EPow(EVar(:pa, Any[region, mode, :tmg]), EConst(exponent)),
                    ])
                    for (region, share) in active
                ]),
            )
        end
        _register_full_equation!(ctx, block, :margin_price_index, mode;
            info="GTAP global price index for a transport-margin commodity", expr=margin_price_expr)
    end

    for importer in data.regions, product in data.products
        source_terms = Tuple{Symbol,Float64}[]
        for exporter in data.regions
            share = _full_table_value(data.derived, :import_source_share, (importer, product, exporter))
            share > 0.0 && push!(source_terms, (exporter, share))
        end
        import_elasticity = _full_table_value(data.elasticities, :esubm, (importer, product); default=5.0)
        if isempty(source_terms)
            _register_full_equation!(ctx, block, :import_price_index, importer, product;
                info="GTAP import price default for a commodity without import sources",
                expr=EEq(EVar(:pmt, Any[importer, product]), EConst(1.0)))
        else
            for (exporter, share) in source_terms
                _register_full_equation!(ctx, block, :bilateral_import_demand, exporter, product, importer;
                    info="GTAP CES allocation of imports across source regions",
                    expr=EEq(
                        EVar(:xw, Any[exporter, product, importer]),
                        EMul([
                            EConst(share),
                            EVar(:xmt, Any[importer, product]),
                            EPow(EDiv(EVar(:pmt, Any[importer, product]),
                                EVar(:pm, Any[exporter, product, importer])), EConst(import_elasticity)),
                        ]),
                    ))
            end
            exponent = 1.0 - import_elasticity
            if abs(exponent) >= 1.0e-8
                _register_full_equation!(ctx, block, :import_price_index, importer, product;
                    info="GTAP CES price index across import sources",
                    expr=EEq(
                        EPow(EVar(:pmt, Any[importer, product]), EConst(exponent)),
                        _full_sum([
                            EMul([
                                EConst(share),
                                EPow(EVar(:pm, Any[exporter, product, importer]), EConst(exponent)),
                            ])
                            for (exporter, share) in source_terms
                        ]),
                    ))
            end
        end

        export_routes = [(destination, _full_table_value(data.derived, :xw_flag, (importer, product, destination)))
            for destination in data.regions]
        active_routes = filter(pair -> pair[2] > 0.0, export_routes)
        export_active = _full_table_value(data.derived, :xet_flag, (importer, product)) > 0.0
        if export_active && !isempty(active_routes)
            export_elasticity = _full_table_value(data.elasticities, :omegaw, (importer, product); default=Inf)
            export_price_expr = if isinf(export_elasticity)
                EEq(EVar(:xet, Any[importer, product]), _full_sum([
                    EVar(:xw, Any[importer, product, destination])
                    for (destination, _) in active_routes
                ]))
            else
                exponent = 1.0 + export_elasticity
                EEq(
                    EPow(EVar(:pet, Any[importer, product]), EConst(exponent)),
                    _full_sum([
                        EMul([
                            EConst(_full_table_value(data.derived, :gw_share, (importer, product, destination))),
                            EPow(EVar(:pe, Any[importer, product, destination]), EConst(exponent)),
                        ])
                        for (destination, _) in active_routes
                    ]),
                )
            end
            _register_full_equation!(ctx, block, :export_price_index, importer, product;
                info="GTAP price index across export destinations", expr=export_price_expr)
        end

        agents_with_domestic_demand = [agent for agent in agents
            if _full_table_value(data.derived, :alphad, (importer, product, agent)) > 0.0]
        _register_full_equation!(ctx, block, :domestic_market_demand, importer, product;
            info="GTAP domestic commodity demand across all active agents",
            expr=EEq(EVar(:xds, Any[importer, product]), _full_sum([
                EDiv(EVar(:xda, Any[importer, product, agent]),
                    EConst(_full_agent_scale(data, importer, agent)))
                for agent in agents_with_domestic_demand
            ])))
    end
    return nothing
end

"""GTAP Standard 7 final demand, CDE utility, savings, and return block."""
struct GTAP7DemandUtilityBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
    residual_region::Symbol
end

function _full_regional_value(data::GTAP7FullData, table::Symbol, region::Symbol;
    default::Float64=0.0)
    return _full_table_value(data.derived, table, (region,); default=default)
end

function _full_regional_elasticity(data::GTAP7FullData, table::Symbol, region::Symbol;
    default::Float64=0.0)
    return _full_table_value(data.elasticities, table, (region,); default=default)
end

function _full_final_demand_start(data::GTAP7FullData, region::Symbol,
    product::Symbol, agent::Symbol)
    return max(_full_purchaser_value(data, region, product, agent), 0.0)
end

function _full_income_seed(data::GTAP7FullData, region::Symbol)
    return _full_regional_value(data, :yc_share_reg, region; default=0.0) *
           _full_regional_value(data, :regy_bench, region; default=0.0)
end

function _full_global_return_seed(data::GTAP7FullData)
    numerator = 0.0
    denominator = 0.0
    capital_factors = [factor for factor in data.factors
        if lowercase(String(factor)) in ("capital", "cap", "k", "kap")]
    for region in data.regions
        capital_stock = _full_table_value(data.benchmark, :vkb, (region,))
        investment = sum(
            _full_table_value(data.benchmark, :vdip, (region, product)) +
            _full_table_value(data.benchmark, :vmip, (region, product))
            for product in data.products)
        capital_return = sum(
            (1.0 - _full_kappaf(data, region, factor, activity)) *
            _full_table_value(data.benchmark, :evfb, (region, factor, activity);
                default=_full_table_value(data.benchmark, :vfm, (region, factor, activity))) /
            _full_table_value(data.derived, :xscale, (region, activity); default=1.0)
            for factor in capital_factors for activity in data.activities)
        asset_return = capital_stock > 0.0 ? capital_return / capital_stock : 0.0
        current_return = asset_return - _full_regional_value(data, :fdepr, region)
        capital_endowment = (1.0 - _full_regional_value(data, :depr, region)) *
            capital_stock + investment
        expected_return = capital_endowment > 0.0 ? current_return *
            (capital_stock / capital_endowment) ^ _full_regional_value(data, :rorflex, region) :
            current_return
        net_investment = investment - _full_regional_value(data, :depr, region) * capital_stock
        numerator += expected_return * net_investment
        denominator += net_investment
    end
    return numerator / (denominator + 1.0e-12)
end

function JCGECore.build!(block::GTAP7DemandUtilityBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    for region in data.regions
        income_seed = max(_full_income_seed(data, region), 1.0e-8)
        investment_seed = sum(_full_final_demand_start(data, region, product, :inv)
            for product in data.products)
        _full_variable!(ctx, model, :xiagg, region; lower=1.0e-8,
            start=max(investment_seed, 1.0e-8))
        for name in (:pcons, :pi, :pg, :uh, :ug, :us, :u, :psave)
            _full_variable!(ctx, model, name, region; lower=1.0e-8, start=1.0)
        end
        _full_variable!(ctx, model, :phip, region; lower=0.0,
            start=max(_full_regional_value(data, :phip0, region; default=1.0), 0.0))
        _full_variable!(ctx, model, :phi, region; lower=0.0,
            start=max(_full_regional_value(data, :phi0, region; default=1.0), 0.0))
        _full_variable!(ctx, model, :xg_agg, region; lower=0.0,
            start=sum(_full_final_demand_start(data, region, product, :gov)
                for product in data.products))
        _full_variable!(ctx, model, :savf, region; lower=-Inf,
            start=_full_regional_value(data, :savf_bar, region))
        _full_variable!(ctx, model, :chif, region; lower=-Inf,
            start=_full_regional_value(data, :chif0, region))
        _full_variable!(ctx, model, :ev, region; lower=1.0e-8, start=income_seed)
        _full_variable!(ctx, model, :cv, region; lower=1.0e-8, start=income_seed)
        for product in data.products
            _full_variable!(ctx, model, :xc, region, product; lower=0.0,
                start=_full_final_demand_start(data, region, product, :hhd))
            _full_variable!(ctx, model, :xg, region, product; lower=0.0,
                start=_full_final_demand_start(data, region, product, :gov))
            _full_variable!(ctx, model, :xi, region, product; lower=0.0,
                start=_full_final_demand_start(data, region, product, :inv))
            _full_variable!(ctx, model, :xcshr, region, product; lower=0.0,
                start=_full_table_value(data.derived, :c_share, (region, product)))
            _full_variable!(ctx, model, :zcons, region, product; lower=0.0,
                start=max(_full_table_value(data.derived, :zcons_init, (region, product)), 0.0))
        end
    end
    net_investment = sum(
        sum(_full_final_demand_start(data, region, product, :inv) for product in data.products) -
        _full_regional_value(data, :depr, region) * _full_table_value(data.benchmark, :vkb, (region,))
        for region in data.regions)
    _full_variable!(ctx, model, :xigbl; lower=1.0e-8, start=max(net_investment, 1.0e-8))
    _full_variable!(ctx, model, :pigbl; lower=1.0e-8, start=1.0)
    _full_variable!(ctx, model, :chiSave; lower=1.0e-8, start=1.0)
    _full_variable!(ctx, model, :rorg; lower=1.0e-8,
        start=max(_full_global_return_seed(data), 1.0e-8))

    for region in data.regions, product in data.products
        key = (region, product)
        c_share = _full_table_value(data.derived, :c_share, key)
        g_share = _full_table_value(data.derived, :g_share, key)
        i_share = _full_table_value(data.derived, :i_share, key)
        if c_share <= 0.0
            _register_full_equation!(ctx, block, :private_demand, region, product;
                info="GTAP private demand is zero for an inactive commodity", expr=EEq(
                    EVar(:xc, Any[region, product]), EConst(0.0)))
        else
            _register_full_equation!(ctx, block, :private_demand, region, product;
                info="GTAP CDE private demand at purchaser prices", expr=EEq(
                    EMul([EVar(:pa, Any[region, product, :hhd]), EVar(:xc, Any[region, product])]),
                    EMul([EVar(:xcshr, Any[region, product]), EVar(:yc, Any[region])]),
                ))
        end
        if g_share <= 0.0
            _register_full_equation!(ctx, block, :government_demand, region, product;
                info="GTAP government demand is zero for an inactive commodity", expr=EEq(
                    EVar(:xg, Any[region, product]), EConst(0.0)))
        else
            sigma = _full_regional_elasticity(data, :esubg, region; default=1.0)
            isapprox(sigma, 1.0; atol=1.0e-8) && (sigma = 1.01)
            _register_full_equation!(ctx, block, :government_demand, region, product;
                info="GTAP CES allocation of government expenditure", expr=EEq(
                    EVar(:xg, Any[region, product]), EMul([
                        EConst(g_share), EVar(:xg_agg, Any[region]),
                        EPow(EDiv(EVar(:pg, Any[region]),
                            EAdd([EVar(:pa, Any[region, product, :gov]), EConst(1.0e-12)])),
                            EConst(sigma)),
                    ])))
        end
        if i_share <= 0.0
            _register_full_equation!(ctx, block, :investment_demand, region, product;
                info="GTAP investment demand is zero for an inactive commodity", expr=EEq(
                    EVar(:xi, Any[region, product]), EConst(0.0)))
        else
            sigma = _full_regional_elasticity(data, :esubi, region; default=0.0)
            isapprox(sigma, 1.0; atol=1.0e-8) && (sigma = 1.01)
            _register_full_equation!(ctx, block, :investment_demand, region, product;
                info="GTAP CES allocation of regional investment", expr=EEq(
                    EVar(:xi, Any[region, product]), EMul([
                        EConst(i_share), EVar(:xiagg, Any[region]),
                        EPow(EDiv(EVar(:pi, Any[region]),
                            EAdd([EVar(:pa, Any[region, product, :inv]), EConst(1.0e-12)])),
                            EConst(sigma)),
                    ])))
        end

        alpha = _full_table_value(data.derived, :alphaa_hhd, key)
        bh = _full_table_value(data.derived, :bh, key)
        eh = _full_table_value(data.derived, :eh, key)
        if c_share <= 0.0 || alpha <= 0.0
            _register_full_equation!(ctx, block, :cde_weight, region, product;
                info="GTAP CDE weight is zero for an inactive commodity", expr=EEq(
                    EVar(:zcons, Any[region, product]), EConst(0.0)))
            _register_full_equation!(ctx, block, :cde_budget_share, region, product;
                info="GTAP CDE budget share is zero for an inactive commodity", expr=EEq(
                    EVar(:xcshr, Any[region, product]), EConst(0.0)))
        else
            cde_weight = EMul([
                EConst(alpha * bh),
                EPow(EVar(:pa, Any[region, product, :hhd]), EConst(bh)),
                EPow(EVar(:uh, Any[region]), EConst(eh * bh)),
                EPow(EDiv(EVar(:yc, Any[region]), EConst(_full_regional_value(data, :pop, region))),
                    EConst(-bh)),
            ])
            _register_full_equation!(ctx, block, :cde_weight, region, product;
                info="GTAP CDE private-consumption weight", expr=EEq(
                    EVar(:zcons, Any[region, product]), cde_weight))
            active_zcons = [EVar(:zcons, Any[region, good]) for good in data.products
                if _full_table_value(data.derived, :c_share, (region, good)) > 0.0]
            _register_full_equation!(ctx, block, :cde_budget_share, region, product;
                info="GTAP CDE private-consumption budget share", expr=EEq(
                    EMul([EVar(:xcshr, Any[region, product]), _full_sum(active_zcons)]),
                    EVar(:zcons, Any[region, product])))
        end
    end

    for region in data.regions
        _register_full_equation!(ctx, block, :investment_income, region;
            info="GTAP investment expenditure equals investment income", expr=EEq(
                EMul([EVar(:pi, Any[region]), EVar(:xiagg, Any[region])]), EVar(:yi, Any[region])))
        active_consumption = [product for product in data.products
            if _full_table_value(data.derived, :c_share, (region, product)) > 0.0]
        _register_full_equation!(ctx, block, :cde_income_elasticity, region;
            info="GTAP CDE aggregate income-elasticity index", expr=EEq(
                EVar(:phip, Any[region]), _full_sum([
                    EMul([EVar(:xcshr, Any[region, product]),
                        EConst(_full_table_value(data.derived, :eh, (region, product)))])
                    for product in active_consumption
                ])))
        _register_full_equation!(ctx, block, :income_split_index, region;
            info="GTAP consumption, government, and savings income split", expr=EEq(
                EMul([EVar(:phi, Any[region]), EAdd([
                    EDiv(EConst(_full_regional_value(data, :betap, region)),
                        EAdd([EVar(:phip, Any[region]), EConst(1.0e-12)])),
                    EConst(_full_regional_value(data, :betag, region)),
                    EConst(_full_regional_value(data, :betas, region)),
                ])]), EConst(1.0)))
        _register_full_equation!(ctx, block, :private_price_index, region;
            info="GTAP CDE private-consumption price index", expr=EEq(
                EVar(:pcons, Any[region]), _full_sum([
                    EMul([EVar(:xcshr, Any[region, product]),
                        EVar(:pa, Any[region, product, :hhd])]) for product in data.products
                ])))
        investment_sigma = _full_regional_elasticity(data, :esubi, region; default=0.0)
        isapprox(investment_sigma, 1.0; atol=1.0e-8) && (investment_sigma = 1.01)
        investment_exponent = 1.0 - investment_sigma
        active_investment = [product for product in data.products
            if _full_table_value(data.derived, :i_share, (region, product)) > 0.0]
        investment_price = isempty(active_investment) ?
            EEq(EVar(:pi, Any[region]), EConst(1.0)) :
            EEq(EPow(EMul([EConst(_full_regional_value(data, :axi, region)), EVar(:pi, Any[region])]),
                    EConst(investment_exponent)),
                _full_sum([
                    EMul([EConst(_full_table_value(data.derived, :i_share, (region, product))),
                        EPow(EVar(:pa, Any[region, product, :inv]), EConst(investment_exponent))])
                    for product in active_investment
                ]))
        _register_full_equation!(ctx, block, :investment_price_index, region;
            info="GTAP investment CES price index", expr=investment_price)
        cde_terms = JCGECore.EquationExpr[]
        for product in active_consumption
            key = (region, product)
            alpha = _full_table_value(data.derived, :alphaa_hhd, key)
            alpha <= 0.0 && continue
            bh = _full_table_value(data.derived, :bh, key)
            eh = _full_table_value(data.derived, :eh, key)
            push!(cde_terms, EMul([
                EConst(alpha), EPow(EVar(:pa, Any[region, product, :hhd]), EConst(bh)),
                EPow(EVar(:uh, Any[region]), EConst(eh * bh)),
                EPow(EDiv(EVar(:yc, Any[region]), EConst(_full_regional_value(data, :pop, region))),
                    EConst(-bh)),
            ]))
        end
        utility = isempty(cde_terms) ? EEq(EVar(:uh, Any[region]), EConst(1.0)) :
            EEq(_full_sum(cde_terms), EConst(1.0))
        _register_full_equation!(ctx, block, :private_utility, region;
            info="GTAP CDE private-consumption utility", expr=utility)
        government_sigma = _full_regional_elasticity(data, :esubg, region; default=1.0)
        isapprox(government_sigma, 1.0; atol=1.0e-8) && (government_sigma = 1.01)
        government_exponent = 1.0 - government_sigma
        active_government = [product for product in data.products
            if _full_table_value(data.derived, :g_share, (region, product)) > 0.0]
        _register_full_equation!(ctx, block, :government_price_index, region;
            info="GTAP government CES price index", expr=EEq(
                EPow(EVar(:pg, Any[region]), EConst(government_exponent)), _full_sum([
                    EMul([EConst(_full_table_value(data.derived, :g_share, (region, product))),
                        EPow(EVar(:pa, Any[region, product, :gov]), EConst(government_exponent))])
                    for product in active_government
                ])))
        _register_full_equation!(ctx, block, :government_expenditure, region;
            info="GTAP aggregate government expenditure", expr=EEq(
                EMul([EVar(:pg, Any[region]), EVar(:xg_agg, Any[region])]), EVar(:yg, Any[region])))
        _register_full_equation!(ctx, block, :government_utility, region;
            info="GTAP per-capita government utility", expr=EEq(EVar(:ug, Any[region]),
                EDiv(EMul([EConst(_full_regional_value(data, :aug, region)),
                    EVar(:xg_agg, Any[region])]), EConst(_full_regional_value(data, :pop, region)))))
        _register_full_equation!(ctx, block, :savings_price, region;
            info="GTAP savings price", expr=EEq(EVar(:psave, Any[region]),
                EMul([EVar(:chiSave, Any[]), EVar(:pi, Any[region])])))
        _register_full_equation!(ctx, block, :savings_utility, region;
            info="GTAP per-capita savings utility", expr=EEq(EVar(:us, Any[region]),
                EDiv(EMul([EConst(_full_regional_value(data, :aus, region)), EVar(:rsav, Any[region])]),
                    EAdd([EMul([EVar(:psave, Any[region]), EConst(_full_regional_value(data, :pop, region))]), EConst(1.0e-12)]))))
        betap = _full_regional_value(data, :betap, region)
        betag = _full_regional_value(data, :betag, region)
        betas = _full_regional_value(data, :betas, region)
        utility_factors = JCGECore.EquationExpr[
            EConst(_full_regional_value(data, :au, region)),
            EPow(EVar(:uh, Any[region]), EConst(betap)),
            EPow(EVar(:ug, Any[region]), EConst(betag)),
        ]
        abs(betas) > 1.0e-12 && push!(utility_factors, EPow(EVar(:us, Any[region]), EConst(betas)))
        _register_full_equation!(ctx, block, :regional_utility, region;
            info="GTAP regional utility aggregate", expr=EEq(EVar(:u, Any[region]),
                _full_product(utility_factors)))
        if region != block.residual_region
            _register_full_equation!(ctx, block, :foreign_savings, region;
                info="GTAP standard capital-account allocation", expr=EEq(EVar(:savf, Any[region]),
                    EMul([EVar(:pigbl, Any[]), EConst(_full_regional_value(data, :savf_bar, region))])))
        end
        _register_full_equation!(ctx, block, :foreign_savings_share, region;
            info="GTAP foreign savings share of regional income", expr=EEq(EVar(:savf, Any[region]),
                EMul([EVar(:chif, Any[region]), EVar(:regy, Any[region])])))
        _register_full_equation!(ctx, block, :capital_endowment, region;
            info="GTAP next-period capital endowment", expr=EEq(EVar(:kapEnd, Any[region]),
                EAdd([
                    EMul([EConst(1.0 - _full_regional_value(data, :depr, region)),
                        EVar(:kstock, Any[region])]),
                    EVar(:xiagg, Any[region]),
                ])))
        capital_factors = [factor for factor in data.factors
            if lowercase(String(factor)) in ("capital", "cap", "k", "kap")]
        capital_return = _full_sum([
            EDiv(EMul([
                EConst(1.0 - _full_kappaf(data, region, factor, activity)),
                EVar(:pf, Any[region, factor, activity]), EVar(:xf, Any[region, factor, activity]),
            ]), EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)))
            for factor in capital_factors for activity in data.activities
        ])
        _register_full_equation!(ctx, block, :asset_return, region;
            info="GTAP regional capital rental return", expr=EEq(EVar(:arent, Any[region]),
                EDiv(capital_return, EAdd([EVar(:kstock, Any[region]), EConst(1.0e-12)]))))
        _register_full_equation!(ctx, block, :capital_return_current, region;
            info="GTAP current real return to capital", expr=EEq(EVar(:rorc, Any[region]),
                EAdd([EDiv(EVar(:arent, Any[region]), EAdd([EVar(:pi, Any[region]), EConst(1.0e-12)])),
                    EConst(-_full_regional_value(data, :fdepr, region))])))
        _register_full_equation!(ctx, block, :capital_return_expected, region;
            info="GTAP expected real return to capital", expr=EEq(EVar(:rore, Any[region]),
                EMul([EVar(:rorc, Any[region]), EPow(EDiv(EVar(:kstock, Any[region]),
                    EAdd([EVar(:kapEnd, Any[region]), EConst(1.0e-12)])),
                    EConst(_full_regional_value(data, :rorflex, region)))])))
    end

    _register_full_equation!(ctx, block, :global_savings_price;
        info="GTAP global savings price adjustment", expr=EEq(
            EMul([EPow(EVar(:chiSave, Any[]), EConst(2.0)), _full_sum([
                EMul([EConst(_full_regional_value(data, :savwgt, region)), EVar(:pi, Any[region])])
                for region in data.regions
            ])]), _full_sum([
                EMul([EConst(_full_regional_value(data, :invwgt, region)), EVar(:pi, Any[region])])
                for region in data.regions
            ])))
    net_investment_terms = [
        EAdd([
            EVar(:xiagg, Any[region]),
            ENeg(EMul([EConst(_full_regional_value(data, :depr, region)), EVar(:kstock, Any[region])])),
        ]) for region in data.regions
    ]
    _register_full_equation!(ctx, block, :global_investment_value;
        info="GTAP global net-investment value", expr=EEq(
            EMul([EVar(:pigbl, Any[]), EVar(:xigbl, Any[])]), _full_sum([
                EMul([EVar(:pi, Any[region]), net]) for (region, net) in zip(data.regions, net_investment_terms)
            ])))
    _register_full_equation!(ctx, block, :global_investment_quantity;
        info="GTAP global net-investment quantity", expr=EEq(EVar(:xigbl, Any[]),
            _full_sum(net_investment_terms)))
    _register_full_equation!(ctx, block, :capital_account;
        info="GTAP global foreign-savings balance", expr=EEq(_full_sum([
            EVar(:savf, Any[region]) for region in data.regions
        ]), EConst(0.0)))
    net_value_terms = [
        EMul([EVar(:pi, Any[region]), net]) for (region, net) in zip(data.regions, net_investment_terms)
    ]
    _register_full_equation!(ctx, block, :global_return;
        info="GTAP globally weighted expected return", expr=EEq(EVar(:rorg, Any[]), EDiv(
            _full_sum([EMul([EVar(:rore, Any[region]), value])
                for (region, value) in zip(data.regions, net_value_terms)]),
            EAdd([_full_sum(net_value_terms), EConst(1.0e-12)]))))
    return nothing
end

"""GTAP Standard 7 regional income, tax revenue, GDP, and welfare block."""
struct GTAP7IncomeBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
    residual_region::Symbol
end

const GTAP7_TAX_STREAMS = (:pt, :ft, :fs, :fc, :pc, :gc, :ic, :et, :mt, :dt)

function _full_scaled_factor_term(data::GTAP7FullData, region::Symbol,
    factor::Symbol, activity::Symbol, expression::JCGECore.EquationExpr)
    return EDiv(expression, EConst(_full_table_value(data.derived, :xscale,
        (region, activity); default=1.0)))
end

function _full_gdp_seed(data::GTAP7FullData, region::Symbol)
    absorption = sum(_full_purchaser_value(data, region, product, agent)
        for product in data.products for agent in GTAP7_FINAL_AGENTS)
    trade = sum(
        _full_table_value(data.benchmark, :vxsb, (region, product, partner)) -
        _full_table_value(data.benchmark, :vcif, (partner, product, region))
        for product in data.products for partner in data.regions)
    return max(absorption + trade, 1.0e-8)
end

function JCGECore.build!(block::GTAP7IncomeBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    for region in data.regions
        regy_seed = _full_regional_value(data, :regy_bench, region)
        yc_seed = _full_income_seed(data, region)
        yg_seed = _full_regional_value(data, :yg_share_reg, region) * regy_seed
        yi_seed = sum(_full_final_demand_start(data, region, product, :inv)
            for product in data.products)
        gdp_seed = _full_gdp_seed(data, region)
        for (name, value) in ((:regy, regy_seed), (:yc, yc_seed), (:yg, yg_seed),
                (:yi, yi_seed), (:rsav, 0.0), (:facty, regy_seed),
                (:ytaxTot, 0.0), (:ytax_ind, 0.0))
            _full_variable!(ctx, model, name, region; lower=-Inf, start=value)
        end
        _full_variable!(ctx, model, :gdpmp, region; lower=0.0, start=gdp_seed)
        _full_variable!(ctx, model, :rgdpmp, region; lower=0.0, start=gdp_seed)
        _full_variable!(ctx, model, :pgdpmp, region; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :pabs, region; lower=1.0e-8, start=1.0)
        _full_variable!(ctx, model, :ev, region; lower=1.0e-8, start=max(yc_seed, 1.0e-8))
        _full_variable!(ctx, model, :cv, region; lower=1.0e-8, start=max(yc_seed, 1.0e-8))
        for stream in GTAP7_TAX_STREAMS
            _full_variable!(ctx, model, :ytax, region, stream; lower=-Inf, start=0.0)
            _full_variable!(ctx, model, :ytaxshr, region, stream; lower=-Inf, start=0.0)
        end
    end

    outputs_by_activity = _full_outputs_by_activity(data)
    for region in data.regions
        factor_income = _full_sum([
            _full_scaled_factor_term(data, region, factor, activity,
                EMul([EVar(:pf, Any[region, factor, activity]),
                    EVar(:xf, Any[region, factor, activity])]))
            for factor in data.factors for activity in data.activities
            if _full_table_value(data.derived, :xfflag, (region, factor, activity)) > 0.0
        ])
        _register_full_equation!(ctx, block, :factor_income, region;
            info="GTAP regional factor income net of capital depreciation", expr=EEq(
                EVar(:facty, Any[region]), EAdd([
                    factor_income,
                    ENeg(EMul([
                        EConst(_full_regional_value(data, :fdepr, region)),
                        EVar(:pi, Any[region]), EVar(:kstock, Any[region]),
                    ])),
                ])))

        for stream in GTAP7_TAX_STREAMS
            tax_expression = if stream == :pt
                _full_sum([
                    EMul([
                        EConst(_full_table_value(data.derived, :prdtx_rai,
                            (region, activity, product))),
                        EVar(:p_rai, Any[region, activity, product]),
                        EVar(:x, Any[region, activity, product]),
                    ]) for activity in data.activities for product in outputs_by_activity[activity]
                    if _full_table_value(data.derived, :xflag, (region, activity, product)) > 0.0
                ])
            elseif stream == :ft || stream == :fs
                table = stream == :ft ? :fcttx : :fctts
                _full_sum([
                    _full_scaled_factor_term(data, region, factor, activity,
                        EMul([
                            EConst(_full_table_value(data.derived, table, (region, factor, activity))),
                            EVar(:pf, Any[region, factor, activity]),
                            EVar(:xf, Any[region, factor, activity]),
                        ]))
                    for factor in data.factors for activity in data.activities
                ])
            elseif stream in (:fc, :pc, :gc, :ic)
                agents = stream == :fc ? data.activities :
                    stream == :pc ? [:hhd] : stream == :gc ? [:gov] : [:inv]
                terms = JCGECore.EquationExpr[]
                for agent in agents, product in data.products
                    scale = agent in data.activities ?
                        _full_table_value(data.derived, :xscale, (region, agent); default=1.0) : 1.0
                    push!(terms, EDiv(EMul([
                        EConst(_full_table_value(data.taxes, :dintx0, (region, product, agent))),
                        EVar(:pd, Any[region, product]), EVar(:xda, Any[region, product, agent]),
                    ]), EConst(scale)))
                    push!(terms, EDiv(EMul([
                        EConst(_full_table_value(data.taxes, :mintx0, (region, product, agent))),
                        EVar(:pmt, Any[region, product]), EVar(:xma, Any[region, product, agent]),
                    ]), EConst(scale)))
                end
                _full_sum(terms)
            elseif stream == :et
                _full_sum([
                    EMul([
                        EConst(_full_table_value(data.taxes, :rtxs, (region, product, destination))),
                        EVar(:pe, Any[region, product, destination]),
                        EVar(:xw, Any[region, product, destination]),
                    ]) for product in data.products for destination in data.regions
                ])
            elseif stream == :mt
                _full_sum([
                    EMul([
                        EConst(_full_table_value(data.taxes, :imptx, (origin, product, region))),
                        EVar(:pmcif, Any[origin, product, region]),
                        EVar(:xw, Any[origin, product, region]),
                    ]) for product in data.products for origin in data.regions
                ])
            elseif stream == :dt
                _full_sum([
                    _full_scaled_factor_term(data, region, factor, activity,
                        EMul([
                            EConst(_full_kappaf(data, region, factor, activity)),
                            EVar(:pf, Any[region, factor, activity]),
                            EVar(:xf, Any[region, factor, activity]),
                        ]))
                    for factor in data.factors for activity in data.activities
                ])
            else
                EConst(0.0)
            end
            _register_full_equation!(ctx, block, :tax_revenue, region, stream;
                info="GTAP $(stream) tax-revenue stream", expr=EEq(
                    EVar(:ytax, Any[region, stream]), tax_expression))
        end
        _register_full_equation!(ctx, block, :total_tax_revenue, region;
            info="GTAP total regional tax revenue", expr=EEq(EVar(:ytaxTot, Any[region]),
                _full_sum([EVar(:ytax, Any[region, stream]) for stream in GTAP7_TAX_STREAMS])))
        _register_full_equation!(ctx, block, :indirect_tax_revenue, region;
            info="GTAP regional tax revenue excluding direct factor taxes", expr=EEq(
                EVar(:ytax_ind, Any[region]), EAdd([
                    EVar(:ytaxTot, Any[region]), ENeg(EVar(:ytax, Any[region, :dt])),
                ])))
        _register_full_equation!(ctx, block, :regional_income, region;
            info="GTAP regional income equals factor plus indirect-tax income", expr=EEq(
                EVar(:regy, Any[region]), EAdd([
                    EVar(:facty, Any[region]), EVar(:ytax_ind, Any[region]),
                ])))
        for stream in GTAP7_TAX_STREAMS
            _register_full_equation!(ctx, block, :tax_revenue_share, region, stream;
                info="GTAP tax-revenue share of regional income", expr=EEq(
                    EVar(:ytaxshr, Any[region, stream]), EDiv(EVar(:ytax, Any[region, stream]),
                        EAdd([EVar(:regy, Any[region]), EConst(1.0e-12)]))))
        end
        _register_full_equation!(ctx, block, :private_income, region;
            info="GTAP private income from regional income", expr=EEq(EVar(:yc, Any[region]),
                EMul([
                    EConst(_full_regional_value(data, :betap, region)),
                    EDiv(EVar(:phi, Any[region]), EVar(:phip, Any[region])),
                    EVar(:regy, Any[region]),
                ])))
        _register_full_equation!(ctx, block, :government_income, region;
            info="GTAP government income from regional income", expr=EEq(EVar(:yg, Any[region]),
                EMul([EConst(_full_regional_value(data, :betag, region)),
                    EVar(:phi, Any[region]), EVar(:regy, Any[region])])))
        if region != block.residual_region
            _register_full_equation!(ctx, block, :investment_income_balance, region;
                info="GTAP investment income under the standard capital closure", expr=EEq(
                    EVar(:yi, Any[region]), EAdd([
                        EMul([EVar(:pi, Any[region]),
                            EConst(_full_regional_value(data, :depr, region)),
                            EVar(:kstock, Any[region])]),
                        EVar(:rsav, Any[region]), EVar(:savf, Any[region]),
                    ])))
        end
        _register_full_equation!(ctx, block, :regional_savings, region;
            info="GTAP regional savings from the calibrated income split", expr=EEq(
                EVar(:rsav, Any[region]), EMul([
                    EConst(_full_regional_value(data, :betas, region)),
                    EVar(:phi, Any[region]), EVar(:regy, Any[region]),
                ])))

        base_absorption = sum(_full_purchaser_value(data, region, product, agent)
            for product in data.products for agent in GTAP7_FINAL_AGENTS)
        if base_absorption > 1.0e-12
            abs_t0 = _full_sum([
                EMul([EVar(:pa, Any[region, product, agent]),
                    EConst(_full_purchaser_value(data, region, product, agent))])
                for product in data.products for agent in GTAP7_FINAL_AGENTS
            ])
            abs_tt = _full_sum([
                EMul([EVar(:pa, Any[region, product, agent]),
                    EVar(:xaa, Any[region, product, agent])])
                for product in data.products for agent in GTAP7_FINAL_AGENTS
            ])
            abs_0t = _full_sum([
                EVar(:xaa, Any[region, product, agent])
                for product in data.products for agent in GTAP7_FINAL_AGENTS
            ])
            _register_full_equation!(ctx, block, :absorption_price_index, region;
                info="GTAP Fisher absorption price index", expr=EEq(EVar(:pabs, Any[region]),
                    EPow(EMul([
                        EDiv(abs_t0, EConst(base_absorption)),
                        EDiv(abs_tt, EAdd([abs_0t, EConst(1.0e-12)])),
                    ]), EConst(0.5))))
        end
        absorption_live = _full_sum([
            EMul([EVar(:pa, Any[region, product, agent]), EVar(:xaa, Any[region, product, agent])])
            for product in data.products for agent in GTAP7_FINAL_AGENTS
        ])
        trade_live = _full_sum([
            EAdd([
                EMul([EVar(:pefob, Any[region, product, partner]),
                    EVar(:xw, Any[region, product, partner])]),
                ENeg(EMul([EVar(:pmcif, Any[partner, product, region]),
                    EVar(:xw, Any[partner, product, region])])),
            ]) for product in data.products for partner in data.regions
        ])
        _register_full_equation!(ctx, block, :gdp_market_prices, region;
            info="GTAP GDP at market prices", expr=EEq(EVar(:gdpmp, Any[region]),
                EAdd([absorption_live, trade_live])))
        _register_full_equation!(ctx, block, :real_gdp, region;
            info="GTAP base-period real GDP", expr=EEq(EVar(:rgdpmp, Any[region]),
                EVar(:gdpmp, Any[region])))
        _register_full_equation!(ctx, block, :gdp_price_index, region;
            info="GTAP GDP price index", expr=EEq(
                EMul([EVar(:pgdpmp, Any[region]), EVar(:rgdpmp, Any[region])]),
                EVar(:gdpmp, Any[region])))
        ev_terms = JCGECore.EquationExpr[]
        cv_terms = JCGECore.EquationExpr[]
        for product in data.products
            key = (region, product)
            alpha = _full_table_value(data.derived, :alphaa_hhd, key)
            bh = _full_table_value(data.derived, :bh, key)
            eh = _full_table_value(data.derived, :eh, key)
            c_share = _full_table_value(data.derived, :c_share, key)
            alpha > 0.0 && c_share > 0.0 || continue
            population = _full_regional_value(data, :pop, region)
            push!(ev_terms, EMul([
                EConst(alpha), EPow(EVar(:uh, Any[region]), EConst(bh * eh)),
                EPow(EDiv(EConst(population), EVar(:ev, Any[region])), EConst(bh)),
            ]))
            push!(cv_terms, EMul([
                EConst(alpha), EPow(EDiv(EMul([
                    EVar(:pa, Any[region, product, :hhd]), EConst(population)]),
                    EVar(:cv, Any[region])), EConst(bh)),
            ]))
        end
        isempty(ev_terms) || _register_full_equation!(ctx, block, :equivalent_variation, region;
            info="GTAP equivalent-variation welfare measure", expr=EEq(_full_sum(ev_terms), EConst(1.0)))
        isempty(cv_terms) || _register_full_equation!(ctx, block, :compensating_variation, region;
            info="GTAP compensating-variation welfare measure", expr=EEq(_full_sum(cv_terms), EConst(1.0)))
    end
    return nothing
end

"""GTAP Standard 7 Fisher factor-price closure, numeraire, and Walras residual."""
struct GTAP7ClosureBlock <: JCGECore.AbstractBlock
    name::Symbol
    data::GTAP7FullData
    residual_region::Symbol
end

function _full_factor_price_seed(data::GTAP7FullData, region::Symbol,
    factor::Symbol, activity::Symbol)
    return max(1.0 / max(1.0 - _full_kappaf(data, region, factor, activity), 1.0e-8), 1.0e-8)
end

function _full_factor_quantity_seed(data::GTAP7FullData, region::Symbol,
    factor::Symbol, activity::Symbol)
    value = _full_table_value(data.benchmark, :evfb, (region, factor, activity);
        default=_full_table_value(data.benchmark, :vfm, (region, factor, activity)))
    return max(value / _full_factor_price_seed(data, region, factor, activity), 0.0)
end

function JCGECore.build!(block::GTAP7ClosureBlock,
    ctx::JCGERuntime.KernelContext, spec::JCGECore.RunSpec)
    data = block.data
    model = ctx.model
    regional_base = Dict{Symbol,Float64}()
    for region in data.regions
        base = sum(
            _full_factor_price_seed(data, region, factor, activity) *
            _full_factor_quantity_seed(data, region, factor, activity) /
            _full_table_value(data.derived, :xscale, (region, activity); default=1.0)
            for factor in data.factors for activity in data.activities)
        regional_base[region] = base > 0.0 ? base : 1.0
        for name in (:mfr_bs, :mfr_sb, :mfr_ss)
            _full_variable!(ctx, model, name, region; lower=-Inf, start=regional_base[region])
        end
        _full_variable!(ctx, model, :pfact, region; lower=1.0e-3, start=1.0)
    end
    world_base = sum(values(regional_base))
    for name in (:mfw_bs, :mfw_sb, :mfw_ss)
        _full_variable!(ctx, model, name; lower=-Inf, start=max(world_base, 1.0))
    end
    _full_variable!(ctx, model, :pwfact; lower=1.0e-3, start=1.0)
    _full_variable!(ctx, model, :pnum; lower=1.0e-3, start=1.0)
    _full_variable!(ctx, model, :walras; lower=-Inf, start=0.0)

    for region in data.regions
        base_factor_price_quantity = [
            EConst(_full_factor_price_seed(data, region, factor, activity) /
                _full_table_value(data.derived, :xscale, (region, activity); default=1.0))
            for factor in data.factors for activity in data.activities
        ]
        live_quantity = [EVar(:xf, Any[region, factor, activity])
            for factor in data.factors for activity in data.activities]
        live_price_base_quantity = [
            EMul([
                EVar(:pf, Any[region, factor, activity]),
                EConst(_full_factor_quantity_seed(data, region, factor, activity) /
                    _full_table_value(data.derived, :xscale, (region, activity); default=1.0)),
            ]) for factor in data.factors for activity in data.activities
        ]
        live_price_quantity = [
            EDiv(EMul([
                EVar(:pf, Any[region, factor, activity]),
                EVar(:xf, Any[region, factor, activity]),
            ]), EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)))
            for factor in data.factors for activity in data.activities
        ]
        _register_full_equation!(ctx, block, :regional_fisher_base_quantity, region;
            info="GTAP regional Fisher factor-price base-quantity aggregate", expr=EEq(
                EVar(:mfr_bs, Any[region]), _full_sum([
                    EMul([factor_price, quantity])
                    for (factor_price, quantity) in zip(base_factor_price_quantity, live_quantity)
                ])))
        _register_full_equation!(ctx, block, :regional_fisher_base_price, region;
            info="GTAP regional Fisher factor-price base-price aggregate", expr=EEq(
                EVar(:mfr_sb, Any[region]), _full_sum(live_price_base_quantity)))
        _register_full_equation!(ctx, block, :regional_fisher_current, region;
            info="GTAP regional Fisher factor-price current aggregate", expr=EEq(
                EVar(:mfr_ss, Any[region]), _full_sum(live_price_quantity)))
        _register_full_equation!(ctx, block, :regional_factor_price_index, region;
            info="GTAP regional Fisher factor-price index", expr=EEq(
                EVar(:pfact, Any[region]), EPow(EMul([
                    EDiv(EVar(:mfr_sb, Any[region]), EConst(regional_base[region])),
                    EDiv(EVar(:mfr_ss, Any[region]),
                        EAdd([EVar(:mfr_bs, Any[region]), EConst(1.0e-12)])),
                ]), EConst(0.5))))
    end

    world_base_price_quantity = [
        EConst(_full_factor_price_seed(data, region, factor, activity) /
            _full_table_value(data.derived, :xscale, (region, activity); default=1.0))
        for region in data.regions for factor in data.factors for activity in data.activities
    ]
    world_live_quantity = [EVar(:xf, Any[region, factor, activity])
        for region in data.regions for factor in data.factors for activity in data.activities]
    world_live_price_base_quantity = [
        EMul([
            EVar(:pf, Any[region, factor, activity]),
            EConst(_full_factor_quantity_seed(data, region, factor, activity) /
                _full_table_value(data.derived, :xscale, (region, activity); default=1.0)),
        ]) for region in data.regions for factor in data.factors for activity in data.activities
    ]
    world_live_price_quantity = [
        EDiv(EMul([
            EVar(:pf, Any[region, factor, activity]), EVar(:xf, Any[region, factor, activity]),
        ]), EConst(_full_table_value(data.derived, :xscale, (region, activity); default=1.0)))
        for region in data.regions for factor in data.factors for activity in data.activities
    ]
    _register_full_equation!(ctx, block, :world_fisher_base_quantity;
        info="GTAP world Fisher factor-price base-quantity aggregate", expr=EEq(
            EVar(:mfw_bs, Any[]), _full_sum([
                EMul([factor_price, quantity])
                for (factor_price, quantity) in zip(world_base_price_quantity, world_live_quantity)
            ])))
    _register_full_equation!(ctx, block, :world_fisher_base_price;
        info="GTAP world Fisher factor-price base-price aggregate", expr=EEq(
            EVar(:mfw_sb, Any[]), _full_sum(world_live_price_base_quantity)))
    _register_full_equation!(ctx, block, :world_fisher_current;
        info="GTAP world Fisher factor-price current aggregate", expr=EEq(
            EVar(:mfw_ss, Any[]), _full_sum(world_live_price_quantity)))
    _register_full_equation!(ctx, block, :world_factor_price_index;
        info="GTAP world Fisher factor-price index", expr=EEq(EVar(:pwfact, Any[]),
            EPow(EMul([
                EDiv(EVar(:mfw_sb, Any[]), EConst(max(world_base, 1.0))),
                EDiv(EVar(:mfw_ss, Any[]), EAdd([EVar(:mfw_bs, Any[]), EConst(1.0e-12)])),
            ]), EConst(0.5))))
    _register_full_equation!(ctx, block, :numeraire;
        info="GTAP numeraire links the world factor-price index to one", expr=EEq(
            EVar(:pnum, Any[]), EVar(:pwfact, Any[])))
    _register_full_equation!(ctx, block, :walras_residual;
        info="GTAP residual-region investment-income identity", expr=EEq(EVar(:walras, Any[]),
            _full_sum([
                EAdd([
                    EVar(:yi, Any[region]),
                    ENeg(EAdd([
                        EMul([EVar(:pi, Any[region]),
                            EConst(_full_regional_value(data, :depr, region)),
                            EVar(:kstock, Any[region])]),
                        EVar(:rsav, Any[region]), EVar(:savf, Any[region]),
                    ])),
                ]) for region in data.regions if region == block.residual_region
            ])))
    return nothing
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

function _full_set_members(path::AbstractString, name::Symbol)
    table = DataFrame(CSV.File(path; types=String))
    required = Set(["set", "item"])
    available = Set(String.(names(table)))
    required ⊆ available || error("sets.csv must contain set and item columns.")
    members = Symbol.(table[table.set .== String(name), :item])
    isempty(members) && error("sets.csv has no members for $(name).")
    length(unique(members)) == length(members) || error("sets.csv repeats a member of $(name).")
    return members
end

function _full_parameter_value(raw, path::AbstractString, row_number::Int)
    value = try
        parse(Float64, strip(String(raw)))
    catch
        error("$(path) row $(row_number) has a non-numeric value.")
    end
    isnan(value) && error("$(path) row $(row_number) has a NaN value.")
    return value
end

function _full_parameter_table(path::AbstractString)
    table = DataFrame(CSV.File(path; types=String))
    columns = String.(names(table))
    "value" in columns || error("$(path) must contain a value column.")
    index_columns = filter(name -> startswith(name, "index_"), columns)
    sort!(index_columns; by=name -> begin
        suffix = replace(name, "index_" => "")
        parsed = tryparse(Int, suffix)
        parsed === nothing && error("$(path) has an invalid index column $(name).")
        return parsed
    end)
    expected = ["index_$(position)" for position in eachindex(index_columns)]
    index_columns == expected || error("$(path) index columns must be contiguous from index_1.")

    values = GTAP7ParameterTable()
    for (row_number, row) in enumerate(eachrow(table))
        key = Tuple(Symbol(strip(String(row[Symbol(column)]))) for column in index_columns)
        any(isempty ∘ String, key) && error("$(path) row $(row_number) has an empty index.")
        haskey(values, key) && error("$(path) repeats index $(key).")
        values[key] = _full_parameter_value(row[:value], path, row_number)
    end
    return values
end

function _full_parameter_group(data_dir::AbstractString, group::Symbol)
    group_dir = joinpath(data_dir, String(group))
    isdir(group_dir) || error("Missing $(group) directory in $(data_dir).")
    files = sort(filter(name -> endswith(name, ".csv"), readdir(group_dir)))
    isempty(files) && error("$(group_dir) contains no parameter tables.")
    return Dict(
        Symbol(first(splitext(name))) => _full_parameter_table(joinpath(group_dir, name))
        for name in files
    )
end

function _require_full_table(group::Dict{Symbol,GTAP7ParameterTable},
    name::Symbol, data_dir::AbstractString)
    haskey(group, name) || error("Portable GTAP data in $(data_dir) are missing $(name).csv.")
    return group[name]
end

function _validate_full_make_structure!(benchmark::Dict{Symbol,GTAP7ParameterTable},
    regions::Vector{Symbol}, products::Vector{Symbol}, activities::Vector{Symbol}, data_dir::AbstractString)
    make = _require_full_table(benchmark, :makb, data_dir)
    expected_regions = Set(regions)
    expected_products = Set(products)
    expected_activities = Set(activities)
    pairs = Set{Tuple{Symbol,Symbol}}()
    regional_pairs = Set{Tuple{Symbol,Symbol,Symbol}}()
    for (key, value) in make
        length(key) == 3 || error("makb.csv must be indexed by region, activity, and product.")
        region, activity, product = key
        region in expected_regions || error("makb.csv uses unknown region $(region).")
        activity in expected_activities || error("makb.csv uses unknown activity $(activity).")
        product in expected_products || error("makb.csv uses unknown product $(product).")
        value < 0.0 && error("makb.csv has a negative make value for $(key).")
        value == 0.0 && continue
        push!(pairs, (activity, product))
        push!(regional_pairs, key)
    end
    isempty(pairs) && error("makb.csv contains no positive activity output.")
    missing_activities = sort!(collect(setdiff(expected_activities, Set(first(pair) for pair in pairs))))
    missing_products = sort!(collect(setdiff(expected_products, Set(last(pair) for pair in pairs))))
    isempty(missing_activities) || error("makb.csv has activities without output: $(missing_activities).")
    isempty(missing_products) || error("makb.csv has products without a producing activity: $(missing_products).")
    for region in regions, pair in pairs
        (region, pair[1], pair[2]) in regional_pairs ||
            error("makb.csv is missing the make entry for $(region), $(pair[1]), $(pair[2]).")
    end
    return sort!(collect(pairs))
end

"""
    load_full_data(data_dir) -> GTAP7FullData

Read the portable full GTAP parameter export used by the 9x10 comparison
implementation. `data_dir` must contain `sets.csv` and the `benchmark`,
    `elasticities`, `taxes`, `shares`, `calibrated`, `shifts`, and `derived`
    table directories emitted by the local data adapter. `derived` holds the
    source model's deterministic calibrated share and scaling inputs. This
    function intentionally has no HAR, GDX, Python, or solver dependency.
"""
function load_full_data(data_dir::AbstractString)
    root = abspath(data_dir)
    sets_path = joinpath(root, "sets.csv")
    isfile(sets_path) || error("Missing sets.csv in $(root).")
    regions = _full_set_members(sets_path, :r)
    products = _full_set_members(sets_path, :i)
    activities = _full_set_members(sets_path, :a)
    factors = _full_set_members(sets_path, :f)
    mobile_factors = _full_set_members(sets_path, :mf)
    sector_specific_factors = _full_set_members(sets_path, :sf)
    modes = _full_set_members(sets_path, :m)
    margins = _full_set_members(sets_path, :marg)
    all(in(Set(factors)), mobile_factors) || error("sets.csv declares a mobile factor outside f.")
    all(in(Set(factors)), sector_specific_factors) || error("sets.csv declares a sector-specific factor outside f.")

    benchmark = _full_parameter_group(root, :benchmark)
    elasticities = _full_parameter_group(root, :elasticities)
    taxes = _full_parameter_group(root, :taxes)
    shares = _full_parameter_group(root, :shares)
    calibrated = _full_parameter_group(root, :calibrated)
    shifts = _full_parameter_group(root, :shifts)
    derived = _full_parameter_group(root, :derived)
    output_pairs = _validate_full_make_structure!(benchmark, regions, products, activities, root)

    # These are the minimum tables needed before a GTAP Standard 7 formulation
    # can be calibrated. Checking them here prevents a later model builder from
    # silently substituting a reduced dataset.
    for name in (:vfm, :vdfb, :vmfb, :vdpp, :vmpp, :vdgb, :vmgb, :vdib, :vmib, :vxsb, :vtwr)
        _require_full_table(benchmark, name, root)
    end
    for name in (:esubva, :esubd, :esubm, :omegas, :sigmas, :subpar, :incpar)
        _require_full_table(elasticities, name, root)
    end
    for name in (:rto, :rtf, :rtpd, :rtpi, :rtxs, :imptx)
        _require_full_table(taxes, name, root)
    end
    for name in (:p_gx, :p_ax, :p_va, :p_nd, :p_io, :p_alphad, :p_alpham, :p_amw, :p_gw, :p_gd, :p_ge, :p_gf, :p_af)
        _require_full_table(shares, name, root)
    end
    for name in (:and_param, :ava_param, :io_param, :af_param, :gx_param)
        _require_full_table(calibrated, name, root)
    end
    for name in (:xscale, :xflag, :prdtx_rai, :alphad, :alpham, :dintx_target,
        :mintx_target, :import_source_share, :c_share, :betap, :betag, :betas)
        _require_full_table(derived, name, root)
    end

    return GTAP7FullData(
        regions,
        products,
        activities,
        factors,
        mobile_factors,
        sector_specific_factors,
        modes,
        margins,
        output_pairs,
        benchmark,
        elasticities,
        taxes,
        shares,
        calibrated,
        shifts,
        derived,
    )
end

"""
    full_model(; data_dir, residual_region=:NAmerica) -> RunSpec

Construct the full, single-period GTAP Standard 7 formulation from a portable
parameter export.  This is distinct from [`model`](@ref), the compact,
GTAP-shaped teaching example built from regional SAM tables.  The full model
retains the original products, activities, make matrix, bilateral flows,
transport margins, CDE demand system, tax accounts, and standard capital
closure.

`Mappings.activity_to_output` supplies Core's required canonical mapping only.
It does not collapse the GTAP make structure: all output pairs continue to be
represented by the model-local production and supply equations.
"""
function full_model(; data_dir::AbstractString, residual_region::Symbol=:NAmerica)
    data = load_full_data(data_dir)
    residual_region in data.regions ||
        error("residual_region $(residual_region) is not a GTAP region in $(data_dir).")
    activity_to_output = Dict{Symbol,Symbol}()
    for activity in data.activities
        outputs = [product for (candidate, product) in data.output_pairs if candidate == activity]
        isempty(outputs) && error("GTAP activity $(activity) has no output in the make matrix.")
        activity_to_output[activity] = first(outputs)
    end
    sets = JCGECore.Sets(data.products, data.activities, data.factors,
        collect(GTAP7_FINAL_AGENTS))
    model_spec = JCGECore.ModelSpec(
        Any[
            GTAP7TradeCETBlock(:gtap_trade_cet, data),
            GTAP7ProductionSupplyBlock(:gtap_production_supply, data),
            GTAP7FactorBlock(:gtap_factor, data),
            GTAP7ArmingtonBilateralBlock(:gtap_armington_bilateral, data),
            GTAP7DemandUtilityBlock(:gtap_demand_utility, data, residual_region),
            GTAP7IncomeBlock(:gtap_income, data, residual_region),
            GTAP7ClosureBlock(:gtap_closure, data, residual_region),
        ],
        sets,
        JCGECore.Mappings(activity_to_output),
    )
    return JCGECore.RunSpec(
        "GTAP Standard 7 full baseline",
        model_spec,
        JCGECore.ClosureSpec(:pnum, :price_index),
        JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}()),
    )
end

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
