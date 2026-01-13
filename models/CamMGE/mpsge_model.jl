using MPSGE
using JuMP

"""
Build MPSGE set definitions from the provided data.
"""
function _mpsge_sets(data)
    I = data.sectors
    IT = data.traded
    LC = data.labor
    DSTR = [i for i in I if data.dstr[i] > 0.0]
    return (I=I, IT=IT, LC=LC, DSTR=DSTR)
end

"""
Build MPSGE parameter definitions from the provided data.
"""
function _mpsge_params(data)
    I = data.sectors
    LC = data.labor

    esub = Dict(i => 1.0 / (1.0 + data.rhoc[i]) for i in I)
    etrn = Dict(i => 1.0 / (data.rhot[i] - 1.0) for i in I)

    pl0 = Dict{Tuple{Symbol,Symbol},Float64}()
    for i in I, lc in LC
        pl0[(i, lc)] = data.wdist[(i, lc)]
    end

    rk0 = Dict{Symbol,Float64}()
    for i in I
        io_sum = sum(data.io[(j, i)] for j in I)
        labor_cost = sum(data.wa0[lc] * data.wdist[(i, lc)] * data.xle[(i, lc)] for lc in LC)
        rk0[i] = (data.xd0[i] * (1.0 - data.itax[i] - io_sum) - labor_cost) / data.k0[i]
    end

    y0 = sum(data.k0[i] * (rk0[i] - data.depr[i]) for i in I) +
         sum(data.wdist[(i, lc)] * data.wa0[lc] * data.xle[(i, lc)] for i in I for lc in LC)

    duty0 = sum(data.te[i] * data.e0[i] for i in data.traded)
    indtax0 = sum(data.itax[i] * data.xd0[i] for i in I)
    tariff0 = sum(data.tm0[i] * data.m0[i] * data.pwm0[i] for i in data.traded) * data.er
    govsav0 = duty0 + indtax0 + tariff0 - data.gdtot0

    hhsav0 = data.mps0 * y0
    totsav0 = hhsav0 + govsav0 + sum(data.depr[i] * data.k0[i] for i in I) + data.fsav0 * data.er
    dk0 = Dict(i => data.kio[i] * (totsav0 - sum(data.dstr[j] * data.xd0[j] for j in I)) for i in I)

    return (esub=esub, etrn=etrn, pl0=pl0, rk0=rk0, y0=y0, govsav0=govsav0, dk0=dk0)
end

"""
    mpsge_model() -> MPSGEModel

Return the Cameroon MPSGE model (from GAMS CAMMGE) as an MPSGE.jl model.
"""
function mpsge_model()
    data = _load_data()
    sets = _mpsge_sets(data)
    params = _mpsge_params(data)

    I = sets.I
    IT = sets.IT
    LC = sets.LC
    DSTR = sets.DSTR

    m = MPSGEModel()

    @parameters(m, begin
        esub[i=I], params.esub[i]
        etrn[i=I], params.etrn[i]
        eta[i=I], data.eta[i]
        tm[i=I], data.tm0[i]
        te[i=I], data.te[i]
        itax[i=I], data.itax[i]
        pwm[i=I], data.pwm0[i]
        pwe[i=I], data.pwe0[i]
    end)

    @sectors(m, begin
        XD[i=I]
        X[i=I]
        DK[i=I]
        M[i=IT]
    end)

    @commodities(m, begin
        PFX
        PD[i=I]
        P[i=I]
        PE[i=I]
        PM[i=I]
        PL[lc=LC]
        RK[i=I]
        PK[i=I]
        PSAV
    end)

    @consumers(m, begin
        HH
        GOVT
        INVESTOR
    end)

    @auxiliaries(m, begin
        E[i=I]
        VEXPORT
        XDL[i=DSTR]
    end)

    @production(m, XD[i=I], [s = 1, t = etrn[i]], begin
        @output(PD[i], data.xxd0[i], t, taxes=[Tax(GOVT, itax[i])])
        @output(PE[i], data.e0[i], t, taxes=[Tax(GOVT, itax[i])])
        [@input(P[j], data.io[(j, i)] * data.xd0[i], s) for j in I]
        [@input(PL[lc], data.wa0[lc] * data.xle[(i, lc)], s,
            taxes=[Tax(HH, data.wdist[(i, lc)] - 1.0)], reference_price=params.pl0[(i, lc)]) for lc in LC]
        @input(RK[i], params.rk0[i] * data.k0[i], s)
    end)

    @production(m, X[i=I], [s = esub[i], t = 0], begin
        @output(P[i], data.x0[i], t)
        @input(PD[i], data.xxd0[i], s)
        @input(PM[i], data.m0[i], s)
    end)

    @production(m, M[i=IT], [s = 1, t = 0], begin
        @output(PM[i], data.m0[i], t)
        @input(PFX, data.pwm0[i] * data.m0[i] * data.er, s, taxes=[Tax(GOVT, tm[i])])
    end)

    @production(m, DK[i=I], [s = 1, t = 0], begin
        @output(PK[i], params.dk0[i], t)
        [@input(P[j], data.imat[(j, i)] * params.dk0[i], s) for j in I]
    end)

    @demand(m, HH, begin
        [@endowment(PE[i], -data.e0[i] * E[i]) for i in I]
        [@endowment(PE[i], -data.e0[i] * data.te[i] * E[i]) for i in I]
        @endowment(PFX, VEXPORT)
        [@endowment(RK[i], params.rk0[i] * data.k0[i]) for i in I]
        [@endowment(PK[i], -data.depr[i] * data.k0[i]) for i in I]
        [@endowment(PL[lc], data.wa0[lc] * data.ls0[lc]) for lc in LC]
        @final_demand(PSAV, data.mps0 * params.y0)
        [@final_demand(P[i], data.cles[i] * (1.0 - data.mps0) * params.y0) for i in I]
    end)

    @demand(m, GOVT, begin
        [@endowment(P[i], -data.gdtot0 * data.gles[i]) for i in I]
        [@endowment(PE[i], data.e0[i] * data.te[i] * E[i]) for i in I]
        @final_demand(PSAV, params.govsav0)
    end)

    @demand(m, INVESTOR, begin
        @endowment(PSAV, params.govsav0 + data.mps0 * params.y0)
        @endowment(PFX, data.fsav0 * data.er)
        [@endowment(PK[i], data.depr[i] * data.k0[i]) for i in I]
        [@endowment(P[i], -data.dstr[i] * data.xd0[i] * (i in DSTR ? XDL[i] : 1.0)) for i in I]
        [@final_demand(PK[i], params.dk0[i]) for i in I]
    end)

    for i in I
        @aux_constraint(m, E[i], E[i] - (PFX / PE[i]) ^ eta[i])
    end

    @aux_constraint(m, VEXPORT, VEXPORT * PFX - data.er * sum(data.pwe0[i] * data.e0[i] * E[i] * PE[i] for i in I))

    for i in DSTR
        @aux_constraint(m, XDL[i], XDL[i] - XD[i])
    end

    fix(PFX, 1.0)
    return m
end
