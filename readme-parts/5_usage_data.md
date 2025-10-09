### 3. Load Data

**Via config:**
```yaml
# config.yml or settings/data.yml
data:
  source:
    private:
      survey:
        path: data/source/private/survey.dta
        type: stata
        locked: true
```

```r
# Load using dot notation
df <- data_load("source.private.survey")
```

**Direct path:**
```r
df <- data_load("data/my_file.csv")       # CSV
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

Statistical formats (Stata/SPSS/SAS) strip metadata by default for safety. Use `keep_attributes = TRUE` to preserve labels.

### 4. Cache Expensive Operations

```r
model <- get_or_cache("model_v1", {
  expensive_model_fit(df)
}, expire_after = 1440)  # Cache for 24 hours
```

### 5. Save Results

```r
# Save data
data_save(processed_df, "final.private.clean", type = "csv")

# Save analysis output
result_save("regression_model", model, type = "model")

# Save notebook (blinded)
result_save("report", file = "report.html", type = "notebook",
            blind = TRUE, public = FALSE)
```

### 6. Query Databases

```yaml
# config.yml
connections:
  db:
    driver: postgresql
    host: !expr Sys.getenv("DB_HOST")
    database: !expr Sys.getenv("DB_NAME")
    user: !expr Sys.getenv("DB_USER")
    password: !expr Sys.getenv("DB_PASS")
```

```r
df <- query_get("SELECT * FROM users WHERE active = true", "db")
```

