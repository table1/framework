#' Get default global configuration structure
#'
#' @return List with default global configuration
#' @export
#' @keywords internal
get_default_global_config <- function() {
  list(
    author = list(
      name = "Your Name",
      email = "your.email@example.com",
      affiliation = "Your Institution"
    ),
    defaults = list(
      project_type = "project",
      notebook_format = "quarto",
      ide = "vscode",
      use_git = TRUE,
      use_renv = FALSE,
      seed = NULL,
      seed_on_scaffold = TRUE,
      ai_support = TRUE,
      ai_assistants = list("claude", "agents"),
      ai_canonical_file = "CLAUDE.md",
      packages = list(
        list(name = "dplyr", auto_attach = TRUE),
        list(name = "tidyr", auto_attach = TRUE),
        list(name = "ggplot2", auto_attach = TRUE),
        list(name = "readr", auto_attach = FALSE)
      ),
      directories = list(
        notebooks = "notebooks",
        scripts = "scripts",
        functions = "functions",
        inputs_raw = "inputs/raw",
        inputs_intermediate = "inputs/intermediate",
        inputs_final = "inputs/final",
        inputs_reference = "inputs/reference",
        outputs_private = "outputs/private",
        outputs_public = "outputs/public",
        cache = "outputs/private/cache",
        scratch = "outputs/private/scratch"
      ),
      git_hooks = list(
        ai_sync = FALSE,
        data_security = FALSE
      )
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
  rc_path <- path.expand("~/.frameworkrc.json")

  if (file.exists(rc_path)) {
    config <- tryCatch({
      jsonlite::fromJSON(rc_path, simplifyVector = FALSE)
    }, error = function(e) {
      if (use_defaults) {
        get_default_global_config()
      } else {
        list(projects = list(), active_project = NULL)
      }
    })

    # Merge with defaults if requested
    if (use_defaults) {
      defaults <- get_default_global_config()
      # Only merge defaults into missing keys, don't override existing values
      for (key in names(defaults)) {
        if (!(key %in% names(config))) {
          config[[key]] <- defaults[[key]]
        } else if (key == "defaults" && is.list(config[[key]])) {
          # Merge defaults.* keys
          config[[key]] <- modifyList(defaults[[key]], config[[key]], keep.null = TRUE)
        }
      }
    }

    return(config)
  } else {
    if (use_defaults) {
      return(get_default_global_config())
    } else {
      return(list(projects = list(), active_project = NULL))
    }
  }
}

#' Write global Framework configuration
#'
#' @param config List containing configuration to write
#' @return Invisibly returns NULL
#' @export
#' @keywords internal
write_frameworkrc <- function(config) {
  rc_path <- path.expand("~/.frameworkrc.json")
  jsonlite::write_json(config, rc_path,
                       pretty = TRUE,
                       auto_unbox = TRUE,
                       null = "null")
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
