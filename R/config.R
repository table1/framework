#' Read project configuration
#'
#' Reads the project configuration from config.yml, evaluating any expressions.
#' @return The configuration as a list
#' @export
read_config <- function(config_file = "config.yml") {
  # Validate arguments
  checkmate::assert_string(config_file, min.chars = 1)

  # 1. Load skeleton config first and set as our base config
  skeleton_path <- system.file("config_skeleton.yml", package = "framework")
  config <- .safe_read_yaml(skeleton_path)

  # Initialize all standard sections
  for (section in c("data", "connections", "git", "security", "packages")) {
    if (is.null(config[[section]])) {
      config[[section]] <- list()
    }
  }

  # Initialize options if not present
  if (is.null(config$options)) {
    config$options <- list()
  }

  # 2. Load user config with config::get() to handle !expr
  user_config <- config::get(file = config_file)

  # Function to evaluate env() calls
  eval_env <- function(x) {
    if (is.character(x)) {
      # Handle vectors of character strings
      if (length(x) > 1) {
        lapply(x, eval_env)
      } else if (grepl("^env\\(.*\\)$", x)) {
        # Extract arguments from env() call
        env_args <- gsub("^env\\(\"(.*?)\"(?:,\\s*\"(.*?)\")?\\)$", "\\1,\\2", x)
        env_args <- strsplit(env_args, ",")[[1]]
        env_args <- trimws(env_args)

        # Get environment variable with optional default
        if (length(env_args) == 2) {
          Sys.getenv(env_args[1], env_args[2])
        } else {
          Sys.getenv(env_args[1])
        }
      } else {
        x
      }
    } else if (is.list(x)) {
      lapply(x, eval_env)
    } else {
      x
    }
  }

  # 3. Handle non-standard sections as options
  for (section in names(user_config)) {
    if (!section %in% c("data", "connections", "git", "security", "packages")) {
      config$options[[section]] <- user_config[[section]]
    }
  }

  # Helper function to merge section data
  .merge_section <- function(config_section, new_data, section_name) {
    if (is.null(new_data)) {
      return(config_section)
    }

    if (section_name == "packages") {
      # Packages are handled specially
      return(new_data)
    } else if (is.list(new_data)) {
      if (length(new_data) > 0 && is.null(names(new_data))) {
        # If it's an unnamed list, convert to named list
        # e.g. [{example: file.csv}] -> {example: file.csv}
        if (length(new_data) == 1 && is.list(new_data[[1]])) {
          return(new_data[[1]])
        }
        return(new_data)
      } else {
        # Otherwise merge with existing config
        return(modifyList(config_section, new_data))
      }
    } else {
      return(new_data)
    }
  }

  # Process each standard section (data, connections, git, security, packages)
  # by either loading from settings file or merging direct YAML
  for (section in c("data", "connections", "git", "packages", "security")) {
    if (!is.null(user_config[[section]])) {
      # Check if this is a settings file reference
      is_settings_file <- is.character(user_config[[section]]) &&
        length(user_config[[section]]) == 1 &&
        grepl("^settings/", user_config[[section]])

      if (is_settings_file) {
        # This is a settings file reference
        settings_file <- user_config[[section]]
        if (file.exists(settings_file)) {
          # Read settings file
          settings <- .safe_read_yaml(settings_file)

          # If the section is not already in the config, create an empty list for it
          if (is.null(config$options[[section]])) {
            config$options[[section]] <- list()
          }

          # If there's an options key, add to the corresponding section in options
          if (!is.null(settings$options)) {
            config$options[[section]] <- modifyList(config$options[[section]], settings$options)
          }

          # If there's a key matching the section name, use that
          if (!is.null(settings[[section]])) {
            config[[section]] <- .merge_section(config[[section]], settings[[section]], section)
          } else {
            # Otherwise use the whole settings file
            config[[section]] <- .merge_section(config[[section]], settings, section)
          }
        } else {
          warning(sprintf("Settings file not found: %s", settings_file))
        }
      } else {
        # Direct YAML, patch into config
        config[[section]] <- .merge_section(config[[section]], user_config[[section]], section)
      }
    }
  }

  # Process packages to ensure consistent format
  config$packages <- .process_packages(config$packages)

  # Evaluate env() calls
  eval_env(config)
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
# as long as the YAML is valid.
#
# @param file Path to YAML file
# @return Parsed YAML content
.safe_read_yaml <- function(file) {
  # Read file content with warnings suppressed
  content <- readLines(file, warn = FALSE)
  # Parse YAML
  yaml::yaml.load(paste(content, collapse = "\n"))
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

    # Get current environment from config::get()
    env <- tryCatch(
      config::get("config")$environment,
      error = function(e) {
        # Default to "default" if config package fails
        "default"
      }
    )

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
