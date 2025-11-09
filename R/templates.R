# Template management utilities -------------------------------------------------

#' Get the Framework user configuration directory
#'
#' Returns ~/.config/framework for consistency with settings location
#' @keywords internal
.framework_config_dir <- function() {
  path.expand("~/.config/framework")
}

#' Get the Framework templates directory
#' @keywords internal
.framework_templates_dir <- function(...) {
  file.path(.framework_config_dir(), "templates", ...)
}

# Mapping of logical template names to package resources
.framework_template_sources <- list(
  notebook = list(file = "notebook-default.qmd"),
  script = list(file = "script-default.R"),
  gitignore = list(file = "gitignore-project"),
  ai_claude = list(file = "CLAUDE.fr.md"),
  ai_claude_project = list(file = "CLAUDE-project.fr.md"),
  ai_claude_sensitive = list(file = "CLAUDE-sensitive.fr.md"),
  ai_claude_course = list(file = "CLAUDE-course.fr.md"),
  ai_claude_presentation = list(file = "CLAUDE-presentation.fr.md"),
  ai_agents = list(file = "AGENTS.fr.md"),
  ai_copilot = list(file = "copilot-instructions.fr.md")
)

.framework_template_path <- function(name) {
  if (!name %in% names(.framework_template_sources)) {
    stop(sprintf("Unknown template: %s", name))
  }

  tpl_dir <- .framework_templates_dir()
  if (!dir.exists(tpl_dir)) {
    dir.create(tpl_dir, recursive = TRUE, showWarnings = FALSE)
  }

  entry <- .framework_template_sources[[name]]
  if (!is.null(entry$subdir)) {
    tpl_dir <- .framework_templates_dir(entry$subdir)
    if (!dir.exists(tpl_dir)) {
      dir.create(tpl_dir, recursive = TRUE, showWarnings = FALSE)
    }
  }

  file.path(tpl_dir, entry$file)
}

.framework_template_default_path <- function(name) {
  entry <- .framework_template_sources[[name]]
  sub_path <- if (!is.null(entry$subdir)) file.path(entry$subdir, entry$file) else entry$file
  system.file("templates", sub_path, package = "framework", mustWork = TRUE)
}

#' Ensure the requested template exists in the user config directory
#' @keywords internal
.ensure_framework_template <- function(name) {
  dest <- .framework_template_path(name)
  if (!file.exists(dest)) {
    default_path <- .framework_template_default_path(name)
    file.copy(default_path, dest, overwrite = FALSE)
  }
  dest
}

#' Read a framework template
#' @keywords internal
.read_framework_template <- function(name) {
  path <- .ensure_framework_template(name)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

#' Write (overwrite) a framework template
#' @keywords internal
.write_framework_template <- function(name, contents) {
  path <- .framework_template_path(name)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(contents, con = path, sep = "\n")
  invisible(path)
}

#' Reset a template back to its packaged default
#' @keywords internal
.reset_framework_template <- function(name) {
  dest <- .framework_template_path(name)
  default_path <- .framework_template_default_path(name)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  file.copy(default_path, dest, overwrite = TRUE)
  invisible(dest)
}

#' Return metadata about available templates
#' @keywords internal
#' List available framework templates
#' @export
list_framework_templates <- function() {
  names(.framework_template_sources)
}

#' Get the user-editable path for a Framework template
#'
#' @param name Template identifier (e.g., "notebook", "gitignore", "ai_claude")
#' @return Absolute path to the template file, ensuring it exists.
#' @export
framework_template_path <- function(name) {
  .ensure_framework_template(name)
}

#' Read the contents of a Framework template
#' @inheritParams framework_template_path
#' @return Character scalar containing template contents
#' @export
read_framework_template <- function(name) {
  .read_framework_template(name)
}

#' Overwrite a Framework template with new contents
#' @inheritParams framework_template_path
#' @param contents Character string to write to the template file.
#' @export
write_framework_template <- function(name, contents) {
  checkmate::assert_string(contents)
  .write_framework_template(name, contents)
}

#' Reset a Framework template back to the packaged default
#' @inheritParams framework_template_path
#' @export
reset_framework_template <- function(name) {
  .reset_framework_template(name)
}
