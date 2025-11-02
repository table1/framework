# Course Project

Course materials built with the Framework R package.

## Project Structure

```
.
├── assignments/        # Homework and lab materials
├── course_docs/        # Syllabus, policies, grading references
├── data/               # Shared datasets for the course
├── readings/           # Assigned articles, PDFs, external links
├── slides/             # Lecture slide sources (render to slides/_rendered/{{ slug }}.html)
├── settings.yml        # Project configuration
└── scaffold.R          # Initialization script
```

## Quick Start

```r
library(framework)
scaffold()              # Load environment
# Render slides
quarto render slides/01-intro.qmd
```

## Configuration

Edit `settings.yml` to customize:
- Data sources
- Required packages
- Directory paths

Cache directory (`outputs/private/cache/`) is created automatically on first use.
