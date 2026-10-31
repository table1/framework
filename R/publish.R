#' @title Publishing Functions
#' @description Functions for publishing notebooks, data, and files to S3
#'   storage or Framework Cloud.
#' @name publish
NULL

# Uploads are the user's choice, so private paths warn rather than refuse.
# Every file that would be uploaded is checked: one whose absolute path
# contains "private", in any case, counts. A leading /private/ is skipped
# because macOS resolves /tmp, /var, and /etc there, so tempdir() would
# always match. Interactive sessions ask, defaulting to No, and scripts stop
# unless include_private = TRUE. framework-py and fw apply the same rule.
#' @keywords internal
.fw_confirm_private <- function(source, include_private = FALSE) {
  if (isTRUE(include_private)) {
    return(invisible(TRUE))
  }
  paths <- source
  if (dir.exists(source)) {
    paths <- c(source, list.files(source, recursive = TRUE, full.names = TRUE))
  }
  paths <- normalizePath(paths, winslash = "/", mustWork = FALSE)
  flagged <- paths[grepl("private", sub("^/private/", "/", paths), ignore.case = TRUE)]
  if (length(flagged) == 0) {
    return(invisible(TRUE))
  }
  shown <- utils::head(flagged, 5)
  if (length(flagged) > 5) {
    shown <- c(shown, sprintf("... and %d more", length(flagged) - 5))
  }
  warning(
    "These paths have \"private\" in them, so they may hold restricted data:\n",
    paste0("  ", shown, collapse = "\n"),
    call. = FALSE, immediate. = TRUE
  )
  if (rlang::is_interactive()) {
    answer <- utils::askYesNo("Upload them anyway?", default = FALSE)
    if (isTRUE(answer)) {
      return(invisible(TRUE))
    }
    stop("Cancelled: nothing was published.", call. = FALSE)
  }
  stop(
    "Not publishing from a non-interactive session. ",
    "Pass include_private = TRUE to publish these paths.",
    call. = FALSE
  )
}

# Arguments that mean something only for buckets or Framework Cloud
#' @keywords internal
.fw_pages_reject <- function(dest = NULL, connection = NULL, slug = NULL) {
  given <- c(
    dest = !is.null(dest),
    connection = !is.null(connection),
    "slug = TRUE/FALSE" = is.logical(slug)
  )
  if (any(given)) {
    stop(
      "Not used with to = \"github\": ", paste(names(given)[given], collapse = ", "),
      ". Name the published folder with slug = \"...\".",
      call. = FALSE
    )
  }
}

# `slug` is a non-empty string, a flag, or NULL.
#' @keywords internal
.fw_assert_slug <- function(slug) {
  checkmate::assert(
    checkmate::check_null(slug),
    checkmate::check_flag(slug),
    checkmate::check_string(slug, min.chars = 1),
    .var.name = "slug"
  )
}

#' @keywords internal
.fw_warn_slug_ignored <- function(slug) {
  if (!is.null(slug)) {
    warning("`slug` applies to Framework Cloud only; ignored for storage buckets.", call. = FALSE)
  }
}

# Where publish() and publish_notebook() send output. A named connection or
# any configured storage bucket wins; otherwise a project set up from
# Framework Cloud publishes there.
#' @keywords internal
.fw_publish_target <- function(connection = NULL) {
  if (!is.null(connection) || .fw_has_storage_buckets()) {
    return("s3")
  }
  if (!is.null(.fw_project_token())) {
    return("cloud")
  }
  stop(
    "Nowhere to publish. Add a storage bucket in settings.yml, or set up this ",
    'project from Framework Cloud with setup("<project token>").

',
    "A storage bucket looks like this:

",
    "connections:
",
    "  storage_buckets:
",
    "    my_s3:
",
    "      bucket: my-bucket
",
    "      region: us-east-1
",
    "  default_storage_bucket: my_s3",
    call. = FALSE
  )
}

#' Publish files to S3 or Framework Cloud
#'
#' Upload files or directories to an S3 bucket. This is the generic publishing
#' function - use `publish_notebook()` for Quarto documents or `publish_data()`
#' for data files.
#'
#' With no `connection` and no storage bucket in settings.yml, a project set
#' up from Framework Cloud publishes to its server instead (the
#' `FW_CLOUD_URL` and `FW_PROJECT_TOKEN` in the project's `.env`). Each
#' publish to Framework Cloud adds a new version of the document. Documents
#' start private, shared by a private link; `slug` turns on a readable URL
#' (`/@handle/project/slug`).
#'
#' @param source Character. Local file or directory path to upload.
#' @param dest Character or NULL. Destination path in S3 bucket. If NULL,
#'   derives from source filename. On Framework Cloud, use `slug` instead;
#'   `dest` still names the document there when `slug` isn't a string, for
#'   older scripts.
#' @param connection Character or NULL. S3 connection name from config.yml.
#'   If NULL, uses the connection marked with `default: true`.
#' @param overwrite Logical. Whether to overwrite existing files. Default TRUE.
#' @param self_contained Logical. When publishing to Framework Cloud, whether
#'   to bundle an HTML file with its resources. Ignored for S3. Default TRUE.
#' @param include_private Logical. Skip the private-path check. When the
#'   absolute path of any file to upload contains "private" in any case
#'   (apart from the `/private/` macOS adds to `/tmp` and `/var`), Framework
#'   warns and, in an interactive session, asks before publishing (default No).
#'   In a non-interactive session it stops unless `include_private = TRUE`.
#' @param to Character or NULL. `"github"` publishes to the project's GitHub
#'   Pages site instead of a storage bucket or Framework Cloud: the document
#'   is copied to `published/<slug>/index.html` (with its `<name>_files/`
#'   folder), only that folder is committed, and the commit is pushed. The
#'   site deploys from the default branch once "Publish with GitHub Pages" is
#'   on for the project in Framework Cloud, and it is public even when the
#'   repository is private, so an interactive session asks first. `slug`
#'   names the folder: lowercase letters, digits, `.`, `_`, and `-`. The
#'   default is the file name lowercased, with other characters as `-`
#'   ("Final Report (v2).html" becomes `final-report-v2`). A folder needs an
#'   `index.html` at its top. `dest`, `connection`, and a `TRUE`/`FALSE`
#'   `slug` are errors here.
#' @param slug Framework Cloud only. A string names the document and turns on
#'   its readable URL, for example `slug = "main-results"`. `TRUE` turns the
#'   readable URL on with the name derived from `dest` or the file name, and
#'   `FALSE` turns it off. `NULL` (the default) publishes under the derived
#'   name and leaves the document's setting as it is (new documents start
#'   private). Ignored, with a warning, for S3. With `to = "github"`, a
#'   string names the folder under `published/`.
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
#'
#' # Framework Cloud: a new version with a readable URL
#' publish("outputs/report.html", slug = "main-results")
#'
#' # GitHub Pages: commits published/main-results/ and pushes it
#' publish("outputs/report.html", to = "github", slug = "main-results")
#' }
#' }
publish <- function(source, dest = NULL, connection = NULL, overwrite = TRUE,
                    self_contained = TRUE, slug = NULL, include_private = FALSE,
                    to = NULL) {
  checkmate::assert_string(source, min.chars = 1)
  checkmate::assert_string(dest, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(overwrite)
  checkmate::assert_flag(self_contained)
  .fw_assert_slug(slug)
  checkmate::assert_flag(include_private)

  if (!file.exists(source) && !dir.exists(source)) {
    stop(sprintf("Source not found: %s", source), call. = FALSE)
  }
  checkmate::assert_choice(to, "github", null.ok = TRUE)
  .fw_confirm_private(source, include_private)

  if (identical(to, "github")) {
    .fw_pages_reject(dest = dest, connection = connection, slug = slug)
    return(.fw_github_publish(source, slug = slug, self_contained = self_contained))
  }
  if (identical(.fw_publish_target(connection), "cloud")) {
    return(.fw_cloud_publish(source, dest = dest, self_contained = self_contained, slug = slug))
  }
  .fw_warn_slug_ignored(slug)

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


#' Publish a Quarto notebook to S3 or Framework Cloud
#'
#' Renders a Quarto document and uploads it to S3. The notebook is rendered
#' to a temporary directory, uploaded, then cleaned up.
#'
#' Publishing follows [publish()]: a named `connection` or a configured
#' storage bucket comes first, then Framework Cloud when the project was set
#' up from it. Framework Cloud takes HTML output only, adds a new version on
#' each publish, and uses `slug` as [publish()] does.
#'
#' The URL format depends on the S3 connection's `static_hosting` setting:
#' - `static_hosting: true` -> uploads to `dest/index.html`, returns `dest/`
#' - `static_hosting: false` (default) -> uploads as `dest.html`, returns `dest.html`
#'
#' @param file Character. Path to .qmd file.
#' @param dest Character or NULL. Destination path in S3 (without extension).
#'   If NULL, derives from filename (e.g., "analysis.qmd" -> "analysis"). On
#'   Framework Cloud, use `slug` instead.
#' @param connection Character or NULL. S3 connection name, or NULL for default.
#' @param self_contained Logical. Whether to embed all resources. Default TRUE.
#'   Ignored if `static_hosting: false` (always renders self-contained).
#' @param format Character. Output format. Default "html".
#' @param include_private Logical. Skip the private-path check. When the
#'   absolute path of any file to upload contains "private" in any case
#'   (apart from the `/private/` macOS adds to `/tmp` and `/var`), Framework
#'   warns and, in an interactive session, asks before publishing (default No).
#'   In a non-interactive session it stops unless `include_private = TRUE`.
#' @param slug Framework Cloud only: name the document and turn on its
#'   readable URL. See [publish()]. With `to = "github"`, names the folder
#'   under `published/`.
#' @param to Character or NULL. `"github"` publishes the rendered HTML to the
#'   project's GitHub Pages site. See [publish()].
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
                             slug = NULL,
                             include_private = FALSE,
                             to = NULL,
                             ...) {
  checkmate::assert_file_exists(file, extension = c("qmd", "Qmd", "QMD"))
  checkmate::assert_string(dest, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(self_contained)
  checkmate::assert_string(format, min.chars = 1)
  .fw_assert_slug(slug)
  checkmate::assert_flag(include_private)
  checkmate::assert_choice(to, "github", null.ok = TRUE)
  .fw_confirm_private(file, include_private)

  if (identical(to, "github")) {
    if (!identical(format, "html")) {
      stop("GitHub Pages publishes HTML only (got format = \"", format, "\").", call. = FALSE)
    }
    .fw_pages_reject(dest = dest, connection = connection, slug = slug)
    return(.fw_github_publish(file, slug = slug, self_contained = self_contained))
  }

  # Check quarto is available
  quarto_path <- Sys.which("quarto")
  if (nchar(quarto_path) == 0) {
    stop("Quarto not found. Install from https://quarto.org/docs/get-started/", call. = FALSE)
  }

  if (identical(.fw_publish_target(connection), "cloud")) {
    if (!identical(format, "html")) {
      stop("Framework Cloud publishes HTML only (got format = \"", format, "\").", call. = FALSE)
    }
    return(.fw_cloud_publish(file, dest = dest, self_contained = self_contained, slug = slug))
  }
  .fw_warn_slug_ignored(slug)

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
#' @param include_private Logical. Skip the private-path check. When the
#'   absolute path of any file to upload contains "private" in any case
#'   (apart from the `/private/` macOS adds to `/tmp` and `/var`), Framework
#'   warns and, in an interactive session, asks before publishing (default No).
#'   In a non-interactive session it stops unless `include_private = TRUE`.
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
                         compress = FALSE,
                         include_private = FALSE) {
  checkmate::assert_string(dest, min.chars = 1)
  checkmate::assert_choice(format, c("csv", "rds", "parquet", "json"))
  checkmate::assert_string(connection, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(compress)
  checkmate::assert_flag(include_private)
  if (is.character(data)) .fw_confirm_private(data, include_private)

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
#' @param include_private Logical. Skip the private-path check. When the
#'   absolute path of any file to upload contains "private" in any case
#'   (apart from the `/private/` macOS adds to `/tmp` and `/var`), Framework
#'   warns and, in an interactive session, asks before publishing (default No).
#'   In a non-interactive session it stops unless `include_private = TRUE`.
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
                        recursive = TRUE,
                        include_private = FALSE) {
  checkmate::assert_directory_exists(dir)
  checkmate::assert_flag(include_private)
  .fw_confirm_private(dir, include_private)
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
