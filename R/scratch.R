#' Capture and Save Data to File
#'
#' @description
#' Saves data to a file in various formats (text, RDS, or CSV) in a specified location.
#' If no location is provided, uses the scratch directory from the configuration.
#'
#' @param x The object to save. For CSV output, must be a data frame or tibble.
#' @param name Character string specifying the name of the file (without extension).
#' @param to Character string indicating the output format. One of: "text" (default),
#'   "rds", or "csv".
#' @param location Character string specifying the directory where the file should be saved.
#'   If NULL, uses the scratch directory from the configuration.
#'
#' @return The input object `x` invisibly.
#'
#' @examples
#' # Save a character vector as text
#' capture(c("hello", "world"), "greeting")
#'
#' # Save a data frame as CSV
#' capture(mtcars, "cars", to = "csv")
#'
#' # Save an R object as RDS
#' capture(list(a = 1, b = 2), "mylist", to = "rds")
#'
#' @export
capture <- function(x, name, to = "text", location = NULL) {
  # Get default location from config if not provided
  if (is.null(location)) {
    config <- read_config()
    location <- config$options$data$scratch_dir
  }

  # Check if directory exists, fail if it doesn't
  if (!dir.exists(location)) {
    stop(sprintf("Directory does not exist: %s", location))
  }

  # Validate 'to' parameter
  if (!to %in% c("text", "rds", "csv")) {
    stop("'to' must be one of: 'text', 'rds', 'csv'")
  }

  # Handle CSV case
  if (to == "csv") {
    if (!inherits(x, c("data.frame", "tbl"))) {
      stop("For CSV output, x must be a data frame or tibble")
    }
    file_path <- file.path(location, paste0(name, ".csv"))
    write.csv(x, file_path, row.names = FALSE)
  } else if (to == "rds") {
    # Handle RDS case
    file_path <- file.path(location, paste0(name, ".rds"))
    saveRDS(x, file_path)
  } else {
    # Handle text case (default)
    file_path <- file.path(location, paste0(name, ".txt"))
    writeLines(as.character(x), file_path)
  }

  # Return the saved object invisibly
  invisible(x)
}
