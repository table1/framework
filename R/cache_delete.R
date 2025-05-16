#' Remove a cache value
#' @param name The cache name to remove
#' @keywords internal
.remove_cache <- function(name) {
  # Remove RDS file
  cache_file <- file.path("data/cached", paste0(name, ".rds"))
  if (file.exists(cache_file)) {
    unlink(cache_file)
  }

  # Remove database record
  con <- .get_db_connection()
  DBI::dbExecute(con, "DELETE FROM cache WHERE name = ?", list(name))
  DBI::dbDisconnect(con)
}

#' Remove a cached value
#' @param name The cache name to remove
#' @export
cache_forget <- function(name) {
  .remove_cache(name)
  invisible(NULL)
}

#' Clear all cached values
#' @export
clear_cache <- function() {
  # Remove all RDS files
  cache_dir <- "data/cached"
  if (dir.exists(cache_dir)) {
    unlink(file.path(cache_dir, "*.rds"))
  }

  # Clear database records
  con <- .get_db_connection()
  DBI::dbExecute(con, "DELETE FROM cache")
  DBI::dbDisconnect(con)
  invisible(NULL)
}

#' Remove a cached value
#' @param name The cache name to remove
#' @export
forget_cache <- function(name) {
  cache_forget(name)
}

#' Remove a cached value
#' @param name The cache name to remove
#' @export
remove_cache <- function(name) {
  cache_forget(name)
}

#' Remove a cached value
#' @param name The cache name to remove
#' @export
uncache <- function(name) {
  cache_forget(name)
}
