#' Remove a data value
#' @param path Dot notation path to remove (e.g. "source.private.example")
#' @param delete_file Whether to delete the actual file (default: TRUE)
#' @export
remove_data <- function(path, delete_file = TRUE) {
  if (!is.character(path) || length(path) != 1) {
    stop("Path must be a single string")
  }

  # Get data specification
  spec <- tryCatch(
    get_data_spec(path),
    error = function(e) {
      stop(sprintf("Failed to get data specification: %s", e$message))
    }
  )

  if (is.null(spec)) {
    stop(sprintf("No data specification found for path: %s", path))
  }

  # Delete file if requested
  if (delete_file && file.exists(spec$path)) {
    tryCatch(
      unlink(spec$path),
      error = function(e) {
        warning(sprintf("Failed to delete file: %s", e$message))
      }
    )
  }

  # Remove database record
  tryCatch(
    .remove_data(path),
    error = function(e) {
      warning(sprintf("Failed to remove data record: %s", e$message))
    }
  )

  invisible(NULL)
}

#' Remove all data values
#' @param delete_files Whether to delete the actual files (default: TRUE)
#' @export
remove_all_data <- function(delete_files = TRUE) {
  # Get all data records
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      stop(sprintf("Failed to connect to database: %s", e$message))
    }
  )

  on.exit(DBI::dbDisconnect(con))

  records <- tryCatch(
    DBI::dbGetQuery(con, "SELECT name FROM data"),
    error = function(e) {
      stop(sprintf("Failed to query database: %s", e$message))
    }
  )

  # Remove each record
  for (name in records$name) {
    tryCatch(
      remove_data(name, delete_files),
      error = function(e) {
        warning(sprintf("Failed to remove data '%s': %s", name, e$message))
      }
    )
  }

  invisible(NULL)
}
