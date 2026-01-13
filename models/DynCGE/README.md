# DynCGE

Recursive-dynamic standard CGE model ported from `dyncge.410` in the GAMS model
library. Reference:

Hosoe, N., Gasawa, K., Hashimoto, H. Textbook of Computable General
Equilibrium Modeling: Programming and Simulations, 2nd Edition,
University of Tokyo Press. (Japanese edition)

This port matches the handbook structure:
- Cobb-Douglas production with Leontief intermediates.
- Armington and CET trade blocks.
- Composite investment and capital-stock evolution.
- Mobile and immobile factors with sector-specific factor prices.
- Numeraire on the price level (`PRICE = 1`).

## Recursive-dynamic runs
Use the helper to solve multiple periods with state updates between solves:
```julia
using JCGEExamples.DynCGE
results = DynCGE.run_recursive(periods=30)
```
Between periods the runner updates `FF` (mobile factors), `KK`, `Xg`, and `Sf`,
and keeps `PRICE` fixed at 1, matching the GAMS loop logic.

Equation dump is saved in `packages/JCGEExamples/models/DynCGE/equations.md`.
