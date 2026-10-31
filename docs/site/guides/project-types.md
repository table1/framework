---
id: project-types
title: Project Types Overview
section: project_types
position: 10
description: 'Understanding the different project types in Framework'
---
## Overview

Framework supports four project types, each optimized for different workflows:

| Type | Best For |
|------|----------|
| **Standard Project** | Data analysis, research, reporting |
| **Privacy Sensitive Project** | Research with private/public data separation |
| **Course/Teaching** | Academic courses with lectures and assignments |
| **Presentation** | Slides and presentations |

## Choosing a Project Type

### Standard Project (Default)

Full-featured with organized data, work, and output directories.

Use for most data analysis work:
- Research projects
- Data pipelines
- Exploratory data analysis

**Default structure:**
```text
my-analysis/
├── functions/
├── inputs/
│   ├── raw/
│   ├── intermediate/
│   └── final/
├── notebooks/
├── outputs/
│   └── notebooks/
├── scripts/
└── settings.yml
```

Optional directories available in the GUI: `docs/`, `scratch/`

### Privacy Sensitive Project

Enhanced privacy controls with separate private/public flows.

Use for research involving sensitive or protected data:
- Research with sensitive data, such as protected health information
- Projects requiring clear public/private separation

**Default structure:**
```text
my-study/
├── functions/
├── inputs/
│   ├── private/
│   │   ├── raw/
│   │   ├── intermediate/
│   │   └── final/
│   └── public/
│       ├── raw/
│       ├── intermediate/
│       └── final/
├── notebooks/
├── outputs/
│   └── private/
│       └── notebooks/
├── scripts/
└── settings.yml
```

Optional directories available in the GUI: `docs/`, `scratch/`

### Course/Teaching

Simplified structure for teaching materials, such as lecture slides, student assignments, and course materials

**Default structure:**
```text
my-course/
├── assignments/
├── course_docs/
├── data/
├── readings/
├── slides/
└── settings.yml
```

Optional directories available in the GUI: `functions/`, `modules/`, `scripts/`

### Presentation

Minimal structure for slides and presentations.

**Default structure:**
```text
my-presentation/
├── presentation.qmd
└── settings.yml
```

Optional directories available in the GUI: `data/`, `functions/`, `outputs/`, `scripts/`

## Creating Projects

### Using the GUI

The easiest way to create projects is through the GUI:

```r
framework::setup()
```

Navigate to **New Project** and follow the wizard.

### Programmatic Creation

```r
# Create a standard project
new_project("sales-analysis", "~/projects/sales-analysis")

# Create a privacy sensitive project
new_project_sensitive("medical-study", "~/projects/medical")

# Create a course
new_course("data-science-101", "~/teaching/ds101")

# Create a presentation
new_presentation("q4-report", "~/presentations/q4")
```

## Shared Features

All project types include:

- **Configuration** (`settings.yml`) - Project settings
- **Git integration** - Version control ready with appropriate `.gitignore`
- **Quarto support** - Modern document rendering
- **AI assistant context** - Optional CLAUDE.md/AGENTS.md generation

---

<div style="display: flex; justify-content: space-between">

[← Publishing](guide:publishing)

[Standard Project →](guide:standard-project)

</div>
