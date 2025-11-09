# Settings migration helpers -------------------------------------------------

#' Migrate settings from v1 to v2 structure
#'
#' Converts old settings catalog structure (with sections) to new v2 structure
#' organized around scaffold() workflow.
#'
#' @param settings_v1 List containing v1 settings structure
#' @return List containing v2 settings structure
#' @keywords internal
.migrate_settings_v1_to_v2 <- function(settings_v1) {
  # Initialize v2 structure
  settings_v2 <- list(
    meta = list(
      version = 2,
      description = "Framework settings - migrated from v1"
    )
  )

  # Migrate author information (if exists)
  if (!is.null(settings_v1$author)) {
    settings_v2$author <- settings_v1$author
  } else {
    settings_v2$author <- list(
      name = "Your Name",
      email = "your.email@example.com",
      affiliation = "Your Institution"
    )
  }

  # Migrate global settings
  settings_v2$global <- list(
    projects_root = settings_v1$global$projects_root %||% "~/projects"
  )

  # Initialize defaults structure
  settings_v2$defaults <- list()

  # Migrate project_type
  settings_v2$defaults$project_type <- settings_v1$defaults$project_type %||% "project"

  # Migrate scaffold behavior (extract from old sections)
  settings_v2$defaults$scaffold <- list(
    seed_on_scaffold = settings_v1$scaffold$seed_on_scaffold %||% FALSE,
    seed = settings_v1$scaffold$seed %||% "",
    set_theme_on_scaffold = settings_v1$scaffold$set_theme_on_scaffold %||% TRUE,
    ggplot_theme = settings_v1$scaffold$ggplot_theme %||% "theme_minimal",
    notebook_format = settings_v1$notebook_format %||% "quarto",
    ide = settings_v1$ide %||% "vscode"
  )

  # Migrate packages
  settings_v2$defaults$packages <- list(
    use_renv = settings_v1$packages$use_renv %||% FALSE,
    default_packages = settings_v1$packages$default_packages %||% list(
      list(name = "dplyr", auto_attach = TRUE),
      list(name = "ggplot2", auto_attach = TRUE),
      list(name = "readr", auto_attach = FALSE)
    )
  )

  # Migrate AI settings
  settings_v2$defaults$ai <- list(
    enabled = settings_v1$ai$enabled %||% TRUE,
    canonical_file = settings_v1$ai$canonical_file %||% "CLAUDE.md",
    preferred_assistant = settings_v1$ai$preferred_assistant %||% "claude",
    assistants = settings_v1$ai$assistants %||% list("claude")
  )

  # Migrate git settings
  settings_v2$defaults$git <- list(
    initialize = settings_v1$git$initialize %||% TRUE,
    gitignore_template = settings_v1$git$gitignore_template %||% "gitignore-project",
    hooks = list(
      ai_sync = settings_v1$git$hooks$ai_sync %||% FALSE,
      data_security = settings_v1$git$hooks$data_security %||% FALSE
    )
  )

  # Migrate templates
  settings_v2$templates <- settings_v1$templates %||% list(
    notebook = list(
      quarto_default = "notebook-default.qmd",
      rmarkdown_default = "notebook-default.Rmd"
    ),
    script = list(
      r_default = "script-default.R"
    ),
    gitignore = list(
      available = list("gitignore-project", "gitignore-sensitive", "gitignore-course", "gitignore-presentation")
    )
  )

  # Migrate project_types (these should remain mostly the same)
  settings_v2$project_types <- settings_v1$project_types %||% list()

  settings_v2
}

#' Check if settings need migration
#'
#' @param settings List containing settings
#' @return Logical indicating whether migration is needed
#' @keywords internal
.settings_need_migration <- function(settings) {
  # Check if meta.version exists and is < 2
  if (is.null(settings$meta$version)) {
    return(TRUE)  # No version = v1
  }

  settings$meta$version < 2
}

#' Migrate user settings file if needed
#'
#' Checks if the user's settings file needs migration from v1 to v2 and
#' performs the migration automatically, creating a backup of the original.
#'
#' @param settings_path Path to user settings file (defaults to user config)
#' @param backup Logical indicating whether to create backup (default TRUE)
#' @return Logical indicating whether migration was performed
#' @export
migrate_user_settings <- function(settings_path = NULL, backup = TRUE) {
  if (is.null(settings_path)) {
    settings_path <- .framework_catalog_user_path()
  }

  # Check if file exists
  if (!file.exists(settings_path)) {
    message("No user settings file found at: ", settings_path)
    return(FALSE)
  }

  # Read current settings
  settings <- tryCatch(
    yaml::read_yaml(settings_path),
    error = function(err) {
      warning("Failed to read settings file: ", err$message)
      return(NULL)
    }
  )

  if (is.null(settings)) {
    return(FALSE)
  }

  # Check if migration needed
  if (!.settings_need_migration(settings)) {
    message("Settings are already v2, no migration needed")
    return(FALSE)
  }

  message("Migrating settings from v1 to v2...")

  # Create backup if requested
  if (backup) {
    backup_path <- paste0(settings_path, ".v1.backup")
    file.copy(settings_path, backup_path, overwrite = TRUE)
    message("Created backup at: ", backup_path)
  }

  # Perform migration
  settings_v2 <- .migrate_settings_v1_to_v2(settings)

  # Write migrated settings
  yaml::write_yaml(settings_v2, settings_path)

  message("Migration complete! Settings updated to v2 structure.")
  message("Review the changes and restart your R session to use the new settings.")

  TRUE
}

#' Auto-migrate settings on package load
#'
#' Called during package initialization to automatically migrate user settings
#' if needed. Runs silently unless migration is actually performed.
#'
#' @keywords internal
.auto_migrate_user_settings <- function() {
  settings_path <- .framework_catalog_user_path()

  if (!file.exists(settings_path)) {
    return(invisible(FALSE))
  }

  settings <- tryCatch(
    yaml::read_yaml(settings_path),
    error = function(err) NULL
  )

  if (is.null(settings) || !.settings_need_migration(settings)) {
    return(invisible(FALSE))
  }

  # Perform migration silently
  backup_path <- paste0(settings_path, ".v1.backup")
  file.copy(settings_path, backup_path, overwrite = TRUE)

  settings_v2 <- .migrate_settings_v1_to_v2(settings)
  yaml::write_yaml(settings_v2, settings_path)

  message("\n=== Framework Settings Migration ===")
  message("Your settings have been automatically migrated from v1 to v2.")
  message("Backup saved to: ", backup_path)
  message("===================================\n")

  invisible(TRUE)
}
