#' Create an R Script from Stub Template
#'
#' Convenience wrapper for `make_notebook()` that creates R scripts (.R files).
#' This is identical to calling `make_notebook("name.R")`.
#'
#' @param name Character. The script name (with or without .R extension).
#'   Examples: "process-data", "process-data.R"
#' @param dir Character. Directory to create the script in. Reads from
#'   config `options$script_dir`, defaults to "scripts/" or current directory.
#' @param stub Character. Name of the stub template to use. Defaults to
#'   "default". User can create custom stubs in `stubs/script-{stub}.R`.
#' @param overwrite Logical. Whether to overwrite existing file. Default FALSE.
#'
#' @return Invisible path to created script
#'
#' @details
#' This function is a convenience wrapper that:
#' 1. Ensures the name ends with .R extension
#' 2. Uses `script_dir` config option instead of `notebook_dir`
#' 3. Calls `make_notebook()` with `type = "script"`
#'
#' ## Creating Custom Script Stubs
#'
#' Create a `stubs/` directory in your project root with custom templates:
#' ```
#' stubs/
#'   script-default.R      # Override default script stub
#'   script-etl.R          # Custom ETL script stub
#'   script-analysis.R     # Custom analysis script stub
#' ```
#'
#' Templates can use placeholders:
#' - `{filename}` - The script filename without extension
#' - `{date}` - Current date (YYYY-MM-DD)
#'
#' @examples
#' \dontrun{
#' # Create script (extension optional)
#' make_script("process-data")
#' make_script("process-data.R")
#'
#' # Use custom stub
#' make_script("etl-pipeline", stub = "etl")
#'
#' # Create in specific directory
#' make_script("analysis", dir = "analysis/")
#' }
#'
#' @seealso [make_notebook()] for creating Quarto/RMarkdown notebooks
#' @export
make_script <- function(name, dir = NULL, stub = "default", overwrite = FALSE) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(dir, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(stub, min.chars = 1)
  checkmate::assert_flag(overwrite)

  # Normalize name to include .R extension
  if (!grepl("\\.R$", name, ignore.case = TRUE)) {
    name <- paste0(name, ".R")
  }

  # Get script directory from config if not specified
  if (is.null(dir)) {
    config <- tryCatch(read_config(), error = function(e) NULL)
    if (!is.null(config$options$script_dir)) {
      dir <- config$options$script_dir
    } else if (dir.exists("scripts")) {
      dir <- "scripts"
    } else {
      dir <- "."
    }
  }

  # Call make_notebook with type = "script"
  make_notebook(
    name = name,
    type = "script",
    dir = dir,
    stub = stub,
    overwrite = overwrite
  )
}
