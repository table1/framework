#' Create VS Code workspace file
#' @param project_name Project name
#' @param target_dir Target directory (defaults to current)
#' @param python Include Python configuration
#' @keywords internal
.create_vscode_workspace <- function(project_name, target_dir = ".", python = FALSE) {
  checkmate::assert_string(project_name, min.chars = 1)
  checkmate::assert_string(target_dir, min.chars = 1)
  checkmate::assert_flag(python)

  workspace_file <- file.path(target_dir, paste0(project_name, ".code-workspace"))

  # Base workspace configuration
  workspace_config <- list(
    folders = list(
      list(path = ".")
    ),
    settings = list(
      # R-specific settings for better out-of-the-box experience
      "r.bracketedPaste" = TRUE,
      "r.plot.useHttpgd" = TRUE,
      "r.rterm.option" = c("--no-save", "--no-restore", "--quiet"),
      "r.session.watch" = FALSE,
      "r.lintr.enabled" = TRUE
    ),
    extensions = list(
      recommendations = c(
        "REditorSupport.r",
        "REditorSupport.r-lsp",
        "reditorsupport.vsc-r-help",
        "quarto.quarto"
      )
    )
  )

  # Add Python configuration if requested
  if (python) {
    workspace_config$settings$`python.defaultInterpreterPath` <- "./.venv"
    workspace_config$extensions$recommendations <- c(
      workspace_config$extensions$recommendations,
      "ms-python.python",
      "ms-python.vscode-pylance"
    )
  }

  # Write JSON file
  json_content <- jsonlite::toJSON(workspace_config, pretty = TRUE, auto_unbox = TRUE)
  writeLines(json_content, workspace_file)

  message(sprintf("Created %s", workspace_file))
  invisible(workspace_file)
}

#' Create VS Code settings.json
#' @param target_dir Target directory (defaults to current)
#' @param python Include Python configuration
#' @keywords internal
.create_vscode_settings <- function(target_dir = ".", python = FALSE) {
  checkmate::assert_string(target_dir, min.chars = 1)
  checkmate::assert_flag(python)

  vscode_dir <- file.path(target_dir, ".vscode")
  dir.create(vscode_dir, showWarnings = FALSE, recursive = TRUE)

  settings_file <- file.path(vscode_dir, "settings.json")

  # Base settings
  settings <- list(
    "r.lintr.enabled" = TRUE,
    "files.associations" = list(
      "*.Rmd" = "rmd",
      "*.qmd" = "quarto"
    )
  )

  # Add Python settings if requested
  if (python) {
    settings$`python.defaultInterpreterPath` <- "${workspaceFolder}/.venv"
    settings$`python.linting.enabled` <- TRUE
    settings$`python.formatting.provider` <- "black"
  }

  # Write JSON file
  json_content <- jsonlite::toJSON(settings, pretty = TRUE, auto_unbox = TRUE)
  writeLines(json_content, settings_file)

  message(sprintf("Created %s", settings_file))
  invisible(settings_file)
}

#' Create IDE configuration files
#' @param project_name Project name
#' @param target_dir Target directory
#' @param python Include Python configuration
#' @keywords internal
.create_ide_configs <- function(project_name, target_dir = ".", python = FALSE) {
  checkmate::assert_string(project_name, min.chars = 1)
  checkmate::assert_string(target_dir, min.chars = 1)
  checkmate::assert_flag(python)

  # Check user's IDE preferences from ~/.frameworkrc
  fw_ides <- Sys.getenv("FW_IDES", "")

  # If not configured, default to both (backward compatibility)
  if (fw_ides == "") {
    ides <- c("vscode", "rstudio")
  } else {
    ides <- strsplit(fw_ides, ",")[[1]]
    ides <- trimws(ides)
  }

  # Create VS Code configs if selected
  if ("vscode" %in% ides || "positron" %in% ides) {
    suppressMessages({
      .create_vscode_workspace(project_name, target_dir, python)
      .create_vscode_settings(target_dir, python)
    })
  }

  # Note: RStudio uses .Rproj file which is always created
  # No additional RStudio-specific configs needed

  invisible(TRUE)
}
