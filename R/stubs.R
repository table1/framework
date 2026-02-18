#' Publish Stub Templates for Customization
#'
#' Copies framework stub templates to your project's `stubs/` directory, allowing
#' you to customize them. Similar to Laravel's `artisan vendor:publish` command.
#'
#' @param type Character vector. Which stub types to publish:
#'   - "notebooks" - Quarto/RMarkdown notebook stubs
#'   - "scripts" - R script stubs
#'   - "all" - All stubs (default)
#' @param overwrite Logical. Whether to overwrite existing stubs. Default FALSE.
#' @param stubs Character vector. Specific stub names to publish (e.g., "default", "minimal").
#'   If NULL (default), publishes all stubs of the specified type.
#'
#' @return Invisible list of published file paths
#'
#' @details
#' ## Stub Customization Workflow
#'
#' 1. Publish stubs to your project: `stubs_publish()`
#' 2. Edit stubs in `stubs/` directory to match your preferences
#' 3. Use `make_notebook()` or `make_script()` - your custom stubs are used automatically
#'
#' ## Stub Naming Convention
#'
#' Stubs follow this naming pattern:
#' - Notebooks: `stubs/notebook-{name}.qmd` or `stubs/notebook-{name}.Rmd`
#' - Scripts: `stubs/script-{name}.R`
#'
#' Framework searches user stubs first, then falls back to built-in stubs.
#'
#' ## Available Placeholders
#'
#' Stubs can use these placeholders:
#' - `{filename}` - File name without extension
#' - `{date}` - Current date (YYYY-MM-DD)
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # Publish all stubs
#' stubs_publish()
#'
#' # Publish only notebook stubs
#' stubs_publish("notebooks")
#'
#' # Publish specific stub
#' stubs_publish(stubs = "default")
#'
#' # Overwrite existing stubs
#' stubs_publish(overwrite = TRUE)
#' }
#' }
#'
#' @seealso [make_notebook()], [make_script()], [stubs_list()], [stubs_path()]
#' @export
stubs_publish <- function(type = "all", overwrite = FALSE, stubs = NULL) {
  # Validate arguments
  checkmate::assert_character(type, min.len = 1)
  checkmate::assert_flag(overwrite)
  checkmate::assert_character(stubs, min.len = 1, null.ok = TRUE)

  type <- match.arg(type, c("all", "notebooks", "scripts"), several.ok = TRUE)

  # Resolve "all" to specific types
  if ("all" %in% type) {
    type <- c("notebooks", "scripts")
  }

  # Get framework stubs directory
  framework_stubs_dir <- system.file("stubs", package = "framework")
  if (framework_stubs_dir == "" || !dir.exists(framework_stubs_dir)) {
    stop("Framework stubs directory not found. Package may be corrupted.")
  }

  # Create user stubs directory if needed
  user_stubs_dir <- "stubs"
  if (!dir.exists(user_stubs_dir)) {
    dir.create(user_stubs_dir, recursive = TRUE)
    message(sprintf("Created directory: %s/", user_stubs_dir))
  }

  # Determine which files to copy
  framework_files <- list.files(framework_stubs_dir, pattern = "\\.(qmd|Rmd|R)$",
                                 full.names = TRUE)

  published <- character()

  for (file in framework_files) {
    filename <- basename(file)

    # Filter by type
    is_notebook <- grepl("^notebook-", filename)
    is_script <- grepl("^script-", filename)

    if (is_notebook && !("notebooks" %in% type)) next
    if (is_script && !("scripts" %in% type)) next

    # Filter by specific stub names if provided
    if (!is.null(stubs)) {
      stub_name <- sub("^(notebook|script)-", "", filename)
      stub_name <- sub("\\.(qmd|Rmd|R)$", "", stub_name)
      if (!(stub_name %in% stubs)) next
    }

    # Determine target path
    target_path <- file.path(user_stubs_dir, filename)

    # Check if exists
    if (file.exists(target_path) && !overwrite) {
      message(sprintf("Skipped (exists): %s", target_path))
      message("  Use overwrite = TRUE to replace existing stubs")
      next
    }

    # Copy file
    success <- file.copy(file, target_path, overwrite = overwrite)
    if (success) {
      message(sprintf("Published: %s", target_path))
      published <- c(published, target_path)
    } else {
      warning(sprintf("Failed to publish: %s", filename))
    }
  }

  if (length(published) == 0) {
    message("No stubs were published.")
  } else {
    message(sprintf("\n[ok] Published %d stub(s) to %s/", length(published), user_stubs_dir))
    message("  Edit these files to customize your templates.")
  }

  invisible(published)
}




#' Get Path to Stub Templates Directory
#'
#' Returns the path to the user's stubs directory, or the framework stubs directory
#' if no user stubs exist.
#'
#' @param which Character. Which directory to return:
#'   - "user" - User's project stubs directory (stubs/)
#'   - "framework" - Framework's built-in stubs directory
#'   - "auto" (default) - User directory if it exists, otherwise framework
#'
#' @return Character path to stubs directory
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # Get active stubs directory
#' stubs_path()
#'
#' # Get framework stubs directory
#' stubs_path("framework")
#'
#' # Get user stubs directory
#' stubs_path("user")
#' }
#' }
#'
#' @export
stubs_path <- function(which = "auto") {
  # Validate arguments
  checkmate::assert_string(which)
  which <- match.arg(which, c("auto", "user", "framework"))

  user_dir <- "stubs"
  framework_dir <- system.file("stubs", package = "framework")

  if (which == "user") {
    return(user_dir)
  } else if (which == "framework") {
    return(framework_dir)
  } else {
    # Auto: prefer user if it exists
    if (dir.exists(user_dir)) {
      return(user_dir)
    } else {
      return(framework_dir)
    }
  }
}
