#' Get Framework config directory path
#'
#' Returns the path to Framework's global configuration directory.
#' Uses `tools::R_user_dir("framework", "config")` by default (CRAN compliant).
#' Can be overridden with the `FW_CONFIG_HOME` environment variable.
#'
#' @return Character string with the config directory path
#' @export
fw_config_dir <- function() {
  # Allow override via environment variable

  custom_dir <- Sys.getenv("FW_CONFIG_HOME", "")
  if (nzchar(custom_dir)) {
    return(path.expand(custom_dir))
  }

  # CRAN-compliant default: tools::R_user_dir
  tools::R_user_dir("framework", "config")
}

#' Initialize global Framework settings
#'
#' Creates the Framework config directory (via `fw_config_dir()`) and copies
#' default settings files if they don't already exist. Also handles migration
#' from previous R versions or legacy `~/.config/framework` location.
#'
#' @param force If TRUE, overwrites existing settings (default: FALSE)
#' @return Invisibly returns NULL
#' @keywords internal
init_global_config <- function(force = FALSE) {
  config_dir <- fw_config_dir()
  settings_path <- file.path(config_dir, "settings.yml")
  projects_path <- file.path(config_dir, "projects.yml")

  # Create directory if needed
  if (!dir.exists(config_dir)) {
    dir.create(config_dir, recursive = TRUE)
    message("Created Framework settings directory: ", config_dir)
  }

  # Attempt migration from legacy location (interactive only)
  # Migrate if: no settings file exists, OR settings file looks like stale test data
  needs_migration <- !file.exists(settings_path)
  if (!needs_migration && !force && file.exists(settings_path)) {
    tryCatch({
      existing <- yaml::read_yaml(settings_path)
      # Detect stale test data: author name is placeholder or projects_root points to nonexistent path
      author_name <- existing$author$name %||% ""
      if (author_name %in% c("", "First User", "Test User", "Test Author")) {
        needs_migration <- TRUE
      }
    }, error = function(e) {
      needs_migration <<- TRUE
    })
  }
  if (needs_migration && !force && interactive()) {
    .migrate_config_from_previous(config_dir)
  }

  # Copy default settings if doesn't exist or force is TRUE
  if (!file.exists(settings_path) || force) {
    default_settings <- system.file("settings", "global-settings-default.yml", package = "framework")
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

#' Migrate config from previous R versions or legacy location
#'
#' Checks for configs in legacy ~/.config/framework location
#' and copies them to the current R_user_dir location if found.
#'
#' @param target_dir Target config directory
#' @return TRUE if migration occurred, FALSE otherwise
#' @keywords internal
.migrate_config_from_previous <- function(target_dir) {
  # Check legacy ~/.config/framework (pre-1.0 location)
  legacy_dir <- path.expand("~/.config/framework")
  if (dir.exists(legacy_dir) && file.exists(file.path(legacy_dir, "settings.yml"))) {
    message("Migrating settings from legacy location: ", legacy_dir)
    .copy_config_files(legacy_dir, target_dir, overwrite = TRUE)
    return(TRUE)
  }

  FALSE
}

#' Copy config files between directories
#' @keywords internal
.copy_config_files <- function(from_dir, to_dir, overwrite = FALSE) {
  # Copy config files
  files_to_copy <- c("settings.yml", "projects.yml", "settings-catalog.yml")
  for (f in files_to_copy) {
    src <- file.path(from_dir, f)
    if (file.exists(src)) {
      file.copy(src, file.path(to_dir, f), overwrite = overwrite)
    }
  }

  # Copy templates directory if it exists
  templates_src <- file.path(from_dir, "templates")
  if (dir.exists(templates_src)) {
    templates_dst <- file.path(to_dir, "templates")
    if (!dir.exists(templates_dst)) {
      dir.create(templates_dst, recursive = TRUE)
    }
    template_files <- list.files(templates_src, full.names = TRUE)
    for (tf in template_files) {
      file.copy(tf, templates_dst, overwrite = overwrite)
    }
  }
}

#' Get default global configuration structure
#'
#' @return List with default global configuration
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
  # Handle nested scaffold structure from catalog
  scaffold <- defaults$scaffold %||% list()
  defaults$seed <- scaffold$seed %||% defaults$seed %||% "123"
  if (is.character(defaults$seed) && identical(defaults$seed, "")) {
    defaults$seed <- "123"
  }
  if (!"seed" %in% names(defaults)) {
    defaults["seed"] <- list("123")
  }
  defaults$seed_on_scaffold <- if (!is.null(scaffold$seed_on_scaffold)) {
    isTRUE(scaffold$seed_on_scaffold)
  } else if (!is.null(defaults$seed_on_scaffold)) {
    isTRUE(defaults$seed_on_scaffold)
  } else {
    FALSE
  }
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
    project_types = project_types,
    author = list(
      name = .catalog_field_default(catalog, "author.name", "Your Name"),
      email = .catalog_field_default(catalog, "author.email", "your.email@example.com"),
      affiliation = .catalog_field_default(catalog, "author.affiliation", "Your Institution")
    ),
    defaults = defaults,
    git = {
      result <- list()
      if (!is.null(git_defaults$user_name) && is.character(git_defaults$user_name) && nzchar(git_defaults$user_name)) {
        result$user_name <- git_defaults$user_name
      }
      if (!is.null(git_defaults$user_email) && is.character(git_defaults$user_email) && nzchar(git_defaults$user_email)) {
        result$user_email <- git_defaults$user_email
      }
      # Force to be JSON object instead of array when empty
      if (length(result) == 0) {
        structure(list(), names = character(0))
      } else {
        result
      }
    },
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
read_frameworkrc <- function(use_defaults = TRUE) {
  # Use CRAN-compliant config directory
  config_dir <- fw_config_dir()
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
        # CRITICAL FIX: modifyList() merges nested objects, so deleted directory fields persist.
        # We need to merge project_types, BUT completely replace directories for each type
        # to allow user deletions to override package defaults.

        # Save user's directories BEFORE merge (to preserve deletions)
        user_directories <- list()
        user_extra_directories <- list()
        for (type_name in names(config[[key]])) {
          if (!is.null(config[[key]][[type_name]]$directories)) {
            user_directories[[type_name]] <- config[[key]][[type_name]]$directories
          }
          if (!is.null(config[[key]][[type_name]]$extra_directories)) {
            user_extra_directories[[type_name]] <- config[[key]][[type_name]]$extra_directories
          }
        }

        # Merge with defaults (gets labels, descriptions, etc.)
        config[[key]] <- modifyList(defaults[[key]], config[[key]], keep.null = TRUE)

        # Restore user's directories (completely replace merged defaults)
        for (type_name in names(user_directories)) {
          config[[key]][[type_name]]$directories <- user_directories[[type_name]]
        }
        for (type_name in names(user_extra_directories)) {
          config[[key]][[type_name]]$extra_directories <- user_extra_directories[[type_name]]
        }
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
write_frameworkrc <- function(config) {
  config_dir <- fw_config_dir()
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
#' @param project_dir Path to project directory
#' @param project_name Optional project name
#' @param project_type Optional project type
#' @return Invisibly returns the project ID
#' @export
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

  # Generate next ID (ensure it's an integer)
  if (is.null(config$projects) || length(config$projects) == 0) {
    next_id <- 1L
  } else {
    existing_ids <- sapply(config$projects, function(p) as.integer(p$id %||% 0))
    next_id <- as.integer(max(existing_ids) + 1)
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

#' List all projects in global configuration
#'
#' @return Data frame with project information
#' @export
project_list <- function() {
  config <- read_frameworkrc()

  if (is.null(config$projects) || length(config$projects) == 0) {
    return(data.frame(
      id = integer(0),
      path = character(0),
      created = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Convert to data frame and ensure IDs are integers
  do.call(rbind, lapply(config$projects, function(p) {
    data.frame(
      id = as.integer(p$id),
      path = as.character(p$path),
      created = as.character(p$created %||% ""),
      stringsAsFactors = FALSE
    )
  }))
}

#' Remove project from global configuration
#'
#' @param project_id Project ID to remove
#' @return Invisibly returns NULL
#' @export
remove_project_from_config <- function(project_id) {
  config <- read_frameworkrc()

  # Find project with matching ID
  if (is.null(config$projects) || length(config$projects) == 0) {
    warning("No projects in registry")
    return(invisible(NULL))
  }

  # Convert project_id to integer for comparison (handles floats like 1.0)
  target_id <- as.integer(project_id)

  # Filter out the project with matching ID
  config$projects <- Filter(function(p) {
    as.integer(p$id) != target_id
  }, config$projects)

  # Convert all IDs to integers while we're here (migration)
  config$projects <- lapply(config$projects, function(p) {
    p$id <- as.integer(p$id)
    p
  })

  write_frameworkrc(config)
  invisible(NULL)
}
