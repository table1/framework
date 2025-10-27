# Feature: Initialize Framework Project From Empty Directory

## Overview
Add capability to run `framework::init()` from any empty directory (not just the framework-project template) to create a complete Framework project. This makes Framework accessible without requiring users to clone the template repository first.

## Requirements
- [x] Detect if running from empty directory vs. framework-project template
- [x] Create all necessary template files when running from empty
- [x] Provide interactive prompts for project configuration
- [x] Support both default and minimal project structures
- [x] Generate appropriate config files based on user choices
- [x] Create init.R for future reinitializations
- [x] Maintain backward compatibility with template-based init

## Implementation Checklist
- [x] Design and planning
- [x] Add template file detection logic to init()
- [x] Create embedded template files or fetch mechanism
- [x] Add interactive prompt system
- [x] Implement file generation for empty directory case
- [x] Write comprehensive tests
- [x] Update documentation
- [x] All tests passing (167 tests, 0 failures)

## Technical Details

### Current Behavior

`framework::init()` currently expects to run from the framework-project template:
- Reads configuration from existing `init.R`
- Copies template files from package `inst/templates/`
- Assumes certain files already exist

### Proposed Behavior

**When running from framework-project template (current):**
- Works exactly as it does now
- No breaking changes

**When running from empty/arbitrary directory (new):**
1. Detect empty directory or missing template files
2. Prompt user for configuration:
   ```r
   Project name: [auto-detect from directory name]
   Project structure: (1) Default (2) Minimal
   Lintr style: (1) Default (2) Tidyverse
   Styler style: (1) Default (2) Tidyverse
   Initialize git repository? (Y/n)
   ```
3. Create init.R with user's choices
4. Copy template files from package
5. Run initialization
6. Display next steps

### Files to Modify

1. **`R/init.R`**
   - Add `init_from_empty()` internal function
   - Modify `init()` to detect context and route appropriately
   - Add interactive prompting with `readline()`
   - Add validation for user inputs

2. **`inst/templates/`**
   - Ensure all necessary template files are included:
     - `init.fr.R` - Template init.R file
     - `scaffold.fr.R` - Template scaffold.R
     - `config.fr.yml` - Default config template
     - `.gitignore.fr` - Gitignore template
     - Other existing templates

3. **`R/scaffold.R`** (if needed)
   - May need to adjust for first-time setup

### Implementation Approach

```r
#' Initialize Framework project
#'
#' @param project_name Project name (default: current directory name)
#' @param project_structure "default" or "minimal"
#' @param lintr Lintr style (default: "default")
#' @param styler Styler style (default: "default")
#' @param interactive If TRUE, prompt for missing parameters
#' @param force Force reinitialize even if already initialized
#' @export
init <- function(
    project_name = NULL,
    project_structure = NULL,
    lintr = NULL,
    styler = NULL,
    interactive = TRUE,
    force = FALSE) {

  # Check if already initialized
  if (is_initialized() && !force) {
    stop("Project already initialized. Use force = TRUE to reinitialize.")
  }

  # Check if init.R exists (template-based init)
  if (file.exists("init.R")) {
    # Template-based initialization (current behavior)
    init_from_template(project_name, project_structure, lintr, styler, force)
  } else {
    # Empty directory initialization (new behavior)
    if (interactive && is.null(project_structure)) {
      # Prompt for configuration
      config <- prompt_project_config(project_name, project_structure, lintr, styler)
      do.call(init_from_empty, config)
    } else {
      # Non-interactive with defaults
      init_from_empty(
        project_name = project_name %||% basename(getwd()),
        project_structure = project_structure %||% "default",
        lintr = lintr %||% "default",
        styler = styler %||% "default"
      )
    }
  }
}

#' Prompt user for project configuration
#' @keywords internal
prompt_project_config <- function(project_name, project_structure, lintr, styler) {
  cat("Framework Project Initialization\n")
  cat("==================================\n\n")

  # Project name
  if (is.null(project_name)) {
    default_name <- basename(getwd())
    response <- readline(sprintf("Project name [%s]: ", default_name))
    project_name <- if (nzchar(response)) response else default_name
  }

  # Project structure
  if (is.null(project_structure)) {
    cat("\nProject structure:\n")
    cat("  1. Default (full structure with work/, settings/, etc.)\n")
    cat("  2. Minimal (lightweight with just data/, functions/, results/)\n")
    response <- readline("Choose structure [1]: ")
    project_structure <- if (response == "2") "minimal" else "default"
  }

  # Lintr style
  if (is.null(lintr)) {
    response <- readline("Lintr style [default]: ")
    lintr <- if (nzchar(response)) response else "default"
  }

  # Styler style
  if (is.null(styler)) {
    response <- readline("Styler style [default]: ")
    styler <- if (nzchar(response)) response else "default"
  }

  list(
    project_name = project_name,
    project_structure = project_structure,
    lintr = lintr,
    styler = styler
  )
}

#' Initialize from empty directory
#' @keywords internal
init_from_empty <- function(project_name, project_structure, lintr, styler) {
  message("Initializing Framework project from empty directory...")

  # 1. Create init.R
  create_init_file(project_name, project_structure, lintr, styler)

  # 2. Create scaffold.R
  create_scaffold_file()

  # 3. Create settings.yml
  create_config_file(project_structure)

  # 4. Create .env template
  create_env_file()

  # 5. Run standard init process
  init_from_template(project_name, project_structure, lintr, styler, force = TRUE)

  # 6. Display next steps
  display_next_steps()
}

#' Create init.R from template
#' @keywords internal
create_init_file <- function(project_name, project_structure, lintr, styler) {
  template <- system.file("templates/init.fr.R", package = "framework")
  content <- readLines(template)

  # Replace placeholders
  content <- gsub("\\{\\{PROJECT_NAME\\}\\}", project_name, content)
  content <- gsub("\\{\\{PROJECT_STRUCTURE\\}\\}", project_structure, content)
  content <- gsub("\\{\\{LINTR\\}\\}", lintr, content)
  content <- gsub("\\{\\{STYLER\\}\\}", styler, content)

  writeLines(content, "init.R")
  message("Created init.R")
}

#' Display next steps after initialization
#' @keywords internal
display_next_steps <- function() {
  cat("\n")
  cat("✓ Framework project initialized successfully!\n\n")
  cat("Next steps:\n")
  cat("  1. Review and edit settings.yml\n")
  cat("  2. Add secrets to .env (gitignored)\n")
  cat("  3. Start a new R session:\n")
  cat("     library(framework)\n")
  cat("     scaffold()\n")
  cat("  4. Start analyzing!\n\n")
  cat("See README.md for full documentation.\n")
}
```

### Template Files Needed

**`inst/templates/init.fr.R`:**
```r
# Framework Project Initialization
#
# This file configures your Framework project.
# Edit the parameters below, then run: framework::init()

framework::init(
  project_name = "{{PROJECT_NAME}}",
  project_structure = "{{PROJECT_STRUCTURE}}",
  lintr = "{{LINTR}}",
  styler = "{{STYLER}}"
)
```

**`inst/templates/scaffold.fr.R`:**
```r
# Scaffold File
#
# This file runs every time you call scaffold()
# Use it to set global options, load common data, etc.

# Example: Set global options
# options(
#   digits = 3,
#   scipen = 999,
#   stringsAsFactors = FALSE
# )

# Example: Load common data
# common_data <- data_load("source.private.common")
```

**`inst/templates/.env.fr`:**
```env
# Environment Variables
# Add your secrets here (this file is gitignored)

# Database credentials
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=mydb
# DB_USER=user
# DB_PASS=secret

# Encryption keys
# DATA_ENCRYPTION_KEY=
# RESULTS_ENCRYPTION_KEY=
```

## Testing Strategy

### Unit Tests

1. **Test empty directory detection:**
   ```r
   test_that("detects empty directory vs template", {
     # Test with init.R present
     # Test without init.R
   })
   ```

2. **Test interactive prompting:**
   - Mock `readline()` responses
   - Verify correct parameter extraction
   - Test defaults when user presses Enter

3. **Test file creation:**
   - Verify init.R created with correct content
   - Verify scaffold.R created
   - Verify settings.yml created
   - Verify .env template created

4. **Test non-interactive mode:**
   ```r
   test_that("non-interactive init works", {
     init(
       project_name = "test",
       project_structure = "minimal",
       lintr = "default",
       styler = "default",
       interactive = FALSE
     )
     expect_true(file.exists("init.R"))
     expect_true(file.exists("settings.yml"))
   })
   ```

### Integration Tests

1. Create temporary directory
2. Run `init()` with defaults
3. Verify complete project structure
4. Run `scaffold()` to verify it works
5. Clean up

## Documentation Updates

- [ ] Update `?init` documentation to explain both modes
- [ ] Add "From Empty Directory" section to README
- [ ] Update CLAUDE.md with new init patterns
- [ ] Create vignette showing both initialization paths
- [ ] Add FAQ: "Do I need to clone framework-project?"

## Breaking Changes

None - this is purely additive. Existing template-based workflow continues unchanged.

## User Experience

**Before (template required):**
```bash
git clone https://github.com/table1/framework-project my-project
cd my-project
# Edit init.R
```
```r
framework::init()
```

**After (two options):**

*Option 1: Template (unchanged):*
```bash
git clone https://github.com/table1/framework-project my-project
cd my-project
```
```r
framework::init()
```

*Option 2: From scratch (new):*
```bash
mkdir my-project
cd my-project
```
```r
library(framework)
init()  # Interactive prompts guide you
```

## Design Decisions

**Q: Should prompts be required or optional?**
A: Optional with sensible defaults. Set `interactive = FALSE` for scripted setup.

**Q: How to handle missing template files?**
A: Embed critical templates in package. Fail gracefully if templates missing.

**Q: Git initialization?**
A: Prompt user. If yes, run `git init` and create initial commit.

**Q: Package installation?**
A: Same as current behavior - prompt to install listed packages.

## Future Enhancements

- Web-based project configurator
- Project templates (analysis, package, report)
- RStudio addin for initialization
- VS Code extension integration
- Template customization system

## Notes

### Implementation Priority

1. File detection and routing logic
2. Template file creation functions
3. Interactive prompting
4. Testing with empty directories
5. Documentation updates

### Edge Cases

- User runs `init()` in directory with some files but no init.R
- User has custom templates in framework-project
- Network issues when fetching templates (if we add remote fetch)
- Permission issues creating files
