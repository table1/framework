---
id: publishing
title: Publishing
section: features
position: 15
description: 'Publishing notebooks, data, and files to S3 storage'
---
## Overview

Framework provides functions for publishing notebooks, data, and files to S3-compatible storage (AWS S3, MinIO, DigitalOcean Spaces, etc.). Share rendered reports, datasets, and analysis outputs with colleagues or the public.

## Configuring S3

Define S3 connections in `settings.yml` (either format works):

**Preferred (connections.storage_buckets):**
```yaml
connections:
  storage_buckets:
    default:
      bucket: my-reports-bucket
      region: us-east-1
      prefix: projects/analysis
      access_key: env("S3_ACCESS_KEY")
      secret_key: env("S3_SECRET_KEY")
      static_hosting: true
    backup:
      bucket: backup-bucket
      endpoint: https://minio.internal:9000
      access_key: env("MINIO_ACCESS_KEY")
      secret_key: env("MINIO_SECRET_KEY")
  default_storage_bucket: default
```

Store credentials in `.env`:

```bash
S3_ACCESS_KEY=AKIA...
S3_SECRET_KEY=...
```

### Configuration Options

| Option | Description |
|--------|-------------|
| `bucket` | S3 bucket name |
| `region` | AWS region (default: us-east-1) |
| `prefix` | Path prefix for all uploads |
| `endpoint` | Custom endpoint for S3-compatible services |
| `access_key` | AWS access key (use `env()`) |
| `secret_key` | AWS secret key (use `env()`) |
| `static_hosting` | If true, uploads notebooks as `dest/index.html` |
| `default` | (connections format) Mark this bucket as the default |

Set a default bucket with `default_storage_bucket` (or `default: true` on a bucket). If no default is set, Framework falls back to the first bucket defined.

## Publishing Notebooks

Render and upload Quarto notebooks in one step:

```r
# Publish a notebook
publish_notebook("notebooks/analysis.qmd")
# -> https://bucket.s3.amazonaws.com/prefix/analysis.html

# Custom destination
publish_notebook("notebooks/analysis.qmd", dest = "reports/q4-2024")

# Use specific connection
publish_notebook("notebooks/analysis.qmd", connection = "backup")
```

### Static Hosting Mode

When `static_hosting: true`, notebooks are uploaded as `index.html` files for clean URLs:

```r
publish_notebook("analysis.qmd", dest = "reports/q4")
# Uploads to: reports/q4/index.html
# Access at:  https://bucket.s3.amazonaws.com/reports/q4/
```

Without static hosting, files keep their extension:

```r
publish_notebook("analysis.qmd", dest = "reports/q4")
# Uploads to: reports/q4.html
# Access at:  https://bucket.s3.amazonaws.com/reports/q4.html
```

### Self-Contained vs Multi-File

By default, notebooks are rendered as self-contained HTML with all resources embedded:

```r
# Self-contained (default) - single file, portable
publish_notebook("analysis.qmd", self_contained = TRUE)

# Multi-file - smaller HTML, separate assets (requires static_hosting)
publish_notebook("analysis.qmd", self_contained = FALSE)
```

## Publishing Data

Upload data frames or existing files:

```r
# Publish a data frame as CSV
publish_data(my_results, "datasets/results.csv")

# Publish as other formats
publish_data(my_results, "datasets/results.parquet", format = "parquet")
publish_data(my_results, "datasets/results.rds", format = "rds")

# Publish with compression
publish_data(my_results, "datasets/results.csv", compress = TRUE)
# -> uploads as results.csv.gz

# Publish an existing file
publish_data("outputs/model.rds", "models/v2/model.rds")
```

## Publishing Directories

Upload entire directories:

```r
# Upload a directory
publish_dir("outputs/dashboard/")

# Custom destination
publish_dir("outputs/dashboard/", dest = "dashboards/v2/")

# Filter files
publish_dir("outputs/", pattern = "\\.html$")
```

## Generic Publish

For any file or directory:

```r
# Single file
publish("outputs/report.html")

# With custom destination
publish("outputs/report.html", dest = "reports/final.html")

# Directory
publish("outputs/charts/", dest = "visualizations/")
```

## Workflow Example

A typical publishing workflow:

```r
library(framework)
scaffold()

# Run analysis
results <- analyze_data(my_data)
summary_plot <- create_visualization(results)

# Save outputs locally
save_table(results, "final_results")
save_figure(summary_plot, "summary")

# Render notebook
save_notebook("notebooks/analysis.qmd")

# Publish to S3
publish_notebook("notebooks/analysis.qmd", dest = "reports/q4-analysis")
publish_data(results, "data/q4-results.csv")

# Share the URL
# https://my-bucket.s3.amazonaws.com/reports/q4-analysis/
```

## Best Practices

### Use Prefixes for Organization

```yaml
connections:
  storage_buckets:
    default:
      prefix: team-name/project-name
  default_storage_bucket: default
```

This keeps your bucket organized:

```text
team-name/project-name/reports/...
team-name/project-name/data/...
```

### Version Important Outputs

Include dates or versions in destinations:

```r
publish_notebook("analysis.qmd", dest = "reports/analysis-2024-01-15")
publish_data(results, "data/results-v2.csv")
```

### Use Static Hosting for Reports

Enable `static_hosting: true` for cleaner URLs when sharing reports:

```text
# With static hosting
https://bucket.s3.amazonaws.com/reports/q4/

# Without
https://bucket.s3.amazonaws.com/reports/q4.html
```

---

<div style="display: flex; justify-content: space-between">

[← Environment](guide:environment)

[Project Types →](guide:project-types)

</div>
