"""
JCGEExamples.CamMGE defines the CamMGE example model.
"""
module CamMGE

using JCGEBlocks
using JCGECore
using JCGERuntime
using JCGECalibrate
using PATHSolver

export model, baseline, scenario, solve, mpsge_model

"""
Convert a labeled vector to a Dict keyed by labels.
"""
function _vecdict(vec::JCGECalibrate.LabeledVector{Float64})
    return Dict(vec.labels[i] => vec.data[i] for i in eachindex(vec.labels))
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
Load model data tables from the local data directory.
"""
function _load_data()
    datadir = joinpath(@__DIR__, "data")
    io_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "io.csv"))
    imat_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "imat.csv"))
    wdist_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "wdist.csv"))
    xle_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "xle.csv"))

    sectors = io_mat.row_labels
    labor = wdist_mat.col_labels

    io = _matdict(io_mat)
    imat = _matdict(imat_mat)
    wdist = _matdict(wdist_mat)
    xle = _matdict(xle_mat)

    m0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "m0.csv")))
    e0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "e0.csv")))
    xd0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "xd0.csv")))
    k0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "k0.csv")))
    id0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "id0.csv")))
    dst0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "dst0.csv")))

    depr = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "depr.csv")))
    rhoc = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "rhoc.csv")))
    rhot = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "rhot.csv")))
    eta = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "eta.csv")))
    pd0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "pd0.csv")))
    tm0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "tm0.csv")))
    itax = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "itax.csv")))
    cles = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "cles.csv")))
    gles = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "gles.csv")))
    kio = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "kio.csv")))
    dstr = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "dstr.csv")))

    wa0 = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "wa0.csv")))
    te = _vecdict(JCGECalibrate.load_labeled_vector(joinpath(datadir, "te.csv")))

    scalars = JCGECalibrate.load_labeled_vector(joinpath(datadir, "scalars.csv"))
    er = scalars[:er]
    gr0 = scalars[:gr0]
    gdtot0 = scalars[:gdtot0]
    cdtot0 = scalars[:cdtot0]
    fsav0 = scalars[:fsav0]
    mps0 = scalars[:mps0]

    xllb = Dict{Tuple{Symbol,Symbol},Float64}()
    for i in sectors, lc in labor
        val = xle[(i, lc)]
        xllb[(i, lc)] = val + (1.0 - sign(val))
    end

    traded = [i for i in sectors if m0[i] > 0.0]
    nontraded = [i for i in sectors if m0[i] <= 0.0]

    xxd0 = Dict(i => xd0[i] - e0[i] for i in sectors)
    pm0 = pd0
    pe0 = pd0
    pwm0 = Dict(i => pm0[i] / ((1.0 + tm0[i]) * er) for i in sectors)
    pwe0 = Dict(i => pe0[i] / ((1.0 + te[i]) * er) for i in sectors)

    pva0 = Dict(i => pd0[i] - sum(io[(j, i)] * pd0[j] for j in sectors) - itax[i] for i in sectors)

    int0 = Dict(i => sum(io[(i, j)] * xd0[j] for j in sectors) for i in sectors)

    delta = Dict{Symbol,Float64}()
    ac = Dict{Symbol,Float64}()
    x0 = Dict(i => pd0[i] * xxd0[i] + (pm0[i] * m0[i]) * (i in traded ? 1.0 : 0.0) for i in sectors)
    for i in sectors
        if i in traded
            delta_val = pm0[i] / pd0[i] * (m0[i] / xxd0[i]) ^ (1.0 + rhoc[i])
            delta_val = delta_val / (1.0 + delta_val)
            delta[i] = delta_val
            ac[i] = x0[i] / (delta_val * m0[i] ^ (-rhoc[i]) + (1.0 - delta_val) * xxd0[i] ^ (-rhoc[i])) ^ (-1.0 / rhoc[i])
        else
            delta[i] = 0.0
            ac[i] = 0.0
        end
    end

    gamma = Dict{Symbol,Float64}()
    for i in sectors
        if i in traded
            gamma[i] = 1.0 / (1.0 + pd0[i] / pe0[i] * (e0[i] / xxd0[i]) ^ (rhot[i] - 1.0))
        else
            gamma[i] = 0.0
        end
    end

    alphl = Dict{Tuple{Symbol,Symbol},Float64}()
    for i in sectors, lc in labor
        w = wdist[(i, lc)]
        val = (w == 0.0 || xle[(i, lc)] == 0.0) ? 0.0 : (w * wa0[lc] * xle[(i, lc)]) / (pva0[i] * xd0[i])
        alphl[(lc, i)] = val
    end

    qd = Dict{Symbol,Float64}()
    for i in sectors
        labor_term = prod(xllb[(i, lc)] ^ alphl[(lc, i)] for lc in labor)
        qd[i] = labor_term * k0[i] ^ (1.0 - sum(alphl[(lc, i)] for lc in labor))
    end

    ad = Dict(i => xd0[i] / qd[i] for i in sectors)

    at = Dict{Symbol,Float64}()
    for i in sectors
        if i in traded
            at[i] = xd0[i] / (gamma[i] * e0[i] ^ rhot[i] + (1.0 - gamma[i]) * xxd0[i] ^ rhot[i]) ^ (1.0 / rhot[i])
        else
            at[i] = 0.0
        end
    end

    ls0 = Dict(lc => sum(xle[(i, lc)] for i in sectors) for lc in labor)

    return (
        sectors=sectors,
        labor=labor,
        traded=traded,
        nontraded=nontraded,
        io=io,
        imat=imat,
        wdist=wdist,
        xle=xle,
        m0=m0,
        e0=e0,
        xd0=xd0,
        k0=k0,
        id0=id0,
        dst0=dst0,
        int0=int0,
        xxd0=xxd0,
        x0=x0,
        pd0=pd0,
        pm0=pm0,
        pe0=pe0,
        pva0=pva0,
        pwm0=pwm0,
        pwe0=pwe0,
        delta=delta,
        ac=ac,
        rhoc=rhoc,
        rhot=rhot,
        at=at,
        gamma=gamma,
        eta=eta,
        ad=ad,
        cles=cles,
        gles=gles,
        depr=depr,
        dstr=dstr,
        kio=kio,
        tm0=tm0,
        te=te,
        itax=itax,
        alphl=alphl,
        wa0=wa0,
        ls0=ls0,
        er=er,
        gr0=gr0,
        gdtot0=gdtot0,
        cdtot0=cdtot0,
        fsav0=fsav0,
        mps0=mps0,
    )
end

"""
    model() -> RunSpec

Return a RunSpec for the Cameroon CGE MPSGE port (block-based MCP).
"""
function model()
    data = _load_data()
    sectors = data.sectors
    labor = data.labor

    sets = JCGECore.Sets(
        sectors,
        sectors,
        labor,
        [Symbol("households"), Symbol("government"), Symbol("foreign"), Symbol("investment")],
    )
    mappings = JCGECore.Mappings(Dict(i => i for i in sectors))

    trade_block = JCGEBlocks.trade_price_link(:trade_prices, sectors, (traded=data.traded, te=data.te, mcp=true))
    absorption_block = JCGEBlocks.absorption_sales(:absorption, sectors, (traded=data.traded, mcp=true))
    activity_price_block = JCGEBlocks.activity_price_io(:activity_price, sectors, sectors, (io=data.io, itax=data.itax, mcp=true))
    capital_price_block = JCGEBlocks.capital_price_composition(:capital_price, sectors, sectors, (imat=data.imat, mcp=true))
    production_block = JCGEBlocks.production_multilabor_cd(:production, sectors, labor; params=(ad=data.ad, alphl=data.alphl, wdist=data.wdist, mcp=true))
    labor_block = JCGEBlocks.labor_market_clearing(:labor_market, labor, sectors; params=(mcp=true,))
    cet_block = JCGEBlocks.cet_xxd_e(:cet, sectors, (traded=data.traded, at=data.at, gamma=data.gamma, rhot=data.rhot, mcp=true))
    export_block = JCGEBlocks.export_demand(:export, sectors, (traded=data.traded, eta=data.eta, e0=data.e0, pwe0=data.pwe0, mcp=true))
    armington_block = JCGEBlocks.armington_m_xxd(:armington, sectors, (traded=data.traded, delta=data.delta, ac=data.ac, rhoc=data.rhoc, mcp=true))
    nontraded_block = JCGEBlocks.nontraded_supply(:nontraded, sectors, (nontraded=data.nontraded, mcp=true))
    inventory_block = JCGEBlocks.inventory_demand(:inventory, sectors, (dstr=data.dstr, mcp=true))
    household_block = JCGEBlocks.household_share_demand(:household, sectors, (cles=data.cles, mcp=true))
    government_demand_block = JCGEBlocks.government_share_demand(:government_demand, sectors, (gles=data.gles, mcp=true))
    government_finance_block = JCGEBlocks.government_finance(:government_finance, sectors, (traded=data.traded, itax=data.itax, te=data.te, mcp=true))
    gdp_block = JCGEBlocks.gdp_income(:gdp, sectors, (mcp=true,))
    savings_block = JCGEBlocks.savings_investment(:savings, sectors, sectors, (depr=data.depr, kio=data.kio, imat=data.imat, mcp=true))
    market_block = JCGEBlocks.final_demand_clearing(:market, sectors, (mcp=true,))
    bop_block = JCGEBlocks.external_balance_var_price(:bop, sectors, (Sf=data.fsav0, mcp=true))

    start_vals = Dict{Symbol,Float64}()
    lower_vals = Dict{Symbol,Float64}()
    fixed_vals = Dict{Symbol,Float64}()

    dk0 = Dict{Symbol,Float64}()
    for j in sectors
        dk0[j] = sum(data.id0[i] * data.imat[(i, j)] for i in sectors)
    end

    for i in sectors
        start_vals[JCGEBlocks.global_var(:x, i)] = data.x0[i]
        start_vals[JCGEBlocks.global_var(:xd, i)] = data.xd0[i]
        start_vals[JCGEBlocks.global_var(:xxd, i)] = data.xd0[i] - data.e0[i]
        start_vals[JCGEBlocks.global_var(:cd, i)] = data.cles[i] * data.cdtot0
        start_vals[JCGEBlocks.global_var(:gd, i)] = data.gles[i] * data.gdtot0
        start_vals[JCGEBlocks.global_var(:id, i)] = data.id0[i]
        start_vals[JCGEBlocks.global_var(:dk, i)] = dk0[i]
        start_vals[JCGEBlocks.global_var(:dst, i)] = data.dst0[i]
        start_vals[JCGEBlocks.global_var(:int, i)] = data.int0[i]
        start_vals[JCGEBlocks.global_var(:pd, i)] = data.pd0[i]
        start_vals[JCGEBlocks.global_var(:pm, i)] = data.pm0[i]
        start_vals[JCGEBlocks.global_var(:pe, i)] = data.pe0[i]
        start_vals[JCGEBlocks.global_var(:p, i)] = data.pd0[i]
        start_vals[JCGEBlocks.global_var(:px, i)] = data.pd0[i]
        start_vals[JCGEBlocks.global_var(:pk, i)] = data.pd0[i]
        start_vals[JCGEBlocks.global_var(:pva, i)] = data.pva0[i]
        start_vals[JCGEBlocks.global_var(:pwe, i)] = data.pwe0[i]
        start_vals[JCGEBlocks.global_var(:pwm, i)] = data.pwm0[i]
        start_vals[JCGEBlocks.global_var(:tm, i)] = data.tm0[i]

        lower_vals[JCGEBlocks.global_var(:x, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:xd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:pd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:p, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:px, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:pk, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:int, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:cd, i)] = 0.0
        lower_vals[JCGEBlocks.global_var(:gd, i)] = 0.0
        lower_vals[JCGEBlocks.global_var(:id, i)] = 0.0
        lower_vals[JCGEBlocks.global_var(:dst, i)] = 0.0
    end

    for i in data.traded
        start_vals[JCGEBlocks.global_var(:m, i)] = data.m0[i]
        start_vals[JCGEBlocks.global_var(:e, i)] = data.e0[i]
        lower_vals[JCGEBlocks.global_var(:pm, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:xxd, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:m, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:e, i)] = 0.01
        lower_vals[JCGEBlocks.global_var(:pwe, i)] = 0.01
    end

    for lc in labor
        start_vals[JCGEBlocks.global_var(:wa, lc)] = data.wa0[lc]
        start_vals[JCGEBlocks.global_var(:ls, lc)] = data.ls0[lc]
        lower_vals[JCGEBlocks.global_var(:wa, lc)] = 0.01
    end

    for i in sectors, lc in labor
        start_vals[JCGEBlocks.global_var(:l, i, lc)] = data.xle[(i, lc)]
        lower_vals[JCGEBlocks.global_var(:l, i, lc)] = 0.01
    end

    start_vals[:er] = data.er
    start_vals[:gr] = data.gr0
    start_vals[:fsav] = data.fsav0
    start_vals[:mps] = data.mps0
    start_vals[:gdtot] = data.gdtot0

    start_vals[:tariff] = 76.548
    start_vals[:indtax] = 102.45
    start_vals[:savings] = 280.98

    y0 = sum(data.pva0[i] * data.xd0[i] for i in sectors) - sum(data.depr[i] * data.k0[i] for i in sectors)
    start_vals[:y] = y0
    start_vals[:hhsav] = data.mps0 * y0
    start_vals[:deprecia] = sum(data.depr[i] * data.pd0[i] * data.k0[i] for i in sectors)
    start_vals[:govsav] = data.gr0 - data.gdtot0
    lower_vals[:y] = 0.01

    fixed_vals[:fsav] = data.fsav0
    fixed_vals[:mps] = data.mps0
    fixed_vals[:gdtot] = data.gdtot0
    fixed_vals[:er] = data.er

    for i in sectors
        fixed_vals[JCGEBlocks.global_var(:k, i)] = data.k0[i]
        fixed_vals[JCGEBlocks.global_var(:pwm, i)] = data.pwm0[i]
    end

    for lc in labor
        fixed_vals[JCGEBlocks.global_var(:ls, lc)] = data.ls0[lc]
    end

    for i in data.traded
        fixed_vals[JCGEBlocks.global_var(:tm, i)] = data.tm0[i]
    end

    for i in data.nontraded
        fixed_vals[JCGEBlocks.global_var(:m, i)] = 0.0
        fixed_vals[JCGEBlocks.global_var(:e, i)] = 0.0
    end

    fixed_vals[JCGEBlocks.global_var(:l, Symbol("publiques"), Symbol("rural"))] = 0.0
    fixed_vals[JCGEBlocks.global_var(:l, Symbol("ag-subsist"), Symbol("urban-skil"))] = 0.0

    fixed_vals[:y] = y0

    init_block = JCGEBlocks.initial_values(:init, (start=start_vals, lower=lower_vals, fixed=fixed_vals))

    closure = JCGECore.ClosureSpec(:pwm)
    scenario = JCGECore.ScenarioSpec(:baseline, Dict{Symbol,Any}())
    allowed_sections = JCGECore.allowed_sections()
    section_blocks = Dict(sym => Any[] for sym in allowed_sections)
    push!(section_blocks[:production], production_block)
    push!(section_blocks[:factors], labor_block)
    push!(section_blocks[:government], government_demand_block, government_finance_block)
    push!(section_blocks[:savings], savings_block)
    push!(section_blocks[:households], household_block)
    push!(section_blocks[:prices], trade_block, absorption_block, activity_price_block, capital_price_block)
    push!(section_blocks[:external], bop_block)
    push!(section_blocks[:trade], cet_block, export_block, armington_block, nontraded_block)
    push!(section_blocks[:markets], inventory_block, gdp_block, market_block)
    push!(section_blocks[:init], init_block)
    sections = [JCGECore.section(sym, section_blocks[sym]) for sym in allowed_sections]
    required_nonempty = [:production, :households, :markets]
    return JCGECore.build_spec(
        "CamMGE",
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
Return the baseline RunSpec for CamMGE.
"""
baseline() = model()

"""
Solve the CamMGE model and return the run result.
"""
function solve(; optimizer=PATHSolver.Optimizer)
    return JCGERuntime.run!(model(); optimizer=optimizer, compile_ast=true, compile_objective=false)
end

"""
Create a scenario placeholder for CamMGE.
"""
function scenario(name::Symbol)
    return JCGECore.ScenarioSpec(name, Dict{Symbol,Any}())
end

include("mpsge_model.jl")

end # module
