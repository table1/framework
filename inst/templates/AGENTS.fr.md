# Framework R Project - AI Agent Instructions

## About This Project

This is a data analysis project built with **Framework**, an R package that provides standardized structure and workflows for reproducible research.

**Key Technologies:**
- Language: R (>= 4.1.0)
- Framework: Framework R package (https://github.com/table1/framework)
- Notebooks: Quarto (.qmd) or RMarkdown (.Rmd)
- Database: SQLite (framework.db for metadata)
- Version Control: Git
- Package Management: Optional renv

## Project Structure

```
├── data/                    # All data files
│   ├── source/             # Original data (public/private subdirs)
│   ├── in_progress/        # Intermediate data (public/private subdirs)
│   ├── final/              # Analysis-ready data (public/private subdirs)
│   ├── cached/             # Computation cache (gitignored)
│   └── scratch/            # Temporary files (gitignored)
├── notebooks/              # Analysis notebooks (.qmd or .Rmd)
├── scripts/                # Automation scripts
├── functions/              # Custom R functions (auto-sourced)
├── results/
│   ├── public/             # Shareable outputs
│   └── private/            # Sensitive outputs (gitignored)
├── settings.yml            # Project configuration (auto-discovered)
├── .env                    # Secrets (gitignored, never commit)
└── framework.db            # Metadata database
```

## Essential Framework Workflows

### Session Initialization
Every R session should start with:
```r
library(framework)
scaffold()  # Loads environment, sources functions/, installs packages
```

### Creating Analysis Notebooks
```r
make_notebook("analysis-name")  # Creates Quarto notebook
make_notebook("report", format = "rmarkdown")  # Creates RMarkdown
```

### Data Operations
```r
# Load data (from catalog or file path)
data <- load_data("dataset_name")

# Save data
save_data(data, "dataset_name")

# Encrypted data (requires sodium package)
save_data(sensitive, "confidential", encrypt = TRUE)
data <- load_data("confidential")  # Prompts for passphrase
```

### Results Management
```r
# Save outputs with automatic organization
result_save(plot, "figure-1", type = "plot")        # → outputs/public/
result_save(table, "table-1", type = "table")       # → outputs/public/
result_save(sensitive, "private-fig", type = "plot", private = TRUE)  # → outputs/private/

# Blind results for unbiased analysis
result_save(data, "blinded-data", blind = TRUE)

# Retrieve results
plot <- result_get("figure-1")
```

### Computation Caching
```r
# Cache expensive computations
result <- get_or_cache("analysis_cache", {
  # Your computation here
  run_expensive_analysis(data)
}, expire_days = 7)

# Manage cache
cache_list()            # Show cached items
cache_clear("name")     # Clear specific cache
```

## Configuration System

Framework uses `settings.yml` for settings (legacy `config.yml` projects remain compatible):

```yaml
default:
  directories:
    notebooks: notebooks
    functions: functions

  packages:
    - dplyr
    - ggplot2

  data:
    survey:
      path: inputs/reference/survey.csv
      type: csv
```

Access in R:
```r
settings("directories.notebooks")        # Smart lookup
settings("data.survey.path")             # Nested access
settings("api.key", default = "")        # With default
```

## Security - CRITICAL RULES

### Never Commit These Files
- `.env` - Contains secrets
- `data/*/private/` - Sensitive data directories
- `outputs/private/` - Sensitive outputs
- `framework.db` - May contain sensitive paths

### Defense-in-Depth Pattern
All private/ directories have **nested .gitignore files** containing `*`:
- `inputs/raw/.gitignore`
- `inputs/intermediate/.gitignore`
- `inputs/final/.gitignore`
- `outputs/private/.gitignore`

This protects against accidental `git add -f` commands.

### Encrypted Data
For highly sensitive data, use encryption:
```r
save_data(data, "confidential", encrypt = TRUE)  # Encrypted at rest
```

## Key Framework Functions

### Project Functions
- `scaffold()` - Initialize session environment
- `init()` - Create new Framework project

### File Creation
- `make_notebook(name)` - Create analysis notebook
- `make_script(name)` - Create R script

### Data Functions
- `load_data(name)` - Load from catalog or path
- `save_data(data, name)` - Save to catalog
- `list_data()` - Show data catalog

### Results Functions
- `result_save(object, name, type)` - Save output
- `result_get(name)` - Retrieve result
- `result_list()` - List all results

### Cache Functions
- `get_or_cache(name, expr, expire_days)` - Cache result
- `cache_clear(name)` - Clear cache
- `cache_list()` - Show cache

### Database Functions
- `query_get(name)` - Run saved query from queries/
- `query_execute(sql, connection)` - Execute SQL

### Settings Functions
- `settings(key)` - Access configuration (supports dot notation)
- `config(key)` - Legacy alias for `settings()`

## Common Code Patterns

### Standard Notebook Header
```r
---
title: "Analysis Title"
author: "Author Name"
date: "`r Sys.Date()`"
---

library(framework)
scaffold()
standardize_wd()  # Important for reproducibility
```

### Data Catalog Pattern
Instead of hardcoded paths, define in settings.yml:
```yaml
data:
  customer_survey:
    path: inputs/reference/survey_2024.csv
    type: csv
    description: "Annual customer satisfaction survey"
```

Then load:
```r
survey <- load_data("customer_survey")
```

### Saved SQL Queries
Create `queries/get-active-users.sql`:
```sql
SELECT * FROM users
WHERE status = 'active'
  AND created_date > :start_date
```

Execute:
```r
users <- query_get("get-active-users", params = list(start_date = "2024-01-01"))
```

### Database Connection
```r
# Framework's built-in SQLite connection
con <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")

# Query project metadata
DBI::dbGetQuery(con, "SELECT * FROM data")
```

## Code Suggestions for AI Agents

When working with this Framework project:

1. **Always use Framework functions** for data I/O (maintains integrity tracking)
2. **Respect directory structure** - use correct public/private paths
3. **Use settings() for paths** - never hardcode directory paths
4. **Suggest caching** for computations > 10 seconds
5. **Recommend data catalog entries** for frequently-used data
6. **Verify scaffold() called** before suggesting framework functions
7. **Use make_notebook()** instead of creating files manually
8. **Never suggest committing** .env or private/ directories
9. **Suggest encryption** for sensitive data
10. **Follow Framework patterns** (see above) for consistency

## Project Types

Framework supports three structures:
- **project** - Full data analysis (default, this project type)
- **course** - Teaching materials
- **presentation** - Talk/slides

## Package Management

If using renv:
```r
renv::status()              # Check status
renv::install("package")    # Install
packages_snapshot()         # Framework helper for renv::snapshot()
packages_restore()          # Framework helper for renv::restore()
```

## Troubleshooting

**Packages missing:**
```r
scaffold()  # Reinstalls packages from settings.yml (legacy config.yml supported)
```

**Data integrity errors:**
```r
save_data(data, "name")  # Re-save to update hash
```

**Working directory issues:**
```r
standardize_wd()  # Add to notebooks
```

**Cache not expiring:**
```r
cache_list()           # Check expiration
cache_clear("name")    # Manual clear
```

## Framework Metadata Database

`framework.db` contains:
- `data` table - Data integrity tracking (hashes, timestamps)
- `cache` table - Cache management (expiration, access times)
- `results` table - Results tracking (type, blind status)
- `metadata` table - Generic key-value storage

Query directly for debugging:
```r
con <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
DBI::dbGetQuery(con, "SELECT name, encrypted, created_at FROM data")
```

## Resources

- **Framework GitHub**: https://github.com/table1/framework
- **Documentation**: Run `?framework` in R
- **Author**: Erik Westlund
- **License**: MIT

## Notes for AI Assistants

This project follows Framework conventions for reproducible data analysis. When suggesting code:
- Prioritize Framework functions over base R equivalents
- Maintain security boundaries (public/private separation)
- Use configuration-driven approaches (settings.yml, data catalog)
- Suggest appropriate caching for expensive operations
- Follow the established patterns shown above
