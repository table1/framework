# Presentation Project

A presentation built with the Framework R package.

## Project Structure

```
.
├── presentation.qmd    # Main presentation file
├── settings.yml        # Project configuration
└── scaffold.R          # Initialization script
```

## Quick Start

```r
library(framework)
scaffold()              # Load environment
# Render presentation
quarto render presentation.qmd
```

## Configuration

Edit `settings.yml` to customize:
- Data sources
- Required packages
- Directory paths

Cache directory (`outputs/private/cache/`) is created automatically on first use.
