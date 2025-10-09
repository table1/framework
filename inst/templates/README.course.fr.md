# Course Project

## Overview

This is a course repository built with the [Framework](https://github.com/yourusername/framework) R package.

## Project Structure

- `presentations/` - Course presentation materials
- `notebooks/` - Lesson notebooks and examples
- `data/` - Course datasets
  - `cached/` - Cached computations (gitignored)
- `functions/` - Reusable R functions for course
- `docs/` - Course documentation and guides
- `resources/` - Additional teaching resources

## Getting Started

1. Open the `.Rproj` file in RStudio
2. Run `library(framework)` and `scaffold()` to initialize
3. Organize presentations by topic/week in `presentations/`
4. Create lesson notebooks in `notebooks/`
5. Add example datasets to `data/`

## Configuration

Edit `config.yml` to:
- Add required R packages for the course
- Configure data catalog for example datasets
- Customize directory paths

## For Students

- All required datasets are in `data/`
- Work through notebooks in numbered order
- Complete exercises in presentation materials
- Functions in `functions/` are available after running `scaffold()`
