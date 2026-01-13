using JCGECalibrate
using MPSGE

"""
Return the data used to build the MPSGE model.
"""
function _mpsge_data()
    datadir = joinpath(@__DIR__, "data")
    a_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "a.csv"))
    alpha_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "alpha.csv"))
    e_mat = JCGECalibrate.load_labeled_matrix(joinpath(datadir, "e.csv"))

    goods = a_mat.row_labels
    sectors = a_mat.col_labels
    consumers = alpha_mat.col_labels

    return (goods=goods, sectors=sectors, consumers=consumers, A=a_mat, alpha=alpha_mat, endow=e_mat)
end

"""
    mpsge_model() -> MPSGEModel

Return the KEHOMGE MPSGE model in MPSGE.jl form.
"""
function mpsge_model()
    data = _mpsge_data()
    G = data.goods
    S = data.sectors
    C = data.consumers

    m = MPSGEModel()

    @sectors(m, begin
        Y[s=S]
    end)

    @commodities(m, begin
        P[g=G]
    end)

    @consumers(m, begin
        H[c=C]
    end)

    @demand(m, H[c=C], begin
        [@endowment(P[g], data.endow[g, c]) for g in G]
        [@final_demand(P[g], data.alpha[g, c]) for g in G]
    end)

    @production(m, Y[s=S], [s = 1, t = 0], begin
        for g in G
            aval = data.A[g, s]
            if aval > 0
                @output(P[g], aval, t)
            elseif aval < 0
                @input(P[g], -aval, s)
            end
        end
    end)

    fix(P[first(G)], 1.0)
    return m
end
