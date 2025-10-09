#' Remove a cache value
#' @param name The cache name to remove
#' @param file Optional file path of the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @keywords internal
.remove_cache <- function(name, file = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)

  # Get config
  config <- read_config()
  cache_dir <- config$options$data$cache_dir

  # Determine cache file path
  cache_file <- if (is.null(file)) {
    file.path(cache_dir, paste0(name, ".rds"))
  } else {
    file
  }

  if (file.exists(cache_file)) {
    tryCatch(
      unlink(cache_file),
      error = function(e) {
        warning(sprintf("Failed to remove cache file: %s", e$message))
      }
    )
  }

  # Remove database record
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      warning(sprintf("Failed to connect to database: %s", e$message))
      return(NULL)
    }
  )

  if (!is.null(con)) {
    on.exit(DBI::dbDisconnect(con))
    tryCatch(
      DBI::dbExecute(con, "DELETE FROM cache WHERE name = ?", list(name)),
      error = function(e) {
        warning(sprintf("Failed to remove cache record: %s", e$message))
      }
    )
  }
}

#' Remove a cached value
#' @param name The cache name to remove
#' @param file Optional file path of the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @export
cache_forget <- function(name, file = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)

  .remove_cache(name, file)
  invisible(NULL)
}

#' Clear all cached values
#' @export
cache_flush <- function() {
  # Get config
  config <- read_config()
  cache_dir <- config$options$data$cache_dir

  # Remove all RDS files
  if (dir.exists(cache_dir)) {
    tryCatch(
      unlink(list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)),
      error = function(e) {
        warning(sprintf("Failed to remove cache files: %s", e$message))
      }
    )
  }

  # Clear database records
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      warning(sprintf("Failed to connect to database: %s", e$message))
      return(NULL)
    }
  )

  if (!is.null(con)) {
    on.exit(DBI::dbDisconnect(con))
    tryCatch(
      DBI::dbExecute(con, "DELETE FROM cache"),
      error = function(e) {
        warning(sprintf("Failed to clear cache records: %s", e$message))
      }
    )
  }

  invisible(NULL)
}
