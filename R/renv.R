#' Check if renv is enabled for this project
#'
#' Determines whether renv integration is active by checking for the
#' `.framework_renv_enabled` marker file in the project root.
#'
#' @return Logical indicating whether renv is enabled
#' @export
#' @examples
#' if (renv_enabled()) {
#'   message("Using renv for package management")
#' }
renv_enabled <- function() {
  file.exists(".framework_renv_enabled")
}

#' Enable renv for this project
#'
#' Initializes renv integration for the current Framework project. This:
#' - Creates `.framework_renv_enabled` marker file
#' - Initializes renv if not already initialized
#' - Syncs packages from config.yml to renv.lock
#' - Updates .gitignore to exclude renv cache
#'
#' @param sync Logical; if TRUE (default), sync packages from config.yml
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' renv_enable()
#' }
renv_enable <- function(sync = TRUE) {
  if (renv_enabled()) {
    message("renv is already enabled for this project")
    return(invisible(TRUE))
  }

  # Check if renv is installed
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop(
      "renv package is required but not installed.\n",
      "Install it with: install.packages('renv')"
    )
  }

  # Initialize renv if not already initialized
  if (!file.exists("renv.lock")) {
    message("Initializing renv...")
    renv::init(bare = TRUE, restart = FALSE)
  } else {
    message("renv already initialized, activating...")
    renv::activate()
  }

  # Create marker file with timestamp
  writeLines(
    paste("Enabled at:", Sys.time()),
    ".framework_renv_enabled"
  )

  # Add renv directories to .gitignore if not already present
  .update_gitignore_for_renv()

  # Sync packages from config.yml if requested
  if (sync && file.exists("config.yml")) {
    # First ensure yaml package is available (needed to read config)
    if (!requireNamespace("yaml", quietly = TRUE)) {
      message("Installing yaml package (required for config reading)...")
      renv::install("yaml")
    }

    message("Syncing packages from config.yml to renv...")
    tryCatch(
      .sync_packages_to_renv(),
      error = function(e) {
        warning("Could not sync packages from config.yml: ", e$message, "\n",
                "You can manually sync later with: packages_snapshot()")
      }
    )
  }

  message(
    "\n",
    "\u2713 renv enabled successfully!\n\n",
    "Your packages are now managed by renv for reproducibility.\n",
    "Use packages_snapshot() to update renv.lock after installing new packages.\n",
    "Use renv_disable() to turn off renv integration."
  )

  invisible(TRUE)
}

#' Disable renv for this project
#'
#' Deactivates renv integration while preserving renv.lock for future use.
#' Removes the `.framework_renv_enabled` marker file.
#'
#' @param keep_renv Logical; if TRUE (default), keep renv.lock and renv/ directory
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' renv_disable()
#' }
renv_disable <- function(keep_renv = TRUE) {
  if (!renv_enabled()) {
    message("renv is not currently enabled for this project")
    return(invisible(TRUE))
  }

  # Deactivate renv if active
  if (requireNamespace("renv", quietly = TRUE)) {
    renv::deactivate()
  }

  # Remove marker file
  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  if (keep_renv) {
    message(
      "\n",
      "\u2139 renv disabled\n\n",
      "Your renv.lock file has been preserved.\n",
      "Use renv_enable() to re-activate renv integration."
    )
  } else {
    # Remove renv files
    if (file.exists("renv.lock")) file.remove("renv.lock")
    if (dir.exists("renv")) unlink("renv", recursive = TRUE)

    message(
      "\n",
      "\u2139 renv disabled and removed\n\n",
      "All renv files have been deleted.\n",
      "Use renv_enable() to set up renv from scratch."
    )
  }

  invisible(TRUE)
}

#' Show educational message about renv
#'
#' Displays a one-time message explaining renv integration and how to enable it.
#' The message is suppressed if `options$renv_nag` is FALSE in config.yml or
#' if `.framework_scaffolded` marker contains a timestamp (not first scaffold).
#'
#' @return Invisibly returns NULL
#' @keywords internal
.renv_nag <- function() {
  # Check if this is the first scaffold
  if (file.exists(".framework_scaffolded")) {
    scaffold_info <- readLines(".framework_scaffolded", warn = FALSE)
    # If file has timestamp, it's not the first scaffold
    if (length(scaffold_info) > 0) {
      return(invisible(NULL))
    }
  }

  # Check if nagging is disabled in config
  if (file.exists("config.yml")) {
    config <- tryCatch(
      read_config("config.yml"),
      error = function(e) list(renv_nag = TRUE)
    )

    # Check new location first, then old location (backward compat)
    renv_nag <- config$renv_nag
    if (is.null(renv_nag)) {
      renv_nag <- config$options$renv_nag
      if (!is.null(renv_nag)) {
        warning("config$options$renv_nag is deprecated. ",
                "Move to config$renv_nag (root level)")
      }
    }

    # Default to TRUE if not specified
    if (is.null(renv_nag)) renv_nag <- TRUE

    if (!renv_nag) {
      return(invisible(NULL))
    }
  }

  # Don't nag if renv is already enabled
  if (renv_enabled()) {
    return(invisible(NULL))
  }

  message(
    "\n",
    "\u2139 Reproducibility Tip\n\n",
    "Framework can manage your R package versions with renv for reproducibility.\n",
    "This ensures your project uses consistent package versions across environments.\n\n",
    "To enable: renv_enable()\n",
    "To disable this message: Set 'options: renv_nag: false' in config.yml\n",
    "Learn more: ?renv_enable\n"
  )

  invisible(NULL)
}

#' Update .gitignore for renv
#'
#' Adds renv-related entries to .gitignore if they don't already exist.
#'
#' @return Invisibly returns NULL
#' @keywords internal
.update_gitignore_for_renv <- function() {
  gitignore_path <- ".gitignore"

  # Create .gitignore if it doesn't exist
  if (!file.exists(gitignore_path)) {
    writeLines("", gitignore_path)
  }

  existing <- readLines(gitignore_path, warn = FALSE)

  # Entries to add
  renv_entries <- c(
    "",
    "# renv",
    "renv/library/",
    "renv/local/",
    "renv/cellar/",
    "renv/lock/",
    "renv/python/",
    "renv/sandbox/",
    "renv/staging/"
  )

  # Only add if not already present
  if (!any(grepl("^# renv$", existing))) {
    writeLines(c(existing, renv_entries), gitignore_path)
    message("Updated .gitignore with renv entries")
  }

  invisible(NULL)
}
