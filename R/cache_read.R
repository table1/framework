#' Get a cache value
#' @param name The cache name
#' @return The cached result, or NULL if not found or hash mismatch
#' @keywords internal
.get_cache <- function(name) {
  # Check if RDS file exists
  cache_file <- file.path("data/cached", paste0(name, ".rds"))
  if (!file.exists(cache_file)) {
    return(NULL)
  }

  # Get metadata from database
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT hash FROM cache WHERE name = ?",
    list(name)
  )
  DBI::dbDisconnect(con)

  if (nrow(result) == 0) {
    return(NULL)
  }

  # Read the actual value from RDS
  value <- readRDS(cache_file)

  # Verify hash matches
  current_hash <- .calculate_file_hash(cache_file)
  if (as.character(current_hash) != result$hash) {
    warning(sprintf("Hash mismatch for cache '%s' - cache may be corrupted", name))
    return(NULL)
  }

  list(value = value, hash = result$hash)
}

#' Get a cached value
#' @param name The cache name
#' @return The cached value, or NULL if not found or hash mismatch
#' @export
cache_get <- function(name) {
  result <- .get_cache(name)
  if (is.null(result)) {
    return(NULL)
  }
  result$value
}

#' Get a cached value
#' @param name The cache name
#' @return The cached value, or NULL if not found or hash mismatch
#' @export
get_cache <- cache_get

#' Get a value, caching the result
#' @param name The cache name
#' @param expr The expression to evaluate and cache
#' @return The result of expr
#' @export
get_and_cache <- function(name, expr) {
  # Always clear the cache first
  cache_forget(name)
  value <- eval(expr)
  cache(name, value)
  value
}

#' Get a value, caching the result
#' @param name The cache name
#' @param expr The expression to evaluate and cache
#' @return The result of expr
#' @export
get_or_cache <- function(name, expr) {
  result <- cache_get(name)
  if (!is.null(result)) {
    return(result)
  }
  value <- eval(expr)
  cache(name, value)
  value
}
