#' Prompt user for project configuration
#' @param project_name Project name (NULL to prompt)
#' @param type Project type (NULL to prompt)
#' @param lintr Lintr style (NULL to prompt)
#' @param styler Styler style (NULL to prompt)
#' @return List of configuration parameters
#' @keywords internal
.prompt_project_config <- function(project_name, type, lintr, styler) {
  cat("\n")
  cat("Framework Project Initialization\n")
  cat("=================================\n\n")

  # Project name
  if (is.null(project_name)) {
    default_name <- basename(getwd())
    response <- readline(sprintf("Project name [%s]: ", default_name))
    project_name <- if (nzchar(response)) response else default_name
  }

  # Project type
  if (is.null(type)) {
    cat("\nProject type:\n")
    cat("  1. Analysis (data work with notebooks/ and scripts/)\n")
    cat("  2. Course (teaching with presentations/ and notebooks/)\n")
    cat("  3. Presentation (single talk, minimal structure)\n")
    response <- readline("Choose type [1]: ")
    type <- switch(response,
      "2" = "course",
      "3" = "presentation",
      "analysis"  # default
    )
  }

  # Lintr style
  if (is.null(lintr)) {
    response <- readline("\nLintr style [default]: ")
    lintr <- if (nzchar(response)) response else "default"
  }

  # Styler style
  if (is.null(styler)) {
    response <- readline("Styler style [default]: ")
    styler <- if (nzchar(response)) response else "default"
  }

  list(
    project_name = project_name,
    type = type,
    lintr = lintr,
    styler = styler
  )
}

#' Create init.R from template
#' @keywords internal
.create_init_file <- function(project_name, type, lintr, styler, subdir = NULL) {
  template_path <- system.file("templates/init.fr.R", package = "framework")
  if (!file.exists(template_path)) {
    stop("Template init.fr.R not found in package")
  }

  content <- readLines(template_path, warn = FALSE)

  # Replace placeholders
  content <- gsub("\\{\\{PROJECT_NAME\\}\\}", project_name, content)
  content <- gsub("\\{\\{PROJECT_TYPE\\}\\}", type, content)
  content <- gsub("\\{\\{LINTR\\}\\}", lintr, content)
  content <- gsub("\\{\\{STYLER\\}\\}", styler, content)

  target_dir <- if (!is.null(subdir) && nzchar(subdir)) subdir else "."
  target_file <- file.path(target_dir, "init.R")

  writeLines(content, target_file)
  message(sprintf("Created %s", target_file))
}

#' Create config.yml from template
#' @keywords internal
.create_config_file <- function(type = "analysis", subdir = NULL) {
  # Try type-specific template first, fall back to generic
  template_name <- sprintf("templates/config.%s.fr.yml", type)
  template_path <- system.file(template_name, package = "framework")

  if (!file.exists(template_path)) {
    # Fall back to generic template
    template_path <- system.file("templates/config.fr.yml", package = "framework")
    if (!file.exists(template_path)) {
      stop("Template config.fr.yml not found in package")
    }
  }

  target_dir <- if (!is.null(subdir) && nzchar(subdir)) subdir else "."
  target_file <- file.path(target_dir, "config.yml")

  file.copy(template_path, target_file, overwrite = TRUE)
  message(sprintf("Created %s", target_file))
}

#' Create .env from template
#' @keywords internal
.create_env_file <- function(subdir = NULL) {
  template_path <- system.file("templates/.env.fr", package = "framework")
  if (!file.exists(template_path)) {
    stop("Template .env.fr not found in package")
  }

  target_dir <- if (!is.null(subdir) && nzchar(subdir)) subdir else "."
  target_file <- file.path(target_dir, ".env")

  file.copy(template_path, target_file, overwrite = TRUE)
  message(sprintf("Created %s", target_file))
}

#' Display next steps after initialization
#' @keywords internal
.display_next_steps <- function() {
  cat("\n")
  cat("\u2713 Framework project initialized successfully!\n\n")
  cat("Next steps:\n")
  cat("  1. Review and edit config.yml\n")
  cat("  2. Add secrets to .env (gitignored)\n")
  cat("  3. Start a new R session:\n")
  cat("       library(framework)\n")
  cat("       scaffold()\n")
  cat("  4. Start analyzing!\n\n")
}

#' Initialize the framework
#'
#' This function initializes the framework for a new project.
#' Can be run from the framework-project template OR from any empty directory.
#' When run from an empty directory, prompts for configuration interactively.
#'
#' @param project_name The name of the project (used for .Rproj file). If NULL, uses current directory name.
#' @param type The project type: "project" (default), "course", or "presentation".
#'   Replaces deprecated project_structure parameter.
#' @param project_structure DEPRECATED. Use 'type' parameter instead.
#'   For backward compatibility: "default"/"minimal" map to "project"/"presentation".
#' @param lintr The lintr style to use.
#' @param styler The styler style to use.
#' @param use_renv If TRUE, enables renv for package management. Default FALSE.
#' @param subdir Optional subdirectory to copy files into. If provided, {subdir} in config files will be replaced with subdir/.
#' @param interactive If TRUE and parameters are NULL, will prompt interactively. Set FALSE for scripted initialization.
#' @param force If TRUE, will reinitialize even if project is already initialized.
#'
#' @examples
#' \dontrun{
#' # Interactive initialization from empty directory
#' init()
#'
#' # Non-interactive with explicit parameters
#' init(
#'   project_name = "MyProject",
#'   type = "project",
#'   lintr = "default",
#'   styler = "default",
#'   use_renv = FALSE,
#'   interactive = FALSE
#' )
#'
#' # Course project with renv enabled
#' init(type = "course", use_renv = TRUE)
#'
#' # Single presentation
#' init(type = "presentation")
#' }
#'
#' @export
init <- function(
    project_name = NULL,
    type = NULL,
    project_structure = NULL,
    lintr = NULL,
    styler = NULL,
    use_renv = FALSE,
    subdir = NULL,
    interactive = TRUE,
    force = FALSE) {
  # Handle deprecated project_structure parameter
  if (!is.null(project_structure) && is.null(type)) {
    warning(
      "Parameter 'project_structure' is deprecated. Use 'type' instead.\n",
      "  Mapping: 'default' -> 'project', 'minimal' -> 'presentation'"
    )
    type <- switch(project_structure,
      "default" = "project",
      "minimal" = "presentation",
      "project"  # fallback
    )
  }

  # Handle deprecated "analysis" type
  if (!is.null(type) && type == "analysis") {
    warning(
      "Type 'analysis' is deprecated. Use 'project' instead.\n",
      "  The 'analysis' type will be removed in a future version."
    )
    type <- "project"
  }

  # Validate arguments
  checkmate::assert_string(project_name, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(type, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(project_structure, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(lintr, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(styler, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(use_renv)
  checkmate::assert_string(subdir, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(interactive)
  checkmate::assert_flag(force)

  # Check if already initialized
  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  if (file.exists(init_file) && !force) {
    stop("Project already initialized. Use force = TRUE to reinitialize.")
  }

  # Detect if running from template (has init.R) or empty directory
  target_dir <- if (!is.null(subdir) && nzchar(subdir)) subdir else "."
  from_template <- file.exists(file.path(target_dir, "init.R"))

  # If from empty directory, create necessary files first
  if (!from_template) {
    message("Initializing from empty directory...")

    # Prompt for configuration if interactive and parameters missing
    if (interactive && (is.null(type) || is.null(project_name))) {
      config <- .prompt_project_config(project_name, type, lintr, styler)
      project_name <- config$project_name
      type <- config$type
      lintr <- config$lintr
      styler <- config$styler
    }

    # Set defaults if still NULL
    if (is.null(project_name)) project_name <- basename(getwd())
    if (is.null(type)) type <- "project"
    if (is.null(lintr)) lintr <- "default"
    if (is.null(styler)) styler <- "default"

    # Create foundational files
    .create_init_file(project_name, type, lintr, styler, subdir)
    .create_config_file(type, subdir)
    .create_env_file(subdir)
  } else {
    # Set defaults from template behavior
    if (is.null(type)) type <- "project"
    if (is.null(lintr)) lintr <- "default"
    if (is.null(styler)) styler <- "default"
  }

  # Continue with standard init process
  .init_standard(project_name, type, lintr, styler, subdir, force)

  # Enable renv if requested
  if (use_renv) {
    message("Enabling renv for this project...")
    renv_enable()
  }

  # Display next steps if from empty directory
  if (!from_template) {
    .display_next_steps()
  }
}

#' Standard initialization process (shared by both paths)
#' @keywords internal
.init_standard <- function(project_name, type, lintr, styler, subdir, force) {
  # Validate arguments (already validated in init, but keep for internal calls)
  checkmate::assert_string(project_name, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(type, min.chars = 1)
  checkmate::assert_string(lintr, min.chars = 1)
  checkmate::assert_string(styler, min.chars = 1)
  checkmate::assert_string(subdir, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(force)

  # Determine path for .initiated marker
  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  if (file.exists(init_file) && !force) {
    stop("Project already initialized. Use force = TRUE to reinitialize.")
  }

  # Derive project name
  if (!is.null(project_name)) {
    # Keep original capitalization, just convert spaces to hyphens for filenames
    rproj_name <- gsub("\\s+", "-", project_name)
  } else {
    project_name <- basename(getwd())
    rproj_name <- project_name
  }

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

  # Create IDE configuration files (VS Code workspace and settings)
  .create_ide_configs(rproj_name, target_dir, python = FALSE)

  # Copy and rename other template files
  template_dir <- system.file("templates", package = "framework")
  template_files <- list.files(template_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  for (file in template_files) {
    fname <- basename(file)

    # Skip files already handled explicitly
    if (fname == "project.fr.Rproj") next
    if (fname == "init.fr.R") next  # Skip init.R template (handled separately in empty dir case)
    if (fname == ".env.fr") next  # Skip .env template (handled separately in empty dir case)
    if (fname == "test.fr.R") next  # Skip test file template

    # Skip type-specific config and README files (these are handled separately)
    if (grepl("^config\\.(project|course|presentation)\\.fr\\.yml$", fname)) next
    if (grepl("^README\\.(project|course|presentation)\\.fr\\.md$", fname)) next
    if (fname == "config.fr.yml") next  # Skip generic config (handled separately)

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
  structure_dir <- system.file("project_structure", type, package = "framework")
  if (!dir.exists(structure_dir)) stop(sprintf("Project type '%s' not found", type))

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

  # Copy type-specific README → README.md
  readme_template <- system.file("templates", sprintf("README.%s.fr.md", type), package = "framework")
  if (!file.exists(readme_template)) {
    # Fall back to generic README if type-specific doesn't exist
    readme_template <- system.file("templates", "README.fr.md", package = "framework")
  }
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
  # Validate arguments
  checkmate::assert_string(subdir, min.chars = 1, null.ok = TRUE)

  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  file.exists(init_file)
}

#' Remove initialization
#'
#' @param subdir Optional subdirectory to check.
#' @return Logical indicating if removal was successful.
#' @export
remove_init <- function(subdir = NULL) {
  # Validate arguments
  checkmate::assert_string(subdir, min.chars = 1, null.ok = TRUE)

  init_file <- if (!is.null(subdir) && nzchar(subdir)) file.path(subdir, ".initiated") else ".initiated"
  if (file.exists(init_file)) {
    unlink(init_file)
    TRUE
  } else {
    FALSE
  }
}
