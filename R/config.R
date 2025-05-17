#' Read project configuration
#'
#' Reads the project configuration from config.yml, evaluating any expressions.
#' @return The configuration as a list
#' @export
read_config <- function(config_file = "config.yml") {
  # Load config with config::get() to handle !expr
  config <- config::get(config = config_file)

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

  # Process settings files and evaluate env() calls
  config <- process_settings(config)
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
