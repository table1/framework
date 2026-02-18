#' @title Publishing Functions
#' @description Functions for publishing notebooks, data, and files to S3 storage.
#' @name publish
NULL

#' Publish files to S3
#'
#' Upload files or directories to an S3 bucket. This is the generic publishing
#' function - use `publish_notebook()` for Quarto documents or `publish_data()`
#' for data files.
#'
#' @param source Character. Local file or directory path to upload.
#' @param dest Character or NULL. Destination path in S3 bucket. If NULL,
#'   derives from source filename.
#' @param connection Character or NULL. S3 connection name from config.yml.
#'   If NULL, uses the connection marked with `default: true`.
#' @param overwrite Logical. Whether to overwrite existing files. Default TRUE.
#' @return Character. The public URL(s) of uploaded file(s).
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # Upload a single file
#' publish("outputs/report.html")
#' # -> https://bucket.s3.region.amazonaws.com/prefix/report.html
#'
#' # Upload with custom destination
#' publish("outputs/report.html", dest = "reports/q4-2024.html")
#'
#' # Upload a directory
#' publish("outputs/charts/", dest = "reports/charts/")
#'
#' # Use specific connection
#' publish("data.csv", connection = "s3_backup")
#' }
#' }
publish <- function(source, dest = NULL, connection = NULL, overwrite = TRUE) {
  checkmate::assert_string(source, min.chars = 1)
  checkmate::assert_string(dest, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(overwrite)

  if (!file.exists(source) && !dir.exists(source)) {
    stop(sprintf("Source not found: %s", source), call. = FALSE)
  }

  # Resolve S3 connection
  s3_config <- .resolve_s3_connection(connection)

  # Determine destination
  if (is.null(dest)) {
    dest <- basename(source)
  }

  # Upload file or directory
  if (dir.exists(source)) {
    urls <- .s3_upload_dir(source, dest, s3_config)
    message(sprintf("Published %d files to S3", length(urls)))
  } else {
    urls <- .s3_upload_file(source, dest, s3_config)
    message(sprintf("Published: %s", urls))
  }

  invisible(urls)
}


#' Publish a Quarto notebook to S3
#'
#' Renders a Quarto document and uploads it to S3. The notebook is rendered
#' to a temporary directory, uploaded, then cleaned up.
#'
#' The URL format depends on the S3 connection's `static_hosting` setting:
#' - `static_hosting: true` -> uploads to `dest/index.html`, returns `dest/`
#' - `static_hosting: false` (default) -> uploads as `dest.html`, returns `dest.html`
#'
#' @param file Character. Path to .qmd file.
#' @param dest Character or NULL. Destination path in S3 (without extension).
#'   If NULL, derives from filename (e.g., "analysis.qmd" -> "analysis").
#' @param connection Character or NULL. S3 connection name, or NULL for default.
#' @param self_contained Logical. Whether to embed all resources. Default TRUE.
#'   Ignored if `static_hosting: false` (always renders self-contained).
#' @param format Character. Output format. Default "html".
#' @param ... Additional arguments passed to quarto render.
#' @return Character. Public URL of the published notebook.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # With static_hosting: true -> returns /analysis/
#' # With static_hosting: false -> returns /analysis.html
#' publish_notebook("notebooks/analysis.qmd")
#'
#' # Publish to specific location
#' publish_notebook("notebooks/analysis.qmd", dest = "reports/2024/q4")
#'
#' # Publish non-self-contained (only with static_hosting: true)
#' publish_notebook("notebooks/analysis.qmd", self_contained = FALSE)
#' }
#' }
publish_notebook <- function(file,
                             dest = NULL,
                             connection = NULL,
                             self_contained = TRUE,
                             format = "html",
                             ...) {
  checkmate::assert_file_exists(file, extension = c("qmd", "Qmd", "QMD"))
  checkmate::assert_string(dest, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(self_contained)
  checkmate::assert_string(format, min.chars = 1)

  # Check quarto is available
  quarto_path <- Sys.which("quarto")
  if (nchar(quarto_path) == 0) {
    stop("Quarto not found. Install from https://quarto.org/docs/get-started/", call. = FALSE)
  }

  # Resolve S3 connection early to fail fast
  s3_config <- .resolve_s3_connection(connection)

  # Determine behavior based on static_hosting
  static_hosting <- isTRUE(s3_config$static_hosting)

  # Without static hosting, always use self-contained single file
  if (!static_hosting) {
    self_contained <- TRUE
  }

  # Create temp directory for output
  temp_dir <- tempfile("publish_notebook_")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Build quarto render command
  args <- c(
    "render",
    shQuote(normalizePath(file)),
    "--output-dir", shQuote(temp_dir),
    "--to", format
  )

  if (self_contained) {
    args <- c(args, "--embed-resources")
  }

  # Execute render
  message(sprintf("Rendering %s...", basename(file)))
  result <- system2(quarto_path, args, stdout = TRUE, stderr = TRUE)

  # Check for errors
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    stop("Quarto render failed:\n", paste(result, collapse = "\n"), call. = FALSE)
  }

  # Find the output file
  output_files <- list.files(temp_dir, pattern = "\\.html$", full.names = TRUE)
  if (length(output_files) == 0) {
    stop("No HTML output found after rendering", call. = FALSE)
  }

  main_output <- output_files[1]

  # Determine base destination (without extension)
  if (is.null(dest)) {
    base_dest <- tools::file_path_sans_ext(basename(file))
  } else {
    # Strip any trailing slash or .html extension from user-provided dest
    base_dest <- sub("/$", "", dest)
    base_dest <- sub("\\.html$", "", base_dest)
  }

  # Upload based on static_hosting setting
  if (static_hosting) {
    # Static hosting: upload to dest/index.html, return dest/
    upload_path <- paste0(base_dest, "/index.html")

    if (self_contained) {
      url <- .s3_upload_file(main_output, upload_path, s3_config)
    } else {
      # Upload entire directory (including _files folder)
      # Rename main file to index.html if needed
      if (basename(main_output) != "index.html") {
        new_path <- file.path(temp_dir, "index.html")
        file.rename(main_output, new_path)
      }
      urls <- .s3_upload_dir(temp_dir, base_dest, s3_config)
      url <- urls[grepl("index\\.html$", urls)][1]
      message(sprintf("Published %d files", length(urls)))
    }

    # Return clean directory URL (without index.html)
    clean_url <- .s3_public_url(paste0(base_dest, "/"), s3_config)
    message(sprintf("Published: %s", clean_url))
    invisible(clean_url)

  } else {
    # No static hosting: upload as dest.html, return dest.html
    upload_path <- paste0(base_dest, ".html")
    url <- .s3_upload_file(main_output, upload_path, s3_config)
    message(sprintf("Published: %s", url))
    invisible(url)
  }
}


#' Publish data to S3
#'
#' Uploads a data frame or existing data file to S3.
#'
#' @param data Data frame or character path to existing file.
#' @param dest Character. Destination path in S3 (required for data frames).
#' @param format Character. Output format when `data` is a data frame:
#'   "csv", "rds", "parquet", or "json". Default "csv".
#' @param connection Character or NULL. S3 connection name, or NULL for default.
#' @param compress Logical. Whether to gzip compress. Default FALSE.
#' @return Character. Public URL of the published data.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # Publish a data frame
#' publish_data(my_df, "datasets/customers.csv")
#'
#' # Publish as RDS
#' publish_data(my_df, "datasets/customers.rds", format = "rds")
#'
#' # Publish existing file
#' publish_data("outputs/model.rds", "models/v2/model.rds")
#' }
#' }
publish_data <- function(data,
                         dest,
                         format = "csv",
                         connection = NULL,
                         compress = FALSE) {
  checkmate::assert_string(dest, min.chars = 1)
  checkmate::assert_choice(format, c("csv", "rds", "parquet", "json"))
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(compress)

  # Resolve S3 connection
  s3_config <- .resolve_s3_connection(connection)

  # Handle data frame vs file path
  if (is.data.frame(data)) {
    # Write to temp file
    temp_file <- tempfile(fileext = paste0(".", format))
    on.exit(unlink(temp_file), add = TRUE)

    switch(format,
      csv = readr::write_csv(data, temp_file),
      rds = saveRDS(data, temp_file),
      parquet = {
        if (!requireNamespace("arrow", quietly = TRUE)) {
          stop("Package 'arrow' required for parquet format. Install with: install.packages('arrow')")
        }
        arrow::write_parquet(data, temp_file)
      },
      json = jsonlite::write_json(data, temp_file)
    )

    source_file <- temp_file
  } else if (is.character(data) && length(data) == 1) {
    if (!file.exists(data)) {
      stop(sprintf("File not found: %s", data), call. = FALSE)
    }
    source_file <- data
  } else {
    stop("'data' must be a data frame or file path", call. = FALSE)
  }

  # Compress if requested
  if (compress) {
    compressed_file <- paste0(source_file, ".gz")
    R.utils::gzip(source_file, compressed_file, remove = FALSE)
    source_file <- compressed_file
    on.exit(unlink(compressed_file), add = TRUE)
    if (!grepl("\\.gz$", dest)) {
      dest <- paste0(dest, ".gz")
    }
  }

  # Upload
  url <- .s3_upload_file(source_file, dest, s3_config)
  message(sprintf("Published: %s", url))

  invisible(url)
}


#' Publish a directory to S3
#'
#' Recursively uploads all files in a directory to S3.
#'
#' @param dir Character. Local directory path.
#' @param dest Character or NULL. Destination prefix in S3. If NULL, uses
#'   the directory name.
#' @param connection Character or NULL. S3 connection name, or NULL for default.
#' @param pattern Character or NULL. Optional regex pattern to filter files.
#' @param recursive Logical. Whether to include subdirectories. Default TRUE.
#' @return Character vector. Public URLs of uploaded files.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # Upload entire directory
#' publish_dir("outputs/dashboard/")
#'
#' # Upload to specific location
#' publish_dir("outputs/dashboard/", dest = "dashboards/v2/")
#'
#' # Upload only HTML files
#' publish_dir("outputs/", pattern = "\\.html$")
#' }
#' }
publish_dir <- function(dir,
                        dest = NULL,
                        connection = NULL,
                        pattern = NULL,
                        recursive = TRUE) {
  checkmate::assert_directory_exists(dir)
  checkmate::assert_string(dest, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(pattern, null.ok = TRUE)
  checkmate::assert_flag(recursive)

  # Resolve S3 connection
  s3_config <- .resolve_s3_connection(connection)

  # Determine destination
  if (is.null(dest)) {
    dest <- basename(normalizePath(dir))
  }

  # List files
  files <- list.files(dir, recursive = recursive, full.names = TRUE)

  if (!is.null(pattern)) {
    files <- files[grepl(pattern, files)]
  }

  # Filter to actual files (not directories)
  files <- files[file.info(files)$isdir == FALSE]

  if (length(files) == 0) {
    warning("No files found to upload")
    return(invisible(character(0)))
  }

  # Upload each file
  message(sprintf("Uploading %d files...", length(files)))
  urls <- character(length(files))

  for (i in seq_along(files)) {
    rel_path <- sub(paste0("^", normalizePath(dir), "/?"), "", normalizePath(files[i]))
    file_dest <- file.path(dest, rel_path)
    urls[i] <- .s3_upload_file(files[i], file_dest, s3_config)
  }

  message(sprintf("Published %d files to %s", length(urls), dest))

  invisible(urls)
}


#' List published files in S3
#'
#' Lists files in an S3 bucket/prefix.
#'
#' @param prefix Character or NULL. Prefix to filter by. If NULL, lists all
#'   files under the connection's configured prefix.
#' @param connection Character or NULL. S3 connection name, or NULL for default.
#' @param max Integer. Maximum number of files to list. Default 1000.
#' @return Data frame with columns: key, size, last_modified.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (FALSE) {
#' # List all published files
#' publish_list()
#'
#' # List files under a prefix
#' publish_list("reports/")
#'
#' # List from specific connection
#' publish_list(connection = "s3_backup")
#' }
#' }
publish_list <- function(prefix = NULL, connection = NULL, max = 1000L) {
  checkmate::assert_string(prefix, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_integerish(max, lower = 1)

  if (!requireNamespace("aws.s3", quietly = TRUE)) {
    stop("Package 'aws.s3' required. Install with: install.packages('aws.s3')")
  }

  # Resolve S3 connection
  s3_config <- .resolve_s3_connection(connection)

  # Build full prefix
  full_prefix <- if (!is.null(prefix)) {
    if (nchar(s3_config$prefix) > 0) {
      paste0(s3_config$prefix, "/", prefix)
    } else {
      prefix
    }
  } else {
    s3_config$prefix
  }

  # Set credentials
  withr::local_envvar(
    AWS_ACCESS_KEY_ID = s3_config$access_key,
    AWS_SECRET_ACCESS_KEY = s3_config$secret_key,
    AWS_DEFAULT_REGION = s3_config$region
  )

  if (!is.null(s3_config$session_token)) {
    withr::local_envvar(AWS_SESSION_TOKEN = s3_config$session_token)
  }

  base_url <- if (!is.null(s3_config$endpoint)) s3_config$endpoint else NULL

  # List objects
  result <- tryCatch({
    aws.s3::get_bucket(
      bucket = s3_config$bucket,
      prefix = full_prefix,
      max = max,
      base_url = base_url,
      region = s3_config$region
    )
  }, error = function(e) {
    stop(sprintf("Failed to list S3 objects: %s", e$message), call. = FALSE)
  })

  # Convert to data frame
  if (length(result) == 0) {
    return(data.frame(
      key = character(0),
      size = numeric(0),
      last_modified = character(0),
      url = character(0),
      stringsAsFactors = FALSE
    ))
  }

  df <- data.frame(
    key = vapply(result, function(x) x$Key, character(1)),
    size = vapply(result, function(x) as.numeric(x$Size), numeric(1)),
    last_modified = vapply(result, function(x) x$LastModified, character(1)),
    stringsAsFactors = FALSE
  )

  # Add URLs
  df$url <- vapply(df$key, function(k) .s3_public_url(k, s3_config), character(1))

  df
}
