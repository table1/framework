# Settings catalog helpers ---------------------------------------------------

#' Get the path to the packaged settings catalog YAML
#' @keywords internal
.framework_catalog_default_path <- function() {
  system.file("config", "settings-catalog.yml", package = "framework", mustWork = TRUE)
}

#' Get the path to the user-editable settings catalog override
#' @keywords internal
.framework_catalog_user_path <- function() {
  file.path(.framework_config_dir(), "settings-catalog.yml")
}

#' Read the Framework settings catalog
#'
#' The catalog defines metadata (labels, hints) and default values for settings
#' sections. Users can override the packaged defaults by placing a
#' `settings-catalog.yml` file in their Framework config directory
#' (`tools::R_user_dir("framework", "config")`). When an override exists it is
#' merged on top of the packaged catalog.
#'
#' @param include_user Logical indicating whether to merge user overrides.
#'   Defaults to `TRUE`.
#' @param validate Logical indicating whether to perform basic validation on
#'   the catalog structure. Defaults to `TRUE`.
#'
#' @return A nested list representing the settings catalog.
#' @export
load_settings_catalog <- function(include_user = TRUE, validate = TRUE) {
  default_path <- .framework_catalog_default_path()
  catalog <- yaml::read_yaml(default_path)

  if (include_user) {
    user_path <- .framework_catalog_user_path()
    if (file.exists(user_path)) {
      user_catalog <- tryCatch(
        yaml::read_yaml(user_path),
        error = function(err) {
          warning(sprintf("Failed to read user settings catalog (%s): %s", user_path, err$message))
          NULL
        }
      )

      if (is.list(user_catalog)) {
        catalog <- stats::modifyList(catalog, user_catalog, keep.null = TRUE)
      }
    }
  }

  if (validate) {
    .validate_settings_catalog(catalog)
  }

  catalog
}

#' Basic validation for the settings catalog structure
#' @keywords internal
.validate_settings_catalog <- function(catalog) {
  if (!is.list(catalog)) {
    stop("Settings catalog must be a list structure", call. = FALSE)
  }

  # Check for v2 structure
  if ("meta" %in% names(catalog) && !is.null(catalog$meta$version) && catalog$meta$version >= 2) {
    # v2 validation: requires defaults, author, project_types
    if (!"defaults" %in% names(catalog)) {
      stop("Settings catalog v2 missing 'defaults' entry", call. = FALSE)
    }
    if (!"author" %in% names(catalog)) {
      stop("Settings catalog v2 missing 'author' entry", call. = FALSE)
    }
    if (!"project_types" %in% names(catalog)) {
      stop("Settings catalog v2 missing 'project_types' entry", call. = FALSE)
    }
  } else {
    # v1 validation: requires sections
    if (!"sections" %in% names(catalog)) {
      stop("Settings catalog missing 'sections' entry", call. = FALSE)
    }
    if (!"project_types" %in% names(catalog)) {
      stop("Settings catalog missing 'project_types' entry", call. = FALSE)
    }
  }

  invisible(TRUE)
}

#' Convenience accessor for catalog field definitions
#' @keywords internal
.catalog_find_field <- function(catalog, field_id) {
  if (is.null(catalog$sections)) return(NULL)

  for (section in catalog$sections) {
    fields <- section$fields
    if (is.null(fields)) next
    for (field in fields) {
      if (identical(field$id, field_id)) {
        return(field)
      }
    }
  }

  NULL
}

#' Retrieve a default value from the catalog, falling back when missing
#' @keywords internal
.catalog_field_default <- function(catalog, field_id, fallback = NULL) {
  field <- .catalog_find_field(catalog, field_id)
  if (!is.null(field) && !is.null(field$default)) {
    field$default
  } else {
    fallback
  }
}

#' Convert catalog project type metadata into default configuration values
#' @keywords internal
.catalog_project_type_defaults <- function(project_types) {
  if (is.null(project_types) || !is.list(project_types)) {
    return(list())
  }

  lapply(project_types, function(type) {
    directories <- lapply(type$directories %||% list(), function(entry) {
      entry$default %||% ""
    })

    quarto_render <- type$quarto$render_dir$default %||% "."

    optional_toggles <- lapply(type$optional_toggles %||% list(), function(toggle) {
      list(
        label = toggle$label %||% NULL,
        directory_key = toggle$directory_key %||% NULL,
        default_path = toggle$default_path %||% NULL,
        default = if (is.null(toggle$default)) FALSE else isTRUE(toggle$default)
      )
    })

    list(
      label = type$label %||% NULL,
      description = type$description %||% NULL,
      directories = directories,
      quarto = list(render_dir = quarto_render),
      notebook_template = type$notebook_template$default %||% "notebook",
      optional_toggles = optional_toggles
    )
  })
}
