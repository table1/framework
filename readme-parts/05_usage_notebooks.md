### 2. Create Notebooks & Scripts

Framework provides commands for creating files from templates:

```r
# Create a Quarto notebook (default)
make_notebook("1-exploration")  # → notebooks/1-exploration.qmd

# Convenient aliases for explicit types
make_qmd("analysis")            # → notebooks/analysis.qmd (always Quarto)
make_rmd("report")              # → notebooks/report.Rmd (always RMarkdown)

# Create presentations
make_revealjs("slides")         # → notebooks/slides.qmd (reveal.js presentation)
make_presentation("deck")       # → notebooks/deck.qmd (alias for make_revealjs)

# Create an R script
make_script("process-data")     # → scripts/process-data.R

# List available stubs
list_stubs()
```

**Built-in stubs:**
- `default` - Full-featured notebook with TOC and sections
- `minimal` - Bare-bones notebook with essential setup only
- `revealjs` - Quarto presentation using reveal.js (Quarto only)

**Custom stubs:** Create a `stubs/` directory in your project:

```
stubs/
  notebook-analysis.qmd     # Custom notebook template
  notebook-default.qmd      # Override default notebook
  script-etl.R              # Custom script template
  script-default.R          # Override default script
```

Stub templates support placeholders:
- `{filename}` - File name without extension
- `{date}` - Current date (YYYY-MM-DD)

**Configure default directories in config.yml:**

```yaml
options:
  notebook_dir: "notebooks"  # Where make_notebook() creates notebook files
  script_dir: "scripts"      # Where make_script() creates script files
```
