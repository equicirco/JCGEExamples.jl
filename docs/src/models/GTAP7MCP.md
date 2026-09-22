# GTAP7MCP

`GTAP7MCP` is the mixed-complementarity counterpart to the compact
[`GTAP7`](GTAP7.md) example. Both formulations use the same open synthetic
fixture and expose the same declared counterfactuals.

```julia
using JCGEExamples.GTAP7MCP

result = GTAP7MCP.solve()

shock = GTAP7MCP.scenario(:factor_endowment;
    endowment_region=:EAST,
    endowment_factor=:LABOUR,
    endowment_multiplier=1.10)
```

The MCP pairs the compact model's production, demand, trade, market-clearing,
external-account, and saving--investment conditions with their model
variables. The existing commodity numeraire and one redundant market-clearing
identity provide the closure. `solve` uses `PATHSolver.jl`; the bundled
synthetic instance is below PATH's free problem-size limit.

This remains a compact, data-driven GTAP Standard 7 example. It does not
bundle, read, or redistribute the licensed GTAP database.
