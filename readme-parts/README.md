# README Parts System

This directory contains the modular parts that build `README.md`.

## Structure

- **Numbered parts**: Files like `1_header.md`, `2_quickstart.md`, etc.
- **build.R**: Script that stitches parts together into `README.md`
- Parts are combined in numerical order with blank lines between sections

## Usage

### Edit README Content

1. Edit the relevant numbered part file (e.g., `4_usage_notebooks.md`)
2. Run: `Rscript readme-parts/build.R`
3. The `README.md` is regenerated from all parts

### Parts Overview

- `1_header.md` - Title and description
- `2_quickstart.md` - Installation and initialization
- `3_workflow_intro.md` - Core workflow intro
- `4_usage_notebooks.md` - **make_notebook() documentation** (SHARED with framework-project)
- `5_usage_data.md` - Data loading, caching, results
- `6_rest.md` - Configuration, functions, security, etc.

## Shared Content with framework-project

**Part 4 (`4_usage_notebooks.md`) is shared** with framework-project!

### framework (this repo)
- Has ALL 6 parts including `4_usage_notebooks.md`
- Build: `Rscript readme-parts/build.R`

### framework-project
- Has parts 1, 2, 3, 5, 6 (NO part 4)
- Build: `Rscript readme-parts/build.R`
- Result: Same README but without notebook usage section

### To Update Shared Section

1. **Edit**: `/Users/erikwestlund/code/framework/readme-parts/4_usage_notebooks.md`
2. **Build framework**: `cd ~/code/framework && Rscript readme-parts/build.R`
3. **Copy to framework-project**:
   ```bash
   cp ~/code/framework/readme-parts/4_usage_notebooks.md ~/code/framework-project/readme-parts/
   ```
4. **Build framework-project**: `cd ~/code/framework-project && Rscript readme-parts/build.R`

## Benefits

- ✅ Single source of truth for notebook documentation
- ✅ No complex hooks or scripts
- ✅ Easy to see what's shared (part 4)
- ✅ Edit from correct location (always framework repo)
- ✅ Simple copy when you update shared content
- ✅ Both READMEs stay in sync
