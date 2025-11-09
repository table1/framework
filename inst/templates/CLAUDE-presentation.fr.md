# Framework Presentation Project - Claude Code Instructions

## Project Overview

This is a Framework-based R project for **presentations, talks, and slide decks** - conference talks, seminars, webinars, or guest lectures.

Framework provides:
- Lightweight structure for presentation development
- Version control for talk iterations
- Reproducible figures and analyses
- Asset management (images, plots, diagrams)

## Directory Structure - PRESENTATION FOCUSED

### Presentation Content (Committed)
- `slides/` or `presentation/` - Main presentation files
  - `slides.qmd` - Quarto presentation (RevealJS, Beamer, PowerPoint)
  - `slides.Rmd` - RMarkdown presentation (xaringan, ioslides)
- `assets/` or `images/` - Graphics, logos, photos (committed)
- `figures/` - Generated plots and diagrams (committed)
- `notebooks/` - Analysis notebooks supporting the talk (optional)
- `scripts/` - R scripts for generating figures

### Speaker Materials (GITIGNORED)
- `notes_private/` - Speaker notes and reminders (**NEVER commit**)
- `*_speaker_notes.*` - Note files (auto-gitignored)

### Generated Outputs (GITIGNORED, regenerated from source)
- `*.html` - Rendered HTML slides (regenerate from .qmd)
- `*.pdf` - Rendered PDF slides (regenerate from .qmd)
- `_site/` - Quarto website output
- `.quarto/` - Quarto cache

### Working Files
- `cache/`, `scratch/` - Temporary build artifacts (gitignored)
- `functions/` - Helper functions for figure generation

## Common Workflows

### 1. Setup Presentation Environment
```r
library(framework)
scaffold()  # Loads packages and helper functions
```

### 2. Create Presentation Notebook
```r
# Quarto RevealJS (modern, interactive)
make_notebook("slides", format = "quarto")
# → slides.qmd

# Or organize by talk
make_notebook("talk-jsm-2024")
```

### 3. Generate Figures for Slides
```r
# Create reproducible plots
my_plot <- ggplot(data, aes(x, y)) +
  geom_point() +
  theme_minimal(base_size = 18)  # Larger text for slides

# Save to figures/ (committed)
result_save(my_plot, "motivation-plot", type = "plot")
# → outputs/public/figures/motivation-plot.png

# Or save directly
ggsave("figures/key-result.png", width = 10, height = 6, dpi = 300)
```

### 4. Cache Expensive Computations
```r
# Cache model fits for quick slide rebuilds
results <- get_or_cache(
  "simulation_results",
  expr = run_long_simulation(params),
  expire_days = 30
)
```

### 5. Load Example Data
```r
# Small example datasets (committed)
data <- data_load("assets/data/example.csv")

# Or use built-in datasets
data(mtcars)
```

## Presentation Best Practices

### 1. Reproducible Figures
- **Never manually edit plots** - regenerate from code
- **Use consistent theme** - set ggplot2 theme in config.yml
- **High DPI for talks** - save at 300 DPI minimum
- **Large text sizes** - readable from back of room

```r
# Presentation-ready ggplot theme
theme_set(theme_minimal(base_size = 18))

# Save high-quality figures
ggsave("figures/main-result.png",
       width = 12, height = 7, dpi = 300)
```

### 2. Version Control Strategy
```yaml
# .gitignore includes:
/*.html              # Rendered slides (regenerate)
/*.pdf               # Rendered slides (regenerate)
/_site/              # Quarto output
/.quarto/            # Quarto cache
/notes_private/      # Speaker notes
*_speaker_notes.*    # Note files
```

**Commit:**
- Source presentation files (.qmd, .Rmd)
- Figures and plots
- Small example datasets
- Images and assets

**Regenerate (don't commit):**
- Rendered HTML/PDF slides
- Quarto build artifacts

### 3. Organizing Talk Materials

**Single Talk:**
```
slides.qmd              # Main presentation
figures/                # All plots
  motivation.png
  main-results.png
assets/
  logo.png
  diagram.svg
```

**Multiple Talks:**
```
talk-jsm-2024/
  slides.qmd
  figures/
talk-useR-2024/
  slides.qmd
  figures/
shared-assets/
  logo.png
```

### 4. Quarto RevealJS Tips

```yaml
---
title: "Your Talk Title"
author: "Your Name"
format:
  revealjs:
    theme: simple
    slide-number: true
    transition: slide
    fig-width: 10
    fig-height: 6
---
```

Use code chunks for figures:
````markdown
```{r}
#| echo: false
#| fig-width: 10
#| fig-height: 6

ggplot(data) + ...
```
````

### 5. Speaker Notes

Keep private notes separate:
- Store in `notes_private/` (gitignored)
- Use Quarto speaker notes in slides.qmd (included in HTML)
- Print PDF handouts with notes for practice

## Framework Functions for Presentations

### Notebooks
- `make_notebook("slides")` - Create presentation file
- `make_script("figure-generator")` - Script to regenerate all plots

### Figures
```r
# Save publication-quality figures
result_save(plot, "fig-main-result", type = "plot")

# Specify dimensions
ggsave("figures/results.png", width = 12, height = 7, dpi = 300)

# Save multiple formats
ggsave("figures/diagram.pdf")  # Vector for LaTeX
ggsave("figures/diagram.png", dpi = 300)  # Raster for PowerPoint
```

### Caching
```r
# Cache expensive analyses
demo_results <- get_or_cache(
  "live_demo_cache",
  expr = run_analysis(data),
  expire_days = 30
)

# Clear cache when data updates
cache_clear("live_demo_cache")
```

## Configuration for Presentations

```yaml
default:
  project_type: presentation

  directories:
    slides: slides
    figures: figures
    assets: assets
    notes_private: notes_private

  scaffold:
    set_theme_on_scaffold: true
    ggplot_theme: theme_minimal  # Presentation-ready theme

  packages:
    - ggplot2
    - dplyr
    - scales      # For pretty axis labels
    - patchwork   # For multi-panel figures
```

## Tips for AI Assistants - PRESENTATION PROJECT

When working with this presentation project:

1. **Large, readable text** - base_size = 18 or larger for ggplot
2. **Minimal content per slide** - one key point per slide
3. **High contrast colors** - readable on projector
4. **Cache live demos** - use `get_or_cache()` for on-stage reliability
5. **Reproducible figures** - never manually edit plots
6. **Vector formats when possible** - PDF for diagrams
7. **DPI 300 minimum** - for crisp projection
8. **Simple animations** - Quarto RevealJS transitions
9. **Speaker notes private** - don't commit to public repo
10. **Build script** - create `scripts/rebuild-all-figures.R` for batch regeneration

## Common Presentation Patterns

### Batch Figure Generation
```r
# Create script to regenerate all figures
# scripts/rebuild-all-figures.R

source("functions/plot_helpers.R")

# Figure 1: Motivation
fig1 <- make_motivation_plot(data)
ggsave("figures/fig-motivation.png", fig1, width = 12, height = 7, dpi = 300)

# Figure 2: Main results
fig2 <- make_results_plot(results)
ggsave("figures/fig-results.png", fig2, width = 12, height = 7, dpi = 300)

# etc...
```

### Live Demo Setup
```r
# Cache demo results for reliability
demo_data <- get_or_cache(
  "live_demo",
  expr = {
    # Setup that takes 30 seconds
    process_large_dataset()
  },
  expire_days = 1  # Refresh daily
)

# Now demo code runs instantly on stage
show_results(demo_data)
```

### Multi-Format Output
```r
# Single source, multiple formats
# slides.qmd:
# ---
# format:
#   revealjs: default
#   beamer: default
#   pptx: default
# ---

# Build all three:
# quarto render slides.qmd --to revealjs
# quarto render slides.qmd --to beamer
# quarto render slides.qmd --to pptx
```

## Building Presentations

### Quarto
```bash
# Render to HTML (RevealJS)
quarto render slides.qmd

# Render to PDF (Beamer)
quarto render slides.qmd --to beamer

# Render to PowerPoint
quarto render slides.qmd --to pptx

# Preview with auto-reload
quarto preview slides.qmd
```

### RMarkdown (legacy)
```r
# In R console
rmarkdown::render("slides.Rmd")
```

## Framework Package
- GitHub: https://github.com/table1/framework
- Author: Erik Westlund
- License: MIT
