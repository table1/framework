---
id: framework-db
title: framework.db
section: features
position: 2
description: 'A lightweight SQLite utility database to help manage your project and ensure data integrity'
---
## Overview

Every Framework project includes a `framework.db` SQLite database for internal tracking. This lightweight database stores metadata about your data sources, cached computations, saved outputs, and more.

You generally don't interact with `framework.db` directly—Framework manages it automatically when you use functions like `data_read()`, `cache_remember()`, and `save_table()`.

It is recommended to commit this file to git/GitHub and consider it as part of your project.

## Database Schema

| Table | Purpose |
|-------|---------|
| `data` | Tracks data sources, file paths, types, and integrity hashes |
| `cache` | Manages cached computation metadata and expiration |
| `results` | Registry of saved outputs (tables, figures, models) |
| `connections` | Database connection metadata |
| `meta` | Key-value store for project metadata |

## Data Integrity

When you read a data file using `data_read()`, Framework stores a hash of the file contents. 

```yaml
data:
  inputs.raw.patients:
    path: inputs/raw/patients.csv
    locked: true
```

```r
patients <- data_read("inputs.raw.patients")

# First read: computes and stores hash in framework.db
# Subsequent reads: verifies hash matches, errors if file changed
```

If you set `locked` to true in the data catalog, it will ensure your source data hasn't been modified unexpectedly by erring. This is critical for reproducible research.

## Cache Tracking

The cache table tracks what's cached, when it expires, and integrity hashes:

```r
result <- cache_remember("expensive_model", {
  fit_complex_model(data)
}, expire = "7 days")  # Strings like "7 days" or numeric hours are accepted
# Metadata stored in framework.db
# Actual data stored in outputs/cache/expensive_model.rds
```

Framework uses the database to:
- Check if a cached result exists and is still valid
- Track expiration times
- Verify cached data hasn't been corrupted

**Durations:** `expire_after` (or `expire`) accepts numeric hours (e.g., `4`) or strings like `"1 day"` or `"7 days"`.

## Results Registry

When you save outputs, Framework automatically records them:

```r
save_table(results, "analysis_results")
save_figure(plot, "summary_chart")
save_model(model, "regression_v1")
```

The results table tracks:
- Output name and type (table, figure, model, report, notebook)
- Whether it's public or private (for sensitive projects)
- File hash for integrity
- Creation and update timestamps

Use `result_list()` to query saved results:

```r
result_list()                        # All results
result_list(type = "figure")         # Only figures
result_list(type = "table", public = TRUE)  # Public tables only
```

See [Saving Work](guide:saving-work) and [Viewing Work](guide:viewing-work) for complete documentation on saving and tracking outputs.

## Querying the Database

For advanced use, you can query `framework.db` directly using the built-in "framework" connection:

```r
# View cached items
cache_entries <- db_query("SELECT name, expire_at FROM cache", "framework")

# Check data registry
data_registry <- db_query("SELECT name, path, hash, locked FROM data", "framework")

# List saved results
results <- db_query("SELECT name, type, created_at FROM results", "framework")
```

## Location

The database lives at your project root:

```text
my-project/
├── framework.db          # Project database
├── settings.yml
├── notebooks/
└── ...
```

It's typically gitignored since it contains local state that may differ between collaborators.

---

<div style="display: flex; justify-content: space-between">

[← scaffold()](guide:scaffold)

[Packages →](guide:packages)

</div>
