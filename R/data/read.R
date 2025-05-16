#' Load data using dot notation path
#'
#' @param path Dot notation path to load data (e.g. "source.private.example")
#' @export
load_data <- function(path) {
  # Get data specification from config
  spec <- get_data_spec(path)
  if (is.null(spec)) {
    stop(sprintf("No data specification found for path: %s", path))
  }

  # Check if file exists
  if (!file.exists(spec$path)) {
    stop(sprintf("File not found: %s", spec$path))
  }

  # Calculate file hash
  file_hash <- digest::digest(spec$path, algo = "sha256", file = TRUE)

  # Check if data is locked
  if (spec$locked) {
    # Get existing data record
    data_record <- .get_data_record(path)
    if (is.null(data_record)) {
      # If no record exists, create one with the current hash
      .update_data(path, file_hash, "data")
    } else {
      # If record exists, ensure hash matches
      if (data_record$hash != file_hash) {
        stop(sprintf("Hash mismatch for locked data: %s", path))
      }
    }
  } else {
    # Update data hash and timestamp
    .update_data(path, file_hash, "data")
  }

  # Load data based on type
  switch(spec$type,
    csv = {
      # Convert delimiter name to actual character
      delim <- switch(spec$delimiter,
        comma = ",",
        tab = "\t",
        semicolon = ";",
        space = " "
      )
      readr::read_csv(spec$path, show_col_types = FALSE)
    },
    rds = readRDS(spec$path),
    stop(sprintf("Unsupported file type: %s", spec$type))
  )
}

#' Get data specification from config
#'
#' Gets the data specification for a given dot notation path
#' @param path Dot notation path (e.g. "source.private.example")
#' @return The data specification as a list
#' @export
get_data_spec <- function(path) {
  config <- read_config()
  parts <- strsplit(path, "\\.")[[1]]

  # Navigate through config to find data specification
  current <- config$default$data
  for (part in parts) {
    if (is.null(current[[part]])) {
      return(NULL)
    }
    current <- current[[part]]
  }

  current
}


#' Get a data value
#' @param name The data name
#' @param key Encryption key (required if data is encrypted)
#' @return The data value, or NULL if not found
#' @keywords internal
.get_data_record <- function(name, key = NULL) {
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT encrypted, hash FROM data WHERE name = ?",
    list(name)
  )
  DBI::dbDisconnect(con)

  if (nrow(result) == 0) {
    return(NULL)
  }

  result
}
