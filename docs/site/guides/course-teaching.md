---
id: course-teaching
title: Course/Teaching
section: project_types
position: 13
description: 'Simplified structure for teaching materials'
---
## Overview

The **Course/Teaching** type is designed for educators creating academic courses. It provides organized directories for slides, assignments, and course materials.

## Directory Structure

```text
my-course/
├── assignments/         # Student assignments
├── course_docs/         # Course documentation
├── data/                # Shared datasets
├── readings/            # Assigned readings
├── slides/              # Lecture presentations
├── framework.db         # Metadata database
└── settings.yml         # Course configuration
```

Optional directories available in the GUI: `functions/`, `modules/`, `scripts/`

## Creating Course Content

### Slides

Create lecture slides with Quarto RevealJS:

```r
make_notebook("intro-to-r", subdir = "slides/week-01")
```

### Assignments

Create assignment notebooks:

```r
make_notebook("assignment-01", subdir = "assignments")
```

### Course Documents

Create syllabi and schedules:

```r
make_notebook("syllabus", subdir = "course_docs")
```

## Configuration

Example `settings.yml` for a course:

```yaml
default:
  project_type: course

  directories:
    data: data
    slides: slides
    assignments: assignments
    course_docs: course_docs
    readings: readings

  packages:
    - name: dplyr
      auto_attach: true
    - name: ggplot2
      auto_attach: true
    - name: palmerpenguins
      auto_attach: false
```

## Organizing Content

### By Week

```text
slides/
├── week-01-introduction/
├── week-02-data-types/
├── week-03-data-wrangling/
└── week-04-visualization/
```

### By Module

```text
slides/
├── foundations/
├── data-manipulation/
└── visualization/
```

## Teaching Workflow

### 1. Prepare Lectures

Create slides in `slides/`:

```r
make_notebook("data-wrangling", subdir = "slides/week-03")
```

### 2. Create Assignments

Build assignments with instructions:

```text
assignments/assignment-01/
├── instructions.qmd  # Student-facing
└── solution.qmd      # Answer key
```

### 3. Render Materials

Slides render to `rendered/slides/`, assignments to `rendered/assignments/`.

```bash
quarto render slides/week-01/lecture.qmd
```

## Best Practices

### Consistent Naming

Use consistent prefixes:
```text
week-01-*, week-02-*, ...
assignment-01, assignment-02, ...
```

### Reusable Functions

Enable and use `functions/` for common code:

```r
# functions/grading.R
calculate_grade <- function(scores, weights) {
  sum(scores * weights) / sum(weights)
}
```

---

<div style="display: flex; justify-content: space-between">

[← Privacy Sensitive Project](guide:privacy-sensitive-project)

[Presentation →](guide:presentation)

</div>
