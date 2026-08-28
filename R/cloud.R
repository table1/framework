# Cloud client for framework.pub
#
# Standalone-first: everything here is opt-in. With no token present, every
# cloud-aware code path falls back to local defaults and the package behaves
# exactly as it always has. HTTP is done via httr2, which is in Suggests --
# cloud functions error with installation guidance when it is missing.

#' @keywords internal
.fw_cloud_url <- function() {
  sub("/+$", "", Sys.getenv("FW_CLOUD_URL", "https://framework.pub"))
}

# The fixed, cross-platform token location. `~` expands on macOS, Linux, and
# Windows alike, so this is the same literal path everywhere. Overridable via
# FW_TOKEN_FILE; FW_CLOUD_TOKEN skips the file entirely (CI).
#' @keywords internal
.fw_token_path <- function() {
  override <- Sys.getenv("FW_TOKEN_FILE", "")
  if (nzchar(override)) {
    return(path.expand(override))
  }
  path.expand(file.path("~", ".secrets", "framework", "token"))
}

#' @keywords internal
.fw_cloud_token <- function() {
  env_token <- Sys.getenv("FW_CLOUD_TOKEN", "")
  if (nzchar(env_token)) {
    return(env_token)
  }

  path <- .fw_token_path()
  if (file.exists(path)) {
    token <- trimws(readLines(path, n = 1L, warn = FALSE)[1])
    if (!is.na(token) && nzchar(token)) {
      return(token)
    }
  }

  NULL
}

#' @keywords internal
.fw_api <- function(path, token, method = "GET", body = NULL) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop(
      "Cloud features require the 'httr2' package. ",
      'Install it with install.packages("httr2").',
      call. = FALSE
    )
  }

  req <- httr2::request(paste0(.fw_cloud_url(), path))
  req <- httr2::req_auth_bearer_token(req, token)
  req <- httr2::req_headers(req, Accept = "application/json")
  req <- httr2::req_user_agent(
    req,
    paste0("framework-r/", as.character(utils::packageVersion("framework")))
  )

  if (!identical(method, "GET")) {
    req <- httr2::req_method(req, method)
  }
  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body)
  }

  # Local development against Herd's self-signed framework.test certificate
  if (nzchar(Sys.getenv("FW_CLOUD_INSECURE", ""))) {
    req <- httr2::req_options(req, ssl_verifypeer = 0, ssl_verifyhost = 0)
  }

  req <- httr2::req_error(req, body = function(resp) {
    msg <- tryCatch(
      httr2::resp_body_json(resp)$message,
      error = function(e) NULL
    )
    msg %||% paste0("Cloud request failed (HTTP ", httr2::resp_status(resp), ")")
  })

  httr2::resp_body_json(httr2::req_perform(req))
}

#' @keywords internal
.fw_require_token <- function() {
  token <- .fw_cloud_token()
  if (is.null(token)) {
    stop(
      "No cloud token found. Create one at ", .fw_cloud_url(), "/tokens and run:\n",
      '  cloud_login("fw_...")\n',
      "or: curl -fsSL ", .fw_cloud_url(), "/install.sh | bash -s -- 'fw_...'",
      call. = FALSE
    )
  }
  token
}

#' Log In to framework.pub
#'
#' Verifies a user token against the cloud and stores it at the fixed
#' cross-platform location (`~/.secrets/framework/token`) that all framework
#' cloud features read. Equivalent to the `install.sh` one-liner.
#'
#' @param token Your user token from framework.pub (starts with a number,
#'   contains `fw_`).
#' @param verify Check the token against the cloud before saving (default TRUE).
#'
#' @return Invisibly, the token file path.
#'
#' @seealso [cloud_status()], [cloud_settings()]
#' @export
cloud_login <- function(token, verify = TRUE) {
  checkmate::assert_string(token, min.chars = 10)

  if (verify) {
    me <- .fw_api("/api/v1/me", token = token)
    message("[ok] Token verified: ", me$email %||% me$project %||% "authenticated")
  }

  path <- .fw_token_path()
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  Sys.chmod(dirname(path), mode = "0700")
  writeLines(token, path)
  Sys.chmod(path, mode = "0600")

  message("[ok] Token saved to ", path)
  invisible(path)
}

#' Check Cloud Connection Status
#'
#' Reports whether a cloud token is configured and, if so, who it
#' authenticates as.
#'
#' @return Invisibly, TRUE if connected, FALSE otherwise.
#'
#' @export
cloud_status <- function() {
  token <- .fw_cloud_token()

  if (is.null(token)) {
    message("Not connected. No token at ", .fw_token_path())
    return(invisible(FALSE))
  }

  me <- tryCatch(
    .fw_api("/api/v1/me", token = token),
    error = function(e) {
      message("Token found but cloud unreachable or token invalid: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(me)) {
    return(invisible(FALSE))
  }

  message("Connected to ", .fw_cloud_url(), " as ", me$email %||% me$project)
  invisible(TRUE)
}

#' Fetch Your Cloud Settings
#'
#' Retrieves your settings document from framework.pub. These settings are
#' overlaid on local defaults when creating projects with [new()].
#'
#' @return A list with `revision`, `schema_version`, and `document`.
#'
#' @export
cloud_settings <- function() {
  .fw_api("/api/v1/settings", token = .fw_require_token())
}

# Fetch cloud settings without failing: falls back to the locally cached
# mirror (written by cloud_sync()) when offline, then to NULL -- callers fall
# back to local defaults (the standalone guarantee).
#' @keywords internal
.fw_cloud_settings_quietly <- function() {
  token <- .fw_cloud_token()
  if (is.null(token)) {
    return(NULL)
  }

  tryCatch(
    {
      res <- .fw_api("/api/v1/settings", token = token)
      message("[ok] Using your framework.pub settings (revision ", res$revision, ")")
      res$document
    },
    error = function(e) {
      cached <- .fw_sync_paths()$document
      if (file.exists(cached)) {
        message("Cloud unreachable (", conditionMessage(e), "). Using cached cloud settings.")
        return(yaml::read_yaml(cached))
      }
      message("Cloud unreachable (", conditionMessage(e), "). Using local defaults.")
      NULL
    }
  )
}

# --- Cloud project registration ------------------------------------------

# Write the project's pull token into its .env (gitignored) so publish() and
# collaborators' setup() can find it. Never touches settings.yml -- the token
# is a secret.
#' @keywords internal
.fw_write_project_token <- function(project_dir, token) {
  env_path <- file.path(project_dir, ".env")
  if (file.exists(env_path)) {
    lines <- readLines(env_path, warn = FALSE)
    if (any(grepl("^FW_PROJECT_TOKEN=", lines))) {
      return(invisible(FALSE))
    }
    lines <- c(lines, "", "# framework.pub project key (created by framework::new)",
               paste0("FW_PROJECT_TOKEN=", token))
    writeLines(lines, env_path)
  } else {
    writeLines(c("# framework.pub project key (created by framework::new)",
                 paste0("FW_PROJECT_TOKEN=", token)), env_path)
  }
  message("  Added: FW_PROJECT_TOKEN to .env")
  invisible(TRUE)
}

# Register a locally created project on framework.pub and store its key.
# Quiet by design: offline or name-taken just means no cloud registration.
#' @keywords internal
.fw_cloud_register_project <- function(project_dir, name, type) {
  token <- .fw_cloud_token()
  if (is.null(token)) {
    return(invisible(NULL))
  }

  res <- tryCatch(
    .fw_api(
      "/api/v1/projects", token = token, method = "POST",
      body = list(name = name, project_type = type)
    ),
    error = function(e) {
      message("Cloud project registration skipped: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(res)) {
    return(invisible(NULL))
  }

  message("[ok] Registered on framework.pub: ", res$project$slug)
  .fw_write_project_token(project_dir, res$pull_token)
  invisible(res)
}

# --- Cloud publishing ----------------------------------------------------

# The project's cloud key: env var (set by dotenv on scaffold()) first, then
# a direct read of ./.env for pre-scaffold sessions.
#' @keywords internal
.fw_project_token <- function(project_dir = ".") {
  env_token <- Sys.getenv("FW_PROJECT_TOKEN", "")
  if (nzchar(env_token)) {
    return(env_token)
  }

  env_path <- file.path(project_dir, ".env")
  if (file.exists(env_path)) {
    lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^FW_PROJECT_TOKEN=", lines, value = TRUE)
    if (length(hit) > 0) {
      token <- sub("^FW_PROJECT_TOKEN=", "", hit[1])
      token <- gsub('^["\']|["\']$', "", trimws(token))
      if (nzchar(token)) {
        return(token)
      }
    }
  }

  NULL
}

# Does this project have any storage bucket configured? Errors (no project,
# no settings) mean no.
#' @keywords internal
.fw_has_storage_buckets <- function() {
  tryCatch(
    {
      config <- settings_read()
      length(.collect_all_s3_connections(config)$connections %||% list()) > 0
    },
    error = function(e) FALSE
  )
}

# Zip a directory's contents (relative paths) for bundle upload
#' @keywords internal
.fw_zip_dir <- function(dir) {
  zipfile <- tempfile("fw_bundle_", fileext = ".zip")
  old_wd <- setwd(dir)
  on.exit(setwd(old_wd), add = TRUE)
  files <- list.files(".", recursive = TRUE)
  if (length(files) == 0) {
    stop("Nothing to bundle in ", dir, call. = FALSE)
  }
  utils::zip(zipfile, files, flags = "-q9X")
  if (!file.exists(zipfile)) {
    stop("Failed to create bundle zip (is the 'zip' tool installed?)", call. = FALSE)
  }
  zipfile
}

# Publish a rendered document to framework.pub. Accepts:
#   - self-contained .html (single upload)
#   - .html with a sibling <name>_files/ directory (bundled automatically)
#   - a render output directory (bundled; entry = index.html or the one HTML)
#   - .qmd (rendered: embedded by default, full bundle when self_contained = FALSE)
#   - .Rmd (rendered self-contained)
#' @keywords internal
.fw_cloud_publish <- function(source, dest = NULL, title = NULL, self_contained = TRUE) {
  token <- .fw_project_token()
  ext <- tolower(tools::file_ext(source))
  html_path <- NULL
  bundle_dir <- NULL
  entrypoint <- NULL

  if (dir.exists(source)) {
    # A render output directory
    bundle_dir <- normalizePath(source)
    htmls <- list.files(bundle_dir, pattern = "\\.html?$")
    entrypoint <- if ("index.html" %in% htmls) "index.html" else htmls[1]
    if (is.na(entrypoint) || is.null(entrypoint)) {
      stop("No HTML file found at the top of ", source, call. = FALSE)
    }
  } else if (ext %in% c("qmd")) {
    quarto <- Sys.which("quarto")
    if (!nzchar(quarto)) {
      stop("Rendering requires the quarto CLI on your PATH.", call. = FALSE)
    }
    out_dir <- tempfile("fw_publish_")
    dir.create(out_dir)
    args <- c("render", shQuote(source), "--output-dir", shQuote(out_dir), "--to", "html")
    if (self_contained) {
      args <- c(args, "--embed-resources")
    }
    status <- system2(quarto, args)
    if (!identical(status, 0L)) {
      stop("Quarto render failed.", call. = FALSE)
    }
    htmls <- list.files(out_dir, pattern = "\\.html$")
    if (length(htmls) == 0) {
      stop("Quarto render produced no HTML output.", call. = FALSE)
    }
    if (self_contained) {
      html_path <- file.path(out_dir, htmls[1])
    } else {
      bundle_dir <- out_dir
      entrypoint <- htmls[1]
    }
  } else if (ext %in% c("rmd")) {
    if (!requireNamespace("rmarkdown", quietly = TRUE)) {
      stop("Rendering .Rmd requires the rmarkdown package.", call. = FALSE)
    }
    html_path <- rmarkdown::render(source, output_format = "html_document",
                                   output_dir = tempfile("fw_publish_"), quiet = TRUE)
  } else if (ext %in% c("html", "htm")) {
    # Quarto's default (non-embedded) output leaves assets in <name>_files/
    files_dir <- paste0(tools::file_path_sans_ext(source), "_files")
    if (dir.exists(files_dir)) {
      stage <- tempfile("fw_publish_")
      dir.create(stage)
      file.copy(source, file.path(stage, basename(source)))
      file.copy(files_dir, stage, recursive = TRUE)
      bundle_dir <- stage
      entrypoint <- basename(source)
    } else {
      html_path <- source
    }
  } else {
    stop(
      "framework.pub publishing takes rendered HTML, a render directory, ",
      "or a .qmd/.Rmd to render. Got: .", ext,
      call. = FALSE
    )
  }

  slug <- dest %||% tools::file_path_sans_ext(basename(source))
  slug <- sub("\\.html?$", "", slug)

  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop('Cloud publishing requires httr2. install.packages("httr2")', call. = FALSE)
  }

  req <- httr2::request(paste0(.fw_cloud_url(), "/api/v1/documents"))
  req <- httr2::req_auth_bearer_token(req, token)
  req <- httr2::req_headers(req, Accept = "application/json")

  if (!is.null(bundle_dir)) {
    zipfile <- .fw_zip_dir(bundle_dir)
    on.exit(unlink(zipfile), add = TRUE)
    message("Publishing bundle (", length(list.files(bundle_dir, recursive = TRUE)), " files)")
    body <- list(
      bundle = curl::form_file(zipfile, type = "application/zip"),
      entrypoint = entrypoint,
      slug = slug
    )
  } else {
    body <- list(
      file = curl::form_file(html_path, type = "text/html"),
      slug = slug
    )
  }
  if (!is.null(title)) {
    body$title <- title
  }
  req <- httr2::req_body_multipart(req, !!!body)
  if (nzchar(Sys.getenv("FW_CLOUD_INSECURE", ""))) {
    req <- httr2::req_options(req, ssl_verifypeer = 0, ssl_verifyhost = 0)
  }
  req <- httr2::req_error(req, body = function(resp) {
    tryCatch(httr2::resp_body_json(resp)$message, error = function(e) NULL) %||%
      paste0("Publish failed (HTTP ", httr2::resp_status(resp), ")")
  })

  res <- httr2::resp_body_json(httr2::req_perform(req))

  message("Published: ", res$url)
  invisible(res$url)
}

# --- Data integrity ledger -----------------------------------------------

# Push a digest to the project's cloud ledger after data_save(). Quiet by
# design: no project token, FW_LEDGER=off, or an unreachable cloud all mean
# "local only", never a failed save. The local framework.db stays canonical.
#' @keywords internal
.fw_ledger_push_quietly <- function(name, hash, size_bytes = NULL, file_path = NULL) {
  if (identical(tolower(Sys.getenv("FW_LEDGER", "")), "off")) {
    return(invisible(NULL))
  }

  # openssl hash objects carry an S3 class jsonlite won't serialize
  hash <- paste0(as.character(hash))
  if (!is.null(size_bytes)) {
    size_bytes <- as.numeric(size_bytes)
  }

  token <- .fw_project_token()
  if (is.null(token)) {
    return(invisible(NULL))
  }

  if (is.null(size_bytes) && !is.null(file_path) && file.exists(file_path)) {
    size_bytes <- file.size(file_path)
  }

  res <- tryCatch(
    .fw_api(
      "/api/v1/ledger", token = token, method = "POST",
      body = list(
        name = name,
        algo = "sha256",
        hash = hash,
        size_bytes = size_bytes,
        recorded_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
        client = list(
          device = Sys.info()[["nodename"]],
          package_version = as.character(utils::packageVersion("framework"))
        )
      )
    ),
    error = function(e) {
      message("Ledger push skipped: ", conditionMessage(e))
      NULL
    }
  )

  if (!is.null(res)) {
    message("[ok] Ledger entry #", res$sequence, " recorded on framework.pub")
  }

  invisible(res)
}

#' Verify a Dataset Against the Integrity Ledger
#'
#' Hashes the file behind a catalog name and compares it against the local
#' framework.db record and the project's cloud ledger on framework.pub.
#' Proves "the data I have is bit-identical to what was recorded" without the
#' data ever leaving the machine.
#'
#' @param name Data catalog name (e.g. "inputs.raw.enrollment"), as used with
#'   [data_read()] / [data_save()].
#'
#' @return Invisibly, TRUE when every available record matches.
#'
#' @export
data_verify <- function(name) {
  checkmate::assert_string(name, min.chars = 1)

  config <- settings_read()

  # Catalog names use dot notation but are stored nested (data$inputs$raw$x);
  # accept a flat key too
  entry <- config$data[[name]]
  if (is.null(entry)) {
    node <- config$data
    for (part in strsplit(name, ".", fixed = TRUE)[[1]]) {
      node <- node[[part]]
      if (is.null(node)) break
    }
    entry <- node
  }
  if (is.null(entry) || is.null(entry$path)) {
    stop("No data catalog entry named '", name, "'.", call. = FALSE)
  }
  if (!file.exists(entry$path)) {
    stop("File missing: ", entry$path, call. = FALSE)
  }

  # paste0 strips openssl's "hash" class, which would defeat identical()
  file_hash <- paste0(as.character(.calculate_file_hash(entry$path)))
  all_match <- TRUE
  message("Verifying ", name, " (", entry$path, ")")
  message("  file sha256: ", substr(file_hash, 1, 16), "...")

  # Local framework.db record
  record <- tryCatch(.get_data_record(name), error = function(e) NULL)
  if (!is.null(record)) {
    if (identical(record$hash[1], file_hash)) {
      message("  [ok] matches local framework.db record")
    } else {
      message("  [MISMATCH] local framework.db has ", substr(record$hash[1], 1, 16), "...")
      all_match <- FALSE
    }
  }

  # Cloud ledger head
  token <- .fw_project_token()
  if (!is.null(token)) {
    entries <- tryCatch(
      .fw_api(paste0("/api/v1/ledger?name=", utils::URLencode(name, reserved = TRUE)), token = token)$entries,
      error = function(e) {
        message("  (cloud ledger unreachable: ", conditionMessage(e), ")")
        NULL
      }
    )
    if (length(entries) > 0) {
      head_entry <- entries[[1]]
      if (identical(head_entry$hash, file_hash)) {
        message("  [ok] matches cloud ledger entry #", head_entry$sequence,
                " (recorded ", head_entry$recorded_at %||% "?", ")")
      } else {
        message("  [MISMATCH] cloud ledger head #", head_entry$sequence,
                " has ", substr(head_entry$hash, 1, 16), "...")
        all_match <- FALSE
      }
    } else if (!is.null(entries)) {
      message("  (no cloud ledger entries for this name yet)")
    }
  }

  if (all_match) {
    message("[ok] Verified")
  } else {
    warning("Integrity mismatch for '", name, "'", call. = FALSE)
  }

  invisible(all_match)
}

#' List the Project's Cloud Ledger
#'
#' @param name Optional data catalog name to filter by.
#'
#' @return A data.frame of ledger entries, newest first.
#'
#' @export
ledger_list <- function(name = NULL) {
  token <- .fw_project_token()
  if (is.null(token)) {
    stop("No project token found (FW_PROJECT_TOKEN / .env). ",
         "Create the project with framework::new() while logged in.", call. = FALSE)
  }

  path <- "/api/v1/ledger"
  if (!is.null(name)) {
    path <- paste0(path, "?name=", utils::URLencode(name, reserved = TRUE))
  }

  entries <- .fw_api(path, token = token)$entries
  if (length(entries) == 0) {
    message("No ledger entries yet.")
    return(invisible(data.frame()))
  }

  do.call(rbind, lapply(entries, function(e) {
    data.frame(
      sequence = e$sequence,
      name = e$name,
      hash = e$hash,
      size_bytes = e$size_bytes %||% NA,
      recorded_at = e$recorded_at %||% NA,
      stringsAsFactors = FALSE
    )
  }))
}

# --- Settings sync -------------------------------------------------------

#' @keywords internal
.fw_sync_paths <- function() {
  dir <- fw_config_dir()
  list(
    document = file.path(dir, "cloud-settings.yml"),
    state = file.path(dir, "sync-state.yml")
  )
}

#' @keywords internal
.fw_document_hash <- function(document) {
  json <- jsonlite::toJSON(document, auto_unbox = TRUE, null = "null")
  as.character(openssl::sha256(as.character(json)))
}

#' Sync Your Settings with framework.pub
#'
#' Your cloud settings document is mirrored to `cloud-settings.yml` in the
#' Framework config directory. Edit it there (or on the website) and sync.
#' Your main `settings.yml` is never touched.
#'
#' - `pull` fetches the cloud document (backing up local edits first).
#' - `push` sends your local mirror to the cloud.
#' - `auto` (default) chooses: pull when the cloud is ahead, push when only
#'   your local mirror changed, and stops with instructions when both changed.
#'
#' @param direction One of "auto", "pull", "push".
#'
#' @return Invisibly, the current revision number.
#'
#' @seealso [cloud_login()], [cloud_settings()]
#' @export
cloud_sync <- function(direction = c("auto", "pull", "push")) {
  direction <- match.arg(direction)
  token <- .fw_require_token()
  paths <- .fw_sync_paths()

  remote <- .fw_api("/api/v1/settings", token = token)
  remote_revision <- remote$revision

  state <- if (file.exists(paths$state)) yaml::read_yaml(paths$state) else NULL
  local_doc <- if (file.exists(paths$document)) yaml::read_yaml(paths$document) else NULL
  local_changed <- !is.null(local_doc) && !is.null(state) &&
    !identical(.fw_document_hash(local_doc), state$hash)
  remote_ahead <- is.null(state) || remote_revision > (state$revision %||% -1)

  if (direction == "auto") {
    direction <- if (is.null(local_doc) || is.null(state)) {
      "pull"
    } else if (local_changed && remote_ahead) {
      stop(
        "Both your local mirror and the cloud changed since the last sync.\n",
        "  cloud_sync(\"pull\") to take the cloud version (your file is backed up), or\n",
        "  cloud_sync(\"push\") to overwrite the cloud with your local mirror.",
        call. = FALSE
      )
    } else if (local_changed) {
      "push"
    } else if (remote_ahead) {
      "pull"
    } else {
      message("[ok] Already in sync (revision ", remote_revision, ")")
      return(invisible(remote_revision))
    }
  }

  if (direction == "pull") {
    if (!is.null(local_doc) && local_changed) {
      backup <- paste0(paths$document, ".backup-", format(Sys.time(), "%Y%m%d-%H%M%S"))
      file.copy(paths$document, backup)
      message("Local edits backed up to ", backup)
    }
    dir.create(dirname(paths$document), recursive = TRUE, showWarnings = FALSE)
    yaml::write_yaml(remote$document, paths$document)
    yaml::write_yaml(
      list(revision = remote_revision, hash = .fw_document_hash(remote$document)),
      paths$state
    )
    message("[ok] Pulled cloud settings (revision ", remote_revision, ") -> ", paths$document)
    return(invisible(remote_revision))
  }

  # push
  if (is.null(local_doc)) {
    stop("Nothing to push: no local mirror. Run cloud_sync(\"pull\") first.", call. = FALSE)
  }
  if (is.null(state)) {
    stop("No sync state. Run cloud_sync(\"pull\") first so pushes can detect conflicts.", call. = FALSE)
  }

  res <- tryCatch(
    .fw_api(
      "/api/v1/settings", token = token, method = "PUT",
      body = list(
        document = local_doc,
        base_revision = state$revision,
        client = list(
          device = Sys.info()[["nodename"]],
          app = "framework-r",
          version = as.character(utils::packageVersion("framework"))
        )
      )
    ),
    error = function(e) {
      stop(
        "Push rejected: ", conditionMessage(e), "\n",
        "The cloud likely changed since your last sync. cloud_sync(\"pull\") first.",
        call. = FALSE
      )
    }
  )

  yaml::write_yaml(
    list(revision = res$revision, hash = .fw_document_hash(local_doc)),
    paths$state
  )
  message("[ok] Pushed settings (revision ", res$revision, ")")
  invisible(res$revision)
}

# Overlay a cloud settings document onto the local default config used by
# new_project(). Only keys the creation path consumes are mapped.
#' @keywords internal
.fw_overlay_cloud_settings <- function(config, doc) {
  if (is.null(doc)) {
    return(config)
  }

  if (!is.null(doc$author)) {
    config$author <- utils::modifyList(config$author %||% list(), doc$author)
  }

  d <- doc$defaults %||% list()
  config$defaults <- config$defaults %||% list()
  for (key in c("use_renv", "use_git", "seed_on_scaffold")) {
    if (!is.null(d[[key]])) config$defaults[[key]] <- isTRUE(d[[key]])
  }
  for (key in c("seed", "ide", "notebook_format")) {
    if (!is.null(d[[key]])) config$defaults[[key]] <- d[[key]]
  }

  if (!is.null(doc$ai$enabled)) {
    config$defaults$ai_support <- isTRUE(doc$ai$enabled)
  }
  if (length(doc$ai$assistants %||% list()) > 0) {
    config$defaults$ai_assistants <- doc$ai$assistants
  }

  # Per-type directory structure overrides
  for (t in names(doc$project_types %||% list())) {
    dirs <- doc$project_types[[t]]$directories
    if (!is.null(dirs)) {
      config$project_types[[t]] <- config$project_types[[t]] %||% list()
      config$project_types[[t]]$directories <- dirs
    }
  }

  config
}

# --- Cloud blueprint plumbing -------------------------------------------
#
# During project creation, the fetched blueprint (structure + AGENTS.md
# master + skill contents) is stashed here so the deeper creation helpers
# (.create_ai_files, .ai_install_skills) can consult it without threading a
# new argument through every call. Cleared via on.exit by the stasher.

.fw_cloud_state <- new.env(parent = emptyenv())

#' @keywords internal
.fw_blueprint_stash <- function(bp) assign("blueprint", bp, envir = .fw_cloud_state)

#' @keywords internal
.fw_blueprint_get <- function() {
  if (exists("blueprint", envir = .fw_cloud_state)) {
    get("blueprint", envir = .fw_cloud_state)
  } else {
    NULL
  }
}

#' @keywords internal
.fw_blueprint_clear <- function() {
  if (exists("blueprint", envir = .fw_cloud_state)) {
    rm("blueprint", envir = .fw_cloud_state)
  }
}

# Fetch the cloud blueprint for a project type; NULL when no token, offline,
# or the type is unknown to the cloud. Never errors.
#' @keywords internal
.fw_cloud_blueprint_quietly <- function(type) {
  token <- .fw_cloud_token()
  if (is.null(token)) {
    return(NULL)
  }

  tryCatch(
    {
      res <- .fw_api(paste0("/api/v1/blueprints?key=", utils::URLencode(type)), token = token)
      bp <- res$blueprints[[1]] %||% NULL
      if (!is.null(bp)) {
        message("[ok] Using cloud blueprint: ", bp$name %||% type)
      }
      bp
    },
    error = function(e) {
      message("Cloud blueprint unavailable (", conditionMessage(e), "). Using local templates.")
      NULL
    }
  )
}

# The AGENTS.md master overrides generated content ONLY when an admin has
# actually customized it -- an unedited master is identical to the packaged
# template, and creation output must stay byte-stable for those users.
#' @keywords internal
.fw_cloud_agents_override <- function(type, project_name) {
  bp <- .fw_blueprint_get()
  master <- bp$agents_md %||% ""
  if (!nzchar(master)) {
    return(NULL)
  }

  template_dir <- system.file("templates", package = "framework")
  template_file <- file.path(template_dir, sprintf("ai-context.%s.md", type))
  if (!file.exists(template_file)) {
    template_file <- file.path(template_dir, "ai-context.project.md")
  }
  packaged <- if (file.exists(template_file)) {
    paste(readLines(template_file, warn = FALSE), collapse = "\n")
  } else {
    ""
  }

  if (identical(trimws(master), trimws(packaged))) {
    return(NULL)
  }

  gsub("\\{ProjectName\\}", project_name, master)
}

# framework::setup("fw_...") lands here: pull a cloud-defined project spec by
# its project token and scaffold it locally. The response carries the owner's
# settings document, so the project comes out configured their way.
#' @keywords internal
.cloud_setup <- function(token, location = NULL, browse = interactive()) {
  res <- .fw_api("/api/v1/project", token = token)
  proj <- res$project

  message("Setting up cloud project: ", proj$name, " (", proj$project_type, ")")

  if (is.null(location)) {
    suggested <- file.path("~", "projects", proj$slug)
    if (interactive()) {
      answer <- readline(paste0("Location [", suggested, "]: "))
      location <- if (nzchar(trimws(answer))) trimws(answer) else suggested
    } else {
      location <- suggested
    }
  }
  location <- path.expand(location)

  config <- get_default_global_config()
  config <- .fw_overlay_cloud_settings(config, res$settings$document)
  args <- .project_args_from_config(config, proj$project_type)

  # The pull response carries the blueprint; stash it so AI masters and
  # skills flow into creation, and apply its structure
  render_dirs <- NULL
  quarto <- NULL
  blueprint <- res$blueprint %||% NULL
  if (!is.null(blueprint)) {
    .fw_blueprint_stash(blueprint)
    on.exit(.fw_blueprint_clear(), add = TRUE)

    structure <- blueprint$structure %||% list()
    if (length(structure$directories %||% list()) > 0) {
      args$directories <- structure$directories
    }
    if (length(structure$render_dirs %||% list()) > 0) {
      render_dirs <- structure$render_dirs
    }
    if (!is.null(structure$quarto$render_dir)) {
      quarto <- list(render_dir = structure$quarto$render_dir)
    }
  }

  # Project payload overrides beat account-level settings
  payload <- proj$payload %||% list()
  for (key in intersect(names(payload), names(args))) {
    if (is.list(args[[key]]) && is.list(payload[[key]])) {
      args[[key]] <- utils::modifyList(args[[key]], payload[[key]])
    } else {
      args[[key]] <- payload[[key]]
    }
  }

  result <- project_create(
    name = proj$name,
    location = location,
    type = proj$project_type,
    author = args$author,
    packages = args$packages,
    directories = args$directories,
    extra_directories = list(),
    ai = args$ai,
    git = args$git,
    scaffold = args$scaffold,
    connections = args$connections,
    env = args$env,
    render_dirs = render_dirs,
    quarto = quarto
  )

  if (result$success) {
    # The setup token IS this project's key; store it for publish() et al.
    if (!identical(proj$project_type, "bare")) {
      .fw_write_project_token(result$path, token)
    }

    message("\nProject ready at ", result$path)
    if (browse) {
      if (Sys.info()["sysname"] == "Darwin") {
        system2("open", result$path)
      }
    }
  }

  invisible(result)
}
