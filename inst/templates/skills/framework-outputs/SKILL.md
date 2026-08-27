---
name: framework-outputs
description: Use when saving analysis results, caching expensive computations, running database queries, or publishing files in this Framework project - covers result_save(), save_table(), cache_fetch(), query_get(), and publish().
---

# Framework Outputs, Caching, Queries, and Publishing

## Saving Results

```r
# Save analysis results with metadata and integrity tracking
result_save("regression_model", model, type = "model")
result_save("summary_stats", stats_df, type = "table")

# Retrieve later
model <- result_get("regression_model")

# Quick export to the tables output directory
save_table(summary_df, "quarterly_summary")
save_table(report_df, "annual_report", format = "xlsx")
```

Use the canonical names `result_save()` / `result_get()` / `result_list()`
(not the legacy `save_result` / `get_result`).

## Caching Expensive Computations

```r
# Compute once, cache the result; re-runs only if missing or expired
model <- cache_fetch("fitted_model", {
  fit_complex_model(training_data)
}, expire_days = 7)

# Manual cache read/write
cache("processed_data", large_dataframe)   # Write
df <- cache_get("processed_data")          # Read (NULL if missing)
```

Use meaningful cache names; caches are tracked in `framework.db` with hashes
and expiry.

## Database Queries

Connections are defined in settings.yml (or settings/connections.yml). Use
Framework's query helpers rather than opening DBI connections manually:

```r
users <- query_get("SELECT * FROM users WHERE active = 1", "main_db")
query_execute("UPDATE runs SET done = 1 WHERE id = 42", "main_db")
```

Use the canonical names `query_get()` / `query_execute()` (not `get_query` / `execute_query`).

## Publishing to S3-Compatible Storage

If the project has an S3 connection configured:

```r
publish("outputs/report.html")                       # Upload a file, returns public URL
publish_notebook("notebooks/analysis.qmd")           # Render Quarto doc and upload
publish("outputs/charts/", dest = "reports/charts/") # Upload a directory
```

Never publish files from private/sensitive directories — see the
`framework-sensitive-data` skill if this project has one.
