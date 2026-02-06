#' Create VS Code workspace file
#' @param project_name Project name
#' @param target_dir Target directory (defaults to current)
#' @param python Include Python configuration
#' @keywords internal
.create_vscode_workspace <- function(project_name, target_dir = ".", python = FALSE) {
  checkmate::assert_string(project_name, min.chars = 1)
  checkmate::assert_string(target_dir, min.chars = 1)
  checkmate::assert_flag(python)

  # Sanitize project name for workspace filename
  # 1. Convert to lowercase
  # 2. Convert spaces to hyphens
  # 3. Remove all special characters except hyphens
  sanitized_name <- tolower(project_name)
  sanitized_name <- gsub("\\s+", "-", sanitized_name)
  sanitized_name <- gsub("[^a-z0-9-]", "", sanitized_name)

  workspace_file <- file.path(target_dir, paste0(sanitized_name, ".code-workspace"))

  # Base workspace configuration
  workspace_config <- list(
    folders = list(
      list(path = ".")
    ),
    settings = list(
      # R-specific settings for better out-of-the-box experience
      "r.bracketedPaste" = FALSE,  # Disable bracketed paste for cleaner terminal
      "r.plot.useHttpgd" = TRUE,
      "r.rterm.option" = c("--no-save", "--no-restore", "--quiet"),
      "r.session.watchGlobalEnvironment" = FALSE,
      "r.session.watch" = FALSE,
      "r.lintr.enabled" = TRUE,
      "r.alwaysUseActiveTerminal" = TRUE,

      # Editor settings
      "editor.tabSize" = 2,
      "editor.insertSpaces" = TRUE,
      "editor.rulers" = list(80, 120),
      "files.trimTrailingWhitespace" = TRUE,
      "files.insertFinalNewline" = TRUE,

      # Terminal settings
      "terminal.integrated.scrollback" = 10000,
      "terminal.integrated.enableBell" = FALSE,

      # Quarto settings
      "quarto.render.previewType" = "internal",

      # File associations
      "files.associations" = list(
        "*.Rmd" = "rmd",
        "*.qmd" = "quarto",
        ".frameworkrc" = "shellscript"
      )
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

  # Copy from template
  template_file <- system.file("templates", "settings.json", package = "framework")
  if (!file.exists(template_file)) {
    stop("Template settings.json not found in package")
  }

  file.copy(template_file, settings_file, overwrite = TRUE)

  # Add Python settings if requested
  if (python) {
    settings <- jsonlite::fromJSON(settings_file)
    settings$`python.defaultInterpreterPath` <- "${workspaceFolder}/.venv"
    settings$`python.linting.enabled` <- TRUE
    settings$`python.formatting.provider` <- "black"

    json_content <- jsonlite::toJSON(settings, pretty = TRUE, auto_unbox = TRUE)
    writeLines(json_content, settings_file)
  }

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

  # If not configured, don't create any IDE-specific configs
  if (fw_ides == "") {
    ides <- character()
  } else {
    ides <- strsplit(fw_ides, ",")[[1]]
    ides <- trimws(ides)
  }

  # Create VS Code configs if explicitly selected
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
