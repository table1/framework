# make_notebook() Function

The `make_notebook()` function provides an artisan-like interface for creating notebooks and scripts from stub templates, similar to Laravel's `artisan make` commands.

## Quick Start

```r
# Create a Quarto notebook (default)
make_notebook("1-init")  # Creates notebooks/1-init.qmd

# Convenient aliases for explicit types
make_qmd("analysis")     # Always creates .qmd (Quarto)
make_rmd("report")       # Always creates .Rmd (RMarkdown)

# Create presentations
make_revealjs("slides")     # Creates reveal.js presentation
make_presentation("deck")   # Alias for make_revealjs()

# Create an R script
make_script("process")   # Creates scripts/process.R

# List available stubs
list_stubs()
```

## Features

### Automatic Extension Normalization

The function automatically detects the file type from the extension:
- `.qmd` → Quarto notebook (default if no extension)
- `.Rmd` → RMarkdown notebook
- `.R` → R script

### Configuration-Aware Directory Placement

By default, files are created in the `work/` directory. You can customize this in `settings.yml`:

```yaml
options:
  notebook_dir: "notebooks"  # Custom directory for notebooks
```

### Built-in Stub Templates

Framework provides several stub templates out of the box:

**Notebooks:**
- `default` - Full-featured notebook with TOC, sections
- `minimal` - Bare-bones notebook with just setup
- `revealjs` - Quarto presentation using reveal.js

**Scripts:**
- `default` - Basic R script with framework setup

### Custom User Stubs

Create a `stubs/` directory in your project to override defaults or add custom templates:

```
stubs/
  notebook-analysis.qmd     # Custom analysis notebook
  notebook-report.Rmd       # Custom report template
  script-etl.R              # Custom ETL script
```

Stub templates support placeholders:
- `{filename}` - Replaced with the notebook name (without extension)
- `{date}` - Replaced with current date (YYYY-MM-DD)

Example custom stub (`stubs/notebook-analysis.qmd`):

```yaml
---
title: "Analysis: {filename}"
author: "Your Name"
date: "{date}"
format: html
---

```{{r}}
library(framework)
scaffold()

# Load data
data <- load_data("source.dataset")
```

## Usage Examples

### Basic Notebook Creation

```r
# Create in default work/ directory
make_notebook("01-exploration")
# → work/01-exploration.qmd

# Create in specific directory
make_notebook("analysis", dir = "reports")
# → reports/analysis.qmd

# Use custom stub
make_notebook("report", stub = "analysis")
```

### Script Creation

```r
# Create R script
make_notebook("clean-data.R")
# → work/clean-data.R

# Create with custom stub
make_notebook("etl", type = "script", stub = "etl")
```

### Presentation Creation

```r
# Create reveal.js presentation
make_notebook("results-presentation", stub = "revealjs")
# → work/results-presentation.qmd (with revealjs format)
```

### Overwriting Files

```r
# Will error if file exists
make_notebook("existing-file")  # Error!

# Overwrite existing file
make_notebook("existing-file", overwrite = TRUE)  # Success
```

## Integration with scaffold()

**Important:** As of the latest version, `standardize_wd()` is now called automatically by `scaffold()`, so you don't need to include it in your notebook setup chunks.

All stub templates use this simplified setup:

```r
library(framework)
scaffold()  # Handles directory standardization automatically
```

## Listing Available Stubs

```r
# List all stubs
list_stubs()

# List only Quarto stubs
list_stubs(type = "quarto")

# List only script stubs
list_stubs(type = "script")
```

## Configuration Options

### settings.yml

```yaml
options:
  notebook_dir: "work"  # Default directory for notebooks
```

If `notebook_dir` is not specified, the function falls back to:
1. `work/` directory (if it exists)
2. Current directory (`.`)

## Development

### Creating New Stub Templates

1. Create a `stubs/` directory in your project root
2. Create stub file with naming convention:
   - Notebooks: `notebook-{name}.{qmd|Rmd}`
   - Scripts: `script-{name}.R`
3. Use placeholders `{filename}` and `{date}` as needed
4. User stubs automatically override framework defaults with same name

### Testing

Run tests with:

```r
devtools::test(filter = "make_notebook")
```

Tests cover:
- Extension normalization
- Quarto/RMarkdown/script creation
- Overwrite behavior
- Custom stub usage
- Placeholder substitution
- Directory creation
- Stub listing

## API Reference

### make_notebook()

```r
make_notebook(
  name,
  type = c("quarto", "rmarkdown", "script"),
  dir = NULL,
  stub = "default",
  overwrite = FALSE
)
```

**Parameters:**
- `name` - File name (with or without extension)
- `type` - File type (auto-detected from extension)
- `dir` - Target directory (defaults to config `notebook_dir` or `work/`)
- `stub` - Stub template name
- `overwrite` - Whether to overwrite existing files

**Returns:** Invisibly returns the path to created file

### list_stubs()

```r
list_stubs(type = NULL)
```

**Parameters:**
- `type` - Filter by type: "quarto", "rmarkdown", "script", or NULL (all)

**Returns:** Data frame with columns: `name`, `type`, `source`

## Workflow Tips

1. **Start projects** - Use `make_notebook("1-init")` to create your first notebook
2. **Number notebooks** - Use numeric prefixes for execution order: `1-load`, `2-clean`, `3-analyze`
3. **Custom stubs for common patterns** - Create project-specific stubs for repeated analysis patterns
4. **Scripts for automation** - Use `.R` scripts for scheduled/batch processes
5. **Presentations** - Use revealjs stub for stakeholder presentations
