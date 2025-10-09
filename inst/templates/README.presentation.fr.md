# Presentation

## Overview

This is a single presentation project built with the [Framework](https://github.com/yourusername/framework) R package.

## Project Structure

- `data/` - Presentation datasets
  - `cached/` - Cached computations (gitignored)
- `functions/` - Supporting R functions
- `results/` - Generated figures and outputs
- `build.R` - Build script for rendering presentation

## Getting Started

1. Open the `.Rproj` file in RStudio
2. Run `library(framework)` and `scaffold()` to initialize
3. Edit your presentation file (e.g., `slides.qmd` or `presentation.Rmd`)
4. Run `source("build.R")` to render

## Configuration

Edit `config.yml` to:
- Add required R packages
- Configure data sources
- Customize paths

## Building

The `build.R` script handles rendering. Customize it for your presentation format (Quarto, R Markdown, etc.).
