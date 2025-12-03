#' Create a new Framework project from GUI configuration
#'
#' This function creates a complete Framework project from scratch based on
#' configuration provided by the GUI. This function builds everything programmatically.
#'
#' @param name Project name (used for project title)
#' @param location Full path to the project directory (will be created)
#' @param type Project type: "project", "project_sensitive", "course", "presentation"
#' @param author List with name, email, affiliation
#' @param packages List with use_renv (logical) and default_packages (list of package configs)
#' @param directories Named list of directory paths (notebooks, scripts, functions, etc.)
#' @param extra_directories List of additional custom directories
#' @param ai List with enabled, assistants, canonical_content
#' @param git List with use_git, hooks, gitignore_content
#' @param scaffold List with seed_on_scaffold, seed, set_theme_on_scaffold, ggplot_theme, ide, positron
#' @param quarto List with html and revealjs format configurations for Quarto
#' @param render_dirs Named list of render directory paths for Quarto outputs
#'
#' @return List with success status, project path, and project ID
#' @export
project_create <- function(
  name,
  location,
  type = "project",
  author = list(name = "", email = "", affiliation = ""),
  packages = list(use_renv = FALSE, default_packages = list()),
  directories = list(),
  extra_directories = list(),
  ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
  git = list(use_git = TRUE, hooks = list(), gitignore_content = ""),
  scaffold = list(
    seed_on_scaffold = FALSE,
    seed = "",
    set_theme_on_scaffold = TRUE,
    ggplot_theme = "theme_minimal"
  ),
  connections = NULL,
  env = NULL,
  quarto = NULL,
  render_dirs = NULL
) {
  # Validate inputs
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(location, min.chars = 1)
  checkmate::assert_choice(type, c("project", "project_sensitive", "course", "presentation"))
  checkmate::assert_list(author)
  checkmate::assert_list(packages)
  checkmate::assert_list(directories)
  checkmate::assert_list(ai)
  checkmate::assert_list(git)
  checkmate::assert_list(scaffold)
  if (!is.null(connections)) {
    checkmate::assert_list(connections)
  }
  if (!is.null(env)) {
    checkmate::assert(
      checkmate::check_character(env, len = 1),
      checkmate::check_list(env)
    )
  }

  # Backfill render directory defaults when not provided
  if (is.null(render_dirs) || length(render_dirs) == 0) {
    render_dirs <- .default_render_dirs_for_type(type)
  }

  # Ensure quarto list exists and has a root render_dir if catalog defines one
  if (is.null(quarto)) {
    quarto <- list()
  }
  if (is.null(quarto$render_dir)) {
    default_root_dir <- .default_root_render_dir_for_type(type)
    if (!is.null(default_root_dir)) {
      quarto$render_dir <- default_root_dir
    }
  }

  # Use location as the full project directory path
  project_dir <- path.expand(location)

  # Check if directory already exists
  if (dir.exists(project_dir)) {
    stop("Project directory already exists: ", project_dir)
  }

  # Create project directory
  dir.create(project_dir, recursive = TRUE)
  message("Created project directory: ", project_dir)

  # Create subdirectories from directories config
  .create_project_directories(project_dir, directories, extra_directories, render_dirs)

  # Ensure settings directory exists (connections/env files live here)
  settings_dir <- file.path(project_dir, "settings")
  dir.create(settings_dir, recursive = TRUE, showWarnings = FALSE)

  # Create config.yml with all settings
  connections_rel_path <- "settings/connections.yml"

  .create_project_config(
    project_dir = project_dir,
    name = name,
    type = type,
    author = author,
    packages = packages,
    directories = directories,
    extra_directories = extra_directories,
    ai = ai,
    git = git,
    scaffold = scaffold,
    settings_dir = settings_dir,
    connections_file = connections_rel_path,
    render_dirs = render_dirs,
    quarto = quarto
  )

  .create_connections_file(
    project_dir = project_dir,
    connections = connections,
    relative_path = connections_rel_path
  )

  .create_env_file(
    project_dir = project_dir,
    env_config = env
  )

  # Create .gitignore from template content
  if (!is.null(git$gitignore_content) && nzchar(git$gitignore_content)) {
    .create_gitignore(project_dir, git$gitignore_content)
  }

  # Create AI context files
  if (ai$enabled && length(ai$assistants) > 0) {
    .create_ai_files(project_dir, ai$assistants, ai$canonical_content, type)
  }

  # Create scaffold.R with seed and theme setup
  .create_scaffold_file(project_dir, scaffold)

  # Create .Rproj file (always)
  .create_rproj_file(project_dir, name)

  # Create .code-workspace file for VSCode/Positron users
  ide <- scaffold$ide %||% ""
  positron <- scaffold$positron %||% FALSE
  if (grepl("vscode|positron", ide, ignore.case = TRUE) || isTRUE(positron)) {
    .create_code_workspace(project_dir, name)
  }

  # Create stub files for specific project types
  .create_stub_files(project_dir, type, name, author)

  # Initialize renv if requested (before git so renv files are committed)
  if (packages$use_renv) {
    .init_renv(project_dir)
  }

  # Generate Quarto configuration files (before git so configs are committed)
  if (!is.null(quarto) || !is.null(render_dirs)) {
    root_output_dir <- NULL
    if (!is.null(quarto) && !is.null(quarto$render_dir)) {
      root_output_dir <- quarto$render_dir
    }
    quarto_result <- quarto_generate_all(
      project_path = project_dir,
      project_type = type,
      render_dirs = render_dirs,
      quarto_settings = quarto,
      directories = directories,
      root_output_dir = root_output_dir
    )
    if (quarto_result$success) {
      message("✓ Generated ", quarto_result$count, " Quarto configuration file(s)")
    }
  }

  # Initialize git repository LAST so all files are included in initial commit
  if (git$initialize %||% git$use_git %||% TRUE) {
    .init_git_repo(project_dir, git$hooks)
  }

  # Add to project registry (skip for temp directories used in tests)
  project_id <- NULL
  if (!grepl("^/tmp/|^/var/folders/", project_dir)) {
    project_id <- .add_project_to_config(project_dir)
  }

  message("✓ Project created successfully: ", project_dir)

  list(
    success = TRUE,
    path = project_dir,
    id = project_id
  )
}

#' Create project subdirectories
#' @keywords internal
.create_project_directories <- function(project_dir, directories, extra_directories, render_dirs = NULL) {
  # Files that should NOT be created as directories
  file_patterns <- c("\\.qmd$", "\\.Rmd$", "\\.R$", "\\.md$")

  # Create standard directories
  for (dir_name in directories) {
    if (!is.null(dir_name) && nzchar(dir_name)) {
      # Skip output directories to avoid clutter; they'll be created on demand by renders
      if (grepl("^outputs/", dir_name)) {
        next
      }
      # Skip if this looks like a file (has a file extension)
      is_file <- any(sapply(file_patterns, function(pattern) grepl(pattern, dir_name)))
      if (is_file) {
        next
      }

      dir_path <- file.path(project_dir, dir_name)
      dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
      message("  Created: ", dir_name)
    }
  }

  # Create extra directories
  if (length(extra_directories) > 0) {
    for (extra_dir in extra_directories) {
      if (!is.null(extra_dir$path) && nzchar(extra_dir$path)) {
        dir_path <- file.path(project_dir, extra_dir$path)
        dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
        message("  Created: ", extra_dir$path)
      }
    }
  }

  # Create render output directories (only for notebooks; others lazy-created on demand)
  if (!is.null(render_dirs) && length(render_dirs) > 0) {
    for (dir_name_idx in seq_along(render_dirs)) {
      dir_name <- render_dirs[[dir_name_idx]]
      dir_key <- names(render_dirs)[dir_name_idx]
      if (is.null(dir_name) || !nzchar(dir_name)) next

      # Only pre-create notebook render outputs to reduce clutter
      if (!is.null(dir_key) && !grepl("notebook", dir_key, ignore.case = TRUE)) next

      is_file <- any(sapply(file_patterns, function(pattern) grepl(pattern, dir_name)))
      if (is_file) next
      dir_path <- file.path(project_dir, dir_name)
      dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
      message("  Created render output: ", dir_name)
    }
  }
}

#' Convert data frame to list of lists for YAML serialization
#' JSON arrays of objects become data frames in R, but YAML needs list of lists
#' @keywords internal
.df_to_list_of_lists <- function(df) {

  if (is.null(df) || length(df) == 0) {
    return(list())
  }
  if (is.data.frame(df)) {
    return(lapply(seq_len(nrow(df)), function(i) as.list(df[i, , drop = FALSE])))
  }
  # Already a list, return as-is
  if (is.list(df)) {
    return(df)
  }
  list()
}

#' Resolve default render directory mappings for a project type from the catalog
#' @keywords internal
.default_render_dirs_for_type <- function(type) {
  catalog_path <- system.file("config/settings-catalog.yml", package = "framework")
  if (!file.exists(catalog_path)) {
    return(list())
  }
  catalog <- yaml::read_yaml(catalog_path)
  render_dirs <- catalog$project_types[[type]]$render_dirs
  if (is.null(render_dirs)) return(list())

  lapply(render_dirs, function(entry) {
    if (is.list(entry) && !is.null(entry$default)) {
      entry$default
    } else {
      entry
    }
  })
}

#' Resolve default root render_dir (if defined) for a project type
#' @keywords internal
.default_root_render_dir_for_type <- function(type) {
  catalog_path <- system.file("config/settings-catalog.yml", package = "framework")
  if (!file.exists(catalog_path)) {
    return(NULL)
  }
  catalog <- yaml::read_yaml(catalog_path)
  rd <- catalog$project_types[[type]]$quarto$render_dir
  if (is.null(rd)) return(NULL)
  if (is.list(rd) && !is.null(rd$default)) {
    return(rd$default)
  }
  rd
}

#' Create project config.yml
#' @keywords internal
.create_project_config <- function(
  project_dir,
  name,
  type,
  author,
  packages,
  directories,
  extra_directories,
  ai,
  git,
  scaffold,
  settings_dir,
  connections_file = "settings/connections.yml",
  render_dirs = NULL,
  quarto = NULL
) {
  # For project and project_sensitive types, use split settings files
  # For presentation and course, use single settings.yml file
  use_split_files <- type %in% c("project", "project_sensitive")

  if (use_split_files) {
    # Ensure settings directory exists
    dir.create(settings_dir, recursive = TRUE, showWarnings = FALSE)

    # Main settings.yml with references to split files
    main_config <- list(
      default = list(
        project_name = name,
        project_type = type,

        # Directory configuration (inline for discoverability)
        directories = directories,
        extra_directories = if (length(extra_directories) > 0) extra_directories else NULL,
        render_dirs = render_dirs,
        quarto = quarto,

        # References to split files
        author = "settings/author.yml",
        packages = "settings/packages.yml",
        git = "settings/git.yml",
        ai = "settings/ai.yml",
        scaffold = "settings/scaffold.yml",
        connections = connections_file
      )
    )

    # Write main settings.yml
    yaml::write_yaml(main_config, file.path(project_dir, "settings.yml"))
    message("  Created: settings.yml")

    # Write split files
    yaml::write_yaml(list(author = list(
      name = author$name %||% "",
      email = author$email %||% "",
      affiliation = author$affiliation %||% ""
    )), file.path(settings_dir, "author.yml"))

    yaml::write_yaml(list(packages = list(
      use_renv = packages$use_renv %||% FALSE,
      default_packages = .df_to_list_of_lists(packages$default_packages)
    )), file.path(settings_dir, "packages.yml"))

    yaml::write_yaml(list(git = list(
      enabled = git$initialize %||% git$use_git %||% TRUE,
      user_name = git$user_name %||% "",
      user_email = git$user_email %||% "",
      hooks = git$hooks
    )), file.path(settings_dir, "git.yml"))

    yaml::write_yaml(list(ai = list(
      enabled = ai$enabled %||% FALSE,
      canonical_file = ai$canonical_file %||% "CLAUDE.md",
      assistants = ai$assistants
    )), file.path(settings_dir, "ai.yml"))

    yaml::write_yaml(list(scaffold = list(
      seed_on_scaffold = scaffold$seed_on_scaffold %||% FALSE,
      seed = scaffold$seed %||% "",
      set_theme_on_scaffold = scaffold$set_theme_on_scaffold %||% TRUE,
      ggplot_theme = scaffold$ggplot_theme %||% "theme_minimal",
      notebook_format = scaffold$notebook_format %||% "quarto",
      positron = scaffold$positron %||% FALSE
    )), file.path(settings_dir, "scaffold.yml"))

    message("  Created: settings/ directory with split configuration files")
  } else {
    # Single settings.yml file for presentation and course types
    config <- list(
      default = list(
        project_name = name,
        project_type = type,

        # Author information
        author = list(
          name = author$name %||% "",
          email = author$email %||% "",
          affiliation = author$affiliation %||% ""
        ),

        # Directories (inline for discoverability)
        directories = directories,
        extra_directories = if (length(extra_directories) > 0) extra_directories else NULL,
        render_dirs = render_dirs,
        quarto = quarto,

        # Package configuration
        packages = list(
          use_renv = packages$use_renv %||% FALSE,
          default_packages = .df_to_list_of_lists(packages$default_packages)
        ),

        # Git configuration
        git = list(
          enabled = git$initialize %||% git$use_git %||% TRUE,
          user_name = git$user_name %||% "",
          user_email = git$user_email %||% "",
          hooks = git$hooks
        ),

        # AI configuration
        ai = list(
          enabled = ai$enabled %||% FALSE,
          canonical_file = ai$canonical_file %||% "CLAUDE.md",
          assistants = ai$assistants
        ),

        # Scaffold configuration
        scaffold = list(
          seed_on_scaffold = scaffold$seed_on_scaffold %||% FALSE,
          seed = scaffold$seed %||% "",
          set_theme_on_scaffold = scaffold$set_theme_on_scaffold %||% TRUE,
          ggplot_theme = scaffold$ggplot_theme %||% "theme_minimal",
          notebook_format = scaffold$notebook_format %||% "quarto",
          positron = scaffold$positron %||% FALSE
        ),
        connections = connections_file
      )
    )

    config_path <- file.path(project_dir, "settings.yml")
    yaml::write_yaml(config, config_path)
    message("  Created: settings.yml")
  }
}

.default_connections_configuration <- function() {
  list(
    options = list(
      default_connection = "framework"
    ),
    connections = list(
      framework = list(
        driver = "sqlite",
        database = "framework.db"
      )
    )
  )
}

.create_connections_file <- function(project_dir, connections, relative_path) {
  config <- connections

  if (is.null(config) || length(config) == 0) {
    config <- .default_connections_configuration()
  } else {
    config$options <- config$options %||% list()
    config$connections <- config$connections %||% list()
    if (is.null(config$options$default_connection) && length(config$connections) > 0) {
      config$options$default_connection <- names(config$connections)[1]
    }
  }

  target_path <- file.path(project_dir, relative_path)
  dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)

  yaml::write_yaml(config, target_path)
  message("  Created: ", relative_path)
}

.create_env_file <- function(project_dir, env_config = NULL) {
  env_lines <- env_resolve_lines(env_config)
  env_path <- file.path(project_dir, ".env")
  writeLines(env_lines, env_path)
  message("  Created: .env")
}

#' Create .gitignore file
#' @keywords internal
.create_gitignore <- function(project_dir, content) {
  gitignore_path <- file.path(project_dir, ".gitignore")
  writeLines(content, gitignore_path)
  message("  Created: .gitignore")
}

#' Create AI context files
#' @keywords internal
.create_ai_files <- function(project_dir, assistants, canonical_content, type) {
  # Map assistants to file paths
  ai_files <- list(
    claude = "CLAUDE.md",
    agents = "AGENTS.md",
    copilot = ".github/copilot-instructions.md"
  )

  # Get project name from directory
  project_name <- basename(normalizePath(project_dir))

  # Try to read config for dynamic generation
  config <- tryCatch(
    config_read(file.path(project_dir, "settings.yml")),
    error = function(e) NULL
  )

  # Generate content
  if (!is.null(config)) {
    # Use dynamic generation with ai_generate()
    content <- ai_generate(
      project_path = project_dir,
      project_name = project_name,
      project_type = type,
      config = config
    )
  } else {
    # Fall back to template
    content <- .load_ai_template(type, project_name)
  }

  # If still empty, use provided canonical_content
  if (is.null(content) || !nzchar(content)) {
    content <- canonical_content
  }

  for (assistant in assistants) {
    if (assistant %in% names(ai_files)) {
      file_path <- file.path(project_dir, ai_files[[assistant]])

      # Create directory if needed (for copilot)
      file_dir <- dirname(file_path)
      if (!dir.exists(file_dir)) {
        dir.create(file_dir, recursive = TRUE)
      }

      # Write file
      writeLines(content, file_path)
      message("  Created: ", ai_files[[assistant]])
    }
  }
}

#' Load template content from inst/templates
#' @keywords internal
.load_template_content <- function(template_name) {
  template_path <- system.file(sprintf("templates/%s", template_name), package = "framework")
  if (file.exists(template_path)) {
    return(paste(readLines(template_path, warn = FALSE), collapse = "\n"))
  }
  NULL
}

#' Create scaffold.R file
#' @keywords internal
.create_scaffold_file <- function(project_dir, scaffold) {
  scaffold_content <- c(
    "# scaffold.R",
    "# This file is sourced by framework::scaffold() to set up your project environment",
    "",
    "# Set random seed for reproducibility"
  )

  if (scaffold$seed_on_scaffold && nzchar(scaffold$seed)) {
    scaffold_content <- c(
      scaffold_content,
      sprintf('set.seed(%s)', scaffold$seed),
      sprintf('message("Random seed set to %s")', scaffold$seed)
    )
  } else {
    scaffold_content <- c(
      scaffold_content,
      "# set.seed(20241109)  # Uncomment and set your seed"
    )
  }

  scaffold_content <- c(
    scaffold_content,
    "",
    "# Set ggplot2 theme"
  )

  if (scaffold$set_theme_on_scaffold && nzchar(scaffold$ggplot_theme)) {
    scaffold_content <- c(
      scaffold_content,
      "if (requireNamespace('ggplot2', quietly = TRUE)) {",
      sprintf("  ggplot2::theme_set(ggplot2::%s())", scaffold$ggplot_theme),
      sprintf('  message("ggplot2 theme set to %s")', scaffold$ggplot_theme),
      "}"
    )
  } else {
    scaffold_content <- c(
      scaffold_content,
      "# if (requireNamespace('ggplot2', quietly = TRUE)) {",
      "#   ggplot2::theme_set(ggplot2::theme_minimal())",
      "# }"
    )
  }

  scaffold_path <- file.path(project_dir, "scaffold.R")
  writeLines(scaffold_content, scaffold_path)
  message("  Created: scaffold.R")
}

#' Convert string to kebab-case
#' @keywords internal
.to_kebab_case <- function(str) {
  # Convert to lowercase
  result <- tolower(str)
  # Remove non-alphanumeric characters except spaces, underscores, and hyphens
  result <- gsub("[^a-z0-9 _-]", "", result)
  # Replace spaces and underscores with hyphens
  result <- gsub("[ _]+", "-", result)
  # Replace multiple hyphens with single hyphen
  result <- gsub("-+", "-", result)
  # Remove leading/trailing hyphens
  result <- gsub("^-|-$", "", result)
  result
}

#' Create .Rproj file
#' @keywords internal
.create_rproj_file <- function(project_dir, name) {
  kebab_name <- .to_kebab_case(name)

  rproj_content <- c(
    "Version: 1.0",
    "",
    "RestoreWorkspace: No",
    "SaveWorkspace: No",
    "AlwaysSaveHistory: No",
    "",
    "EnableCodeIndexing: Yes",
    "UseSpacesForTab: Yes",
    "NumSpacesForTab: 2",
    "Encoding: UTF-8",
    "",
    "RnwWeave: knitr",
    "LaTeX: XeLaTeX"
  )

  rproj_path <- file.path(project_dir, sprintf("%s.Rproj", kebab_name))
  writeLines(rproj_content, rproj_path)
  message("  Created: ", sprintf("%s.Rproj", kebab_name))
}

#' Create .code-workspace file for VSCode/Positron
#' @keywords internal
.create_code_workspace <- function(project_dir, name) {
  kebab_name <- .to_kebab_case(name)

  # Create basic workspace configuration
  workspace_config <- list(
    folders = list(
      list(path = ".")
    ),
    settings = list(
      `r.rterm.option` = c("--no-save", "--no-restore"),
      `r.sessionWatcher` = TRUE,
      `r.alwaysUseActiveTerminal` = TRUE,
      `files.associations` = list(
        `*.qmd` = "quarto",
        `*.Rmd` = "rmarkdown"
      )
    )
  )

  workspace_path <- file.path(project_dir, sprintf("%s.code-workspace", kebab_name))
  workspace_json <- jsonlite::toJSON(workspace_config, pretty = TRUE, auto_unbox = TRUE)
  writeLines(workspace_json, workspace_path)
  message("  Created: ", sprintf("%s.code-workspace", kebab_name))
}

#' Initialize git repository
#' @keywords internal
.init_git_repo <- function(project_dir, hooks) {
  old_wd <- getwd()
  on.exit(setwd(old_wd))
  setwd(project_dir)

  # Initialize git
  system2("git", c("init"), stdout = FALSE, stderr = FALSE)
  message("  Initialized git repository")

  # Install git hooks if any are enabled
  # hooks_install() reads settings from config file, so just call it with force=TRUE
  if (length(hooks) > 0 && any(unlist(hooks))) {
    tryCatch({
      hooks_install(force = TRUE, verbose = FALSE)
      message("  Installed git hooks")
    }, error = function(e) {
      warning("Failed to install git hooks: ", e$message)
    })
  }

  # Stage all files
  add_result <- system2("git", c("add", "."), stdout = TRUE, stderr = TRUE)

  # Create initial commit with proper message formatting
  # Use system() with proper shell quoting for the commit message
  commit_result <- system(
    "git commit -m 'Initial commit from Framework'",
    intern = TRUE,
    ignore.stderr = FALSE
  )

  if (length(commit_result) > 0 && any(grepl("create mode|Initial commit|file changed|files changed", commit_result))) {
    message("  Created initial commit")
  }
}

#' Initialize renv
#' @keywords internal
.init_renv <- function(project_dir) {
  old_wd <- getwd()
  on.exit(setwd(old_wd))
  setwd(project_dir)

  if (requireNamespace("renv", quietly = TRUE)) {
    tryCatch({
      renv::init(bare = TRUE)
      message("  Initialized renv")
    }, error = function(e) {
      warning("Failed to initialize renv: ", e$message)
    })
  } else {
    warning("renv package not available - skipping renv initialization")
  }
}

#' Create stub files for specific project types
#' @keywords internal
.create_stub_files <- function(project_dir, type, name, author) {
  author_name <- if (!is.null(author$name) && nzchar(author$name)) {
    author$name
  } else {
    "Your Name"
  }

  # Presentation projects need a presentation.qmd file
  if (type == "presentation") {
    presentation_file <- file.path(project_dir, "presentation.qmd")
    presentation_content <- sprintf('---
title: "%s"
author: "%s"
date: "`r Sys.Date()`"
format:
  revealjs:
    theme: default
    transition: slide
    slide-number: true
    chalkboard: true
execute:
  echo: true
---

```{r}
#| label: setup
#| include: false

library(framework)
scaffold()
```

## Introduction

Welcome to your presentation!

Edit this file or create new presentations with `make_notebook(stub = "revealjs")`.

## Key Points

- Point 1
- Point 2
- Point 3

## Data Analysis

```{r}
# Load and analyze data
# data <- data_read("example")
summary(mtcars[, 1:3])
```

## Visualization

```{r}
plot(mtcars$mpg, mtcars$hp,
     xlab = "MPG", ylab = "Horsepower",
     main = "Example Plot")
```

## Conclusion

- Summary point 1
- Summary point 2
- Next steps

## Thank You!

Questions?
', name, author_name)

    writeLines(presentation_content, presentation_file)
    message("  Created: presentation.qmd")
  }

  # Course projects might need similar stub files in the future
  # project and project_sensitive types don't need stub files
}
