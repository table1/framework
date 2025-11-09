# Framework Research Project - Claude Code Instructions

## Project Overview

This is a Framework-based R research project for reproducible data analysis with comprehensive data management, caching, and results tracking.

Framework provides:
- Standardized directory structure for data workflows
- Configuration-driven analysis pipelines
- Data cataloging and integrity tracking
- Built-in caching system for expensive computations
- Secure handling of sensitive data
- Results management with public/private separation

## Directory Structure

### Data Directories
- `inputs/raw/` - Original data files as delivered (private, gitignored by default)
- `inputs/intermediate/` - Cleaned datasets from processing steps (private, gitignored)
- `inputs/final/` - Analysis-ready datasets (private, gitignored)
- `inputs/reference/` - Codebooks, documentation, external references
- `cache/` or `outputs/cache/` - Cached computation results (gitignored)
- `scratch/` - Temporary workspace files (gitignored, auto-cleaned)

### Working Directories
- `notebooks/` - Quarto (.qmd) or RMarkdown (.Rmd) analysis notebooks
- `scripts/` - Standalone R scripts for automation and batch jobs
- `functions/` - Custom R functions for this project (auto-sourced by scaffold())
- `outputs/public/` - **SHAREABLE** outputs like figures and tables (tracked in git)
- `outputs/private/` - Sensitive or draft outputs (gitignored)

### Configuration
- `config.yml` or `settings.yml` - Project configuration (directories, packages, data catalog, connections)
- `settings/` - Optional split config files (data.yml, connections.yml) for complex projects
- `.env` - Secrets and environment variables (**ALWAYS gitignored, never commit**)
- `framework.db` - SQLite metadata database (integrity, cache, results tracking)

## Common Workflows

### 1. Start Working Session
```r
library(framework)
scaffold()  # Loads environment, sources functions/, installs/attaches packages
```

The `scaffold()` function:
- Sources all R files from `functions/` directory
- Installs and loads packages from config
- Sets up database connections
- Configures ggplot2 theme (if enabled)
- Sets random seed for reproducibility (if configured)

### 2. Create Analysis Notebook
```r
make_notebook("exploratory-analysis")
# Creates notebooks/exploratory-analysis.qmd

make_notebook("model-fitting", format = "rmarkdown")
# Creates notebooks/model-fitting.Rmd for RMarkdown users
```

### 3. Load Data
```r
# From data catalog (recommended)
data <- data_load("my_dataset")

# Direct file load
data <- data_load("inputs/reference/file.csv")
data <- data_load("inputs/final/processed.rds")

# Encrypted data (requires sodium, prompts for passphrase)
sensitive <- data_load("confidential_data")
```

### 4. Save Results
```r
# Public results (committed to git)
result_save(my_plot, "figure-1", type = "plot")
# → outputs/public/figures/figure-1.png

result_save(summary_table, "table-1", type = "table")
# → outputs/public/tables/table-1.csv

# Private results (gitignored)
result_save(sensitive_plot, "private-figure", type = "plot", private = TRUE)
# → outputs/private/docs/

# Blinded results (prevents accidental viewing)
result_save(treatment_data, "blinded-results", blind = TRUE)
```

### 5. Caching Expensive Computations
```r
# Cache with 7-day expiration
expensive_result <- get_or_cache(
  "model_fit_cache",
  expr = {
    fit_complex_model(data)
  },
  expire_days = 7
)

# Clear when data changes
cache_clear("model_fit_cache")

# List all caches
cache_list()
```

## Security Best Practices

### Data Privacy - CRITICAL
- **NEVER commit raw data or sensitive files**
- `inputs/`, `outputs/private/`, `cache/`, `scratch/` are gitignored by default
- Store credentials in `.env`, **NEVER in code or config files**
- Use `result_save(..., private = TRUE)` for sensitive outputs
- Defense-in-depth: nested .gitignore files prevent accidental commits

### Encrypted Data
```r
data_save(sensitive_data, "confidential", encrypt = TRUE)
# Prompts for passphrase

data <- data_load("confidential")
# Prompts to decrypt
```

## Framework-Specific Functions

### Project Setup
- `scaffold()` - Load project environment (call at start of each session)

### Notebooks & Scripts
- `make_notebook(name, format)` - Create analysis notebook (.qmd or .Rmd)
- `make_script(name)` - Create R script in scripts/

### Data Management
- `data_load(name)` - Load from catalog or path
- `data_save(data, name, encrypt)` - Save with integrity tracking
- `data_list()` - Show catalog entries
- `data_integrity_check(name)` - Verify data hasn't been tampered with

### Results
- `result_save(object, name, type, blind, private)`
- `result_get(name)` - Retrieve result
- `result_list()` - Show all results
- `result_delete(name)`

### Caching
- `get_or_cache(name, expr, expire_days)`
- `cache_get(name)`
- `cache_clear(name)`
- `cache_list()`

### Configuration
- `config(key, default)` - Access config with dot notation
  - `config("directories.notebooks")` → "notebooks"
  - `config("connections.db.host")` → database host

## Tips for AI Assistants

When working with this Framework research project:

1. **Use Framework functions** for data/results (maintains integrity tracking)
2. **Respect public/private separation** - don't suggest moving files between them
3. **Use config() for paths** - never hardcode directories
4. **Suggest data catalog entries** for frequently-used datasets
5. **Recommend caching** for expensive model fits or simulations
6. **Check scaffold() was called** before using framework functions
7. **Use make_notebook()** instead of manually creating files
8. **Security first** - never suggest committing .env or private/ directories
9. **Reproducibility** - encourage using random seed and renv for critical analyses
10. **Documentation** - always add descriptions to data catalog entries

## Framework Package
- GitHub: https://github.com/table1/framework
- Author: Erik Westlund
- License: MIT
