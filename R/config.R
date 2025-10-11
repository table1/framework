#' Get configuration value by dot-notation key
#'
#' Laravel-style configuration helper that supports both flat and hierarchical
#' key access using dot notation. Automatically checks common locations for
#' directory settings.
#'
#' @param key Character. Dot-notation key path (e.g., "notebooks" or
#'   "directories.notebooks" or "connections.db.host")
#' @param default Optional default value if key is not found
#' @param config_file Configuration file path (default: "config.yml")
#'
#' @return The configuration value, or default if not found
#'
#' @details
#' For directory settings, the function checks multiple locations:
#' - Direct: `config("notebooks")` checks `directories$notebooks`, then `options$notebook_dir`
#' - Explicit: `config("directories.notebooks")` checks only `directories$notebooks`
#'
#' @examples
#' \dontrun{
#' # Get notebook directory (checks both locations)
#' config("notebooks")
#'
#' # Get explicit nested setting
#' config("directories.notebooks")
#' config("connections.db.host")
#'
#' # With default value
#' config("missing_key", default = "fallback")
#' }
#'
#' @export
config <- function(key, default = NULL, config_file = "config.yml") {
  # Read full config
  cfg <- read_config(config_file)

  # Split key by dots
  parts <- strsplit(key, "\\.")[[1]]

  # For single-part keys, try smart directory lookups
  if (length(parts) == 1) {
    # Check directories first
    if (!is.null(cfg$directories[[key]])) {
      return(cfg$directories[[key]])
    }
    # Check options for legacy keys
    legacy_key <- paste0(key, "_dir")
    if (!is.null(cfg$options[[legacy_key]])) {
      return(cfg$options[[legacy_key]])
    }
  }

  # Navigate through config hierarchy
  value <- cfg
  for (part in parts) {
    if (is.list(value) && part %in% names(value)) {
      value <- value[[part]]
    } else {
      # Key not found - return default
      return(default)
    }
  }

  value
}


#' Read project configuration
#'
#' Reads the project configuration from config.yml with environment-aware merging
#' and split file resolution.
#'
#' @param config_file Path to configuration file (default: "config.yml")
#' @param environment Active environment name (default: R_CONFIG_ACTIVE or "default")
#'
#' @return The configuration as a list
#' @export
read_config <- function(config_file = "config.yml", environment = NULL) {
  # Validate arguments
  checkmate::assert_string(config_file, min.chars = 1)
  checkmate::assert_string(environment, null.ok = TRUE)

  # Check file exists
  if (!file.exists(config_file)) {
    stop(sprintf("Config file not found: %s", config_file))
  }

  # Detect active environment
  active_env <- environment %||%
    Sys.getenv("R_CONFIG_ACTIVE", Sys.getenv("R_CONFIG_NAME", "default"))

  # Read raw YAML
  raw_config <- tryCatch(
    .safe_read_yaml(config_file),
    error = function(e) {
      stop(sprintf("Failed to parse config file '%s': %s", config_file, e$message))
    }
  )

  # Check if file has environment sections
  has_envs <- .has_environment_sections(raw_config)

  if (!has_envs) {
    # Flat file - treat entire content as default environment
    config <- raw_config
  } else {
    # Environment-scoped file
    if (!"default" %in% names(raw_config)) {
      stop(sprintf("Config file '%s' has environment sections but no 'default' environment", config_file))
    }

    # Start with default environment
    config <- raw_config$default

    # Merge active environment if different
    if (active_env != "default") {
      if (active_env %in% names(raw_config)) {
        config <- modifyList(config, raw_config[[active_env]])
      } else {
        warning(sprintf("Environment '%s' not found in config, using 'default'", active_env))
      }
    }
  }

  # Resolve split file references recursively
  config <- .resolve_split_files(config, active_env, config_file, character())

  # Initialize standard sections AFTER split file resolution (if still missing)
  for (section in c("data", "connections", "git", "security", "packages", "directories")) {
    if (is.null(config[[section]])) {
      config[[section]] <- list()
    }
  }

  # Initialize options if not present
  if (is.null(config$options)) {
    config$options <- list()
  }

  # Evaluate !expr expressions
  config <- .eval_expressions(config)

  config
}


# Helper: Check if config has environment sections
.has_environment_sections <- function(config) {
  if (!is.list(config) || length(config) == 0) {
    return(FALSE)
  }

  # Check if top-level keys look like environment names
  # Common environment names: default, production, development, test, staging
  env_keywords <- c("default", "production", "development", "test", "testing", "staging")
  top_keys <- names(config)

  # If we have a 'default' key, assume environment sections
  if ("default" %in% top_keys) {
    return(TRUE)
  }

  # Otherwise, check if keys match common environment names
  matches <- sum(top_keys %in% env_keywords)
  return(matches > 0)
}


# Helper: Resolve split file references recursively
.resolve_split_files <- function(config, environment, parent_file, visited_files, config_root = NULL, main_config_keys = NULL) {
  # Track which keys are file references
  file_refs <- character()

  # First call: set config_root to parent file's directory and remember main config keys
  if (is.null(config_root)) {
    config_root <- dirname(parent_file)
    main_config_keys <- names(config)
  }

  for (key in names(config)) {
    value <- config[[key]]

    # Check if value looks like a file reference
    if (is.character(value) && length(value) == 1 && grepl("\\.ya?ml$", value, ignore.case = TRUE)) {
      file_refs <- c(file_refs, key)

      # Resolve file path relative to config root (not parent file!)
      file_path <- .resolve_file_path(value, config_root)

      # Normalize path for circular reference check
      file_path_norm <- normalizePath(file_path, mustWork = FALSE)

      # Check if file exists
      if (!file.exists(file_path_norm)) {
        stop(sprintf("%s not found (referenced from %s)", value, basename(parent_file)))
      }

      # Circular reference check
      if (file_path_norm %in% visited_files) {
        stop(sprintf("Circular reference detected: %s", paste(c(visited_files, file_path_norm), collapse = " -> ")))
      }

      # Read raw split file
      raw_split <- tryCatch(
        .safe_read_yaml(file_path_norm),
        error = function(e) {
          stop(sprintf("Failed to parse split file '%s': %s", value, e$message))
        }
      )

      # Check if split file has environment sections
      has_envs <- .has_environment_sections(raw_split)

      if (!has_envs) {
        # Flat split file - use as-is
        split_config <- raw_split
      } else {
        # Environment-scoped split file
        if (!"default" %in% names(raw_split)) {
          stop(sprintf("Split file '%s' has environment sections but no 'default' environment", value))
        }

        # Merge environments (same logic as main config)
        split_config <- raw_split$default
        if (environment != "default" && environment %in% names(raw_split)) {
          split_config <- modifyList(split_config, raw_split[[environment]])
        }
      }

      # Recursively resolve nested split files (preserve config_root and main_config_keys)
      split_config <- .resolve_split_files(split_config, environment, file_path_norm, c(visited_files, file_path_norm), config_root, main_config_keys)

      # Evaluate !expr in split file
      split_config <- .eval_expressions(split_config)

      # Merge split file contents into main config
      # Main file wins for conflicts
      for (split_key in names(split_config)) {
        if (split_key == key) {
          # This is the section key (e.g., 'connections' in connections.yml)
          # Replace the file reference with the actual data
          config[[split_key]] <- split_config[[split_key]]
        } else if (split_key %in% names(config)) {
          if (split_key %in% file_refs) {
            # This key is another file reference, not a conflict - skip
            next
          } else {
            # Conflict: key already exists (either from main config or previous split file)
            # Check if it's a simple value (not a file ref string)
            is_real_value <- !is.character(config[[split_key]]) ||
                            length(config[[split_key]]) != 1 ||
                            !grepl("\\.ya?ml$", config[[split_key]], ignore.case = TRUE)

            if (is_real_value) {
              # Key was already defined - check if it came from main config
              if (split_key %in% main_config_keys) {
                # Conflict with main config
                warning(sprintf(
                  "Key '%s' defined in both main config and '%s'. Using value from main config.",
                  split_key,
                  value
                ))
              } else {
                # Conflict with another split file
                warning(sprintf(
                  "Key '%s' already defined, ignoring value from '%s'",
                  split_key,
                  value
                ))
              }
            } else {
              # This is a file reference that will be processed later, not a conflict
              config[[split_key]] <- split_config[[split_key]]
            }
          }
        } else {
          # No conflict - merge from split
          config[[split_key]] <- split_config[[split_key]]
        }
      }

      # Note: No need to remove file reference - if split_key == key, we already replaced it above
      # If split_key != key (split file has different top-level keys), the reference stays as a string
      # which is harmless
    }
  }

  config
}


# Helper: Resolve file path relative to config root directory
.resolve_file_path <- function(file_path, config_root_dir) {
  # If absolute, return as-is
  if (grepl("^/", file_path) || grepl("^[A-Za-z]:", file_path)) {
    return(file_path)
  }

  # Relative path - resolve relative to config root directory
  file.path(config_root_dir, file_path)
}


# Helper: Evaluate !expr expressions and env() calls
.eval_expressions <- function(x) {
  if (is.list(x)) {
    # Recursively process lists - preserve names!
    result <- lapply(x, .eval_expressions)
    names(result) <- names(x)
    result
  } else if (is.character(x) && length(x) == 1) {
    # Check for !expr marker
    if (grepl("^!expr\\s+", x)) {
      expr_string <- sub("^!expr\\s+", "", x)

      # Evaluate in controlled environment
      # WARNING: This evaluates arbitrary R code - only use trusted configs!
      tryCatch(
        eval(parse(text = expr_string), envir = new.env(parent = baseenv())),
        error = function(e) {
          stop(sprintf("Failed to evaluate expression '%s': %s", expr_string, e$message))
        }
      )
    } else if (grepl("^env\\(.*\\)$", x)) {
      # Handle env() syntax - cleaner alternative to !expr Sys.getenv()
      # Extract arguments: env("VAR") or env("VAR", "default")
      env_args <- gsub("^env\\(\"(.*?)\"(?:,\\s*\"(.*?)\")?\\)$", "\\1,\\2", x)
      env_args <- strsplit(env_args, ",")[[1]]
      env_args <- trimws(env_args)

      # Get environment variable with optional default
      if (length(env_args) == 2 && env_args[2] != "") {
        Sys.getenv(env_args[1], env_args[2])
      } else {
        Sys.getenv(env_args[1])
      }
    } else {
      x
    }
  } else {
    x
  }
}

# Helper function to process package configurations
#
# Ensures consistent format for package configurations by converting simple strings
# to named lists with default values. For example:
#
# Input:  list("dplyr", list(name = "readr", attached = FALSE))
# Output: list(list(name = "dplyr", attached = FALSE),
#             list(name = "readr", attached = FALSE))
#
# @param packages List of package configurations, where each item is either:
#   - A character string (package name)
#   - A list with 'name' and optional 'attached' fields
# @return List of package configurations, all in list format with 'name' and 'attached' fields
.process_packages <- function(packages) {
  if (is.null(packages)) {
    return(NULL)
  }

  # Convert simple strings to named lists
  lapply(packages, function(pkg) {
    if (is.character(pkg) && !is.list(pkg)) {
      list(name = pkg, attached = FALSE)
    } else {
      pkg
    }
  })
}

# Helper function to safely read YAML files
#
# Reads a YAML file while suppressing the "incomplete final line" warning
# as long as the YAML is valid. Preserves !expr tags as strings for later evaluation.
#
# @param file Path to YAML file
# @return Parsed YAML content
.safe_read_yaml <- function(file) {
  # Read file content with warnings suppressed
  content <- readLines(file, warn = FALSE)
  # Parse YAML - handlers preserve !expr as strings for later evaluation
  yaml::yaml.load(
    paste(content, collapse = "\n"),
    handlers = list(
      expr = function(x) paste0("!expr ", x)
    )
  )
}

#' Write project configuration
#'
#' Writes the project configuration to config.yml or settings files
#' @param config The configuration list to write
#' @param config_file The configuration file path (default: "config.yml")
#' @param section Optional section to update (e.g. "data")
#' @export
write_config <- function(config, config_file = "config.yml", section = NULL) {
  # Validate arguments
  checkmate::assert_list(config)
  checkmate::assert_string(config_file, min.chars = 1)
  checkmate::assert_string(section, min.chars = 1, null.ok = TRUE)

  if (!is.null(section)) {

    # Check if config file exists
    if (!file.exists(config_file)) {
      stop(sprintf("Configuration file '%s' does not exist. Use write_config(config) to create it first.", config_file))
    }

    # Read current config
    current <- tryCatch(
      yaml::read_yaml(config_file),
      error = function(e) {
        stop(sprintf("Failed to read configuration file '%s': %s", config_file, e$message))
      }
    )

    # Get current environment from R_CONFIG_ACTIVE or default
    env <- Sys.getenv("R_CONFIG_ACTIVE", Sys.getenv("R_CONFIG_NAME", "default"))

    # Check if this section uses a settings file
    if (is.character(current[[env]][[section]]) && grepl("^settings/", current[[env]][[section]])) {
      # This is a settings file, update that instead
      settings_file <- current[[env]][[section]]
      if (file.exists(settings_file)) {
        # Read current settings
        settings <- tryCatch(
          yaml::read_yaml(settings_file),
          error = function(e) {
            stop(sprintf("Failed to read settings file '%s': %s", settings_file, e$message))
          }
        )
        # Update with new values
        settings <- modifyList(settings, config)
        # Write back to settings file
        tryCatch(
          yaml::write_yaml(settings, settings_file),
          error = function(e) {
            stop(sprintf("Failed to write settings file '%s': %s", settings_file, e$message))
          }
        )
      } else {
        stop(sprintf("Settings file '%s' does not exist", settings_file))
      }
    } else {
      # This is a direct section in config.yml
      current[[env]][[section]] <- config
      tryCatch(
        yaml::write_yaml(current, config_file),
        error = function(e) {
          stop(sprintf("Failed to write configuration file '%s': %s", config_file, e$message))
        }
      )
    }
  } else {
    # Writing entire config - wrap in "default" section if not already wrapped
    if (!"default" %in% names(config)) {
      config <- list(default = config)
    }

    tryCatch(
      yaml::write_yaml(config, config_file),
      error = function(e) {
        stop(sprintf("Failed to write configuration file '%s': %s", config_file, e$message))
      }
    )
  }

  invisible(NULL)
}
