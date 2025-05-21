#' Read project configuration
#'
#' Reads the project configuration from config.yml, evaluating any expressions.
#' @return The configuration as a list
#' @export
read_config <- function(config_file = "config.yml") {
  # Load skeleton config first
  skeleton_path <- system.file("R", "config_skeleton.yml", package = "framework")
  skeleton <- yaml::read_yaml(skeleton_path)

  # Load user config with config::get() to handle !expr
  user_config <- config::get(config = config_file)

  # Function to evaluate env() calls
  eval_env <- function(x) {
    if (is.character(x)) {
      # Handle vectors of character strings
      if (length(x) > 1) {
        lapply(x, eval_env)
      } else if (grepl("^env\\(.*\\)$", x)) {
        # Extract arguments from env() call
        env_args <- gsub("^env\\(\"(.*)\"(?:,\\s*\"(.*)\")?\\)$", "\\1,\\2", x)
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
    } else if (is.list(x)) {
      lapply(x, eval_env)
    } else {
      x
    }
  }

  # Function to process settings files
  process_settings <- function(x) {
    if (is.list(x)) {
      lapply(x, process_settings)
    } else if (is.character(x)) {
      # Handle vectors of character strings
      if (length(x) > 1) {
        lapply(x, process_settings)
      } else if (grepl("^settings/", x)) {
        if (file.exists(x)) {
          suppressWarnings(yaml::read_yaml(x, eval.expr = TRUE))
        } else {
          warning(sprintf("Settings file not found: %s", x))
          x
        }
      } else {
        x
      }
    } else {
      x
    }
  }

  # Function to merge config with skeleton
  merge_with_skeleton <- function(config, skeleton) {
    # Start with skeleton as base
    result <- skeleton

    # Initialize options if not present
    if (is.null(result$options)) {
      result$options <- list()
    }

    # For each section in config
    for (section in names(config)) {
      if (section == "options") {
        # Handle options specially - merge with user options
        result$options <- modifyList(result$options, config$options)
      } else if (section %in% names(skeleton)) {
        # This is a top-level skeleton section
        if (is.character(config[[section]]) && grepl("^settings/", config[[section]])) {
          # This is a settings file reference
          settings_file <- config[[section]]
          if (file.exists(settings_file)) {
            # Load settings and merge with skeleton
            settings <- yaml::read_yaml(settings_file)
            result[[section]] <- modifyList(skeleton[[section]], settings)
          }
        } else if (!is.null(config[[section]])) {
          # Direct config, merge with skeleton
          if (is.list(skeleton[[section]]) && is.list(config[[section]])) {
            result[[section]] <- modifyList(skeleton[[section]], config[[section]])
          } else {
            # If either is not a list, use the user's value
            result[[section]] <- config[[section]]
          }
        }
      } else {
        # This is not a top-level skeleton section, move to options
        result$options[[section]] <- config[[section]]
      }
    }

    result
  }

  # Process settings files first
  user_config <- process_settings(user_config)
  skeleton <- process_settings(skeleton)

  # Merge user config with skeleton
  config <- merge_with_skeleton(user_config, skeleton)

  # Evaluate env() calls
  eval_env(config)
}

#' Write project configuration
#'
#' Writes the project configuration to config.yml or settings files
#' @param config The configuration list to write
#' @param section Optional section to update (e.g. "data")
#' @export
write_config <- function(config, section = NULL) {
  if (!is.null(section)) {
    # Read current config
    current <- yaml::read_yaml("config.yml")

    # Get current environment from config::get()
    env <- config::get("config")$environment

    # Check if this section uses a settings file
    if (is.character(current[[env]][[section]]) && grepl("^settings/", current[[env]][[section]])) {
      # This is a settings file, update that instead
      settings_file <- current[[env]][[section]]
      if (file.exists(settings_file)) {
        # Read current settings
        settings <- yaml::read_yaml(settings_file)
        # Update with new values
        settings <- modifyList(settings, config)
        # Write back to settings file
        yaml::write_yaml(settings, settings_file)
      }
    } else {
      # This is a direct section in config.yml
      current[[env]][[section]] <- config
      yaml::write_yaml(current, "config.yml")
    }
  } else {
    # Writing entire config
    yaml::write_yaml(config, "config.yml")
  }
}
