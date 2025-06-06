#' Validate refresh parameter
#' @param refresh Boolean or function that returns boolean
#' @return Boolean indicating if refresh is needed
#' @keywords internal
.validate_refresh <- function(refresh) {
  if (is.function(refresh)) {
    result <- tryCatch(
      refresh(),
      error = function(e) {
        warning(sprintf("Refresh function failed: %s", e$message))
        FALSE
      }
    )
    if (!is.logical(result) || length(result) != 1) {
      warning("Refresh function must return a single boolean value")
      return(FALSE)
    }
    return(result)
  }

  if (!is.logical(refresh) || length(refresh) != 1) {
    warning("Refresh parameter must be a single boolean value or a function")
    return(FALSE)
  }

  refresh
}

#' Get a cache value
#' @param name The cache name
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @return The cached result, or NULL if not found, expired, or hash mismatch
#' @keywords internal
.get_cache <- function(name, file = NULL, expire_after = NULL) {
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

  if (!file.exists(cache_file)) {
    message(sprintf("Cache '%s' not found", name))
    return(NULL)
  }

  # Get metadata from database
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      warning(sprintf("Failed to connect to database: %s", e$message))
      return(NULL)
    }
  )

  if (is.null(con)) {
    return(NULL)
  }

  on.exit(DBI::dbDisconnect(con))

  # Get cache metadata including expire_at
  result <- tryCatch(
    DBI::dbGetQuery(con, "SELECT hash, expire_at FROM cache WHERE name = ?", list(name)),
    error = function(e) {
      warning(sprintf("Failed to query database: %s", e$message))
      return(data.frame())
    }
  )

  if (nrow(result) == 0) {
    message(sprintf("Cache '%s' not found in database", name))
    return(NULL)
  }

  # Check if cache has expired
  if (!is.na(result$expire_at)) {
    expire_at <- as.POSIXct(result$expire_at)
    if (Sys.time() > expire_at) {
      message(sprintf("Cache '%s' has expired", name))
      .remove_cache(name, file)
      return(NULL)
    }
  }

  # Read the actual value from RDS
  value <- tryCatch(
    readRDS(cache_file),
    error = function(e) {
      warning(sprintf("Failed to read cache file: %s", e$message))
      return(NULL)
    }
  )

  if (is.null(value)) {
    message(sprintf("Failed to read cache '%s'", name))
    return(NULL)
  }

  # Verify hash matches
  current_hash <- tryCatch(
    .calculate_file_hash(cache_file),
    error = function(e) {
      warning(sprintf("Failed to calculate file hash: %s", e$message))
      return(NULL)
    }
  )

  if (is.null(current_hash)) {
    return(NULL)
  }

  if (as.character(current_hash) != result$hash) {
    warning(sprintf("Hash mismatch for cache '%s' - cache may be corrupted", name))
    return(NULL)
  }

  # Update last_read_at
  tryCatch(
    DBI::dbExecute(
      con,
      "UPDATE cache SET last_read_at = ? WHERE name = ?",
      list(lubridate::now(), name)
    ),
    error = function(e) {
      warning(sprintf("Failed to update last_read_at: %s", e$message))
    }
  )

  list(value = value, hash = result$hash)
}

#' Get a cached value
#' @param name The cache name
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @return The cached value, or NULL if not found, expired, or hash mismatch
#' @export
cache_get <- function(name, file = NULL, expire_after = NULL) {
  if (!is.character(name) || length(name) != 1) {
    stop("Cache name must be a single string")
  }

  result <- .get_cache(name, file, expire_after)
  if (is.null(result)) {
    return(NULL)
  }
  result$value
}

#' Get a value, caching the result if not found
#' @param name The cache name
#' @param expr The expression to evaluate and cache
#' @param file Optional file path to store the cache (default: {config$options$data$cache_dir}/{name}.rds)
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @param refresh Optional boolean or function that returns boolean to force refresh
#' @return The result of expr
#' @export
get_or_cache <- function(name, expr, file = NULL, expire_after = NULL, refresh = FALSE) {
  if (!is.character(name) || length(name) != 1) {
    stop("Cache name must be a single string")
  }

  # Check if refresh is needed
  if (.validate_refresh(refresh)) {
    message(sprintf("Cache '%s' refresh requested", name))
    .remove_cache(name, file)
  }

  result <- cache_get(name, file, expire_after)
  if (!is.null(result)) {
    return(result)
  }

  value <- tryCatch(
    eval(expr, envir = parent.frame()),
    error = function(e) {
      stop(sprintf("Failed to evaluate expression: %s", e$message))
    }
  )

  tryCatch(
    cache(name, value, file, expire_after),
    error = function(e) {
      warning(sprintf("Failed to cache value: %s", e$message))
    }
  )

  value
}
