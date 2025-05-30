#' Capture and Save Data to File
#'
#' @description
#' Saves data to a file in various formats based on the object type and specified format.
#' If no name is provided, uses the name of the object passed in.
#' If no location is provided, uses the scratch directory from the configuration.
#'
#' @param x The object to save
#' @param name Optional character string specifying the name of the file (without extension).
#'   If not provided, will use the name of the object passed in.
#' @param to Optional character string indicating the output format. One of: "text", "rds", "csv", "tsv".
#'   If not provided, will choose based on object type.
#' @param location Optional character string specifying the directory where the file should be saved.
#'   If NULL, uses the scratch directory from the configuration.
#' @param n Optional number of rows to capture for data frames (default: all rows)
#'
#' @return The input object `x` invisibly.
#'
#' @examples
#' # Save a character vector as text
#' capture(c("hello", "world"))
#'
#' # Save a data frame as TSV
#' capture(mtcars)
#'
#' # Save an R object as RDS
#' capture(list(a = 1, b = 2), to = "rds")
#'
#' @export
capture <- function(x, name = NULL, to = NULL, location = NULL, n = Inf) {
  # Get default location from config if not provided
  if (is.null(location)) {
    config <- read_config()
    location <- config$options$data$scratch_dir
  }

  # Check if directory exists
  if (!dir.exists(location)) {
    stop(sprintf("Directory does not exist: %s", location))
  }

  # Get object name if not provided
  if (is.null(name)) {
    # Try to get the name of the object passed in
    name <- deparse(substitute(x))

    # If it's a pipe expression, try to get the name from the pipe chain
    if (grepl("\\|>", name)) {
      # Get all expressions in the pipe chain
      pipe_expr <- strsplit(name, "\\|>")[[1]]
      pipe_expr <- trimws(pipe_expr)

      # Look through the chain from right to left for a valid variable name
      for (expr in rev(pipe_expr)) {
        # Skip the capture() call itself
        if (grepl("^capture\\(\\)$", expr)) next

        # If we find a valid variable name, use it
        if (grepl("^[a-zA-Z][a-zA-Z0-9_.]*$", expr)) {
          name <- expr
          break
        }
      }

      # If we didn't find a valid name, use timestamp
      if (grepl("^capture_", name)) {
        name <- paste0("capture_", format(Sys.time(), "%Y%m%d_%H%M%S"))
      }
    } else if (grepl("\\(", name) || grepl("\\{", name)) {
      # For other complex expressions, use timestamp
      name <- paste0("capture_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    } else {
      # Clean up the name by removing any quotes and whitespace
      name <- gsub("[\"']", "", name)
      name <- trimws(name)
    }
  }

  # Determine output format if not specified
  if (is.null(to)) {
    if (is.data.frame(x) || inherits(x, "tbl")) {
      to <- "tsv"
    } else {
      # Default to text for everything else
      to <- "text"
    }
  }

  # Validate 'to' parameter
  if (!to %in% c("text", "rds", "csv", "tsv")) {
    stop("'to' must be one of: 'text', 'rds', 'csv', 'tsv'")
  }

  # Check if name already has an extension
  has_extension <- grepl("\\.(txt|tsv|csv|rds)$", name)
  if (has_extension) {
    # Extract base name and extension
    name_parts <- strsplit(name, "\\.")[[1]]
    base_name <- paste(name_parts[-length(name_parts)], collapse = ".")
    ext <- name_parts[length(name_parts)]

    # Override 'to' parameter with the extension from the filename
    to <- switch(ext,
      "txt" = "text",
      "tsv" = "tsv",
      "csv" = "csv",
      "rds" = "rds"
    )
    name <- base_name
  }

  # Handle data frames
  if (is.data.frame(x) || inherits(x, "tbl")) {
    # Limit rows if n is finite
    if (is.finite(n)) {
      x <- head(x, n)
    }

    if (to == "rds") {
      file_path <- file.path(location, paste0(name, ".rds"))
      saveRDS(x, file_path)
    } else {
      # Default to TSV for data frames
      file_path <- file.path(location, paste0(name, ".tsv"))
      write.table(x, file_path, sep = "\t", row.names = FALSE, quote = FALSE)
    }
  } else if (is.vector(x) && !is.list(x)) {
    # Handle vectors
    if (to == "text") {
      file_path <- file.path(location, paste0(name, ".txt"))
      writeLines(as.character(x), file_path)
    } else if (to == "rds") {
      file_path <- file.path(location, paste0(name, ".rds"))
      saveRDS(x, file_path)
    } else {
      stop("Vectors can only be saved as 'text' or 'rds'")
    }
  } else {
    # Handle lists and other objects
    if (to == "text") {
      file_path <- file.path(location, paste0(name, ".txt"))
      if (is.list(x)) {
        # Write list size header and YAML representation
        writeLines(
          c(
            sprintf("List of %d items:", length(x)),
            "",
            yaml::as.yaml(x, indent = 2)
          ),
          file_path
        )
      } else {
        writeLines(capture.output(print(x)), file_path)
      }
    } else if (to == "rds") {
      file_path <- file.path(location, paste0(name, ".rds"))
      saveRDS(x, file_path)
    } else {
      stop("Complex objects can only be saved as 'text' or 'rds'")
    }
  }

  # Return the saved object invisibly
  invisible(x)
}

#' Clean up the scratch directory by deleting all files
#' @export
clean_scratch <- function() {
  config <- read_config()
  scratch_dir <- config$options$data$scratch_dir

  if (dir.exists(scratch_dir)) {
    files <- list.files(scratch_dir, full.names = TRUE)
    file.remove(files)
    message("Scratch directory cleaned: ", scratch_dir)
  } else {
    message("Scratch directory does not exist: ", scratch_dir)
  }
}
