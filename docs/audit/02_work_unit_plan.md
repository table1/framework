# Audit Work Unit Plan

Each unit below should be small enough for a focused review pass. Update `Status` to `DONE` once the unit is fully audited and any follow-up tasks are logged.

## Unit: Repo Metadata & Packaging
Status: DONE  
Scope: `DESCRIPTION`, `NAMESPACE`, `LICENSE*`, `package.json`, `Makefile`, `docker-compose.test.yml`, root scripts (`build.sh`, `Makefile`). Confirm versioning, dependencies, and release metadata align with 1.0.

## Unit: Session & Initialization Core
Status: DONE  
Scope: `R/scaffold.R`, `R/init.R`, `R/configure.R`, `R/configure_ai.R`, `R/ide_config.R`, `R/ai_sync.R`, `R/on_load.R`, `R/zzz.R`. Verify session bootstrap, AI integration, and options defaults.

## Unit: Configuration System
Status: DONE  
Scope: `R/config.R`, `R/build_settings.R`, `R/env.R`, `R/schema.R`, `R/status.R`. Review settings loading, validation, and schema helpers—including v2 rewrite plans in `docs/`.

## Unit: Data Access & Integrity
Status: DONE  
Scope: `R/data_read.R`, `R/data_write.R`, `R/framework_db.R`, `R/framework_util.R`, `R/cache_*`, `R/results_*`, `R/scratch.R`. Check data catalog, caching, results persistence, and metadata tracking.

## Unit: Database Connections & CRUD
Status: DONE  
Scope: `R/connections*.R`, `R/connection_helpers.R`, `R/connection_pool.R`, `R/driver_helpers.R`, `R/drivers.R`, `R/crud.R`, `R/transactions.R`, `R/queries.R`, `R/framework_view.R`. Validate multi-database support, pooling, and query APIs.

## Unit: Security & Encryption
Status: DONE  
Scope: `R/encryption_core.R`, `R/security_audit.R`, `R/git_hooks.R`, `R/packages.R` (renv portions), `docs/security` (if applicable). Confirm encryption workflows, security audit coverage, and git integration.

## Unit: CLI & Tooling Scripts
Status: DONE  
Scope: `R/install_cli.R`, `R/console.R`, `R/make_notebook.R`, `R/make_script.R`, `R/stubs.R`, plus all files in `inst/bin/`. Ensure CLI behaviors, shell scripts, and completions are production-ready.

## Unit: Templates & Project Scaffolds
Status: DONE  
Scope: `inst/templates/**`, `inst/project_structure/**`, `inst/stubs/**`, `resources/`, `results/` seed files. Check template accuracy, placeholder values, and alignment with new defaults.

## Unit: Documentation Set
Status: DONE  
Scope: Remaining files in `docs/` (beyond README-focused notes), `docs/analysis/**`, `docs/debug/**`, `docs/features/**`, `CLAUDE.md`, `api.md`, `dev_mode.md`, `readme-parts/**`, etc. Track copy edits and ensure version ready messaging.

## Unit: Testing Suite
Status: DONE  
Scope: `tests/testthat/**`, fixtures, `_snaps`, helper scripts, plus `tests/docker/**`. Validate coverage, update expectations for 1.0, and identify gaps needing new tests.

## Unit: Man Pages & Generated Docs
Status: DONE  
Scope: `man/*.Rd`, `inst/templates/framework-cheatsheet.fr.md`, any generated outputs. Confirm documentation matches code behavior after audit fixes.

## Unit: Build Outputs & Legacy Artifacts
Status: DONE  
Scope: `framework_0.1.0.tar.gz`, `framework.Rcheck/**`, `results/**`, `resources/**`. Determine which artifacts can be removed, regenerated, or ignored; ensure release package tarball is updated for 1.0 or excluded from repo.

## Unit: Continuous Integration & Automation
Status: DONE  
Scope: Look for GitHub Actions, scripts, or external integrations (if absent, note gap). Confirm release workflow exists or log follow-up tasks.
