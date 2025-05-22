#' Set a cache value
#' @param name The cache name
#' @param value The value to cache
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @keywords internal
.set_cache <- function(name, value, file = NULL, expire_after = NULL) {
  # Get config
  config <- read_config()
  cache_dir <- config$options$data$cache_dir
  default_expire <- config$options$data$cache_default_expire

  # Determine cache file path
  cache_file <- if (is.null(file)) {
    file.path(cache_dir, paste0(name, ".rds"))
  } else {
    file
  }

  # Create cache directory if it doesn't exist
  cache_dir <- dirname(cache_file)
  tryCatch(
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE),
    error = function(e) {
      stop(sprintf("Failed to create cache directory: %s", e$message))
    }
  )

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
  if (!is.character(name) || length(name) != 1) {
    stop("Cache name must be a single string")
  }

  .set_cache(name, value, file, expire_after)
}
