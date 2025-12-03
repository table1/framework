#' Remove a cache value
#' @param name The cache name to remove
#' @param file Optional file path of the cache (default: `cache/{name}.rds`)
#' @keywords internal
.remove_cache <- function(name, file = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)

  # Get config
  config <- settings_read()
  cache_dir <- config$directories$cache %||% config$options$data$cache_dir

  if (is.null(cache_dir) || !nzchar(cache_dir)) {
  stop("Cache directory not configured. Add 'cache: outputs/private/cache' to settings/directories.yml")
  }

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
#' @param file Optional file path of the cache (default: `cache/{name}.rds`)
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
  config <- settings_read()
  cache_dir <- config$directories$cache %||% config$options$data$cache_dir

  if (is.null(cache_dir) || !nzchar(cache_dir)) {
  stop("Cache directory not configured. Add 'cache: outputs/private/cache' to settings/directories.yml")
  }

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
