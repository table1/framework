---
id: environment
title: Environment
section: features
position: 14
description: 'Managing environment variables, secrets, and R session state'
---
## Overview

Framework provides tools for managing environment variables (secrets, credentials) and R session state. Keep sensitive data out of your code and version control while maintaining reproducibility.

## Environment Variables

### The .env File

Store sensitive values in a `.env` file at your project root:

```bash
# .env (gitignored)
# Database credentials
DB_HOST=db.example.com
DB_USER=analyst
DB_PASSWORD=secret123

# API keys
OPENAI_API_KEY=sk-...
S3_ACCESS_KEY=AKIA...
S3_SECRET_KEY=...
```

Framework's `.gitignore` templates automatically exclude `.env` files to prevent accidental exposure.

### Using env() in Configuration

Reference environment variables in `settings.yml` using `env()`:

```yaml
connections:
  analytics:
    driver: postgres
    host: env("DB_HOST")
    user: env("DB_USER")
    password: env("DB_PASSWORD")

connections:
  storage_buckets:
    default:
      bucket: my-reports-bucket
      region: us-east-1
      access_key: env("S3_ACCESS_KEY")
      secret_key: env("S3_SECRET_KEY")
  default_storage_bucket: default
```

This keeps credentials out of version control while allowing configuration to be shared.

### Default .env Template

When you create a new project, Framework generates a `.env` template with common variables:

```bash
# Framework environment defaults
# Populate these values before running scaffold() or publishing.

# PostgreSQL connection (example)
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_DB=
POSTGRES_SCHEMA=public
POSTGRES_USER=
POSTGRES_PASSWORD=

# S3-compatible object storage (AWS S3, MinIO, etc.)
S3_ENDPOINT=
S3_BUCKET=
S3_REGION=
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_SESSION_TOKEN=
```

## R Session Management

### Clear Environment

Reset your R session while optionally keeping specific objects:

```r
# Clear everything
env_clear()

# Keep specific objects
env_clear(keep = c("config", "raw_data"))
```

`env_clear()` removes:
- All objects from the global environment
- Open plot devices
- Loaded packages (except base packages)
- Runs garbage collection

### Environment Summary

Get an overview of your current R session:

```r
env_summary()
```

This displays:
- R version and platform
- Loaded packages with versions
- Objects in global environment (sorted by size)
- Memory usage

Example output:

```text
=== Environment Summary ===

R Version: R version 4.3.2 (2023-10-31)
Platform: aarch64-apple-darwin20

Loaded Packages (5):
  • framework (0.1.0)
  • dplyr (1.1.4)
  • ggplot2 (3.4.4)
  • readr (2.1.4)
  • tibble (3.2.1)

Objects in Global Environment: 12
  Top 10 by size:
    large_dataset [tbl_df] - 45.2 MB
    model_results [list] - 12.3 MB
    summary_stats [data.frame] - 0.8 KB
    ...

Memory in use: 234.5 MB
```

## Best Practices

### Never Hardcode Secrets

```yaml
# Bad - secrets in config
password: "my_secret_password"

# Good - reference environment variable
password: env("DB_PASSWORD")
```

### Check .gitignore

Framework warns if `.env` isn't gitignored:

```text
Warning: .env is NOT in .gitignore!
  Add it to prevent accidentally committing secrets.
```

All Framework project templates include `.env` in `.gitignore` by default.

### Use Descriptive Variable Names

```bash
# Good - clear purpose
PROD_DB_PASSWORD=...
STAGING_DB_PASSWORD=...
ANALYTICS_API_KEY=...

# Avoid - ambiguous
PASSWORD=...
KEY=...
```

### Document Required Variables

Add comments to your `.env` template:

```bash
# Required for database connections
# Get credentials from your team lead
DB_HOST=
DB_PASSWORD=

# Optional - only needed for S3 publishing
S3_ACCESS_KEY=
```

---

<div style="display: flex; justify-content: space-between">

[← Database Connections](guide:connections)

[Publishing →](guide:publishing)

</div>
