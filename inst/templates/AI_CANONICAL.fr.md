# Framework Project – Canonical Instructions

## Project Overview

Framework standardizes R research projects so every analysis uses the same layout, tooling, and security model. These instructions describe how assistants should interact with any Framework-generated project.

## Directory Model

- `inputs/raw/`, `inputs/intermediate/`, `inputs/final/` – private data; gitignored
- `reference/` – external docs/codebooks for context
- `notebooks/` – Quarto or RMarkdown notebooks
- `scripts/` – reusable R scripts / automation
- `functions/` – helper R files auto-sourced by `scaffold()`
- `outputs/public/` – shareable artifacts tracked in git
- `outputs/private/`, `cache/`, `scratch/` – gitignored working space

## Session Workflow

```r
library(framework)
scaffold()
```

`scaffold()` loads packages, sources `functions/`, configures notebooks, connections, ggplot theme, and seeds.

### Create assets
- `make_notebook("analysis")` → `notebooks/analysis.qmd`
- `make_script("etl")` → `scripts/etl.R`

### Data helpers
- `data_read("catalog_entry")`
- `data_save(object, "name", encrypt = TRUE)`
- `data_list()` / `data_integrity_check()`

### Results helpers
- `result_save(plot, "figure-1", type = "plot", private = FALSE)`
- `result_get("figure-1")`, `result_list()`

### Caching
```r
output <- get_or_cache(
  "model_fit",
  expr = fit_complex_model(data),
  expire_days = 7
)
```

## Assistant Guardrails

1. Always rely on Framework helpers (`scaffold()`, `make_*`, `data_*`, `result_*`).
2. Respect public vs private directories—never suggest committing gitignored paths.
3. Store secrets only in `.env`; never hard-code credentials or tokens.
4. Encourage data catalog updates instead of ad-hoc file paths.
5. Suggest caching for expensive computations and call `cache_clear()` when inputs change.
6. Prefer config-driven paths via `config("directories.notebooks")` rather than literals.
7. Promote reproducibility: renv, deterministic seeds, documented notebooks.
8. When unsure, ask for clarification instead of guessing file structure.

## Documentation
- Project README / notebooks live in `notebooks/` and `docs/` (if present).
- Settings live in `settings.yml` or split files under `settings/`.

Treat this file as the single canonical source. Any assistant-specific files (CLAUDE.md, AGENTS.md, `.github/copilot-instructions.md`) should contain an exact copy generated from here unless the user explicitly customizes them.
