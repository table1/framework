#' Set a cache value
#' @param name The cache name
#' @param value The value to cache (will be evaluated if it's an expression)
#' @keywords internal
.set_cache <- function(name, value) {
  # Evaluate the value if it's an expression
  if (is.call(value) || is.expression(value)) {
    value <- eval(value)
  }

  # Create cache directory if it doesn't exist
  cache_dir <- "data/cached"
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  # Save value to RDS file
  cache_file <- file.path(cache_dir, paste0(name, ".rds"))
  saveRDS(value, cache_file)

  # Calculate hash from file
  hash <- .calculate_file_hash(cache_file)

  # Update database record with just metadata
  con <- .get_db_connection()
  now <- lubridate::now()

  if (DBI::dbExistsTable(con, "cache")) {
    # Check if entry exists
    entry_exists <- DBI::dbGetQuery(con, "SELECT 1 FROM cache WHERE name = ?", list(name))

    if (nrow(entry_exists) > 0) {
      # Update existing entry
      DBI::dbExecute(
        con,
        "UPDATE cache SET hash = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
        list(as.character(hash), now, now, name)
      )
    } else {
      # Insert new entry
      DBI::dbExecute(
        con,
        "INSERT INTO cache (name, hash, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
        list(name, as.character(hash), now, now, now)
      )
    }
  }

  DBI::dbDisconnect(con)
  value
}


#' Cache a value
#' @param name The cache name
#' @param value The value to cache (will be evaluated if it's an expression)
#' @return The cached value
#' @export
cache <- function(name, value) {
  .set_cache(name, value)
}
