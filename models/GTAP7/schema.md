# GTAP7 normalized input contract

`GTAP7` does not distribute GTAP data or GTAP source code. The bundled
`data/synthetic` directory is an open, internally balanced fixture used only
for package tests. A user holding an appropriately licensed GTAP aggregation
can create the same portable tables in another directory and pass it through
`data_dir`.

## Required tables

- `sets.csv`: `set,item`, with `region`, `product`, and `factor` members.
- `sam_<REGION>.csv`: one square regional SAM per `region`, with the product
  and factor labels listed in `sets.csv`, and the accounts `IDT`, `TRF`,
  `HOH`, `GOV`, `INV`, and `EXT`.
- `trade.csv`: `id,product,origin,destination,value,delivery_wedge`.
  `value` is the producer-side base value of the route and `delivery_wedge`
  represents the calibrated delivery cost. Each product must have positive
  bilateral flows that exactly exhaust both regional output and regional
  composite demand.
  `ROW` may occur as an origin or a destination, but is not a modelled
  production region.
- `elasticities.csv`:
  `product,region,armington_elasticity,cet_elasticity,subpar,incpar`.
  `subpar` and `incpar` are GTAP's CDE substitution and expansion parameters
  for private demand. All four behavioural parameters must be strictly positive.

The first implementation uses a one-to-one product/activity correspondence.
This keeps the test fixture transparent while GTAP-specific nested production,
transport-margin, and tariff layers are added against the same portable contract.

## Data boundary

The GTAP database is licensed. This package therefore contains neither GTAP
database extracts nor a reader for distribution formats. Dataset conversion is
deliberately separated from this model example; a future general importer can
be added only after the normalized contract has been exercised with licensed
data.
