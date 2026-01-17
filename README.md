<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/src/assets/jcge_examples_logo_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="docs/src/assets/jcge_examples_logo_light.png">
  <img alt="JCGE Examples logo" src="docs/src/assets/jcge_examples_logo_light.png" height="150">
</picture>

# JCGEExamples

## What is a CGE?
A Computable General Equilibrium (CGE) model is a quantitative economic model that represents an economy as interconnected markets for goods and services, factors of production, institutions, and the rest of the world. It is calibrated with data (typically a Social Accounting Matrix) and solved numerically as a system of nonlinear equations until equilibrium conditions (zero-profit, market-clearing, and income-balance) hold within tolerance.

## What is JCGE?
[JCGE](https://jcge.org) is a block-based CGE modeling and execution framework in Julia. It defines a shared RunSpec structure and reusable blocks so models can be assembled, validated, solved, and compared consistently across packages.

## What is this package?
A package that bundles **model definitions** (as submodules) for the [JCGE](https://jcge.org) ecosystem.

## What belongs here
- Named model modules implemented as Julia submodules.
- Model constructors returning a **spec** or **builder object** (recommended: `RunSpec`/`ModelSpec` + optional default scenarios).
- Small toy datasets that are safe to ship in-repo (optional), under `models/<ModelName>/data/`.

## What does NOT belong here
- Core framework code (data model, calibration, runtime, generic blocks): those stay in `JCGECore`, `JCGECalibrate`, `JCGERuntime`, `JCGEBlocks`, `JCGEOutput`, `JCGEAgentInterface`, `JCGEImportMPSGE`, `JCGEImportData`.
- Large, licensed, or country SAM datasets unless distribution rights are clear.
- Solver-specific configuration that is not part of the model definition.

## Expected user-facing usage
Typical usage should look like:

- `using JCGEExamples`
- `using JCGEExamples.<ModelName>`
- `spec = <ModelName>.model()` (returns a spec/object that the framework can build/run)

## RunSpec sections (model structure)
Models are assembled via named sections to enforce a consistent RunSpec skeleton.
Canonical section names:
- `:production`, `:factors`, `:government`, `:savings`, `:households`, `:prices`,
  `:external`, `:trade`, `:markets`, `:objective`, `:init`, `:closure`

All sections should be present (empty is allowed), and the following must be non-empty:
- `:production`, `:households`, `:markets`

## Folder layout
- `src/`: package module entrypoint
- `models/<ModelName>/`: module file and all model-specific resources
  - `models/<ModelName>/<ModelName>.jl`: model submodule
  - `models/<ModelName>/data/`: optional small benchmark inputs
  - `models/<ModelName>/docs/`: optional model notes and documentation

## Models
- `StandardCGE`: Chapter 6, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `SimpleCGE`: Chapter 5, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `LargeCountryCGE`: Chapter 10.2, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `TwoCountryCGE`: Chapter 10.3, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `MonopolyCGE`: Chapter 10.4, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `QuotaCGE`: Chapter 10.5, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `ScaleEconomyCGE`: Chapter 10.6, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.
- `DynCGE`: Recursive-dynamic model, Hosoe, N., Gasawa, K., Hashimoto, H. Textbook of Computable General Equilibrium Modeling: Programming and Simulations, 2nd Edition, University of Tokyo Press. (Japanese edition)
- `CamCGE`: Cameroon CGE model, Condon, T, Dahl, H, and Devarajan, S. Implementing a Computable General Equilibrium Model on GAMS - The Cameroon Model. The World Bank, 1987.
- `CamMGE`: Cameroon CGE model, MPSGE syntax, Condon, T, Dahl, H, and Devarajan, S. Implementing a Computable General Equilibrium Model on GAMS - The Cameroon Model. The World Bank, 1987.
- `CamMCP`: Cameroon CGE model as MCP, Condon, T, Dahl, H, and Devarajan, S. Implementing a Computable General Equilibrium Model on GAMS - The Cameroon Model. The World Bank, 1987.
- `KEHOMGE`: Multiple equilibria model in MPSGE, Kehoe, T, A Numerical Investigation of the Multiplicity of Equilibria. Mathematical Programming Study 23 (1985), 240-258.
- `KorCGE`: Korea CGE model, Chapter 11 in Chenery et al., 1986.
- `KorMCP`: Korea CGE model as MCP, Chapter 11 in Chenery et al., 1986.

## Optional solve tests (CI)
Solver-based tests are gated behind `JCGE_SOLVE_TESTS=1` and run via a manual GitHub Actions workflow:
- Workflow name: `Solve Tests`
- Workflow: `.github/workflows/solve-tests.yml`
- Trigger: workflow_dispatch only
- Command: `julia --project=packages/JCGEExamples -e 'using Pkg; Pkg.instantiate(); Pkg.test()'`

## MCP solver and PATH license
MCP models use PATH via `PATHSolver.jl`. PATH can run without a license for small instances (up to 300 variables and 2000 non-zeros); larger problems require a license.

To use a license string, either:
- set `PATH_LICENSE_STRING="<LICENSE STRING>"`, or
- call `PATHSolver.c_api_License_SetString("<LICENSE STRING>")` before solving.

### Running MCP models
With a license:
- `PATH_LICENSE_STRING="..." JCGE_MCP_SOLVE=1 julia --project=packages/JCGEExamples -e 'using Pkg; Pkg.test()'`
- or in code:
```julia
using JCGEExamples.CamMCP
result = CamMCP.solve(license_string="...")
```

Without a license (small problems only):
- `JCGE_MCP_SOLVE=1 julia --project=packages/JCGEExamples -e 'using Pkg; Pkg.test()'`
- or in code:
```julia
using JCGEExamples.CamMCP
result = CamMCP.solve()
```

If the problem exceeds PATH's free limits, `CamMCP.solve()` will error unless a license is provided.
## Optional solution comparison
A separate manual workflow compares results against `StandardCGE.jl` and `MPSGE`:
- Workflow: `.github/workflows/compare-solutions.yml`
- Env flags: `JCGE_SOLVE_TESTS=1`, `JCGE_COMPARE_SOLUTIONS=1`

## How to cite
If you use the JCGE framework, please cite:

Boero, R. *JCGE - Julia Computable General Equilibrium Framework* [software], 2026.
DOI: 10.5281/zenodo.18282436
URL: https://JCGE.org

```bibtex
@software{boero_jcge_2026,
  title  = {JCGE - Julia Computable General Equilibrium Framework},
  author = {Boero, Riccardo},
  year   = {2026},
  doi    = {10.5281/zenodo.18282436},
  url    = {https://JCGE.org}
}
```

If you use this package, please cite:

Boero, R. *JCGEExamples.jl - Reference models and examples for JCGE.* [software], 2026.
DOI:
URL: https://Examples.JCGE.org
SourceCode: https://github.com/equicirco/JCGEExamples.jl

```bibtex
@software{boero_jcgeexamples_2026,
  title  = {JCGEExamples.jl - Reference models and examples for JCGE.},
  author = {Boero, Riccardo},
  year   = {2026},
  doi    = {},
  url    = {https://Examples.JCGE.org}
}
```

If you use a specific tagged release, please cite the version DOI assigned on Zenodo for that release (preferred for exact reproducibility).
