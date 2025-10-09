### 2. Create Notebooks & Scripts

Framework provides artisan-style commands for creating files from templates:

```r
# Create a Quarto notebook (default)
make_notebook("1-exploration")  # → notebooks/1-exploration.qmd

# Create an RMarkdown notebook
make_notebook("analysis.Rmd")   # → notebooks/analysis.Rmd

# Create an R script
make_notebook("process-data.R") # → scripts/process-data.R

# Create a reveal.js presentation
make_notebook("results-presentation", stub = "revealjs")

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
  notebook-analysis.qmd     # Override default or add custom template
  script-etl.R              # Custom script template
```

Stub templates support placeholders:
- `{filename}` - File name without extension
- `{date}` - Current date (YYYY-MM-DD)

**Configure default directory in config.yml:**
```yaml
options:
  notebook_dir: "notebooks"  # Where make_notebook() creates files
```
