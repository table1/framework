# Data Analysis Project

A data analysis project built with the Framework R package.

## Project Structure

```
.
├── data/
│   ├── source/         # Raw data (public/private)
│   ├── in_progress/    # Working datasets
│   ├── final/          # Finalized datasets
│   └── scratch/        # Temporary files
├── notebooks/          # Analysis notebooks
├── scripts/            # Analysis scripts
├── functions/          # Custom R functions
├── results/            # Outputs (public/private)
├── docs/               # Documentation
├── resources/          # Additional materials
├── settings.yml        # Project configuration
└── scaffold.R          # Initialization script
```

## Quick Start

```r
library(framework)
scaffold()              # Load environment
make_notebook("analysis")  # Create new notebook
```

## Configuration

Edit `settings.yml` to customize:
- Data sources and connections
- Required packages
- Directory paths

Cache directory (`data/cached/`) is created automatically on first use.
