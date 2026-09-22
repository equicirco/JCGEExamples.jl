"""
`JCGEExamples.GTAP7MCP` provides a mixed-complementarity formulation of the
compact GTAP Standard 7 example.

It uses the same synthetic data contract, economic scope, and declared
counterfactuals as `GTAP7`.  The distinction is the solution form: each
equilibrium condition is paired explicitly with its associated model variable
and the resulting system is solved with PATH.
"""
module GTAP7MCP

using PATHSolver
using JuMP
using JCGECore
using JCGERuntime
using JCGECore: EEq, EVar

using ..GTAP7

export baseline, datadir, model, scenario, solve

"""Return the directory containing the shared compact GTAP7 fixture."""
datadir() = GTAP7.datadir()

"""
Internal wrapper which builds the compact GTAP7 blocks and records their
explicit MCP equation--variable pairing.

The nonlinear GTAP7 model is intentionally left unchanged.  Keeping the
pairing here makes the MCP closure auditable and avoids introducing solver
details into its equality/NLP formulation.
"""
struct GTAP7MCPBlock <: JCGECore.AbstractBlock
    name::Symbol
    blocks::Vector{Any}
    route_endpoints::Dict{Symbol,Tuple{Symbol,Symbol}}
    start_values::Union{Nothing,Dict{Symbol,Float64}}
end

_mcp_var(name::Symbol, indices::Symbol...) = EVar(name, Any[indices...])
_regional_good(product::Symbol, region::Symbol) = Symbol(product, "_", region)

function _route_endpoints(blocks::Vector{Any})
    trade = only(filter(block ->
        hasproperty(block, :name) && getproperty(block, :name) == :bilateral_trade,
        blocks))
    hasproperty(trade, :routes) || error("GTAP7 bilateral-trade block has no route inventory.")
    return Dict(route.id => (route.origin, route.destination)
        for route in getproperty(trade, :routes))
end

function _pairing(eq, route_endpoints::Dict{Symbol,Tuple{Symbol,Symbol}})
    payload = eq.payload
    indices = Symbol[get(payload, :indices, ())...]
    block = eq.block
    tag = eq.tag

    if startswith(String(block), "production_")
        tag == :eqpy && return _mcp_var(:Y, only(indices))
        tag == :eqF && return _mcp_var(:F, indices...)
        tag == :eqX && return _mcp_var(:X, indices...)
        # The physical-output link closes the activity-price variable, while
        # the CET transformation closes physical output below.
        tag == :eqY && return _mcp_var(:py, only(indices))
        tag == :eqpzs && return _mcp_var(:pz, only(indices))
    elseif startswith(String(block), "factor_market_")
        tag == :eqF && return _mcp_var(:pf, only(indices))
    elseif block == :government
        tag == :regional_direct_tax && return _mcp_var(:Td, only(indices))
        tag == :regional_output_tax && return _mcp_var(:Tz, first(indices))
        tag == :regional_government_saving && return _mcp_var(:Sg, only(indices))
        tag == :regional_government_demand && return _mcp_var(:Xg, first(indices))
    elseif block == :private_saving
        tag == :regional_private_saving && return _mcp_var(:Sp, only(indices))
    elseif block == :global_investment
        tag == :regional_investment_allocation && return _mcp_var(:INV, only(indices))
        tag == :regional_investment_demand && return _mcp_var(:Xv, first(indices))
        tag == :global_saving_investment_balance && return _mcp_var(:GLOBAL_INV)
    elseif block == :cde_households
        tag == :private_expenditure && return _mcp_var(:P_PRIV, only(indices))
        tag == :cde_utility && return _mcp_var(:U_PRIV, only(indices))
        tag == :cde_private_demand && return _mcp_var(:Xp, first(indices))
    elseif block == :external
        tag == :regional_external_balance && return _mcp_var(:FSAV, only(indices))
    elseif block == :bilateral_trade
        if tag == :trade_delivery_price
            return _mcp_var(:pD, only(indices))
        elseif tag == :row_trade_price
            return _mcp_var(:pS, only(indices))
        elseif tag in (:cet_quantity, :cet_cobb_douglas)
            return _mcp_var(:Z, _regional_good(indices[1], indices[2]))
        elseif tag in (:cet_allocation, :cet_allocation_cobb_douglas)
            route = only(indices)
            _, destination = route_endpoints[route]
            return destination == :ROW ? _mcp_var(:T, route) : _mcp_var(:pS, route)
        elseif tag in (:armington_quantity, :armington_cobb_douglas)
            return _mcp_var(:Q, _regional_good(indices[1], indices[2]))
        elseif tag in (:armington_sourcing, :armington_sourcing_cobb_douglas)
            return _mcp_var(:T, only(indices))
        end
    elseif block == :composite_market
        tag == :regional_composite_market && return _mcp_var(:pq, first(indices))
    end

    error("No GTAP7 MCP pairing is declared for $(block).$(tag)$(Tuple(indices)).")
end

function JCGECore.build!(block::GTAP7MCPBlock,
    ctx::JCGERuntime.KernelContext,
    spec::JCGECore.RunSpec)
    for nested in block.blocks
        JCGECore.build!(nested, ctx, spec)
    end

    if block.start_values !== nothing
        for (name, value) in block.start_values
            variable = get(ctx.variables, name, nothing)
            variable isa JuMP.VariableRef || continue
            JuMP.set_start_value(variable, value)
        end
    end

    for i in eachindex(ctx.equations)
        equation = ctx.equations[i]
        payload = equation.payload
        payload isa NamedTuple || continue
        expr = get(payload, :expr, nothing)
        expr isa EEq || continue
        mcp_var = _pairing(equation, block.route_endpoints)
        ctx.equations[i] = (
            tag=equation.tag,
            block=equation.block,
            payload=merge(payload, (mcp_var=mcp_var,)),
        )
    end
    return nothing
end

"""
    model(; kwargs...) -> RunSpec

Build the MCP companion to `GTAP7.model`.  Keyword arguments, including all
declared GTAP7 counterfactuals, are forwarded unchanged to the compact
equality/NLP formulation before its equations receive the GTAP7 MCP pairing.
"""
function model(; start_values::Union{Nothing,Dict{Symbol,Float64}}=nothing, kwargs...)
    equality_spec = GTAP7.model(; kwargs...)
    mcp_block = GTAP7MCPBlock(
        :gtap7_mcp,
        equality_spec.model.blocks,
        _route_endpoints(equality_spec.model.blocks),
        start_values,
    )
    return JCGECore.RunSpec(
        "GTAP7MCP",
        JCGECore.ModelSpec(
            Any[mcp_block],
            equality_spec.model.sets,
            equality_spec.model.mappings,
        ),
        equality_spec.closure,
        equality_spec.scenario,
    )
end

"""Return the GTAP7MCP baseline `RunSpec`."""
baseline(; kwargs...) = model(; kwargs...)

"""Return a declared GTAP7MCP baseline or supported counterfactual scenario."""
scenario(name::Symbol=:baseline; kwargs...) = model(; scenario_name=name, kwargs...)

function _solve(spec; optimizer)
    return JCGERuntime.run!(spec;
        optimizer=optimizer,
        compile_ast=true,
        compile_objective=false,
    )
end

"""
Solve the compact GTAP7 equilibrium as an MCP with PATH.

Counterfactuals start from the solved compact baseline. This short
continuation step keeps the public scenario interface identical to `GTAP7`
while giving PATH a consistent start when a bilateral price wedge changes.
"""
function solve(; optimizer=PATHSolver.Optimizer, scenario_name::Symbol=:baseline, kwargs...)
    if scenario_name == :baseline
        return _solve(model(; scenario_name, kwargs...); optimizer=optimizer)
    end
    baseline_result = _solve(model(; scenario_name=:baseline, kwargs...); optimizer=optimizer)
    start_values = JCGERuntime.snapshot(baseline_result)
    # A delivery-cost scenario changes a route's calibrated delivered-price
    # wedge. Retain that scenario-specific price start instead of overwriting
    # it with the baseline route price.
    for name in collect(keys(start_values))
        startswith(String(name), "pD_") && delete!(start_values, name)
    end
    return _solve(model(; scenario_name, start_values, kwargs...);
        optimizer=optimizer)
end

end # module
