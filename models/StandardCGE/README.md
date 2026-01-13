# StandardCGE

Julia implementation of the standard CGE model from Hosoe, Gasawa, and Hashimoto (Chapter 6).

## Block usage (form-aware)
This model uses the form-aware wrappers for production, household demand, and utility:
```julia
prod = JCGEBlocks.production(:prod, activities, factors, commodities; form=:cd_leontief, params=params)
hh = JCGEBlocks.household_demand(:household, Symbol[], commodities, factors; form=:cd, consumption_var=:Xp, params=params)
util = JCGEBlocks.utility(:utility, Symbol[], commodities; form=:cd, consumption_var=:Xp, params=(alpha=params.alpha,))
```

Equation dump is saved in `packages/JCGEExamples/models/StandardCGE/equations.md`.
