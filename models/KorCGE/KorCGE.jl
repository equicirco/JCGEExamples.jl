"""
JCGEExamples.KorCGE defines the KorCGE example model.
"""
module KorCGE

using JCGEBlocks
using JCGECore
using JCGERuntime
using JCGECalibrate
using Ipopt

export model, baseline, scenario, solve, datadir

"""
Return the data directory for KorCGE.
"""
datadir() = joinpath(@__DIR__, "data")

"""
Load a labeled matrix CSV from the model data directory.
"""
function _load_matrix(name::String)
    return JCGECalibrate.load_labeled_matrix(joinpath(datadir(), "$(name).csv"))
end

"""
Load a labeled vector CSV from the model data directory.
"""
function _load_vector(name::String)
    return JCGECalibrate.load_labeled_vector(joinpath(datadir(), "$(name).csv"))
end

"""
Convert a labeled matrix to a Dict keyed by label tuples.
"""
function _matdict(mat::JCGECalibrate.LabeledMatrix{Float64})
    out = Dict{Tuple{Symbol,Symbol},Float64}()
    for r in mat.row_labels, c in mat.col_labels
        out[(r, c)] = mat[r, c]
    end
    return out
end

"""
Convert a labeled vector to a Dict keyed by labels.
"""
function _vecdict(vec::JCGECalibrate.LabeledVector{Float64})
    return Dict(vec.labels[i] => vec.data[i] for i in eachindex(vec.labels))
end

"""
Return a RunSpec for KorCGE.
"""
function model()
    alphl = _load_matrix("alphl")
    io = _load_matrix("io")
    imat = _load_matrix("imat")
    wdist = _load_matrix("wdist")
    cles = _load_matrix("cles")
    zz = _load_matrix("zz")
    labres1 = _load_matrix("labres1")
    labres2 = _load_matrix("labres2")
    hhres = _load_matrix("hhres")
    sectres = _load_matrix("sectres")
    htax_vec = _load_vector("htax")
    scalars = _load_vector("scalars")

    sectors = alphl.row_labels
    labor = alphl.col_labels
    households = cles.col_labels

    traded = [i for i in sectors if sectres[:m, i] > 0.0 || sectres[:e, i] > 0.0]
    nontraded = [i for i in sectors if !(i in traded)]

    sets = JCGECore.Sets(sectors, sectors, labor, households)
    mappings = JCGECore.Mappings(Dict(i => i for i in sectors))

    io_vals = _matdict(io)
    imat_vals = _matdict(imat)
    wdist_vals = _matdict(wdist)
    cles_vals = _matdict(cles)

    alphl_vals = Dict{Tuple{Symbol,Symbol},Float64}()
    for i in alphl.row_labels, lc in alphl.col_labels
        alphl_vals[(lc, i)] = alphl[i, lc]
    end

    htax_vals = _vecdict(htax_vec)

    depr_vals = Dict(i => zz[:depr, i] for i in sectors)
    itax_vals = Dict(i => zz[:itax, i] for i in sectors)
    gles_vals = Dict(i => zz[:gles, i] for i in sectors)
    kio_vals = Dict(i => zz[:kio, i] for i in sectors)
    dstr_vals = Dict(i => zz[:dstr, i] for i in sectors)
    te_vals = Dict(i => zz[:te, i] for i in sectors)
    tm_vals = Dict(i => zz[:tm, i] for i in sectors)
    ad_vals = Dict(i => zz[:ad, i] for i in sectors)
    pwts_vals = Dict(i => zz[:pwts, i] for i in sectors)
    pwm_vals = Dict(i => zz[:pwm, i] for i in sectors)
    pwe_vals = Dict(i => zz[:pwe, i] for i in sectors)
    sigc_vals = Dict(i => zz[:sigc, i] for i in sectors)
    sigt_vals = Dict(i => zz[:sigt, i] for i in sectors)
    delta_vals = Dict(i => zz[:delta, i] for i in sectors)
    ac_vals = Dict(i => zz[:ac, i] for i in sectors)
    gamma_vals = Dict(i => zz[:gamma, i] for i in sectors)
    at_vals = Dict(i => zz[:at, i] for i in sectors)

    rhoc_vals = Dict(i => (1.0 / sigc_vals[i]) - 1.0 for i in sectors)
    rhot_vals = Dict(i => (1.0 / sigt_vals[i]) + 1.0 for i in sectors)

    labor_hh = :lab_hh in households ? :lab_hh : Symbol("lab-hh")
    capital_hh = :cap_hh in households ? :cap_hh : Symbol("cap-hh")
    alpha_vals = Dict(i => cles_vals[(i, labor_hh)] for i in sectors)

    trade_block = JCGEBlocks.trade_price_link(
        :trade_price,
        sectors,
        (traded = traded, te = te_vals, include_pr = true, pedef_mode = :pwe, pwe = pwe_vals, pwm = pwm_vals),
    )
    absorption_block = JCGEBlocks.absorption_sales(:absorption, sectors, (traded = traded,))
    activity_price_block = JCGEBlocks.activity_price_io(:activity_price, sectors, sectors, (io = io_vals, itax = itax_vals))
    capital_price_block = JCGEBlocks.capital_price_composition(:capital_price, sectors, sectors, (imat = imat_vals,))
    production_block = JCGEBlocks.production_multilabor_cd(
        :production,
        sectors,
        labor;
        params = (ad = ad_vals, wdist = wdist_vals, alphl = alphl_vals),
    )
    labor_block = JCGEBlocks.labor_market_clearing(:labor_market, labor, sectors; params = (;))
    cet_block = JCGEBlocks.cet_xxd_e(:cet, sectors, (at = at_vals, gamma = gamma_vals, rhot = rhot_vals, traded = traded))
    armington_block = JCGEBlocks.armington_m_xxd(:armington, sectors, (ac = ac_vals, delta = delta_vals, rhoc = rhoc_vals, traded = traded))
    nontraded_block = JCGEBlocks.nontraded_supply(:nontraded, sectors, (nontraded = nontraded,))
    inventory_block = JCGEBlocks.inventory_demand(:inventory, sectors, (dstr = dstr_vals,))
    household_demand_block = JCGEBlocks.household_share_demand_hh(
        :household_demand,
        households,
        sectors;
        params = (cles = cles_vals, htax = htax_vals),
    )
    household_income_block = JCGEBlocks.household_income_labor_capital(
        :household_income,
        households,
        sectors,
        labor;
        params = (labor_household = labor_hh, capital_household = capital_hh),
    )
    household_tax_block = JCGEBlocks.household_tax_revenue(:household_tax, households; params = (htax = htax_vals,))
    household_sum_block = JCGEBlocks.household_income_sum(:household_sum, households)
    government_demand_block = JCGEBlocks.government_share_demand(:government_demand, sectors, (gles = gles_vals,))
    government_revenue_block = JCGEBlocks.government_revenue(
        :government_revenue,
        sectors;
        params = (itax = itax_vals, te = te_vals, traded = traded, pwe = pwe_vals, pwm = pwm_vals),
    )
    premium_block = JCGEBlocks.import_premium_income(:premium_income, sectors, (traded = traded, pwm = pwm_vals))
    savings_block = JCGEBlocks.savings_investment(
        :savings,
        sectors,
        sectors,
        (depr = depr_vals, kio = kio_vals, imat = imat_vals, use_invest = true),
    )
    price_index_block = JCGEBlocks.price_index(:price_index, sectors, (pwts = pwts_vals,))
    bop_block = JCGEBlocks.external_balance_remit(:bop, sectors, (traded = traded, pwe = pwe_vals, pwm = pwm_vals))
    market_block = JCGEBlocks.final_demand_clearing(:market, sectors, (;))
    objective_block = JCGEBlocks.consumption_objective(:objective, sectors, (alpha = alpha_vals,))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    fixed_vals = Dict{Symbol,Float64}()

    for i in sectors
        start_vals[JCGEBlocks.global_var(:pd, i)] = sectres[:pd, i]
        start_vals[JCGEBlocks.global_var(:pk, i)] = sectres[:pk, i]
        start_vals[JCGEBlocks.global_var(:pva, i)] = sectres[:pva, i]
        start_vals[JCGEBlocks.global_var(:x, i)] = sectres[:x, i]
        start_vals[JCGEBlocks.global_var(:xd, i)] = sectres[:xd, i]
        start_vals[JCGEBlocks.global_var(:xxd, i)] = sectres[:xxd, i]
        start_vals[JCGEBlocks.global_var(:e, i)] = sectres[:e, i]
        start_vals[JCGEBlocks.global_var(:m, i)] = sectres[:m, i]
        start_vals[JCGEBlocks.global_var(:k, i)] = sectres[:k, i]
        start_vals[JCGEBlocks.global_var(:int, i)] = sectres[:int, i]
        start_vals[JCGEBlocks.global_var(:cd, i)] = sectres[:cd, i]
        start_vals[JCGEBlocks.global_var(:gd, i)] = sectres[:gd, i]
        start_vals[JCGEBlocks.global_var(:id, i)] = sectres[:id, i]
        start_vals[JCGEBlocks.global_var(:dst, i)] = sectres[:dst, i]
        start_vals[JCGEBlocks.global_var(:dk, i)] = sectres[:dk, i]
        start_vals[JCGEBlocks.global_var(:pm, i)] = sectres[:pm, i]
        start_vals[JCGEBlocks.global_var(:pe, i)] = sectres[:pe, i]
        start_vals[JCGEBlocks.global_var(:px, i)] = sectres[:px, i]
        start_vals[JCGEBlocks.global_var(:p, i)] = sectres[:p, i]
        start_vals[JCGEBlocks.global_var(:tm, i)] = tm_vals[i]

        lower_vals[JCGEBlocks.global_var(:p, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:pd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:pk, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:px, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:x, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:xd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:int, i)] = 0.01

        fixed_vals[JCGEBlocks.global_var(:k, i)] = sectres[:k, i]
        fixed_vals[JCGEBlocks.global_var(:tm, i)] = tm_vals[i]
    end

    for i in traded
        lower_vals[JCGEBlocks.global_var(:pm, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:m, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:xxd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:e, i)] = 0.01
    end

    for i in nontraded
        fixed_vals[JCGEBlocks.global_var(:m, i)] = 0.0
        fixed_vals[JCGEBlocks.global_var(:e, i)] = 0.0
    end

    for lc in labor
        start_vals[JCGEBlocks.global_var(:wa, lc)] = labres2[:wa, lc]
        start_vals[JCGEBlocks.global_var(:ls, lc)] = labres2[:ls, lc]
        lower_vals[JCGEBlocks.global_var(:wa, lc)] = 0.01
        fixed_vals[JCGEBlocks.global_var(:ls, lc)] = labres2[:ls, lc]
    end

    for i in sectors, lc in labor
        lval = labres1[i, lc]
        start_vals[JCGEBlocks.global_var(:l, i, lc)] = lval
        if lval > 0.0
            lower_vals[JCGEBlocks.global_var(:l, i, lc)] = 0.01
        else
            fixed_vals[JCGEBlocks.global_var(:l, i, lc)] = 0.0
        end
    end

    for hh in households
        start_vals[JCGEBlocks.global_var(:mps, hh)] = hhres[:mps, hh]
        start_vals[JCGEBlocks.global_var(:yh, hh)] = hhres[:yh, hh]
        fixed_vals[JCGEBlocks.global_var(:mps, hh)] = hhres[:mps, hh]
    end

    scalar_vals = _vecdict(scalars)
    start_vals[:er] = scalar_vals[:er]
    start_vals[:pr] = scalar_vals[:pr]
    start_vals[:pindex] = scalar_vals[:pindex]
    start_vals[:gr] = scalar_vals[:gr]
    start_vals[:tariff] = scalar_vals[:tariff]
    start_vals[:indtax] = scalar_vals[:indtax]
    start_vals[:netsub] = scalar_vals[:netsub]
    start_vals[:gdtot] = scalar_vals[:gdtot]
    start_vals[:hhsav] = scalar_vals[:hhsav]
    start_vals[:govsav] = scalar_vals[:govsav]
    start_vals[:deprecia] = scalar_vals[:deprecia]
    start_vals[:savings] = scalar_vals[:savings]
    start_vals[:invest] = scalar_vals[:invest]
    start_vals[:fsav] = scalar_vals[:fsav]
    start_vals[:fbor] = scalar_vals[:fbor]
    start_vals[:remit] = scalar_vals[:remit]
    start_vals[:tothhtax] = scalar_vals[:tothhtax]
    start_vals[:y] = scalar_vals[:y]
    start_vals[:ypr] = 0.0

    lower_vals[:y] = 0.01
    fixed_vals[:er] = scalar_vals[:er]
    fixed_vals[:fsav] = scalar_vals[:fsav]
    fixed_vals[:remit] = scalar_vals[:remit]
    fixed_vals[:fbor] = scalar_vals[:fbor]
    fixed_vals[:pindex] = scalar_vals[:pindex]
    fixed_vals[:gdtot] = scalar_vals[:gdtot]

    init_block = JCGEBlocks.initial_values(:init, (start = start_vals, lower = lower_vals, fixed = fixed_vals))

    closure = JCGECore.ClosureSpec(:pindex)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], production_block)
    push!(section_blocks[:factors], labor_block)
    push!(section_blocks[:government], government_demand_block, government_revenue_block)
    push!(section_blocks[:savings], savings_block)
    push!(section_blocks[:households], household_demand_block, household_income_block, household_tax_block, household_sum_block)
    push!(section_blocks[:prices], trade_block, absorption_block, activity_price_block, capital_price_block, premium_block, price_index_block)
    push!(section_blocks[:external], bop_block)
    push!(section_blocks[:trade], cet_block, armington_block, nontraded_block)
    push!(section_blocks[:markets], inventory_block, market_block)
    push!(section_blocks[:objective], objective_block)
    push!(section_blocks[:init], init_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    required_nonempty = [:production, :households, :markets]
    return JCGECore.build_spec(
        "KorCGE",
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
Return the baseline RunSpec for KorCGE.
"""
baseline() = model()

"""
Solve the KorCGE model and return the run result.
"""
function solve(; optimizer = Ipopt.Optimizer)
    return JCGERuntime.run!(model(); optimizer = optimizer)
end

"""
Create a scenario placeholder for KorCGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

end # module
