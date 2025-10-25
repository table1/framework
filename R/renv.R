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

  message("Setting up renv (this may take a moment)...")

  # Suppress renv output during initialization (capture both stdout and stderr)
  invisible(capture.output({
    # Initialize renv if not already initialized
    if (!file.exists("renv.lock")) {
      # Suppress renv startup messages
      suppressMessages(renv::init(bare = TRUE, restart = FALSE))
    } else {
      suppressMessages(renv::activate())
    }

    # Create marker file with timestamp
    writeLines(
      paste("Enabled at:", Sys.time()),
      ".framework_renv_enabled"
    )

    # Add renv directories to .gitignore if not already present
    .update_gitignore_for_renv()

    # Create .renvignore to exclude Framework data/output directories
    .create_renvignore()

    # Always ensure framework is in renv.lock
    # Framework is on GitHub at table1/framework
    renv::install("table1/framework", rebuild = FALSE)

    # Always install rmarkdown when notebooks exist
    # Quarto uses rmarkdown's knitr engine for R code chunks
    if (dir.exists("notebooks") || file.exists("config.yml")) {
      if (!requireNamespace("rmarkdown", quietly = TRUE)) {
        renv::install("rmarkdown")
      }
    }

    # Sync packages from config.yml if requested
    pkg_count <- 0
    if (sync && file.exists("config.yml")) {
      # First ensure yaml package is available (needed to read config)
      if (!requireNamespace("yaml", quietly = TRUE)) {
        renv::install("yaml")
      }

      tryCatch({
        config <- read_config()
        pkg_count <- length(config$packages)
        .sync_packages_to_renv()
      }, error = function(e) {
        warning("Could not sync packages from settings: ", e$message, "\n",
                "You can manually sync later with: renv_snapshot()")
      })
    }
  }))

  # Show clean summary
  if (pkg_count > 0) {
    message("\u2713 renv enabled (", pkg_count, " packages installed)")
  } else {
    message("\u2713 renv enabled")
  }

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

#' Create .renvignore file for Framework projects
#'
#' Creates a .renvignore file that excludes Framework data and output
#' directories from renv dependency scanning.
#'
#' @return Invisibly returns NULL
#' @keywords internal
.create_renvignore <- function() {
  renvignore_path <- ".renvignore"

  # Skip if already exists
  if (file.exists(renvignore_path)) {
    return(invisible(NULL))
  }

  renvignore_content <- c(
    "# Exclude Framework data and output directories from renv tracking",
    "data/",
    "results/",
    "scratch/",
    "work/",
    "",
    "# R project files",
    "*.Rproj",
    ".Rproj.user",
    "",
    "# Framework markers",
    ".framework_renv_enabled",
    ".framework_scaffolded"
  )

  writeLines(renvignore_content, renvignore_path)

  invisible(NULL)
}
