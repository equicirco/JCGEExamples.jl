# CamCGE

Cameroon CGE model based on:
Condon, T, Dahl, H, and Devarajan, S.
Implementing a Computable General Equilibrium Model on GAMS - The Cameroon Model.
The World Bank, 1987.

This port uses the embedded IO, capital composition, wage distribution, and employment tables from the
original formulation.

Note: Ipopt can report `LOCALLY_INFEASIBLE` for this model even when equation residuals are within
the numerical tolerance; the solve test accepts the solution if max constraint residual is <= 1e-5.

Equation dump is saved in `packages/JCGEExamples/models/CamCGE/equations.md`.
