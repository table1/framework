# Quarto Render Directory Specifications

This document defines the mapping between project types and their render directories, including which Quarto format (HTML vs revealjs) should be used for each.

## Project Type: `project` (Standard Project)

**Render Directories:**
- `notebooks` → **HTML format**
  - Path: `outputs/notebooks` (default)
  - Used for: Analysis notebooks, exploratory work

- `docs` → **HTML format**
  - Path: `outputs/docs` (default)
  - Used for: Documentation, reports

**Root `_quarto.yml`:** Uses HTML format as default

## Project Type: `project_sensitive` (Privacy Sensitive)

**Render Directories:**
- `notebooks` → **HTML format**
  - Path: `outputs/private/notebooks` (default)
  - Used for: Analysis notebooks with sensitive data

- `docs` → **HTML format**
  - Path: `outputs/private/docs` (default)
  - Used for: Internal documentation

**Root `_quarto.yml`:** Uses HTML format as default

## Project Type: `course` (Teaching/Course)

**Render Directories:**
- `slides` → **revealjs format**
  - Path: `rendered/slides` (default)
  - Used for: Lecture slides, presentations

- `assignments` → **HTML format**
  - Path: `rendered/assignments` (default)
  - Used for: Homework, problem sets

- `course_docs` → **HTML format**
  - Path: `rendered/course_docs` (default)
  - Used for: Syllabus, course materials

- `modules` → **HTML format**
  - Path: `rendered/modules` (default)
  - Used for: Module notebooks/tutorials

**Root `_quarto.yml`:** Uses HTML format as default

## Project Type: `presentation` (Single Presentation)

**Render Directories:**
- Root directory only → **revealjs format**
  - Path: `.` (project root)
  - Used for: Single standalone presentation

**Root `_quarto.yml`:** Uses revealjs format (since entire project is a presentation)

## Format Selection Rules

### HTML Format
Used for directories containing:
- Notebooks
- Documentation
- Assignments
- Modules
- Reports
- Any directory type **except** slides/presentations

**Settings inherited from:** `defaults.quarto.html` in global config

### revealjs Format
Used for directories containing:
- Slides
- Presentations
- Any directory explicitly marked as presentation type

**Settings inherited from:** `defaults.quarto.revealjs` in global config

## Implementation Notes

1. **Directory Detection:** Format is determined by directory key name (e.g., "slides" → revealjs, "notebooks" → HTML)

2. **Inheritance:** Directory-specific `_quarto.yml` files inherit from project root `_quarto.yml`, which inherits from global defaults

3. **Override Capability:** Users can manually edit any `_quarto.yml` file to override inherited settings

4. **Generation Timing:** All `_quarto.yml` files are generated once during project creation and never auto-regenerated

5. **Directory Creation:** Render directories are created even if empty, ensuring `_quarto.yml` files are present and ready for use

## Validation Rules for Tests

Tests should verify:
- ✅ Each project type creates the correct render directories
- ✅ Each render directory gets the appropriate format (HTML vs revealjs)
- ✅ All `_quarto.yml` files exist and are valid YAML
- ✅ Format-specific settings are correctly applied
- ✅ Auto-generated headers are present in all files
- ✅ Project-specific overrides take precedence over global defaults
- ✅ Root `_quarto.yml` uses appropriate default format for project type
