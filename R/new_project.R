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
#' \donttest{
#' if (FALSE) {
#' # Interactive - prompts for name and location
#' new_project()
#'
#' # With name and location specified
#' new_project("my-analysis", "~/projects/my-analysis")
#'
#' # Create a sensitive data project
#' new_project("medical-study", "~/projects/medical", type = "project_sensitive")
#' }
#' }
#'
#' @export
new_project <- function(name = NULL, location = NULL, type = "project", browse = interactive(), ...) {
  # Check global config exists
  config_dir <- fw_config_dir()
  settings_path <- file.path(config_dir, "settings.yml")

  if (!file.exists(settings_path)) {
    message("Global settings not found. Initializing defaults...")
    init_global_config()
  }

  # Load global config, then overlay cloud settings when a token is present
  # (no token or unreachable cloud -> local defaults, unchanged behavior)
  config <- get_default_global_config()
  config <- .fw_overlay_cloud_settings(config, .fw_cloud_settings_quietly())

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
  valid_types <- c("project", "project_sensitive", "course", "presentation", "bare")
  if (!type %in% valid_types) {
    stop("Invalid project type. Must be one of: ", paste(valid_types, collapse = ", "))
  }

  # Build arguments from global config
  args <- .project_args_from_config(config, type)

  # Cloud blueprint (opinionated offering) overrides structure and AI masters
  # when a token is present; offline this is a no-op
  blueprint <- .fw_cloud_blueprint_quietly(type)
  render_dirs <- NULL
  quarto <- NULL
  if (!is.null(blueprint)) {
    .fw_blueprint_stash(blueprint)
    on.exit(.fw_blueprint_clear(), add = TRUE)

    structure <- blueprint$structure %||% list()
    if (length(structure$directories %||% list()) > 0) {
      args$directories <- structure$directories
    }
    if (length(structure$render_dirs %||% list()) > 0) {
      render_dirs <- structure$render_dirs
    }
    if (!is.null(structure$quarto$render_dir)) {
      quarto <- list(render_dir = structure$quarto$render_dir)
    }
  }

  message("Creating ", type, " project: ", name)
  message("Location: ", location)

  # Create the project
  result <- project_create(
    name = name,
    location = location,
    type = type,
    author = args$author,
    packages = args$packages,
    directories = args$directories,
    extra_directories = list(),
    ai = args$ai,
    git = args$git,
    scaffold = args$scaffold,
    connections = args$connections,
    env = args$env,
    render_dirs = render_dirs,
    quarto = quarto,
    ...
  )

  # Register on framework.pub and store the project key (non-bare only:
  # bare projects have no .env to hold the secret)
  if (result$success && !identical(type, "bare")) {
    .fw_cloud_register_project(result$path, name, type)
  }

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
#' \donttest{
#' if (FALSE) {
#' new_project_sensitive("medical-study", "~/projects/medical")
#' }
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
#' \donttest{
#' if (FALSE) {
#' new_presentation("quarterly-review", "~/projects/q4-review")
#' }
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
#' \donttest{
#' if (FALSE) {
#' new_course("stats-101", "~/projects/stats-101")
#' }
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
#' \donttest{
#' if (FALSE) {
#' # Create different project types
#' new("analysis", "~/projects/analysis")
#' new("study", "~/projects/study", type = "project_sensitive")
#' new("slides", "~/projects/slides", type = "presentation")
#' new("course-materials", "~/projects/course", type = "course")
#' }
#' }
#'
#' @export
new <- function(name = NULL, location = NULL, type = NULL, browse = interactive(), ...) {
  if (is.null(type)) {
    # Bare (no blueprint) is the default; the rest are opinionated offerings
    valid_types <- c("bare", "project", "project_sensitive", "course", "presentation")
    if (interactive()) {
      labels <- c("bare (no blueprint - bring your own structure)",
                  "project", "project_sensitive", "course", "presentation")
      choice <- utils::menu(labels, title = "Project type:")
      if (choice == 0) {
        stop("Project creation cancelled")
      }
      type <- valid_types[choice]
    } else {
      type <- "bare"
    }
  }
  new_project(name = name, location = location, type = type, browse = browse, ...)
}

# Map a (possibly cloud-overlaid) global config to project_create() arguments.
# Shared by new_project() and the cloud project setup path in R/cloud.R.
#' @keywords internal
.project_args_from_config <- function(config, type) {
  defaults <- config$defaults %||% list()

  project_type_config <- config$project_types[[type]] %||% config$project_types$project %||% list()

  ai_config <- list(
    enabled = isTRUE(defaults$ai_support),
    assistants = defaults$ai_assistants %||% list(),
    canonical_content = ""
  )
  if (ai_config$enabled && length(ai_config$assistants) == 0) {
    ai_config$assistants <- list("claude")
  }

  list(
    author = config$author %||% list(name = "", email = "", affiliation = ""),
    packages = list(
      use_renv = isTRUE(defaults$use_renv),
      default_packages = defaults$packages %||% list()
    ),
    directories = project_type_config$directories %||% defaults$directories %||% list(),
    ai = ai_config,
    git = list(
      use_git = isTRUE(defaults$use_git),
      hooks = defaults$git_hooks %||% list(),
      gitignore_content = ""
    ),
    scaffold = list(
      seed_on_scaffold = isTRUE(defaults$seed_on_scaffold),
      seed = as.character(defaults$seed %||% ""),
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal",
      ide = defaults$ide %||% "vscode"
    ),
    connections = defaults$connections,
    env = defaults$env
  )
}
