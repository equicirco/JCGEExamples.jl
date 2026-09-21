# GTAP7

`GTAP7` is an independent, data-driven implementation of the core GTAP
Standard 7 economic structure. The bundled dataset is a small open synthetic
fixture; licensed GTAP data are neither included nor read directly.

```julia
using JCGEExamples.GTAP7

spec = GTAP7.baseline()
result = GTAP7.solve()

shock = GTAP7.scenario(:factor_endowment;
    endowment_region=:EAST,
    endowment_factor=:LABOUR,
    endowment_multiplier=1.10)

trade_cost = GTAP7.scenario(:trade_cost;
    trade_route=:MANUF_EAST_WEST,
    trade_cost_multiplier=1.10)
```

The equality/NLP layer represents regional production, GTAP's non-homothetic
CDE private demand, bilateral Armington sourcing and CET sales allocation,
regional external accounts, and global saving--investment allocation. The
validated counterfactual layer supports selected regional factor endowments,
productivity, output and direct taxes, private and government preferences,
private saving, and a delivery-cost change on one trade route. The latter acts
on the route's calibrated delivery wedge only; it is not a tariff or a
transport-margin account. GTAP-specific production nests, transport margins,
tariff accounting, and an alternative MCP formulation remain later extensions.

See the bundled [input schema](https://github.com/equicirco/JCGEExamples.jl/blob/main/models/GTAP7/schema.md)
for the portable table contract for user-supplied licensed GTAP aggregations.
