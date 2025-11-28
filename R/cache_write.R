#' Set a cache value
#' @param name The cache name
#' @param value The value to cache
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @keywords internal
.set_cache <- function(name, value, file = NULL, expire_after = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)
  checkmate::assert_number(expire_after, lower = 0, null.ok = TRUE)

  # Get cache directory - uses FW_CACHE_DIR env var if set, otherwise config
  cache_dir <- .get_cache_dir()

  config_obj <- read_config()
  default_expire <- config_obj$options$data$cache_default_expire

  # Determine cache file path
  cache_file <- if (is.null(file)) {
    file.path(cache_dir, paste0(name, ".rds"))
  } else {
    file
  }

  # Create cache directory if it doesn't exist (lazy creation)
  cache_dir <- dirname(cache_file)
  if (!dir.exists(cache_dir)) {
    tryCatch({
      dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
      cli::cli_alert_info("Creating cache directory: {.path {cache_dir}}")
    }, error = function(e) {
      cli::cli_abort("Failed to create cache directory {.path {cache_dir}}: {e$message}")
    })
  }

  # Save value to RDS file
  tryCatch(
    saveRDS(value, cache_file),
    error = function(e) {
      stop(sprintf("Failed to save cache file: %s", e$message))
    }
  )

  # Calculate hash from file
  hash <- tryCatch(
    .calculate_file_hash(cache_file),
    error = function(e) {
      stop(sprintf("Failed to calculate file hash: %s", e$message))
    }
  )

  # Calculate expiration time
  now <- lubridate::now()
  expire_after <- expire_after %||% default_expire
  expire_at <- if (!is.null(expire_after)) {
    now + lubridate::hours(expire_after)
  } else {
    NA
  }

  # Update database record with just metadata
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      warning(sprintf("Failed to connect to database: %s", e$message))
      return(NULL)
    }
  )

  if (is.null(con)) {
    return(FALSE)
  }

  on.exit(DBI::dbDisconnect(con))

  if (DBI::dbExistsTable(con, "cache")) {
    # Check if entry exists
    entry_exists <- tryCatch(
      DBI::dbGetQuery(con, "SELECT 1 FROM cache WHERE name = ?", list(name)),
      error = function(e) {
        stop(sprintf("Failed to query database: %s", e$message))
      }
    )

    if (nrow(entry_exists) > 0) {
      # Update existing entry
      tryCatch(
        DBI::dbExecute(
          con,
          "UPDATE cache SET hash = ?, expire_at = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
          list(as.character(hash), expire_at, now, now, name)
        ),
        error = function(e) {
          stop(sprintf("Failed to update cache record: %s", e$message))
        }
      )
    } else {
      # Insert new entry
      tryCatch(
        DBI::dbExecute(
          con,
          "INSERT INTO cache (name, hash, expire_at, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
          list(name, as.character(hash), expire_at, now, now, now)
        ),
        error = function(e) {
          stop(sprintf("Failed to insert cache record: %s", e$message))
        }
      )
    }
  }

  value
}

#' Cache a value
#' @param name The cache name
#' @param value The value to cache
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @return The cached value
#' @export
cache <- function(name, value, file = NULL, expire_after = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)
  checkmate::assert_number(expire_after, lower = 0, null.ok = TRUE)

  .set_cache(name, value, file, expire_after)
}
