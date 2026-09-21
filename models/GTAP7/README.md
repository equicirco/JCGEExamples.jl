# GTAP7

Independent, data-driven implementation of the core structure of the GTAP
Standard 7 model. It is being developed directly from the published GTAP
theory and documentation, with no dependency on another implementation.

The current layer includes regional production, GTAP's non-homothetic CDE
private demand, differentiated bilateral sourcing and sales, regional external
accounts, and a global saving--investment closure. It solves as an equality/NLP
system with Ipopt. Declared counterfactuals cover regional factor endowments,
productivity, output and direct taxes, private and government preferences,
private saving, and the delivery cost of one bilateral trade route. The bundled
two-region/two-product data are synthetic and exist solely to test calibration,
closure, and scenario execution.

```julia
shock = scenario(:factor_endowment;
    endowment_region=:EAST,
    endowment_factor=:LABOUR,
    endowment_multiplier=1.10)

trade_cost = scenario(:trade_cost;
    trade_route=:MANUF_EAST_WEST,
    trade_cost_multiplier=1.10)
```

`trade_cost` changes the route's calibrated delivery wedge. It is neither a
tariff nor a transport-margin account; those GTAP components are outside this
core example.

GTAP data are licensed and are not included. See [schema.md](schema.md) for
the normalized input tables expected from a user-supplied licensed aggregation.

Reference: Hertel, T. W. (ed.), *Global Trade Analysis: Modeling and
Applications*, Cambridge University Press, 1997.
