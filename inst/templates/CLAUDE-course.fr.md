# Framework Course Project - Claude Code Instructions

## Project Overview

This is a Framework-based R project for **teaching and course materials** - workshops, semester courses, bootcamps, or training programs.

Framework provides:
- Organized structure for course content and student materials
- Separation of public materials and private grading/solutions
- Version control for course iteration and improvement
- Reproducible examples and datasets

## Directory Structure - COURSE FOCUSED

### Course Content (Committed)
- `course_materials/` - Main course content (slides, handouts, datasets)
  - `week-01/`, `week-02/`, etc. - Organized by week/module
  - `data/` - Small example datasets for students (committed)
  - `rendered/` - Pre-built slide decks (optionally gitignored, can be regenerated)
- `notebooks/` - Quarto teaching notebooks and demonstrations
- `scripts/` - Example R scripts for students
- `functions/` - Helper functions for course exercises

### Student Work (GITIGNORED)
- `submissions/` - Student homework and project submissions (**NEVER commit**)
- `student_work/` - Student in-class work (**NEVER commit**)
- `grades/` - Grade spreadsheets and records (**NEVER commit PII**)

### Private Materials (GITIGNORED)
- `solutions_private/` - Answer keys and complete solutions (**NEVER commit**)
- `answer_keys/` - Test/quiz answers (**NEVER commit**)
- Files matching `*_solutions.*`, `*_answers.*` - Auto-gitignored

### Course Administration
- `config.yml` - Course configuration (syllabus metadata, package list)
- `cache/`, `scratch/` - Temporary build artifacts (gitignored)

## Common Workflows

### 1. Setup Course Environment
```r
library(framework)
scaffold()  # Loads course packages and helper functions
```

### 2. Create New Lecture Notebook
```r
# Create teaching notebook
make_notebook("week-03-regression")
# → notebooks/week-03-regression.qmd

# Or organize by module
make_notebook("module-2-ggplot-intro")
```

### 3. Create Student Exercise
```r
# Create exercise template (without solutions)
make_notebook("exercise-data-wrangling")

# Add exercise instructions and code stubs
# Students fill in the blanks
```

### 4. Load Example Datasets
```r
# Small teaching datasets (committed in course_materials/data/)
data <- data_load("course_materials/data/mtcars_subset.csv")

# Or use built-in datasets
data(iris)
data(penguins, package = "palmerpenguins")
```

### 5. Save Course Materials
```r
# Public course content (committed)
result_save(lecture_plot, "week-03-figure-1", type = "plot")
# → outputs/public/figures/

# Private solutions (gitignored)
result_save(solution_plot, "exercise-1-solution", type = "plot", private = TRUE)
# → outputs/private/docs/
```

## Teaching Best Practices

### 1. Reproducibility for Students
- **Include renv.lock** so students get exact package versions
- **Small example datasets** in `course_materials/data/` (committed)
- **Seed random numbers** for consistent examples:
  ```r
  set.seed(2024)  # Or configure in config.yml
  ```

### 2. Version Control Strategy
```yaml
# .gitignore includes:
/submissions/          # Student work
/grades/               # Grade records
/solutions_private/    # Answer keys
*_solutions.*          # Any solution files
*_answers.*            # Any answer files
```

**Commit:**
- Lecture notes and teaching notebooks
- Public example datasets
- Code templates and exercises (without solutions)
- Helper functions for course

**Never Commit:**
- Student submissions or grades (privacy violation)
- Complete solution sets (defeats learning)
- Large datasets (use external hosting)

### 3. Organizing Course Content

**By Week:**
```
course_materials/
├── week-01/
│   ├── slides.qmd
│   ├── exercises.qmd
│   └── data/
├── week-02/
└── ...
```

**By Module:**
```
course_materials/
├── module-1-intro-to-r/
├── module-2-data-wrangling/
├── module-3-visualization/
└── ...
```

### 4. Student-Facing Documentation

Create `README.md` with:
- Course prerequisites
- How to install R packages: `scaffold()` or `renv::restore()`
- Where to find datasets
- How to submit assignments
- Office hours and communication

### 5. Handling Solutions

**Option A: Separate private repo**
- Keep solutions in private GitHub repo
- Share with TAs only

**Option B: Tagged commits**
- Commit solutions to same repo
- Tag solution commits (e.g., `v2024-solutions`)
- Students clone without --tags

**Option C: Framework approach (recommended)**
- Store solutions in `solutions_private/` (gitignored)
- Share with TAs via secure file sharing
- Never commit to git

## Framework Functions for Teaching

### Notebooks
- `make_notebook("lecture-topic")` - Create teaching notebook
- `make_script("demo-script")` - Create demonstration script

### Course Data
```r
# Load teaching datasets
data <- data_load("course_materials/data/example.csv")

# Save student-facing datasets
data_save(teaching_data, "course_materials/data/week-02-demo.csv")
```

### Example Caching (for large demonstrations)
```r
# Cache expensive model fits for live demos
demo_model <- get_or_cache(
  "week-05-demo-model",
  expr = fit_big_model(data),
  expire_days = 7
)
# Students see instant results in class
```

## Configuration for Courses

```yaml
default:
  project_type: course

  directories:
    course_materials: course_materials
    notebooks: notebooks
    solutions_private: solutions_private

  # Packages for course
  packages:
    - dplyr
    - ggplot2
    - tidyr
    - palmerpenguins  # Teaching datasets

  # Course metadata
  course:
    name: "Introduction to Data Science with R"
    semester: "Fall 2024"
    instructor: "Dr. Name"
```

## Tips for AI Assistants - COURSE PROJECT

When working with this course project:

1. **Separate public and private** - teaching materials vs solutions
2. **Never suggest committing** student work or grades
3. **Use small datasets** - keep examples manageable for students
4. **Reproducibility matters** - fixed seeds, clear package versions
5. **Progressive difficulty** - start simple, build complexity
6. **Comment heavily** - students are learning
7. **Include checks** - add assertions to catch common student errors
8. **Suggest exercises** - provide practice opportunities
9. **Avoid advanced R** - stick to concepts taught in course
10. **Create answer keys separately** - in `solutions_private/`

## Common Course Patterns

### Creating Exercise Template
```r
# Create notebook with exercise structure
make_notebook("exercise-02-dplyr")

# Add:
# - Learning objectives
# - Code stubs with # YOUR CODE HERE
# - Expected output examples
# - Hints in comments
```

### Live Coding Demo
```r
# Use make_script() for live coding
make_script("demo-ggplot-layers")

# Benefits:
# - Students see code and output side-by-side
# - Can save demo script for later reference
# - Less error-prone than typing live
```

### Weekly Template
```r
# Standardize weekly structure
make_notebook("week-04-slides")           # Lecture slides
make_notebook("week-04-exercises")        # In-class practice
make_notebook("week-04-homework")         # Take-home assignment
make_notebook("week-04-solutions")        # Solutions (gitignored)
```

## Framework Package
- GitHub: https://github.com/table1/framework
- Author: Erik Westlund
- License: MIT
