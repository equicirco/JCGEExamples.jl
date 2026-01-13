# Models

Add one directory per model submodule:

- `models/<ModelName>/<ModelName>.jl` defining `module <ModelName> ... end`
- `models/<ModelName>/data/` for any model-specific inputs
- Export `model()` as the minimal required API.
