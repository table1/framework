#' Create a New Framework Project
#'
#' Convenience wrapper for creating Framework projects from the command line.
#' Uses global settings configured via `setup()` as defaults, prompts for
#' missing required values (name and location).
#'
#' @param name Project name. If NULL (default), prompts interactively.
#' @param location Directory path where project will be created. If NULL (default),
#'   prompts interactively.
#' @param type Project type. One of "project" (default), "project_sensitive",
#'   "course", or "presentation".
#' @param browse Whether to open the project folder after creation (default: TRUE in
#'   interactive sessions)
#' @param ... Additional arguments passed to `project_
#'
#' @return Invisibly returns the result from `project_create()` (list with success,
#'   path, and project_id)
#'
#' @details
#' This function is designed for the streamlined workflow:
#' ```r
#' remotes::install_github("table1/framework")
#' framework::setup()        # One-time global configuration
#' framework::new_project()  # Create projects using saved defaults
#' ```
#'
#' Global settings from `tools::R_user_dir("framework", "config")` are used for:
#' - Author information (name, email, affiliation
#' - Default packages
#' - Directory structure
#' - Git settings
#' - AI assistant configuration
#' - Quarto format preferences
#'
#' @seealso [setup()] for initial configuration, [project_create()] for full control
#'
#' @examples
#' \dontrun{
#' # Interactive - prompts for name and location
#' new_project()
#'
#' # With name and location specified
#' new_project("my-analysis", "~/projects/my-analysis")
#'
#' # Create a sensitive data project
#' new_project("medical-study", "~/projects/medical", type = "project_sensitive")
#' }
#'
#' @export
new_project <- function(name = NULL, location = NULL, type = "project", browse = interactive(), ...) {
  # Check global config exists
  config_dir <- fw_config_dir()
  settings_path <- file.path(config_dir, "settings.yml")

  if (!file.exists(settings_path)) {
    message("Global settings not found. Running setup() first...")
    setup()
    if (!file.exists(settings_path)) {
      stop("Setup cancelled or failed. Run framework::setup() to configure global settings.")
    }
  }

  # Load global config
  config <- get_default_global_config()

  # Prompt for name if not provided
  if (is.null(name)) {
    if (!interactive()) {
      stop("Project name is required in non-interactive mode")
    }
    name <- readline("Project name: ")
    if (nchar(trimws(name)) == 0) {
      stop("Project name cannot be empty")
    }
    name <- trimws(name)
  }

  # Prompt for location if not provided
  if (is.null(location)) {
    if (!interactive()) {
      stop("Project location is required in non-interactive mode")
    }
    # Suggest a default location based on name
    suggested <- file.path("~", "projects", gsub(" ", "-", tolower(name)))
    location <- readline(paste0("Project location [", suggested, "]: "))
    if (nchar(trimws(location)) == 0) {
      location <- suggested
    }
    location <- trimws(location)
  }

  # Expand path

  location <- path.expand(location)

  # Validate type
  valid_types <- c("project", "project_sensitive", "course", "presentation")
  if (!type %in% valid_types) {
    stop("Invalid project type. Must be one of: ", paste(valid_types, collapse = ", "))
  }

  # Build arguments from global config
  author <- config$author %||% list(name = "", email = "", affiliation = "")
  defaults <- config$defaults %||% list()

  packages_config <- list(
    use_renv = isTRUE(defaults$use_renv),
    default_packages = defaults$packages %||% list()
  )

  # Get directories for this project type
  project_type_config <- config$project_types[[type]] %||% config$project_types$project %||% list()
  directories <- project_type_config$directories %||% defaults$directories %||% list()

  ai_config <- list(
    enabled = isTRUE(defaults$ai_support),
    assistants = defaults$ai_assistants %||% list(),
    canonical_content = ""
  )
  if (ai_config$enabled && length(ai_config$assistants) == 0) {
    ai_config$assistants <- list("claude")
  }

  git_config <- list(
    use_git = isTRUE(defaults$use_git),
    hooks = defaults$git_hooks %||% list(),
    gitignore_content = ""
  )

  scaffold_config <- list(
    seed_on_scaffold = isTRUE(defaults$seed_on_scaffold),
    seed = as.character(defaults$seed %||% ""),
    set_theme_on_scaffold = TRUE,
    ggplot_theme = "theme_minimal",
    ide = defaults$ide %||% "vscode"
  )

  connections <- defaults$connections

  env <- defaults$env

  message("Creating ", type, " project: ", name)
  message("Location: ", location)

  # Create the project
  result <- project_create(
    name = name,
    location = location,
    type = type,
    author = author,
    packages = packages_config,
    directories = directories,
    extra_directories = list(),
    ai = ai_config,
    git = git_config,
    scaffold = scaffold_config,
    connections = connections,
    env = env,
    ...
  )

  # Open project folder if requested
  if (browse && result$success) {
    if (Sys.info()["sysname"] == "Darwin") {
      system2("open", location)
    } else if (Sys.info()["sysname"] == "Windows") {
      shell.exec(location)
    } else {
      system2("xdg-open", location)
    }
  }

  if (result$success) {
    message("\nProject created successfully!")
    message("Next steps:")
    message("  1. Open the project in your IDE")
    message("  2. Run scaffold() to set up your environment")
    message("  3. Start working with make_notebook() or make_script()")
  }

  invisible(result)
}


#' Create a Sensitive Data Project
#'
#' Shorthand for `new_project(..., type = "project_sensitive")`. Creates a project
#' with additional privacy protections for handling sensitive data.
#'
#' @inheritParams new_project
#'
#' @return Invisibly returns the result from `project_create()`
#'
#' @seealso [new_project()]
#'
#' @examples
#' \dontrun{
#' new_project_sensitive("medical-study", "~/projects/medical")
#' }
#'
#' @export
new_project_sensitive <- function(name = NULL, location = NULL, browse = interactive(), ...) {
  new_project(name = name, location = location, type = "project_sensitive", browse = browse, ...)
}


#' Create a Presentation Project
#'
#' Shorthand for `new_project(..., type = "presentation")`. Creates a project
#' optimized for RevealJS presentations.
#'
#' @inheritParams new_project
#'
#' @return Invisibly returns the result from `project_create()`
#'
#' @seealso [new_project()]
#'
#' @examples
#' \dontrun{
#' new_presentation("quarterly-review", "~/projects/q4-review")
#' }
#'
#' @export
new_presentation <- function(name = NULL, location = NULL, browse = interactive(), ...) {
  new_project(name = name, location = location, type = "presentation", browse = browse, ...)
}


#' Create a Course Project
#'
#' Shorthand for `new_project(..., type = "course")`. Creates a project
#' structured for teaching materials with slides, assignments, and modules.
#'
#' @inheritParams new_project
#'
#' @return Invisibly returns the result from `project_create()`
#'
#' @seealso [new_project()]
#'
#' @examples
#' \dontrun{
#' new_course("stats-101", "~/projects/stats-101")
#' }
#'
#' @export
new_course <- function(name = NULL, location = NULL, browse = interactive(), ...) {
  new_project(name = name, location = location, type = "course", browse = browse, ...)
}


#' Create a New Project (Master Wrapper)
#'
#' Flexible project creation interface. Alias for `new_project()` that accepts
#' type as a parameter.
#'
#' @inheritParams new_project
#'
#' @return Invisibly returns the result from `project_create()`
#'
#' @seealso [new_project()], [new_project_sensitive()], [new_presentation()], [new_course()]
#'
#' @examples
#' \dontrun{
#' # Create different project types
#' new("analysis", "~/projects/analysis")
#' new("study", "~/projects/study", type = "project_sensitive")
#' new("slides", "~/projects/slides", type = "presentation")
#' new("course-materials", "~/projects/course", type = "course")
#' }
#'
#' @export
new <- function(name = NULL, location = NULL, type = "project", browse = interactive(), ...) {
  new_project(name = name, location = location, type = type, browse = browse, ...)
}
