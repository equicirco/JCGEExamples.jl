# JCGEExamples Changelog
All notable changes to this project will be documented in this file.
Releases use semantic versioning as in 'MAJOR.MINOR.PATCH'.

## Change entries
Added: For new features that have been added.
Changed: For changes in existing functionality.
Deprecated: For once-stable features removed in upcoming releases.
Removed: For features removed in this release.
Fixed: For any bug fixes.
Security: For vulnerabilities.

## [0.2.0] - 2026-09-21
### Added
- GTAP7: an independent, data-driven implementation of the core GTAP Standard 7 multi-region structure, using a normalized input contract and an open synthetic fixture.
- Declared GTAP7 counterfactuals for regional factor endowments, productivity, output and direct taxes, private and government demand preferences, private saving, and bilateral delivery costs.
- GTAP7 documentation, input-schema documentation, and construction and solver-backed scenario tests.

## [0.1.0] - 2026-01-22
### Added
- Project layout for JCGE example submodules and model resources.
- Example model suite: StandardCGE, SimpleCGE, LargeCountryCGE, TwoCountryCGE, MonopolyCGE, QuotaCGE, ScaleEconomyCGE, DynCGE.
- Cameroon models: CamCGE (CGE), CamMGE (MPSGE), CamMCP (MCP).
- KEHOMGE multiple-equilibria model and Korea CGE/MCP variants.
- Model equation dumps and documentation pages per model.
- CI workflows for core tests, solver tests, and solution comparison.
