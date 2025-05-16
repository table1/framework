#' Initialize the framework
#'
#' This function initializes the framework for a new project.
#' It sets up the necessary files in the current directory.
#' @param project_name The name of the project (used for .Rproj file).
#' @param project_structure The project structure to use.
#' @param lintr The lintr style to use.
#' @param styler The styler style to use.
#' @param subdir Optional subdirectory to copy files into. If provided, {subdir} in config files will be replaced with subdir/.
#' @param force If TRUE, will reinitialize even if project is already initialized.
#' @export
init <- function(
    project_name = NULL,
    project_structure = "default",
    lintr = "default",
    styler = "default",
    subdir = NULL,
    force = FALSE) {
  # Determine path for .initiated marker
  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  if (file.exists(init_file) && !force) {
    stop("Project already initialized. Use force = TRUE to reinitialize.")
  }

  # Derive project name
  if (!is.null(project_name)) {
    project_name <- tools::toTitleCase(tolower(project_name))
  } else {
    project_name <- basename(getwd())
  }
  rproj_name <- gsub("\\s+", "", project_name)

  # Validate template style files
  lintr_template <- system.file("templates", paste0(".lintr.", lintr, ".fr"), package = "framework")
  styler_template <- system.file("templates", paste0(".styler.", styler, ".fr.R"), package = "framework")
  if (!file.exists(lintr_template)) stop(sprintf("Lintr style '%s' not found", lintr))
  if (!file.exists(styler_template)) stop(sprintf("Styler style '%s' not found", styler))

  # Remove existing *.Rproj file (only one per project)
  target_dir <- if (!is.null(subdir) && nzchar(subdir)) subdir else "."
  existing_rproj <- list.files(path = target_dir, pattern = "\\.Rproj$", full.names = TRUE)
  if (length(existing_rproj)) file.remove(existing_rproj)

  # Copy and rename .Rproj file
  rproj_template <- system.file("templates", "project.fr.Rproj", package = "framework")
  if (!file.exists(rproj_template)) stop("Template project.fr.Rproj file not found in package.")
  rproj_target <- file.path(target_dir, paste0(rproj_name, ".Rproj"))
  file.copy(rproj_template, rproj_target, overwrite = TRUE)

  # Copy and rename other template files
  template_dir <- system.file("templates", package = "framework")
  template_files <- list.files(template_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  for (file in template_files) {
    fname <- basename(file)

    # Skip files already handled explicitly
    if (fname == "project.fr.Rproj") next
    if (!grepl("\\.fr($|\\.)", fname)) next

    # Replace `.fr.` with `.` or `.fr` suffix with nothing
    new_name <- gsub("\\.fr\\.", ".", fname)
    new_name <- gsub("\\.fr$", "", new_name)
    # Remove .default from lintr and styler files (both in middle and end)
    new_name <- gsub("\\.default\\.", ".", new_name)
    new_name <- gsub("\\.default$", "", new_name)

    # Preserve leading dot
    if (grepl("^\\.", fname)) {
      new_name <- paste0(".", sub("^\\.", "", new_name))
    }

    target_path <- file.path(target_dir, new_name)
    dir.create(dirname(target_path), showWarnings = FALSE, recursive = TRUE)

    success <- file.copy(file, target_path, overwrite = TRUE)
    if (!success) warning(sprintf("Failed to copy template file: %s to %s", file, target_path))

    # Substitute {subdir} in YAML-like config files
    if (grepl("\\.ya?ml$", new_name)) {
      content <- readLines(target_path)
      subdir_prefix <- if (!is.null(subdir) && nzchar(subdir)) paste0(subdir, "/") else ""
      content <- gsub("\\{subdir\\}", subdir_prefix, content)
      writeLines(content, target_path)
    }
  }

  # Copy project structure
  structure_dir <- system.file("project_structure", project_structure, package = "framework")
  if (!dir.exists(structure_dir)) stop(sprintf("Project structure '%s' not found", project_structure))

  all_dirs <- list.dirs(structure_dir, recursive = TRUE, full.names = TRUE)
  all_dirs <- all_dirs[all_dirs != structure_dir]

  for (dir in all_dirs) {
    rel_path <- sub(paste0("^", structure_dir, "/?"), "", dir)
    target_path <- file.path(target_dir, rel_path)
    dir.create(target_path, showWarnings = FALSE, recursive = TRUE)
  }

  structure_files <- list.files(structure_dir, recursive = TRUE, full.names = TRUE)
  for (file in structure_files) {
    if (basename(file) == ".gitkeep") next
    rel_path <- sub(paste0("^", structure_dir, "/?"), "", file)
    target_path <- file.path(target_dir, rel_path)
    file.copy(file, target_path, overwrite = TRUE)
  }

  # Copy .env.example to .env if present
  env_example <- file.path(target_dir, ".env.example")
  if (file.exists(env_example)) {
    file.copy(env_example, file.path(target_dir, ".env"), overwrite = TRUE)
  }

  # Copy README.fr.md → README.md
  readme_template <- system.file("templates", "README.fr.md", package = "framework")
  if (file.exists(readme_template)) {
    readme_path <- file.path(target_dir, "README.md")
    file.copy(readme_template, readme_path, overwrite = TRUE)
  }

  # Mark as initialized
  writeLines(as.character(Sys.time()), file.path(target_dir, ".initiated"))
  message(sprintf("Project '%s' initialized successfully!", project_name))
}

#' Check if project is initialized
#'
#' @param subdir Optional subdirectory to check.
#' @return Logical indicating if project is initialized.
#' @export
is_initialized <- function(subdir = NULL) {
  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  file.exists(init_file)
}

#' Remove initialization
#'
#' @param subdir Optional subdirectory to check.
#' @return Logical indicating if removal was successful.
#' @export
remove_init <- function(subdir = NULL) {
  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  if (file.exists(init_file)) {
    unlink(init_file)
    TRUE
  } else {
    FALSE
  }
}
