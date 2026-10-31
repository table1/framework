---
id: privacy-sensitive-project
title: Privacy Sensitive Project
section: project_types
position: 12
description: 'Enhanced privacy controls with separate private/public flows'
---
## Overview

The **Privacy Sensitive Project** is designed for research involving sensitive or protected data. It provides enhanced privacy controls with separate private and public directories, and stricter `.gitignore` rules that prevent private data from being committed.

## Directory Structure

```text
my-study/
├── functions/           # Custom R functions (auto-loaded)
│   └── helpers.R
├── inputs/
│   ├── private/         # Sensitive data (gitignored)
│   │   ├── raw/
│   │   ├── intermediate/
│   │   └── final/
│   └── public/          # Non-sensitive data
│       ├── raw/
│       ├── intermediate/
│       └── final/
├── notebooks/           # Analysis notebooks
├── outputs/
│   └── private/
│       └── notebooks/   # Rendered notebooks (gitignored)
├── scripts/             # Automation scripts
├── framework.db         # Metadata database
└── settings.yml         # Project configuration
```

Additional directories are created on first use:
- `outputs/private/cache` - Cached computations
- `outputs/private/figures` - Private figures
- `outputs/private/tables` - Private tables
- `outputs/public/` - Shareable results

## Privacy Controls

### What Gets Gitignored

The privacy sensitive `.gitignore` template excludes:
- `inputs/private/` - All private input data
- `outputs/private/` - All private outputs
- `.env` - Environment variables with credentials
- `framework.db` - May contain data hashes

### Public vs Private Outputs

Use the `public` parameter when saving outputs:

```r
# Save to private (default)
save_table(results, "analysis_results")

# Save to public for sharing
save_table(summary_stats, "summary", public = TRUE)
```

## Workflow

### 1. Set Up Environment

```r
library(framework)
scaffold()
```

### 2. Organize Data by Sensitivity

Place sensitive data in private directories:

```yaml
data:
  # Private: contains PHI
  inputs.private.raw.patients:
    path: inputs/private/raw/patients.csv
    type: csv
    locked: true

  # Public: aggregated, de-identified
  inputs.public.final.demographics:
    path: inputs/public/final/demographics.csv
    type: csv
```

### 3. Work with Private Data

```r
# Load private data
patients <- data_read("inputs.private.raw.patients")

# Process and de-identify
demographics <- patients |>
  group_by(age_group, region) |>
  summarize(n = n())

# Save de-identified data to public
data_save(demographics, "inputs.public.final.demographics")
```

### 4. Generate Public Outputs

```r
# Private analysis output
save_figure(detailed_plot, "patient_outcomes")

# Public summary for publication
save_figure(summary_plot, "figure_1", public = TRUE)
```

## Configuration

Example `settings.yml` for a privacy sensitive project:

```yaml
default:
  project_type: project_sensitive

  directories:
    notebooks: notebooks
    scripts: scripts
    functions: functions
    inputs_private_raw: inputs/private/raw
    inputs_private_intermediate: inputs/private/intermediate
    inputs_private_final: inputs/private/final
    inputs_public_raw: inputs/public/raw
    inputs_public_intermediate: inputs/public/intermediate
    inputs_public_final: inputs/public/final
    cache: outputs/private/cache

  packages:
    - name: dplyr
      auto_attach: true
    - name: ggplot2
      auto_attach: true

  data:
    inputs.private.raw.patients:
      path: inputs/private/raw/patients.csv
      type: csv
      locked: true
```

## Best Practices

### Lock Sensitive Source Data

Use `locked: true` to ensure source data hasn't changed:

```yaml
data:
  inputs.private.raw.patients:
    path: inputs/private/raw/patients.csv
    type: csv
    locked: true  # Error if file changes
```

### De-identify Before Publishing

Always aggregate or de-identify data before moving to public directories:

```r
# Never do this
save_table(raw_patient_data, "patients", public = TRUE)

# Do this instead
public_summary <- raw_patient_data |>
  group_by(category) |>
  summarize(mean_value = mean(value), n = n())

save_table(public_summary, "summary", public = TRUE)
```

### Review Before Committing

Check `git status` before committing to ensure no private data is staged:

```r
git_status()
```

---

<div style="display: flex; justify-content: space-between">

[← Standard Project](guide:standard-project)

[Course/Teaching →](guide:course-teaching)

</div>
