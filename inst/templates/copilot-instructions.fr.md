# Framework Project Instructions

## Project Overview

This is a Framework-based R project for reproducible data analysis.

Framework is an R package that provides:
- Standardized directory structure for data science projects
- Configuration-driven workflows
- Data cataloging with integrity tracking
- Built-in caching system for expensive computations
- Secure handling of sensitive data with defense-in-depth

## Directory Structure

```
project/
├── data/
│   ├── source/         # Original data files
│   │   ├── public/     # Non-sensitive (tracked in git)
│   │   └── private/    # Sensitive (gitignored with nested .gitignore)
│   ├── in_progress/    # Intermediate analysis data (public/private)
│   ├── final/          # Analysis-ready datasets (public/private)
│   ├── cached/         # Cached computation results (gitignored)
│   └── scratch/        # Temporary files (gitignored)
├── notebooks/          # Quarto (.qmd) or RMarkdown (.Rmd) analyses
├── scripts/            # Standalone R scripts for automation
├── functions/          # Custom R functions (auto-sourced by scaffold())
├── results/
│   ├── public/         # Shareable outputs (tracked in git)
│   └── private/        # Sensitive outputs (gitignored)
├── settings.yml          # Main configuration file
├── .env                # Environment variables and secrets (gitignored)
└── framework.db        # SQLite database for metadata tracking
```

## Essential Workflows

### Starting a Session
```r
library(framework)
scaffold()  # Loads environment, sources functions/, installs/loads packages
```

### Creating Notebooks
```r
make_notebook("analysis-name")  # Creates notebooks/analysis-name.qmd
```

### Data Management
```r
# Load from catalog (defined in settings.yml)
data <- load_data("dataset_name")

# Save data
save_data(data, "dataset_name")

# Save encrypted (requires sodium package)
save_data(sensitive_data, "confidential", encrypt = TRUE)
```

### Results Management
```r
# Save outputs
result_save(plot, "figure-1", type = "plot")
result_save(table, "table-1", type = "table")

# Save to private results
result_save(sensitive_plot, "private-fig", type = "plot", private = TRUE)

# Blind results for unbiased analysis
result_save(data, "blinded", blind = TRUE)
```

### Caching Expensive Computations
```r
result <- get_or_cache("cache_name", {
  # Your expensive computation
  run_analysis(data)
}, expire_days = 7)
```

## Configuration Access

Framework uses `settings.yml` for project settings:

```r
# Smart lookups
config("notebooks")  # Returns directory path

# Nested access with dot notation
config("connections.db.host")
config("data.my_dataset.path")

# With default value
config("api.endpoint", default = "https://default.com")
```

## Security Best Practices

### Critical Security Rules
1. **NEVER commit sensitive data to git**
2. **Use private/ subdirectories** for all sensitive files
3. **Store secrets in .env**, never in code or settings.yml
4. **Nested .gitignore files** provide defense-in-depth in private/ directories
5. **Use encryption** for highly sensitive data: `save_data(data, "name", encrypt = TRUE)`

### Private Directory Pattern
```
inputs/raw/      # Has nested .gitignore with "*"
inputs/intermediate/ # Has nested .gitignore with "*"
inputs/final/       # Has nested .gitignore with "*"
outputs/private/          # Has nested .gitignore with "*"
```

These directories are protected even if someone uses `git add -f`.

## Key Framework Functions

### Project Setup
- `scaffold()` - Load environment (run at start of each session)
- `init()` - Initialize new project

### Notebooks & Scripts
- `make_notebook(name)` - Create Quarto/RMarkdown notebook
- `make_script(name)` - Create R script

### Data Functions
- `load_data(name)` - Load from catalog or file
- `save_data(data, name)` - Save to catalog
- `list_data()` - Show catalog entries

### Results Functions
- `result_save(object, name, type)` - Save analysis output
- `result_get(name)` - Retrieve saved result
- `result_list()` - Show all results

### Caching Functions
- `get_or_cache(name, expr, expire_days)` - Cache computation
- `cache_clear(name)` - Clear cache
- `cache_list()` - Show cached items

### Database Functions
- `query_get(name)` - Execute saved query from queries/
- `query_execute(sql, connection)` - Run ad-hoc SQL

### Configuration
- `config(key)` - Access config values (dot notation supported)

## Common Patterns

### Notebook Setup
```r
# Standard notebook header (after YAML)
library(framework)
scaffold()
standardize_wd()  # Handle rendering from subdirectories
```

### Data Catalog Usage
Define in `settings.yml`:
```yaml
data:
  customer_survey:
    path: inputs/reference/survey.csv
    type: csv
    description: "2024 customer satisfaction survey"
```

Then load in R:
```r
survey <- load_data("customer_survey")
```

### Database Connections
```r
# Framework's built-in SQLite database
con <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")

# Query metadata
DBI::dbGetQuery(con, "SELECT * FROM data")
```

### Saved Queries
Create `queries/get-users.sql`:
```sql
SELECT * FROM users WHERE created_date > :start_date
```

Execute in R:
```r
users <- query_get("get-users", params = list(start_date = "2024-01-01"))
```

## Project Types

Framework supports three project structures:

1. **project** - Full-featured data analysis (default)
2. **course** - Teaching materials organized by modules
3. **presentation** - Lightweight structure for talks

## renv Integration

If project uses renv:
```r
renv::status()           # Check package status
renv::install("pkg")     # Install package
packages_snapshot()      # Update renv.lock
packages_restore()       # Restore from renv.lock
```

## Troubleshooting

**Package not found:**
```r
scaffold()  # Reinstalls missing packages from config
```

**Data integrity check failed:**
```r
save_data(data, "name")  # Re-save to update hash
```

**Working directory issues:**
```r
standardize_wd()  # Add to top of notebooks
```

## Code Suggestions for Copilot

When suggesting code for this Framework project:

1. **Use Framework functions** instead of base R for data I/O
2. **Respect directory structure** - suggest correct public/private paths
3. **Use config() for paths** instead of hardcoding
4. **Suggest caching** for expensive operations
5. **Recommend data catalog** for frequently-used datasets
6. **Always check scaffold() called** before using framework functions
7. **Never suggest committing** .env or private/ directories
8. **Use make_notebook()** instead of manually creating files

## Framework Package Info

- GitHub: https://github.com/table1/framework
- Author: Erik Westlund
- License: MIT
- R Version: >= 4.1.0

## Additional Resources

Run `?framework` in R for package documentation.
