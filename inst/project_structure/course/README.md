# Course Project

Course materials built with the Framework R package.

## Project Structure

```
.
├── data/               # Course datasets
├── notebooks/          # Student notebooks
├── presentations/      # Lecture slides
├── docs/               # Documentation
├── resources/          # Course materials
├── functions/          # Custom R functions
├── config.yml          # Project configuration
└── scaffold.R          # Initialization script
```

## Quick Start

```r
library(framework)
scaffold()              # Load environment
make_notebook("topic")  # Create new notebook
```

## Configuration

Edit `config.yml` to customize:
- Data sources
- Required packages
- Directory paths

Cache directory (`data/cached/`) is created automatically on first use.
