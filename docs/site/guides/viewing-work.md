---
id: viewing-work
title: Viewing Work
section: features
position: 8
description: 'Browse your work interactively with view() and the GUI'
---
## Overview

Framework provides tools for interactively exploring your data, viewing saved results, and browsing your project structure.

## Interactive Viewing

Use `view()` to open objects in an interactive HTML viewer in your browser.

### Data Frames

For data frames, you get a searchable, sortable, filterable table:

```r
view(mtcars)
```

Features:
- Search across all columns
- Filter individual columns
- Sort by clicking headers
- Export to Copy, CSV, or Excel
- Pagination for large datasets

### Complex Objects

For lists and other complex objects, `view()` displays a structured view with YAML and R tabs:

```r
x <- list(a = 1, b = c(2, 3), c = list("D", "E", list(F = "G")))
view(x)
```

<div style="display: flex; gap: 1rem;">
<img src="/images/view-list-yaml.png" alt="List viewer - YAML tab" style="max-width: 48%;">
<img src="/images/view-list-r.png" alt="List viewer - R tab" style="max-width: 48%;">
</div>

### Options

```r
# Custom title
view(df, title = "Survey Results")

# Limit rows for very large datasets
view(large_df, max_rows = 1000)
```

Aliases `view_create()` and `view_detail()` also work.

## Listing Results

Query saved results with `result_list()`:

```r
# All results
result_list()

# Filter by type
result_list(type = "figure")
result_list(type = "table")
result_list(type = "model")

# Filter by public status
result_list(public = TRUE)
result_list(public = FALSE)

# Combine filters
result_list(type = "table", public = TRUE)
```

Returns a data frame with all tracked results and their metadata.

## Project Info

View your project structure and output mappings:

```r
project_info()
```

This displays:
- Project type and root directory
- Configured directories
- Output directory mappings
- Data catalog summary

## GUI Integration

The Framework GUI provides visual access to your work. Run `setup()` and navigate to the **Project** section to see:

- **Inputs**: Browse files in your input directories
- **Outputs**: Browse saved output files
- **Results**: View tracked results from `framework.db`

---

<div style="display: flex; justify-content: space-between">

[← Quarto Integration](guide:quarto)

[Saving Work →](guide:saving-work)

</div>
