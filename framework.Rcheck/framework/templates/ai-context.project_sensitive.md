# {ProjectName}

This file provides guidance to AI assistants working with this Framework project.
Edit the sections without regeneration markers freely - they won't be overwritten.

## Framework Environment <!-- @framework:regenerate -->

This project uses Framework for reproducible data analysis. **Every notebook and script
MUST begin with `scaffold()`** which initializes the environment.

### What scaffold() Does

When you call `scaffold()`, it automatically:

1. **Sets the working directory** to the project root (handles nested notebook execution)
2. **Loads environment variables** from `.env` (database credentials, API keys)
3. **Installs missing packages** listed in settings.yml
4. **Attaches packages** marked with `auto_attach: true` (see Packages section below)
5. **Sources all functions** from `functions/` directory - they are globally available

### CRITICAL RULES

**DO NOT** call `library()` for packages listed in the auto-attach section below.
They are already loaded by scaffold(). Calling library() again wastes time and clutters output.

**DO NOT** use `source()` to load functions from the functions/ directory.
They are auto-loaded by scaffold(). Just call them directly.

## Installed Packages <!-- @framework:regenerate -->

### Auto-Attached (DO NOT call library() for these)

These packages are loaded automatically by `scaffold()`. **NEVER use library() for them:**

*Configure packages in settings.yml and run `ai_regenerate()` to update this section.*

### Installed Only (call library() if needed)

These are installed but not auto-loaded. Use `library()` only when needed.

### Adding New Packages

**ALWAYS use Framework's package management:**

```r
# Add a CRAN package (will be installed on next scaffold)
package_add("janitor")

# Add and auto-attach
package_add("forcats", auto_attach = TRUE)

# Add from GitHub
package_add("tidyverse/dplyr@main")
```

**DO NOT** use `install.packages()` directly - it bypasses Framework's tracking.

## Data Management <!-- @framework:regenerate -->

**CRITICAL: All data operations MUST go through Framework functions.**
This ensures integrity tracking, encryption support, and reproducibility.

### Reading Data

**ALWAYS use `data_read()`:**

```r
# From data catalog (preferred)
survey <- data_read("inputs.raw.survey")

# Direct path
customers <- data_read("inputs/private/raw/customers.csv")
```

**NEVER use these functions:**
- ❌ `read.csv()` - no tracking, no encryption support
- ❌ `read_csv()` - no tracking, no encryption support
- ❌ `readRDS()` - no tracking, no encryption support
- ❌ `read_excel()` - no tracking, no encryption support

If you see code using these functions, **replace it with `data_read()`**.

### Saving Data

**ALWAYS use `data_save()`:**

```r
# Save to intermediate (tracked, integrity-checked)
data_save(cleaned_df, "inputs/private/intermediate/cleaned.csv")

# Save to public final (de-identified only!)
data_save(final_df, "inputs/public/final/analysis_ready.csv", locked = TRUE)
```

**NEVER use these functions:**
- ❌ `write.csv()` - no tracking
- ❌ `write_csv()` - no tracking
- ❌ `saveRDS()` - no tracking

### Directory Structure

| Purpose | Directory | Notes |
|---------|-----------|-------|
| Private raw data | `inputs/private/raw/` | PII/PHI, never commit |
| Public raw data | `inputs/public/raw/` | De-identified source files |
| Private intermediate | `inputs/private/intermediate/` | Cleaned data with PII |
| Public intermediate | `inputs/public/intermediate/` | De-identified cleaned data |
| Private final | `inputs/private/final/` | Analysis-ready with PII |
| Public final | `inputs/public/final/` | Safe to share |
| Private outputs | `outputs/private/` | Reports with PII |
| Public outputs | `outputs/public/` | Shareable artifacts |

## Function Reference <!-- @framework:regenerate -->

### Data Functions

#### data_read(path)
Read data from catalog or file path. Supports CSV, RDS, Excel, Stata, SPSS, SAS.

```r
df <- data_read("inputs.raw.survey")      # From catalog
df <- data_read("inputs/raw/file.csv")    # Direct path
```

#### data_save(data, path, locked = FALSE)
Save data with integrity tracking.

```r
data_save(df, "inputs/intermediate/cleaned.csv")
data_save(df, "inputs/final/analysis_ready.csv", locked = TRUE)
```

### Cache Functions

#### cache_fetch(name, expr)
Compute once, cache result. Use for expensive operations.

```r
model <- cache_fetch("my_model", {
  # This only runs if cache doesn't exist or is expired
  train_expensive_model(data)
})
```

#### cache_get(name) / cache(name, value)
Manual cache read/write.

```r
cache("processed_data", large_dataframe)  # Write
df <- cache_get("processed_data")          # Read (NULL if missing)
```

### Output Functions

#### result_save(name, value, type)
Save analysis results with metadata.

```r
result_save("regression_model", model, type = "model")
result_save("summary_stats", stats_df, type = "table")
```

#### save_table(data, name, format = "csv")
Quick export to outputs/tables/.

```r
save_table(summary_df, "quarterly_summary")
save_table(report_df, "annual_report", format = "xlsx")
```

### Query Functions

#### query_get(sql, connection)
Execute SQL and return results.

```r
users <- query_get("SELECT * FROM users WHERE active = 1", "main_db")
```

### Notebook/Script Creation

#### make_notebook(name) / make_script(name)
Create new files from templates.

```r
make_notebook("01-data-cleaning")     # Creates notebooks/01-data-cleaning.qmd
make_script("data-processing")        # Creates scripts/data-processing.R
```

## Privacy Requirements

This is a privacy-sensitive project. **Critical rules:**

1. **NEVER commit `inputs/private/` or `outputs/private/` directories** - they contain PII/PHI
2. All raw data with PII goes in `private/` subdirectories
3. Only de-identified, aggregated data goes in `public/` directories
4. Review ALL outputs before moving to public directories
5. Use `data_save(..., private = TRUE)` for sensitive outputs
6. Run `framework check:sensitive` before commits to scan for data leaks

### Data Flow

```
Raw PII Data -> inputs/private/raw/
    |
    v (clean, de-identify)
Intermediate -> inputs/private/intermediate/
    |
    v (aggregate, anonymize)
Public-safe -> inputs/public/final/
```

## Project Notes

*Add your project-specific notes, conventions, and documentation here.*
*This section is never modified by `ai_regenerate()`.*
