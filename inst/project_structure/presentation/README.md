# Presentation Project

A presentation built with the Framework R package.

## Project Structure

```
.
├── data/               # Presentation data
├── functions/          # Custom R functions
├── presentation.qmd    # Main presentation file
├── config.yml          # Project configuration
└── scaffold.R          # Initialization script
```

## Quick Start

```r
library(framework)
scaffold()              # Load environment
```

## Configuration

Edit `config.yml` to customize:
- Data sources
- Required packages
- Directory paths

Cache directory (`data/cached/`) is created automatically on first use.
