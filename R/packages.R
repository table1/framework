#' Parse package specification with version pinning
#'
#' Parses package specifications that may include version pins or GitHub references:
#' - "dplyr" -> list(name = "dplyr", version = NULL, source = "cran")
#' - "dplyr@1.1.0" -> list(name = "dplyr", version = "1.1.0", source = "cran")
#' - "tidyverse/dplyr@main" -> list(name = "dplyr", repo = "tidyverse/dplyr", ref = "main", source = "github")
#'
#' @param spec Character string with package specification
#' @return List with parsed components (name, version, source, repo, ref)
#' @keywords internal
#' @examples
#' \dontrun{
#' .parse_package_spec("dplyr")
#' .parse_package_spec("dplyr@1.1.0")
#' .parse_package_spec("tidyverse/dplyr@main")
#' }
.parse_package_spec <- function(spec) {
  spec <- trimws(spec)

  # Check for GitHub pattern: user/repo@ref or user/repo
  if (grepl("/", spec)) {
    parts <- strsplit(spec, "@")[[1]]
    repo <- parts[1]
    ref <- if (length(parts) > 1) parts[2] else "HEAD"
    pkg_name <- basename(repo)

    return(list(
      name = pkg_name,
      repo = repo,
      ref = ref,
      source = "github",
      version = NULL
    ))
  }

  # Check for CRAN pattern: package@version or package
  parts <- strsplit(spec, "@")[[1]]
  pkg_name <- parts[1]
  version <- if (length(parts) > 1) parts[2] else NULL

  list(
    name = pkg_name,
    version = version,
    source = "cran",
    repo = NULL,
    ref = NULL
  )
}

#' Install package via renv
#'
#' Installs a package using renv, handling version pinning and GitHub sources.
#'
#' @param spec Parsed package specification from .parse_package_spec()
#' @return Invisibly returns TRUE on success
#' @keywords internal
.install_package_renv <- function(spec) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  if (spec$source == "github") {
    # Install from GitHub
    pkg_ref <- if (!is.null(spec$ref) && spec$ref != "HEAD") {
      paste0(spec$repo, "@", spec$ref)
    } else {
      spec$repo
    }
    message("Installing ", spec$name, " from GitHub (", pkg_ref, ")...")
    renv::install(pkg_ref)
  } else {
    # Install from CRAN
    if (!is.null(spec$version)) {
      pkg_ref <- paste0(spec$name, "@", spec$version)
      message("Installing ", spec$name, " version ", spec$version, "...")
      renv::install(pkg_ref)
    } else {
      message("Installing ", spec$name, " from CRAN...")
      renv::install(spec$name)
    }
  }

  invisible(TRUE)
}

#' Install package without renv
#'
#' Installs a package using base R functions, handling version pinning and GitHub sources.
#'
#' @param spec Parsed package specification from .parse_package_spec()
#' @return Invisibly returns TRUE on success
#' @keywords internal
.install_package_base <- function(spec) {
  if (spec$source == "github") {
    # Install from GitHub using remotes
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }

    pkg_ref <- if (!is.null(spec$ref) && spec$ref != "HEAD") {
      paste0(spec$repo, "@", spec$ref)
    } else {
      spec$repo
    }
    message("Installing ", spec$name, " from GitHub (", pkg_ref, ")...")
    remotes::install_github(pkg_ref)
  } else {
    # Install from CRAN
    if (!is.null(spec$version)) {
      # For version pinning without renv, use remotes::install_version
      if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes")
      }
      message("Installing ", spec$name, " version ", spec$version, "...")
      remotes::install_version(
        spec$name,
        version = spec$version,
        upgrade = "never"
      )
    } else {
      message("Installing ", spec$name, " from CRAN...")
      install.packages(spec$name)
    }
  }

  invisible(TRUE)
}

#' Sync packages from config.yml to renv
#'
#' Reads the packages list from config.yml and installs them via renv,
#' then snapshots the result to renv.lock.
#'
#' @return Invisibly returns TRUE on success
#' @keywords internal
.sync_packages_to_renv <- function() {
  if (!renv_enabled()) {
    warning("renv is not enabled. Use renv_enable() first.")
    return(invisible(FALSE))
  }

  if (!file.exists("config.yml")) {
    warning("config.yml not found")
    return(invisible(FALSE))
  }

  config <- read_config("config.yml")

  if (is.null(config$packages) || length(config$packages) == 0) {
    message("No packages listed in config.yml")
    return(invisible(TRUE))
  }

  message("Syncing ", length(config$packages), " package(s) from config.yml...")

  # Install each package via renv
  for (pkg_spec in config$packages) {
    # Extract package name from list or string
    if (is.list(pkg_spec)) {
      pkg_name <- pkg_spec$name
    } else {
      pkg_name <- pkg_spec
    }

    spec <- .parse_package_spec(pkg_name)

    # Check if package is already installed at correct version
    if (requireNamespace(spec$name, quietly = TRUE)) {
      if (is.null(spec$version)) {
        # No version pin, already installed - skip
        next
      } else {
        # Check if installed version matches
        installed_ver <- as.character(packageVersion(spec$name))
        if (installed_ver == spec$version) {
          next
        }
      }
    }

    # Install the package
    tryCatch(
      .install_package_renv(spec),
      error = function(e) {
        warning("Failed to install ", spec$name, ": ", e$message)
      }
    )
  }

  # Snapshot to renv.lock
  message("Creating snapshot in renv.lock...")
  renv::snapshot(prompt = FALSE)

  message(cli::col_green(cli::symbol$tick), " Packages synced successfully!")

  invisible(TRUE)
}

#' Snapshot current package versions to renv.lock
#'
#' A user-facing wrapper around renv::snapshot() that ensures renv is enabled.
#'
#' @param prompt Logical; if TRUE, prompt before creating snapshot
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' packages_snapshot()
#' }
packages_snapshot <- function(prompt = FALSE) {
  if (!renv_enabled()) {
    stop(
      "renv is not enabled for this project.\n",
      "Use renv_enable() to enable renv integration."
    )
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  message("Creating snapshot of current package versions...")
  renv::snapshot(prompt = prompt)

  message(cli::col_green(cli::symbol$tick), " Snapshot saved to renv.lock")

  invisible(TRUE)
}

#' Restore packages from renv.lock
#'
#' A user-facing wrapper around renv::restore() that ensures renv is enabled.
#'
#' @param prompt Logical; if TRUE, prompt before restoring
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' packages_restore()
#' }
packages_restore <- function(prompt = FALSE) {
  if (!renv_enabled()) {
    stop(
      "renv is not enabled for this project.\n",
      "Use renv_enable() to enable renv integration."
    )
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  if (!file.exists("renv.lock")) {
    stop("No renv.lock file found. Run packages_snapshot() first.")
  }

  message("Restoring packages from renv.lock...")
  renv::restore(prompt = prompt)

  message(cli::col_green(cli::symbol$tick), " Packages restored successfully!")

  invisible(TRUE)
}

#' Show package status
#'
#' A user-facing wrapper around renv::status() that ensures renv is enabled.
#'
#' @return Invisibly returns the status object from renv::status()
#' @export
#' @examples
#' \dontrun{
#' packages_status()
#' }
packages_status <- function() {
  if (!renv_enabled()) {
    stop(
      "renv is not enabled for this project.\n",
      "Use renv_enable() to enable renv integration."
    )
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  renv::status()
}

#' Update packages
#'
#' A user-facing wrapper around renv::update() that ensures renv is enabled.
#'
#' @param packages Character vector of package names to update, or NULL for all
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' packages_update()
#' packages_update(c("dplyr", "ggplot2"))
#' }
packages_update <- function(packages = NULL) {
  if (!renv_enabled()) {
    stop(
      "renv is not enabled for this project.\n",
      "Use renv_enable() to enable renv integration."
    )
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  if (is.null(packages)) {
    message("Updating all packages...")
    renv::update()
  } else {
    message("Updating ", length(packages), " package(s)...")
    renv::update(packages = packages)
  }

  message(cli::col_green(cli::symbol$tick), " Packages updated!")

  invisible(TRUE)
}
