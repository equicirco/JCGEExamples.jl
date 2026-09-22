using Test
using JCGEExamples
using JCGEExamples.StandardCGE
using JCGEExamples.SimpleCGE
using JCGEExamples.LargeCountryCGE
using JCGEExamples.TwoCountryCGE
using JCGEExamples.MonopolyCGE
using JCGEExamples.QuotaCGE
using JCGEExamples.ScaleEconomyCGE
using JCGEExamples.DynCGE
using JCGEExamples.CamCGE
using JCGEExamples.CamMGE
using JCGEExamples.CamMCP
using JCGEExamples.KorCGE
using JCGEExamples.KorMCP
using JCGEExamples.GTAP7
using JCGEExamples.GTAP7MCP
using JCGECore
using JCGERuntime
using JCGEBlocks
using JuMP
using Ipopt
import MathOptInterface as MOI

@testset "JCGEExamples" begin
    sam_path = joinpath(StandardCGE.datadir(), "sam_2_2.csv")
    spec = StandardCGE.model(sam_path=sam_path)
    @test spec.name == "StandardCGE"
    report = validate_spec(spec)
    @test report.ok

    lrg_sam = joinpath(LargeCountryCGE.datadir(), "sam_2_2.csv")
    lrg_spec = LargeCountryCGE.model(sam_path=lrg_sam)
    @test lrg_spec.name == "LargeCountryCGE"

    two_spec = TwoCountryCGE.model()
    @test two_spec.name == "TwoCountryCGE"

    mon_sam = joinpath(MonopolyCGE.datadir(), "sam_2_2.csv")
    mon_spec = MonopolyCGE.model(sam_path=mon_sam)
    @test mon_spec.name == "MonopolyCGE"

    quo_sam = joinpath(QuotaCGE.datadir(), "sam_2_2.csv")
    quo_spec = QuotaCGE.model(sam_path=quo_sam)
    @test quo_spec.name == "QuotaCGE"

    irs_sam = joinpath(ScaleEconomyCGE.datadir(), "sam_2_2.csv")
    irs_spec = ScaleEconomyCGE.model(sam_path=irs_sam)
    @test irs_spec.name == "ScaleEconomyCGE"

    dyn_spec = DynCGE.model()
    @test dyn_spec.name == "DynCGE"

    cam_spec = CamCGE.model()
    @test cam_spec.name == "CamCGE"

    cammge_spec = CamMGE.model()
    @test cammge_spec.name == "CamMGE"


    cammcp_spec = CamMCP.model()
    @test cammcp_spec.name == "CamMCP"

    kor_spec = KorCGE.model()
    @test kor_spec.name == "KorCGE"

    kormcp_spec = KorMCP.model()
    @test kormcp_spec.name == "KorMCP"

    gtap_spec = GTAP7.model()
    @test gtap_spec.name == "GTAP7"
    @test validate_spec(gtap_spec).ok
    gtap_cde_blocks = filter(block -> block isa GTAP7.CDEPrivateDemandBlock, gtap_spec.model.blocks)
    @test length(gtap_cde_blocks) == 1
    gtap_investment_blocks = filter(block -> block isa GTAP7.GlobalInvestmentAllocationBlock, gtap_spec.model.blocks)
    @test length(gtap_investment_blocks) == 1
    gtap_block(spec, name) = only(filter(block ->
        hasproperty(block, :name) && getproperty(block, :name) == name,
        spec.model.blocks))
    gtap_scenarios = [
        (:factor_endowment, (
            endowment_region=:EAST,
            endowment_factor=:LABOUR,
            endowment_multiplier=1.01,
        )),
        (:productivity, (
            productivity_region=:EAST,
            productivity_product=:MANUF,
            productivity_multiplier=1.01,
        )),
        (:output_tax, (
            output_tax_region=:EAST,
            output_tax_product=:MANUF,
            output_tax_change=0.01,
        )),
        (:direct_tax, (
            direct_tax_region=:EAST,
            direct_tax_change=0.01,
        )),
        (:private_preference, (
            private_preference_region=:EAST,
            private_preference_product=:MANUF,
            private_preference_multiplier=1.01,
        )),
        (:government_preference, (
            government_preference_region=:EAST,
            government_preference_product=:MANUF,
            government_preference_multiplier=1.01,
        )),
        (:private_saving, (
            private_saving_region=:EAST,
            private_saving_multiplier=1.01,
        )),
        (:trade_cost, (
            trade_route=:MANUF_EAST_WEST,
            trade_cost_multiplier=1.01,
        )),
    ]
    gtap_scenario_specs = Dict{Symbol,JCGECore.RunSpec}()
    for (scenario_name, kwargs) in gtap_scenarios
        gtap_scenario = GTAP7.scenario(scenario_name; kwargs...)
        @test gtap_scenario.scenario.name == scenario_name
        @test validate_spec(gtap_scenario).ok
        gtap_scenario_specs[scenario_name] = gtap_scenario
    end
    @test_throws ErrorException GTAP7.scenario(:factor_endowment)

    gtap_mcp_spec = GTAP7MCP.model()
    @test gtap_mcp_spec.name == "GTAP7MCP"
    @test validate_spec(gtap_mcp_spec).ok
    @test GTAP7MCP.scenario(:trade_cost;
        trade_route=:MANUF_EAST_WEST,
        trade_cost_multiplier=1.01).scenario.name == :trade_cost

    @test isapprox(
        gtap_block(gtap_scenario_specs[:factor_endowment], :factor_market_EAST).params.FF[:LABOUR_EAST],
        1.01 * gtap_block(gtap_spec, :factor_market_EAST).params.FF[:LABOUR_EAST],
    )
    @test isapprox(
        gtap_block(gtap_scenario_specs[:productivity], :production_EAST).params.b[:MANUF_EAST],
        1.01 * gtap_block(gtap_spec, :production_EAST).params.b[:MANUF_EAST],
    )
    @test isapprox(
        gtap_block(gtap_scenario_specs[:output_tax], :government).params.tau_z[:MANUF_EAST],
        gtap_block(gtap_spec, :government).params.tau_z[:MANUF_EAST] + 0.01,
    )
    @test isapprox(
        gtap_block(gtap_scenario_specs[:direct_tax], :government).params.tau_d[:EAST],
        gtap_block(gtap_spec, :government).params.tau_d[:EAST] + 0.01,
    )
    @test gtap_block(gtap_scenario_specs[:private_preference], :cde_households).params.cde_share[(:MANUF_EAST, :EAST)] >
        gtap_block(gtap_spec, :cde_households).params.cde_share[(:MANUF_EAST, :EAST)]
    @test gtap_block(gtap_scenario_specs[:government_preference], :government).params.mu[(:MANUF_EAST, :EAST)] >
        gtap_block(gtap_spec, :government).params.mu[(:MANUF_EAST, :EAST)]
    @test isapprox(
        gtap_block(gtap_scenario_specs[:private_saving], :private_saving).params.ssp[:EAST],
        1.01 * gtap_block(gtap_spec, :private_saving).params.ssp[:EAST],
    )
    @test isapprox(
        gtap_block(gtap_scenario_specs[:trade_cost], :bilateral_trade).params.delivery_wedge[:MANUF_EAST_WEST],
        1.01 * gtap_block(gtap_spec, :bilateral_trade).params.delivery_wedge[:MANUF_EAST_WEST],
    )

    gtap_data = GTAP7.load_data()
    @test gtap_data.regions == [:EAST, :WEST]
    @test gtap_data.products == [:AGRI, :MANUF]
    @test length(gtap_data.routes) == 8
    @test length(gtap_data.substitution_parameter) == 4
    @test length(gtap_data.expansion_parameter) == 4

    gtap_calibrations = Dict(
        region => GTAP7._regional_calibration(gtap_data.sam_tables[region])
        for region in gtap_data.regions
    )
    gtap_goods = GTAP7._regional_mapping(gtap_data.products, gtap_data.regions)
    @test GTAP7._validate_flow_totals(gtap_data, gtap_calibrations) === nothing
    gtap_cde = GTAP7._cde_parameters(gtap_data, gtap_calibrations, gtap_goods)
    @test GTAP7._validate_cde_calibration(gtap_data, gtap_calibrations, gtap_cde, gtap_goods) === nothing

    mktempdir() do temp_dir
        malformed = joinpath(temp_dir, "malformed_gtap7_fixture")
        cp(GTAP7.datadir(), malformed)
        elasticity_file = joinpath(malformed, "elasticities.csv")
        text = read(elasticity_file, String)
        write(elasticity_file, replace(text, "AGRI,EAST,2,2,0.75,0.90" => "AGRI,EAST,2,2,0.0,0.90"))
        @test_throws ErrorException GTAP7.load_data(malformed)
    end


end

if get(ENV, "JCGE_SOLVE_TESTS", "0") == "1"
    @testset "JCGEExamples.Solve" begin
        function max_constraint_residual(result)
            max_abs = 0.0
            for eq in result.context.equations
                payload = eq.payload
                if payload isa NamedTuple && haskey(payload, :constraint) && payload.constraint !== nothing
                    obj = try
                        JuMP.constraint_object(payload.constraint)
                    catch
                        continue
                    end
                    val = try
                        JuMP.value(obj.func)
                    catch
                        continue
                    end
                    r = val
                    if obj.set isa MOI.EqualTo
                        r = val - obj.set.value
                    elseif obj.set isa MOI.GreaterThan
                        r = min(0.0, val - obj.set.lower)
                    elseif obj.set isa MOI.LessThan
                        r = max(0.0, val - obj.set.upper)
                    end
                    max_abs = max(max_abs, abs(r))
                end
            end
            return max_abs
        end

        sam_path = joinpath(StandardCGE.datadir(), "sam_2_2.csv")
        result = StandardCGE.solve(sam_path=sam_path; optimizer=Ipopt.Optimizer)
        status = MOI.get(result.context.model, MOI.TerminationStatus())
        @test status in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
        validate_report = JCGERuntime.validate_model(result.context; level=:basic)
        @test validate_report.ok

        result_simple = SimpleCGE.solve(; optimizer=Ipopt.Optimizer)
        status_simple = MOI.get(result_simple.context.model, MOI.TerminationStatus())
        @test status_simple in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        lrg_sam = joinpath(LargeCountryCGE.datadir(), "sam_2_2.csv")
        result_large = LargeCountryCGE.solve(sam_path=lrg_sam; optimizer=Ipopt.Optimizer)
        status_large = MOI.get(result_large.context.model, MOI.TerminationStatus())
        @test status_large in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        result_two = TwoCountryCGE.solve(; optimizer=Ipopt.Optimizer)
        status_two = MOI.get(result_two.context.model, MOI.TerminationStatus())
        @test status_two in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        mon_sam = joinpath(MonopolyCGE.datadir(), "sam_2_2.csv")
        result_mon = MonopolyCGE.solve(sam_path=mon_sam; optimizer=Ipopt.Optimizer)
        status_mon = MOI.get(result_mon.context.model, MOI.TerminationStatus())
        @test status_mon in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        quo_sam = joinpath(QuotaCGE.datadir(), "sam_2_2.csv")
        result_quo = QuotaCGE.solve(sam_path=quo_sam; optimizer=Ipopt.Optimizer)
        status_quo = MOI.get(result_quo.context.model, MOI.TerminationStatus())
        @test status_quo in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        irs_sam = joinpath(ScaleEconomyCGE.datadir(), "sam_2_2.csv")
        result_irs = ScaleEconomyCGE.solve(sam_path=irs_sam; optimizer=Ipopt.Optimizer)
        status_irs = MOI.get(result_irs.context.model, MOI.TerminationStatus())
        @test status_irs in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        result_dyn = DynCGE.solve(periods=1; optimizer=Ipopt.Optimizer)
        result_dyn = result_dyn[1]
        status_dyn = MOI.get(result_dyn.context.model, MOI.TerminationStatus())
        @test status_dyn in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)

        result_cam = CamCGE.solve(; optimizer=Ipopt.Optimizer)
        status_cam = MOI.get(result_cam.context.model, MOI.TerminationStatus())
        if status_cam in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
            @test true
        else
            @test max_constraint_residual(result_cam) <= 1e-5
        end

        cam_spec = CamCGE.model()
        sectors = cam_spec.model.sets.commodities
        labor = cam_spec.model.sets.factors

        function cam_val(sym::Symbol)
            return JuMP.value(result_cam.context.variables[sym])
        end

        for i in sectors
            x = cam_val(JCGEBlocks.global_var(:x, i))
            int = cam_val(JCGEBlocks.global_var(:int, i))
            cd = cam_val(JCGEBlocks.global_var(:cd, i))
            gd = cam_val(JCGEBlocks.global_var(:gd, i))
            id = cam_val(JCGEBlocks.global_var(:id, i))
            dst = cam_val(JCGEBlocks.global_var(:dst, i))
            @test isapprox(x, int + cd + gd + id + dst; atol=1e-5, rtol=1e-6)
        end

        gr = cam_val(:gr)
        tariff = cam_val(:tariff)
        duty = cam_val(:duty)
        indtax = cam_val(:indtax)
        @test isapprox(gr, tariff + duty + indtax; atol=1e-5, rtol=1e-6)

        govsav = cam_val(:govsav)
        total_gd = sum(cam_val(JCGEBlocks.global_var(:p, i)) * cam_val(JCGEBlocks.global_var(:gd, i)) for i in sectors)
        @test isapprox(gr, total_gd + govsav; atol=1e-5, rtol=1e-6)

        savings = cam_val(:savings)
        hhsav = cam_val(:hhsav)
        deprecia = cam_val(:deprecia)
        fsav = cam_val(:fsav)
        er = cam_val(:er)
        @test isapprox(savings, hhsav + govsav + deprecia + fsav * er; atol=1e-5, rtol=1e-6)

        for lc in labor
            lsum = sum(cam_val(JCGEBlocks.global_var(:l, i, lc)) for i in sectors)
            ls = cam_val(JCGEBlocks.global_var(:ls, lc))
            @test isapprox(lsum, ls; atol=1e-5, rtol=1e-6)
        end

        result_kor = KorCGE.solve(; optimizer=Ipopt.Optimizer)
        status_kor = MOI.get(result_kor.context.model, MOI.TerminationStatus())
        if status_kor in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
            @test true
        else
            @test max_constraint_residual(result_kor) <= 1e-5
        end

        result_gtap = GTAP7.solve(; optimizer=Ipopt.Optimizer)
        status_gtap = MOI.get(result_gtap.context.model, MOI.TerminationStatus())
        @test status_gtap in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
        @test JCGERuntime.validate_model(result_gtap.context; level=:basic).ok
        gtap_residuals = JCGERuntime.evaluate_residuals!(result_gtap.context)
        @test JCGERuntime.summarize_residuals(gtap_residuals).max_abs <= 1.0e-7
        for variable in (:Xp_AGRI_EAST, :Xp_MANUF_EAST, :Xp_AGRI_WEST, :Xp_MANUF_WEST)
            @test isapprox(JuMP.value(result_gtap.context.variables[variable]), 70.0; atol=1.0e-6, rtol=1.0e-8)
        end

        gtap_solve_scenarios = [
            (:factor_endowment, (
                endowment_region=:EAST,
                endowment_factor=:LABOUR,
                endowment_multiplier=1.01,
            )),
            (:productivity, (
                productivity_region=:EAST,
                productivity_product=:MANUF,
                productivity_multiplier=1.01,
            )),
            (:output_tax, (
                output_tax_region=:EAST,
                output_tax_product=:MANUF,
                output_tax_change=0.01,
            )),
            (:direct_tax, (
                direct_tax_region=:EAST,
                direct_tax_change=0.01,
            )),
            (:private_preference, (
                private_preference_region=:EAST,
                private_preference_product=:MANUF,
                private_preference_multiplier=1.01,
            )),
            (:government_preference, (
                government_preference_region=:EAST,
                government_preference_product=:MANUF,
                government_preference_multiplier=1.01,
            )),
            (:private_saving, (
                private_saving_region=:EAST,
                private_saving_multiplier=1.01,
            )),
            (:trade_cost, (
                trade_route=:MANUF_EAST_WEST,
                trade_cost_multiplier=1.01,
            )),
        ]
        for (scenario_name, kwargs) in gtap_solve_scenarios
            result_gtap_scenario = GTAP7.solve(
                scenario_name=scenario_name,
                kwargs...,
                optimizer=Ipopt.Optimizer,
            )
            status_gtap_scenario = MOI.get(result_gtap_scenario.context.model, MOI.TerminationStatus())
            @test status_gtap_scenario in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
            scenario_residuals = JCGERuntime.evaluate_residuals!(result_gtap_scenario.context)
            @test JCGERuntime.summarize_residuals(scenario_residuals).max_abs <= 2.0e-5
        end

    end
end

@testset "JCGEExamples.MCP" begin
    result_mcp = CamMCP.solve()
    @test result_mcp.summary.count >= 0

    result_mge = CamMGE.solve()
    @test result_mge.summary.count >= 0

    result_kor_mcp = KorMCP.solve()
    @test result_kor_mcp.summary.count >= 0

    result_kehomge = KEHOMGE.solve()
    @test result_kehomge.summary.count >= 0

    result_gtap_mcp = GTAP7MCP.solve()
    status_gtap_mcp = MOI.get(result_gtap_mcp.context.model, MOI.TerminationStatus())
    @test status_gtap_mcp in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT)
    @test result_gtap_mcp.summary.max_abs <= 1.0e-7


    for eq in result_mcp.context.equations
        payload = eq.payload
        if payload isa NamedTuple && eq.block != :init && eq.block != :numeraire
            @test haskey(payload, :mcp_var)
        end
    end
    for eq in result_kor_mcp.context.equations
        payload = eq.payload
        if payload isa NamedTuple && eq.block != :init && eq.block != :numeraire
            @test haskey(payload, :mcp_var)
        end
    end

    for eq in result_mge.context.equations
        payload = eq.payload
        if payload isa NamedTuple && eq.block != :init && eq.block != :numeraire
            @test haskey(payload, :mcp_var)
        end
    end

    for eq in result_kehomge.context.equations
        payload = eq.payload
        if payload isa NamedTuple && eq.block != :init && eq.block != :numeraire
            @test haskey(payload, :mcp_var)
        end
    end
    for eq in result_gtap_mcp.context.equations
        payload = eq.payload
        expr = payload isa NamedTuple ? get(payload, :expr, nothing) : nothing
        if expr isa JCGECore.EEq
            @test haskey(payload, :mcp_var)
        end
    end
end


if get(ENV, "JCGE_COMPARE_SOLUTIONS", "0") == "1"
    @testset "JCGEExamples.Compare.Solutions" begin
        using Pkg
        using CSV
        using DataFrames
        Pkg.add("StandardCGE")
        import StandardCGE as StdCGE
        import MPSGE

        sam_path = joinpath(StandardCGE.datadir(), "sam_2_2.csv")
        df = DataFrame(CSV.File(sam_path))
        if "Column1" ∉ names(df) && "label" ∈ names(df)
            rename!(df, "label" => "Column1")
        end
        tmp_dir = mktempdir()
        tmp_sam_path = joinpath(tmp_dir, "sam_2_2.csv")
        CSV.write(tmp_sam_path, df)

        sam_table = StdCGE.load_sam_table(tmp_sam_path)
        std_model, _, _ = StdCGE.solve_model(sam_table; optimizer_attributes=Dict("print_level" => 0))
        std_obj = JuMP.objective_value(std_model)
        std_Xp = JuMP.value.(std_model[:Xp])

        spec = StandardCGE.model(sam_path=sam_path)
        result = JCGERuntime.run!(spec; optimizer=Ipopt.Optimizer, dataset_id="standard_cge_compare")
        ours_model = result.context.model
        ours_obj = JuMP.objective_value(ours_model)
        goods = spec.model.sets.commodities
        ours_Xp = [JuMP.value(result.context.variables[Symbol("Xp_", g)]) for g in goods]

        @test isfinite(std_obj)
        @test isfinite(ours_obj)
        @test isapprox.(ours_Xp, std_Xp; rtol=1e-5, atol=1e-6) |> all

        cam_data = CamMGE._load_data()
        mpsge_model = CamMGE.mpsge_model()
        MPSGE.solve!(mpsge_model)

        result_mge = CamMGE.solve()
        result_mcp = CamMCP.solve(fix_er=true)

        cammge_vars = result_mge.context.variables
        cammcp_vars = result_mcp.context.variables

        sectors = CamMGE.model().model.sets.commodities
        traded = cam_data.traded
        labor = CamMGE.model().model.sets.factors

        function jcge_value(vars, sym)
            return JuMP.value(vars[sym])
        end

        for i in sectors
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:xd, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:xd, i)); rtol=1e-4, atol=1e-6)
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:pd, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:pd, i)); rtol=1e-4, atol=1e-6)
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:p, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:p, i)); rtol=1e-4, atol=1e-6)
        end

        for i in traded
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:m, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:m, i)); rtol=1e-4, atol=1e-6)
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:e, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:e, i)); rtol=1e-4, atol=1e-6)
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:pm, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:pm, i)); rtol=1e-4, atol=1e-6)
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:pe, i)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:pe, i)); rtol=1e-4, atol=1e-6)
        end

        for lc in labor
            @test isapprox(jcge_value(cammge_vars, JCGEBlocks.global_var(:wa, lc)),
                jcge_value(cammcp_vars, JCGEBlocks.global_var(:wa, lc)); rtol=1e-4, atol=1e-6)
        end

        for i in sectors
            xd_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:xd, i))
            pd_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:pd, i))
            p_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:p, i))

            xd_mpsge = JuMP.value(mpsge_model[:XD][i]) * cam_data.xd0[i]
            pd_mpsge = JuMP.value(mpsge_model[:PD][i]) * cam_data.pd0[i]
            p_mpsge = JuMP.value(mpsge_model[:P][i]) * cam_data.pd0[i]

            @test isapprox(xd_val, xd_mpsge; rtol=1e-4, atol=1e-6)
            @test isapprox(pd_val, pd_mpsge; rtol=1e-4, atol=1e-6)
            @test isapprox(p_val, p_mpsge; rtol=1e-4, atol=1e-6)
        end

        for i in traded
            m_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:m, i))
            pm_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:pm, i))
            pe_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:pe, i))

            m_mpsge = JuMP.value(mpsge_model[:M][i]) * cam_data.m0[i]
            pm_base = cam_data.pwm0[i] * cam_data.er * (1.0 + cam_data.tm0[i])
            pe_base = cam_data.pwe0[i] * cam_data.er / (1.0 + cam_data.te[i])
            pm_mpsge = JuMP.value(mpsge_model[:PM][i]) * pm_base
            pe_mpsge = JuMP.value(mpsge_model[:PE][i]) * pe_base

            @test isapprox(m_val, m_mpsge; rtol=1e-4, atol=1e-6)
            @test isapprox(pm_val, pm_mpsge; rtol=1e-4, atol=1e-6)
            @test isapprox(pe_val, pe_mpsge; rtol=1e-4, atol=1e-6)
        end

        for lc in labor
            wa_val = jcge_value(cammge_vars, JCGEBlocks.global_var(:wa, lc))
            wa_mpsge = JuMP.value(mpsge_model[:PL][lc]) * cam_data.wa0[lc]
            @test isapprox(wa_val, wa_mpsge; rtol=1e-4, atol=1e-6)
        end

    end
end
