# Data Analysis Project

A data analysis project built with the Framework R package.

## Project Structure

```
.
├── inputs/
│   ├── raw/                # Source files exactly as delivered
│   ├── intermediate/       # Cleaned datasets still treated as inputs
│   ├── final/              # Curated datasets ready for analysis
│   └── reference/          # External manuals, codebooks, protocols
├── outputs/
│   ├── private/            # Working artifacts (tables, figures, cache)
│   └── public/             # Approved deliverables ready to ship
├── notebooks/              # Analysis notebooks
├── scripts/                # Production scripts / pipelines
├── functions/              # Custom helper functions
├── docs/                   # Team-authored documentation
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

Cache directory (`outputs/private/cache/`) is created automatically on first use.
