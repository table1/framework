# Framework Project - Claude Code Instructions

## Project Overview

This is a Framework-based R project for reproducible data analysis.

Framework provides:
- Standardized directory structure
- Configuration-driven workflows
- Data cataloging and integrity tracking
- Built-in caching system
- Secure handling of sensitive data

## Directory Structure

### Data Directories
- `data/source/` - Original data files (public/private subdirs)
  - `data/source/public/` - Non-sensitive source data (tracked in git)
  - `data/source/private/` - Sensitive source data (gitignored, nested .gitignore for defense-in-depth)
- `data/in_progress/` - Intermediate analysis data (public/private subdirs)
- `data/final/` - Cleaned, analysis-ready datasets (public/private subdirs)
- `data/cached/` - Cached computation results (gitignored)
- `data/scratch/` - Temporary files (gitignored, auto-cleaned)

### Working Directories
- `notebooks/` - Quarto (.qmd) or RMarkdown (.Rmd) analysis notebooks
- `scripts/` - Standalone R scripts for automation
- `functions/` - Custom R functions for this project (auto-sourced by scaffold())
- `results/public/` - Shareable outputs like figures and tables (tracked in git)
- `results/private/` - Sensitive outputs (gitignored)

### Configuration Files
- `config.yml` - Main project configuration (directories, packages, data catalog, connections)
- `settings/` - Optional split config files for complex projects (data.yml, connections.yml, etc.)
- `.env` - Environment variables and secrets (ALWAYS gitignored, never commit)
- `framework.db` - SQLite database tracking data integrity, cache, and results metadata

### Git and Environment
- `.gitignore` - Root-level git exclusions
- `renv.lock` - Package versions (if renv enabled)
- `.Rproj` - RStudio project file

## Common Workflows

### 1. Start Working Session
```r
library(framework)
scaffold()  # Loads environment, sources functions/, installs packages from config
```

The `scaffold()` function:
- Loads all R files from `functions/` directory
- Installs and loads packages listed in config.yml
- Sets up database connections
- Prepares the working environment

### 2. Create Analysis Notebook
```r
make_notebook("exploratory-analysis")
# Creates notebooks/exploratory-analysis.qmd with standardized YAML header

make_notebook("model-fitting", format = "rmarkdown")
# Creates notebooks/model-fitting.Rmd for RMarkdown users
```

Notebooks are created with:
- Proper YAML frontmatter (title, author, date)
- Framework-specific setup chunk that calls scaffold()
- Standard section headers for reproducible analysis

### 3. Load Data

**From Data Catalog:**
```r
# Data catalog defined in config.yml
data <- load_data("my_dataset")
```

**Direct File Load:**
```r
# CSV
data <- load_data("data/source/public/file.csv")

# RDS
data <- load_data("data/final/public/processed.rds")

# Encrypted data (requires sodium package, prompts for passphrase)
sensitive <- load_data("confidential_data")
```

### 4. Save Results
```r
# Save plot
result_save(my_plot, "figure-1", type = "plot")
# Saves to results/public/figure-1.png

# Save table
result_save(summary_table, "table-1", type = "table")
# Saves to results/public/table-1.csv

# Save to private results
result_save(sensitive_plot, "private-figure", type = "plot", private = TRUE)
# Saves to results/private/

# Mark as blind for unbiased analysis
result_save(treatment_data, "blinded-results", blind = TRUE)
# Prevents accidental viewing until unblinded
```

### 5. Caching Expensive Computations
```r
# Cache result with 7-day expiration
expensive_result <- get_or_cache(
  "model_fit_cache",
  expr = {
    # Your expensive computation here
    fit_complex_model(data)
  },
  expire_days = 7
)

# Clear specific cache when data changes
cache_clear("model_fit_cache")

# List all cached items
cache_list()
```

## Security and Best Practices

### Data Privacy - CRITICAL
- **NEVER commit sensitive data to git**
- Use `data/source/private/`, `data/in_progress/private/`, `data/final/private/` for sensitive files
- These directories have **nested .gitignore files** (defense-in-depth against accidental `git add -f`)
- Store credentials and API keys in `.env`, **NEVER in code or config.yml**
- Use `result_save(..., private = TRUE)` for sensitive outputs

### Encrypted Data
```r
# Requires sodium package
save_data(sensitive_data, "confidential", encrypt = TRUE)
# Prompts for passphrase, saves encrypted

data <- load_data("confidential")
# Prompts for passphrase to decrypt
```

### Code Organization
- Keep reusable functions in `functions/` directory
- One function per file or logical groupings
- Use descriptive function names (verb_noun pattern)
- Document complex logic with inline comments
- Prefer Quarto notebooks for analysis documentation

### Reproducibility Best Practices
- Use data catalog in config.yml to document all data sources
- Include data descriptions and source information
- Cache intermediate results to avoid re-running expensive steps
- Use renv for package management (opt-in during init)
- Document your workflow thoroughly in notebooks
- Use `standardize_wd()` at top of notebooks to handle rendering from subdirectories

## Framework-Specific Functions

### Project Setup
- `init(project_name, type, target_dir)` - Initialize new Framework project
- `scaffold()` - Load project environment (run at start of each session)

### Notebooks & Scripts
- `make_notebook(name, format)` - Create new analysis notebook (.qmd or .Rmd)
- `make_script(name)` - Create new R script in scripts/

### Data Management
- `load_data(name)` - Load data from catalog or file path
- `save_data(data, name, encrypt)` - Save data to catalog
- `list_data()` - Show data catalog entries
- `data_integrity_check(name)` - Verify data hasn't been tampered with

### Results Management
- `result_save(object, name, type, blind, private)` - Save analysis results
  - `type`: "plot", "table", "data", "model", "other"
  - `blind`: TRUE to prevent viewing until unblinded
  - `private`: TRUE to save to results/private/
- `result_get(name)` - Retrieve saved result
- `result_list()` - Show all saved results
- `result_delete(name)` - Remove result

### Caching System
- `get_or_cache(name, expr, expire_days)` - Cache computation results
- `cache_get(name)` - Retrieve cached item
- `cache_clear(name)` - Clear specific cache
- `cache_list()` - Show all cached items with expiration dates

### Database Queries
- `query_get(name, params)` - Execute saved query from queries/ directory
- `query_execute(sql, connection)` - Run ad-hoc SQL query

### Configuration Access
- `config(key, default)` - Access config values (supports dot notation)
  - Example: `config("directories.notebooks")` returns "notebooks"
  - Example: `config("notebooks")` smart lookup (checks multiple locations)
  - Example: `config("connections.db.host")` returns nested value

### Scratch Files
- `scratch_capture()` - Save current environment state for later restoration
- `scratch_clean()` - Remove old scratch files

## Working with Configuration

### config.yml Structure
```yaml
default:
  project_type: project

  # Directories - inline for discoverability
  directories:
    notebooks: notebooks
    scripts: scripts
    functions: functions
    results_public: results/public
    results_private: results/private
    cache: data/cached
    scratch: data/scratch

  # Packages to load
  packages:
    - dplyr
    - ggplot2
    - tidyr

  # Data catalog
  data:
    my_dataset:
      path: data/source/public/dataset.csv
      type: csv
      description: "Customer survey responses from 2024"

  # Database connections
  connections:
    framework:  # Built-in connection to framework.db
      type: sqlite
      path: framework.db
```

### Accessing Configuration
```r
# Smart lookups (checks multiple locations)
notebook_dir <- config("notebooks")  # Returns "notebooks"
cache_dir <- config("cache")  # Returns "data/cached"

# Explicit nested paths
db_host <- config("connections.db.host")
data_path <- config("data.my_dataset.path")

# With default value
api_url <- config("api.endpoint", default = "https://default.com")
```

### Split Configuration Files
For complex projects, you can split config.yml:

```yaml
# config.yml
default:
  directories: { notebooks: notebooks, ... }
  data: settings/data.yml
  connections: settings/connections.yml
```

Then create `settings/data.yml`, `settings/connections.yml` with detailed specifications.

**Important**: Main config.yml ALWAYS takes precedence over split files.

## Common Patterns and Examples

### Standardize Working Directory in Notebooks
```r
# At top of notebook (after setup chunk)
# Handles rendering from subdirectories
standardize_wd()
```

### Database Connections
```r
# Framework includes built-in "framework" connection to framework.db
con <- DBI::dbConnect(RSQLite::SQLite(), config("connections.framework.path"))

# Query the framework database to see tracked data
DBI::dbGetQuery(con, "SELECT * FROM data")

# Or use configured PostgreSQL connection
con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = config("connections.prod.host"),
  dbname = config("connections.prod.database")
)
```

### Saved Queries
Create `queries/get-users.sql`:
```sql
SELECT * FROM users WHERE created_date > :start_date
```

Then in R:
```r
users <- query_get("get-users", params = list(start_date = "2024-01-01"))
```

### Data Catalog Best Practices
```yaml
data:
  # Document source and update frequency
  customer_survey:
    path: data/source/public/survey_2024.csv
    type: csv
    description: "Annual customer satisfaction survey"
    source: "Marketing team, updated yearly"
    updated: "2024-03-15"

  # Mark encrypted data
  patient_records:
    path: data/source/private/patients.rds
    type: rds
    encrypted: true
    description: "De-identified patient data for outcomes analysis"
```

### Error Handling
```r
# Framework functions return informative errors
tryCatch({
  data <- load_data("nonexistent_dataset")
}, error = function(e) {
  message("Data not found. Available datasets:")
  print(list_data())
})
```

## renv Integration (Optional)

If project uses renv for package management:

```r
# Check renv status
renv::status()

# Install new package
renv::install("package_name")

# Update renv.lock after adding packages to config.yml
packages_snapshot()

# Restore packages from renv.lock
packages_restore()
```

Framework provides helpers that abstract renv complexity.

## Framework Database Schema

The `framework.db` SQLite database tracks project metadata:

**Tables:**
- `data` - Data integrity tracking (name, hash, encrypted, timestamps)
- `cache` - Cache management (name, hash, expiration, last access)
- `results` - Results tracking (name, type, blind status, hash, timestamps)
- `metadata` - Generic key-value storage

You can query this database directly to inspect Framework's internal state.

## Git Workflow

Framework projects are git-ready:
- Initial commit created automatically
- Comprehensive .gitignore for data directories
- Private directories have nested .gitignore (defense-in-depth)
- Results and cache directories properly excluded

**CRITICAL**: Before committing, always verify no sensitive data:
```bash
git status
git diff --cached
```

## Project Types

Framework supports three project types with different structures:

1. **project** (default) - Full-featured data analysis
   - All directories (data, notebooks, functions, results, etc.)
   - Suitable for complex analyses

2. **course** - Teaching materials
   - Organized by week/module
   - Minimal data infrastructure

3. **presentation** - Single talk/presentation
   - Lightweight structure
   - Focus on slides and supporting materials

## Troubleshooting

### Common Issues

**"Package not found" errors:**
```r
# Reinstall packages from config
scaffold()  # Will auto-install missing packages
```

**"Data integrity check failed":**
```r
# Data file was modified outside Framework
# Re-save to update hash
save_data(data, "dataset_name")
```

**Working directory issues in notebooks:**
```r
# Add to top of notebook
standardize_wd()
```

**Cache not expiring:**
```r
# Manually clear expired caches
cache_list()  # Check expiration dates
cache_clear("old_cache_name")
```

## Framework Package Information

- **GitHub**: https://github.com/table1/framework
- **Author**: Erik Westlund
- **License**: MIT
- **R Version**: >= 4.1.0

## Tips for AI Assistants

When working with this Framework project:

1. **Always use Framework functions** instead of base R for data/results (maintains integrity tracking)
2. **Respect directory structure** - don't suggest moving files between public/private
3. **Use config() for paths** - don't hardcode directory paths
4. **Suggest data catalog entries** when user loads data frequently
5. **Recommend caching** for expensive computations
6. **Check scaffold() was called** before suggesting framework functions
7. **Use make_notebook()** instead of manually creating .qmd/.Rmd files
8. **Be mindful of security** - never suggest committing .env or private/ directories
