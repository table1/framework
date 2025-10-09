# Analysis Project

## Overview

This is a data analysis project built with the [Framework](https://github.com/yourusername/framework) R package.

## Project Structure

- `data/` - Data storage with public/private separation
  - `source/` - Original, immutable data files
  - `in_progress/` - Intermediate data products
  - `final/` - Final analysis datasets
  - `cached/` - Cached computations (gitignored)
  - `scratch/` - Temporary files (gitignored)
- `notebooks/` - Exploratory analysis and reports
- `scripts/` - Production data processing pipelines
- `functions/` - Reusable R functions
- `results/` - Analysis outputs
  - `public/` - Shareable results
  - `private/` - Internal results (gitignored)
- `docs/` - Documentation
- `resources/` - Additional project resources

## Getting Started

1. Open the `.Rproj` file in RStudio
2. Run `library(framework)` and `scaffold()` to initialize
3. Add your data files to `data/source/`
4. Create analysis notebooks in `notebooks/`
5. Write reusable functions in `functions/`

## Configuration

Edit `config.yml` to:
- Add package dependencies
- Configure data catalog entries
- Set up database connections
- Customize directory paths

## Environment Variables

Store secrets in `.env` (gitignored):
- Database credentials
- API keys
- Encryption keys

See `.env.example` for template.
