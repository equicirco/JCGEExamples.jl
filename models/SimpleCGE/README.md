# SimpleCGE

Simple CGE model from Chapter 5 of:
Hosoe, N, Gasawa, K, and Hashimoto, H.
Handbook of Computable General Equilibrium Modeling.
University of Tokyo Press, Tokyo, Japan, 2004.

This model is intended for testing and development, using the SAM in `data/sam_2_2.csv`.

## Block usage (form-aware)
The simple model uses the form-aware wrappers for production, household demand, and utility:
```julia
prod = JCGEBlocks.production(:prod, goods, factors, Symbol[]; form=:cd, params=params)
hh = JCGEBlocks.household_demand(:household, Symbol[], goods, factors; form=:cd, consumption_var=:X, params=params)
util = JCGEBlocks.utility(:utility, Symbol[], goods; form=:cd, consumption_var=:X, params=(alpha=alpha,))
```

## Output (equation description)
To dump a human-readable equation listing for the model:
```julia
using JCGEOutput
using JCGERuntime

spec, start, params = SimpleCGE.model(; sam_path="data/sam_2_2.csv")
result = JCGERuntime.run!(spec; optimizer=Ipopt.Optimizer)

equations_md = render_equations(result.context; format=:markdown, level=:equation)
write("simplecge_equations.md", equations_md)
```

Equation dump is saved in `packages/JCGEExamples/models/SimpleCGE/equations.md`.
