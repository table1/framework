### 3. Load Data

**Via config:**
```yaml
# settings.yml or settings/data.yml
data:
  inputs:
    raw:
      survey:
        path: inputs/raw/survey.dta
        type: stata
        locked: true
```

```r
# Load using dot notation (follows YAML structure exactly)
df <- data_load("inputs.raw.survey")

# If data_load() fails, it suggests available paths:
# Error: No data specification found for path: inputs.survey
#
# Available data paths:
#   inputs.raw.survey
#   inputs.raw.companies
#   inputs.intermediate.table1
#   ...
```

**Direct path:**
```r
df <- data_load("inputs/raw/my_file.csv")       # CSV
df <- data_load("inputs/raw/stata_file.dta")    # Stata
df <- data_load("inputs/raw/spss_file.sav")     # SPSS
```

**Important:** Dot notation paths must match your YAML structure exactly. Each level in the YAML becomes a dot-separated part of the path. Use underscores for multi-word keys (e.g., `modeling_data`, not `modeling.data`).

Statistical formats (Stata/SPSS/SAS) strip metadata by default for safety. Use `keep_attributes = TRUE` to preserve labels.

### 4. Cache Expensive Operations

```r
model <- get_or_cache("model_v1", {
  expensive_model_fit(df)
}, expire_after = 1440)  # Cache for 24 hours
```

### 5. Save Results

**Save data files** using smart path resolution:

```r
# Dot notation (resolves to configured directories)
data_save(processed_df, "intermediate.cleaned_data")
# → saves to inputs/intermediate/cleaned_data.rds

data_save(final_df, "final.analysis_ready", type = "csv")
# → saves to inputs/final/analysis_ready.csv

# Direct path
data_save(processed_df, "inputs/intermediate/my_data.csv")
# → saves to inputs/intermediate/my_data.csv

# Legacy: nested dot notation (creates data/ subdirectories)
data_save(df, "outputs.tables.clean", type = "csv", force = TRUE)
# → saves to data/outputs/tables/clean.csv
```

**Save analysis outputs:**

```r
# Save models and results
result_save("regression_model", model, type = "model")

# Save notebook (blinded)
result_save("report", file = "report.html", type = "notebook",
            blind = TRUE, public = FALSE)
```

**Note:** Directories must exist unless `force = TRUE`. File type is auto-detected from extension.

### 6. Query Databases

```yaml
# settings.yml (using clean env() syntax)
connections:
  db:
    driver: postgresql
    host: env("DB_HOST")
    database: env("DB_NAME")
    user: env("DB_USER")
    password: env("DB_PASS")
```

```r
df <- query_get("SELECT * FROM users WHERE active = true", "db")
```
