#' Create a Notebook or Script from Stub Template
#'
#' Creates a new Quarto (.qmd), RMarkdown (.Rmd) notebook, or R script (.R)
#' from stub templates. Searches for user-provided stubs first (in `stubs/`
#' directory), then falls back to framework defaults.
#'
#' @param name Character. The file name. Extension determines type:
#'   - .qmd: Quarto notebook (default if no extension)
#'   - .Rmd: RMarkdown notebook
#'   - .R: R script
#'   Examples: "1-init", "1-init.qmd", "analysis.Rmd", "script.R"
#' @param type Character. File type: "quarto", "rmarkdown", or "script".
#'   Auto-detected from extension if provided.
#' @param dir Character. Directory to create the file in. Reads from
#'   config `options$notebook_dir`, defaults to "work/" or current directory.
#' @param stub Character. Name of the stub template to use. Defaults to
#'   "default". User can create custom stubs in `stubs/notebook-{stub}.qmd`,
#'   `stubs/notebook-{stub}.Rmd`, or `stubs/script-{stub}.R`.
#' @param overwrite Logical. Whether to overwrite existing file. Default FALSE.
#'
#' @return Invisible path to created notebook
#'
#' @details
#' ## Stub Template Resolution
#'
#' The function searches for stub templates in this order:
#' 1. User stubs: `stubs/notebook-{stub}.qmd` or `stubs/notebook-{stub}.Rmd`
#' 2. Framework stubs: `inst/stubs/notebook-{stub}.qmd` or `inst/stubs/notebook-{stub}.Rmd`
#'
#' ## Extension Normalization
#'
#' - If name includes `.qmd` or `.Rmd`, type is auto-detected
#' - If no extension provided, `.qmd` is used (Quarto-first)
#' - Use `type = "rmarkdown"` to default to `.Rmd`
#'
#' ## Creating Custom Stubs
#'
#' Create a `stubs/` directory in your project root with custom templates:
#' ```
#' stubs/
#'   notebook-default.qmd      # Override default Quarto stub
#'   notebook-analysis.qmd     # Custom analysis stub
#'   notebook-report.Rmd       # Custom RMarkdown report stub
#' ```
#'
#' Templates can use placeholders:
#' - `{filename}` - The notebook filename without extension
#' - `{date}` - Current date (YYYY-MM-DD)
#'
#' @examples
#' \dontrun{
#' # Create work/1-init.qmd from default stub
#' make_notebook("1-init")
#'
#' # Create work/analysis.Rmd (RMarkdown)
#' make_notebook("analysis.Rmd")
#'
#' # Use custom stub template
#' make_notebook("report", stub = "analysis")
#'
#' # Create in specific directory
#' make_notebook("explore", dir = "notebooks")
#' }
#'
#' @export
make_notebook <- function(name,
                          type = c("quarto", "rmarkdown", "script"),
                          dir = NULL,
                          stub = "default",
                          overwrite = FALSE) {

  # Normalize extension and detect type
  normalized <- .normalize_notebook_name(name, type)
  name_normalized <- normalized$name
  type <- normalized$type
  ext <- normalized$ext
  is_script <- (type == "script")

  # Determine target directory from config if possible
  if (is.null(dir)) {
    dir <- .get_notebook_dir_from_config()
  }

  # Ensure directory exists
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    message(sprintf("Created directory: %s", dir))
  }

  # Full path to target file
  target_path <- file.path(dir, name_normalized)

  # Check if file exists
  if (file.exists(target_path) && !overwrite) {
    stop(sprintf("File already exists: %s\nUse overwrite = TRUE to replace it.",
                 target_path))
  }

  # Find stub template
  stub_path <- .find_stub_template(stub, ext)

  # Read and process stub
  stub_content <- readLines(stub_path, warn = FALSE)

  # Replace placeholders
  filename_no_ext <- sub("\\.[^.]+$", "", basename(name_normalized))
  stub_content <- gsub("{filename}", filename_no_ext, stub_content, fixed = TRUE)
  stub_content <- gsub("{date}", Sys.Date(), stub_content, fixed = TRUE)

  # Write notebook
  writeLines(stub_content, target_path)

  if (is_script) {
    message(sprintf("Created R script: %s", target_path))
  } else {
    message(sprintf("Created %s notebook: %s",
                    if (type == "quarto") "Quarto" else "RMarkdown",
                    target_path))
  }
  if (!identical(stub, "default")) {
    message(sprintf("  Using stub: %s", stub))
  }

  invisible(target_path)
}


#' Normalize Notebook Name and Detect Type
#'
#' @param name Character. File name with or without extension
#' @param type Character. Type preference
#'
#' @return List with name, type, and ext
#' @keywords internal
.normalize_notebook_name <- function(name, type = c("quarto", "rmarkdown", "script")) {

  type <- match.arg(type)

  # Check if extension is provided
  has_qmd <- grepl("\\.qmd$", name, ignore.case = TRUE)
  has_rmd <- grepl("\\.Rmd$", name, ignore.case = TRUE)
  has_r <- grepl("\\.R$", name, ignore.case = TRUE)

  if (has_qmd) {
    # .qmd extension provided
    name_normalized <- sub("\\.qmd$", ".qmd", name, ignore.case = TRUE)
    type <- "quarto"
    ext <- "qmd"
  } else if (has_rmd) {
    # .Rmd extension provided
    name_normalized <- sub("\\.Rmd$", ".Rmd", name, ignore.case = TRUE)
    type <- "rmarkdown"
    ext <- "Rmd"
  } else if (has_r) {
    # .R extension provided
    name_normalized <- sub("\\.R$", ".R", name, ignore.case = TRUE)
    type <- "script"
    ext <- "R"
  } else {
    # No extension - use type preference
    if (type == "quarto") {
      name_normalized <- paste0(name, ".qmd")
      ext <- "qmd"
    } else if (type == "rmarkdown") {
      name_normalized <- paste0(name, ".Rmd")
      ext <- "Rmd"
    } else {
      name_normalized <- paste0(name, ".R")
      ext <- "R"
    }
  }

  list(
    name = name_normalized,
    type = type,
    ext = ext
  )
}


#' Find Stub Template
#'
#' Searches for stub templates in user stubs/ directory first, then framework
#' inst/stubs/ directory.
#'
#' @param stub Character. Stub name (e.g., "default", "analysis")
#' @param ext Character. File extension ("qmd", "Rmd", or "R")
#'
#' @return Path to stub template file
#' @keywords internal
.find_stub_template <- function(stub, ext) {

  # Determine prefix based on extension
  prefix <- if (ext == "R") "script" else "notebook"
  stub_filename <- sprintf("%s-%s.%s", prefix, stub, ext)

  # Check user stubs directory first
  user_stub <- file.path("stubs", stub_filename)
  if (file.exists(user_stub)) {
    message(sprintf("Using user stub: %s", user_stub))
    return(user_stub)
  }

  # Fall back to framework stubs
  framework_stub <- system.file("stubs", stub_filename, package = "framework")

  if (framework_stub == "" || !file.exists(framework_stub)) {
    stop(sprintf(
      "Stub template not found: %s\n\nSearched:\n  - %s\n  - inst/stubs/%s\n\nAvailable stubs: %s",
      stub,
      user_stub,
      stub_filename,
      paste(.list_available_stubs(ext), collapse = ", ")
    ))
  }

  framework_stub
}


#' List Available Stub Templates
#'
#' @param ext Character. File extension to filter by
#'
#' @return Character vector of stub names
#' @keywords internal
.list_available_stubs <- function(ext = NULL) {

  stubs <- character(0)

  # User stubs
  if (dir.exists("stubs")) {
    user_files <- list.files("stubs", pattern = "^(notebook|script)-.*\\.(qmd|Rmd|R)$")
    stubs <- c(stubs, user_files)
  }

  # Framework stubs
  framework_stubs_dir <- system.file("stubs", package = "framework")
  if (framework_stubs_dir != "" && dir.exists(framework_stubs_dir)) {
    framework_files <- list.files(framework_stubs_dir,
                                   pattern = "^(notebook|script)-.*\\.(qmd|Rmd|R)$")
    stubs <- c(stubs, framework_files)
  }

  # Extract stub names
  stub_names <- sub("^(notebook|script)-", "", stubs)
  stub_names <- sub("\\.(qmd|Rmd|R)$", "", stub_names)

  # Filter by extension if requested
  if (!is.null(ext)) {
    ext_pattern <- sprintf("\\.%s$", ext)
    matching <- grep(ext_pattern, stubs, value = TRUE)
    stub_names <- sub("^(notebook|script)-", "", matching)
    stub_names <- sub("\\.(qmd|Rmd|R)$", "", stub_names)
  }

  unique(stub_names)
}


#' List Available Stubs
#'
#' Shows all available stub templates that can be used with `make_notebook()`.
#'
#' @param type Character. Filter by type: "quarto", "rmarkdown", "script", or NULL (all).
#'
#' @return Data frame with columns: name, type, source (user/framework)
#'
#' @examples
#' \dontrun{
#' # List all stubs
#' list_stubs()
#'
#' # List only Quarto stubs
#' list_stubs("quarto")
#'
#' # List only script stubs
#' list_stubs("script")
#' }
#'
#' @export
list_stubs <- function(type = NULL) {

  result <- data.frame(
    name = character(0),
    type = character(0),
    source = character(0),
    stringsAsFactors = FALSE
  )

  # User stubs
  if (dir.exists("stubs")) {
    user_files <- list.files("stubs", pattern = "^(notebook|script)-.*\\.(qmd|Rmd|R)$",
                             full.names = FALSE)
    if (length(user_files) > 0) {
      user_result <- data.frame(
        name = sub("^(notebook|script)-", "", sub("\\.(qmd|Rmd|R)$", "", user_files)),
        type = ifelse(grepl("\\.qmd$", user_files), "quarto",
                      ifelse(grepl("\\.Rmd$", user_files), "rmarkdown", "script")),
        source = "user",
        stringsAsFactors = FALSE
      )
      result <- rbind(result, user_result)
    }
  }

  # Framework stubs
  framework_stubs_dir <- system.file("stubs", package = "framework")
  if (framework_stubs_dir != "" && dir.exists(framework_stubs_dir)) {
    framework_files <- list.files(framework_stubs_dir,
                                   pattern = "^(notebook|script)-.*\\.(qmd|Rmd|R)$",
                                   full.names = FALSE)
    if (length(framework_files) > 0) {
      framework_result <- data.frame(
        name = sub("^(notebook|script)-", "", sub("\\.(qmd|Rmd|R)$", "", framework_files)),
        type = ifelse(grepl("\\.qmd$", framework_files), "quarto",
                      ifelse(grepl("\\.Rmd$", framework_files), "rmarkdown", "script")),
        source = "framework",
        stringsAsFactors = FALSE
      )
      result <- rbind(result, framework_result)
    }
  }

  # Filter by type if requested
  if (!is.null(type)) {
    type <- match.arg(type, c("quarto", "rmarkdown", "script"))
    result <- result[result$type == type, ]
  }

  # Remove duplicates (user overrides framework)
  result <- result[!duplicated(paste(result$name, result$type)), ]

  # Sort by name
  result <- result[order(result$name, result$type), ]
  rownames(result) <- NULL

  result
}


#' Get Notebook Directory from Config
#'
#' Reads config to determine where notebooks should be created.
#' Falls back to "notebooks", "work", or current directory if config unavailable.
#'
#' @return Character path to notebook directory
#' @keywords internal
.get_notebook_dir_from_config <- function() {
  # Try to read config
  config <- tryCatch(
    read_config(),
    error = function(e) NULL
  )

  # Check for notebook directory in config (new directories structure)
  if (!is.null(config$directories$notebooks)) {
    return(config$directories$notebooks)
  }

  # Legacy: check options$notebook_dir for backward compatibility
  if (!is.null(config$options$notebook_dir)) {
    return(config$options$notebook_dir)
  }

  # Default fallback - check for notebooks/ then work/
  if (dir.exists("notebooks")) {
    return("notebooks")
  }

  if (dir.exists("work")) {
    return("work")
  }

  "."
}
