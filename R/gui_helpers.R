#' Initialize global Framework settings
#'
#' Creates ~/.config/framework/ directory and copies default settings files
#' if they don't already exist.
#'
#' @param force If TRUE, overwrites existing settings (default: FALSE)
#' @return Invisibly returns NULL
#' @export
init_global_config <- function(force = FALSE) {
  config_dir <- path.expand("~/.config/framework")
  settings_path <- file.path(config_dir, "settings.yml")
  projects_path <- file.path(config_dir, "projects.yml")

  # Create directory if needed
  if (!dir.exists(config_dir)) {
    dir.create(config_dir, recursive = TRUE)
    message("Created Framework settings directory: ", config_dir)
  }

  # Copy default settings if doesn't exist or force is TRUE
  if (!file.exists(settings_path) || force) {
    default_settings <- system.file("config", "global-settings-default.yml", package = "framework")
    if (file.exists(default_settings)) {
      file.copy(default_settings, settings_path, overwrite = force)
      message("Initialized global settings: ", settings_path)
    } else {
      stop("Could not find default settings template in package")
    }
  }

  # Create empty projects file if doesn't exist
  if (!file.exists(projects_path)) {
    yaml::write_yaml(list(projects = list()), projects_path)
    message("Initialized projects registry: ", projects_path)
  }

  invisible(NULL)
}

#' Get default global configuration structure
#'
#' @return List with default global configuration
#' @export
#' @keywords internal
get_default_global_config <- function() {
  catalog <- load_settings_catalog(include_user = TRUE, validate = TRUE)

  project_types <- .catalog_project_type_defaults(catalog$project_types)

  defaults <- catalog$defaults %||% list()
  defaults$project_type <- defaults$project_type %||% "project"
  defaults$notebook_format <- defaults$notebook_format %||% "quarto"
  defaults$ide <- defaults$ide %||% "vscode"
  defaults$use_git <- if (is.null(defaults$use_git)) TRUE else isTRUE(defaults$use_git)
  defaults$use_renv <- if (is.null(defaults$use_renv)) FALSE else isTRUE(defaults$use_renv)
  defaults$seed <- defaults$seed %||% NULL
  if (is.character(defaults$seed) && identical(defaults$seed, "")) {
    defaults$seed <- NULL
  }
  if (!"seed" %in% names(defaults)) {
    defaults["seed"] <- list(NULL)
  }
  defaults$seed_on_scaffold <- if (is.null(defaults$seed_on_scaffold)) FALSE else isTRUE(defaults$seed_on_scaffold)
  defaults$ai_support <- if (is.null(defaults$ai_support)) TRUE else isTRUE(defaults$ai_support)
  defaults$ai_assistants <- as.list(defaults$ai_assistants %||% list())
  defaults$ai_canonical_file <- defaults$ai_canonical_file %||% "CLAUDE.md"
  defaults$git_hooks <- defaults$git_hooks %||% list()
  defaults$git_hooks$ai_sync <- if (is.null(defaults$git_hooks$ai_sync)) FALSE else isTRUE(defaults$git_hooks$ai_sync)
  defaults$git_hooks$data_security <- if (is.null(defaults$git_hooks$data_security)) FALSE else isTRUE(defaults$git_hooks$data_security)

  defaults$packages <- if (!is.null(defaults$packages) && is.list(defaults$packages)) {
    result <- lapply(defaults$packages, function(pkg) {
      if (is.character(pkg) && length(pkg) == 1) {
        # Single string like "dplyr"
        list(name = pkg, auto_attach = TRUE)
      } else if (is.list(pkg) && !is.null(pkg$name)) {
        # Already proper format
        list(
          name = as.character(pkg$name),
          auto_attach = if (is.null(pkg$auto_attach)) FALSE else isTRUE(pkg$auto_attach)
        )
      } else {
        # Skip arrays, malformed entries, etc.
        NULL
      }
    })
    # Filter out NULLs
    Filter(Negate(is.null), result)
  } else {
    list()
  }

  defaults$directories <- project_types$project$directories %||% list()

  defaults$env <- defaults$env %||% list(
    raw = paste(env_default_template_lines(), collapse = "\n")
  )

  defaults$connections <- defaults$connections %||% .default_connections_configuration()

  git_defaults <- catalog$git %||% list()
  privacy_defaults <- catalog$privacy %||% list()

  list(
    projects_root = path.expand(catalog$global$projects_root %||% "~/framework-projects"),
    project_types = project_types,
    author = list(
      name = .catalog_field_default(catalog, "author.name", "Your Name"),
      email = .catalog_field_default(catalog, "author.email", "your.email@example.com"),
      affiliation = .catalog_field_default(catalog, "author.affiliation", "Your Institution")
    ),
    defaults = defaults,
    git = list(
      user_name = {
        value <- git_defaults$user_name %||% NULL
        if (is.character(value) && identical(value, "")) NULL else value
      },
      user_email = {
        value <- git_defaults$user_email %||% NULL
        if (is.character(value) && identical(value, "")) NULL else value
      }
    ),
    privacy = list(
      secret_scan = if (is.null(privacy_defaults$secret_scan)) FALSE else isTRUE(privacy_defaults$secret_scan),
      gitignore_template = privacy_defaults$gitignore_template %||% "gitignore"
    ),
    projects = list()
  )
}

#' Read global Framework configuration
#'
#' @param use_defaults Whether to merge with default structure (default: TRUE)
#' @return List containing global configuration
#' @export
#' @keywords internal
read_frameworkrc <- function(use_defaults = TRUE) {
  # New YAML path (preferred)
  config_dir <- path.expand("~/.config/framework")
  new_settings_path <- file.path(config_dir, "settings.yml")
  new_projects_path <- file.path(config_dir, "projects.yml")

  # Legacy paths (for migration)
  legacy_config_path <- file.path(config_dir, "config.yml")  # Old YAML naming
  legacy_json_path <- path.expand("~/.frameworkrc.json")     # Very old JSON

  # Try new YAML settings first
  if (file.exists(new_settings_path)) {
    config <- tryCatch({
      yaml::read_yaml(new_settings_path)
    }, error = function(e) {
      warning("Failed to read ", new_settings_path, ": ", e$message)
      if (use_defaults) {
        get_default_global_config()
      } else {
        list(projects = list(), active_project = NULL)
      }
    })

    # Read projects from separate file
    if (file.exists(new_projects_path)) {
      projects_data <- tryCatch({
        yaml::read_yaml(new_projects_path)
      }, error = function(e) {
        warning("Failed to read ", new_projects_path, ": ", e$message)
        list(projects = list())
      })
      config$projects <- projects_data$projects %||% list()
    }

  } else if (file.exists(legacy_config_path)) {
    # Migrate from old config.yml naming
    message("Migrating from config.yml to settings.yml...")
    config <- tryCatch({
      yaml::read_yaml(legacy_config_path)
    }, error = function(e) {
      warning("Failed to read legacy config.yml: ", e$message)
      if (use_defaults) {
        get_default_global_config()
      } else {
        list(projects = list(), active_project = NULL)
      }
    })

    # Write to new naming
    write_frameworkrc(config)
    file.remove(legacy_config_path)  # Clean up old file

  } else if (file.exists(legacy_json_path)) {
    # Migrate from legacy JSON format
    message("Migrating from .frameworkrc.json to settings.yml...")
    config <- tryCatch({
      jsonlite::fromJSON(legacy_json_path, simplifyVector = FALSE)
    }, error = function(e) {
      warning("Failed to read legacy JSON config: ", e$message)
      if (use_defaults) {
        get_default_global_config()
      } else {
        list(projects = list(), active_project = NULL)
      }
    })

    # Write to new YAML format
    if (!dir.exists(config_dir)) {
      dir.create(config_dir, recursive = TRUE)
    }
    write_frameworkrc(config)

  } else {
    # No config exists, initialize with defaults
    message("No Framework settings found. Initializing...")
    init_global_config()

    # Read the newly created settings
    if (file.exists(new_settings_path)) {
      config <- yaml::read_yaml(new_settings_path)
    } else if (use_defaults) {
      config <- get_default_global_config()
    } else {
      config <- list(projects = list(), active_project = NULL)
    }
  }

  # Merge with defaults if requested
  if (use_defaults) {
    defaults <- get_default_global_config()
    # Only merge defaults into missing keys, don't override existing values
    for (key in names(defaults)) {
      if (!(key %in% names(config))) {
        config[[key]] <- defaults[[key]]
      } else if (key == "defaults" && is.list(config[[key]])) {
        config[[key]] <- modifyList(defaults[[key]], config[[key]], keep.null = TRUE)
      } else if (key == "project_types" && is.list(config[[key]])) {
        config[[key]] <- modifyList(defaults[[key]], config[[key]], keep.null = TRUE)
      }
    }

    # Backfill defaults.directories from project type when missing
    if (is.null(config$defaults$directories) && !is.null(config$project_types$project$directories)) {
      config$defaults$directories <- config$project_types$project$directories
    }
  }

  return(config)
}

#' Write global Framework configuration
#'
#' @param config List containing configuration to write
#' @return Invisibly returns NULL
#' @export
#' @keywords internal
write_frameworkrc <- function(config) {
  config_dir <- path.expand("~/.config/framework")
  settings_path <- file.path(config_dir, "settings.yml")
  projects_path <- file.path(config_dir, "projects.yml")

  # Create directory if needed
  if (!dir.exists(config_dir)) {
    dir.create(config_dir, recursive = TRUE)
  }

  # Split out projects into separate file
  projects <- config$projects
  config$projects <- NULL

  # Fix packages structure - ensure default_packages array doesn't have names
  if (!is.null(config$defaults$packages$default_packages)) {
    # Ensure default_packages is an unnamed array
    if (is.list(config$defaults$packages$default_packages) && !is.null(names(config$defaults$packages$default_packages))) {
      config$defaults$packages$default_packages <- unname(config$defaults$packages$default_packages)
    }
  }

  # Fix extra_directories arrays for all project types
  if (!is.null(config$project_types)) {
    for (type_name in names(config$project_types)) {
      if (!is.null(config$project_types[[type_name]]$extra_directories)) {
        extra_dirs <- config$project_types[[type_name]]$extra_directories

        # If it's a named list (object), it means JSON gave us an object instead of array
        # Convert to unnamed list (array) while preserving the structure of each item
        if (is.list(extra_dirs) && !is.null(names(extra_dirs)) && any(names(extra_dirs) != "")) {
          # Strip outer names but keep each item as-is
          config$project_types[[type_name]]$extra_directories <- unname(extra_dirs)
        }
      }
    }
  }

  # Write main settings
  yaml::write_yaml(config, settings_path)

  # Write projects separately
  yaml::write_yaml(list(projects = projects %||% list()), projects_path)

  invisible(NULL)
}

#' Add project to global configuration
#'
#' @param project_dir Path to project directory
#' @param project_name Optional project name
#' @param project_type Optional project type
#' @return Invisibly returns NULL
#' @export
#' @keywords internal
add_project_to_config <- function(project_dir, project_name = NULL, project_type = NULL) {
  config <- read_frameworkrc()

  # Check if project already exists
  normalized_path <- normalizePath(project_dir, mustWork = FALSE)
  if (!is.null(config$projects) && length(config$projects) > 0) {
    existing_paths <- sapply(config$projects, function(p) p$path)
    if (normalized_path %in% existing_paths) {
      message("Project already in registry")
      return(invisible(NULL))
    }
  }

  # Generate next ID
  if (is.null(config$projects) || length(config$projects) == 0) {
    next_id <- 1
  } else {
    existing_ids <- sapply(config$projects, function(p) p$id %||% 0)
    next_id <- max(existing_ids) + 1
  }

  new_project <- list(
    id = next_id,
    path = normalized_path,
    created = format(Sys.Date(), "%Y-%m-%d")
  )
  # Metadata will be read from settings.yml when needed

  # Add new project
  if (is.null(config$projects)) {
    config$projects <- list()
  }
  config$projects <- c(config$projects, list(new_project))

  write_frameworkrc(config)
  invisible(next_id)
}
