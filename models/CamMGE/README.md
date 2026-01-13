# CamMGE

Cameroon general equilibrium model written in MPSGE syntax, ported to JCGE blocks.

Reference:
- Condon, T, Dahl, H, and Devarajan, S. Implementing A Computable General Equilibrium Model on GAMS - the Cameroon Model. The World Bank, 1987.

Notes:
- The MPSGE.jl specification lives in `packages/JCGEExamples/models/CamMGE/mpsge_model.jl`.
- The block-based MCP port is implemented in `packages/JCGEExamples/models/CamMGE/CamMGE.jl` (generated from the importer workflow).
- Equation dump is saved in `packages/JCGEExamples/models/CamMGE/equations.md`.
