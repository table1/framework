#' Parse package specification with source detection
#'
#' Parses package specifications that may include explicit sources, version pins,
#' or GitHub/Bioconductor references. Supports both scalar strings and list-style
#' entries from `settings.yml`.
#'
#' Examples:
#' - "dplyr" -> list(name = "dplyr", source = "cran")
#' - "dplyr@1.1.0" -> list(name = "dplyr", version = "1.1.0", source = "cran")
#' - "tidyverse/dplyr@main" -> list(name = "dplyr", repo = "tidyverse/dplyr", ref = "main", source = "github")
#' - list(name = "DESeq2", source = "bioc") -> list(name = "DESeq2", source = "bioc")
#'
#' @param spec Character or list describing the package
#' @return List with normalized components (name, source, version, repo, ref, auto_attach)
#' @keywords internal
#' @examples
#' \dontrun{
#' .parse_package_spec("dplyr")
#' .parse_package_spec("dplyr@1.1.0")
#' .parse_package_spec("tidyverse/dplyr@main")
#' .parse_package_spec(list(name = "DESeq2", source = "bioc", auto_attach = FALSE))
#' }
.parse_package_spec <- function(spec) {
  .normalize_package_spec(spec)
}

#' Normalize package specification from config
#'
#' Converts the various package representations supported in settings.yml into a
#' consistent structure that downstream helpers can rely on.
#'
#' @param spec Character string or list describing a package dependency
#' @return List with fields: name, source, version, repo, ref, auto_attach
#' @keywords internal
.normalize_package_spec <- function(spec) {
  if (is.null(spec)) {
    return(NULL)
  }

  if (is.list(spec)) {
    return(.normalize_package_list_spec(spec))
  }

  if (is.character(spec) && length(spec) == 1) {
    return(.normalize_package_string_spec(spec))
  }

  stop("Unsupported package specification type: ", class(spec)[1])
}

.normalize_package_string_spec <- function(spec) {
  spec <- trimws(spec)
  if (identical(spec, "")) {
    stop("Package specification cannot be empty")
  }

  auto_attach <- FALSE

  # Bioconductor shorthand: bioc::pkg
  if (grepl("^bioc::", spec, ignore.case = TRUE)) {
    pkg_name <- sub("^bioc::", "", spec, ignore.case = TRUE)
    return(list(
      name = pkg_name,
      source = "bioc",
      version = NULL,
      repo = NULL,
      ref = NULL,
      auto_attach = auto_attach
    ))
  }

  # GitHub shorthand: user/repo@ref or user/repo
  if (grepl("/", spec, fixed = TRUE)) {
    parts <- strsplit(spec, "@", fixed = TRUE)[[1]]
    repo <- trimws(parts[1])
    ref <- if (length(parts) > 1) trimws(parts[2]) else "HEAD"
    pkg_name <- basename(repo)

    return(list(
      name = pkg_name,
      source = "github",
      version = NULL,
      repo = repo,
      ref = ref,
      auto_attach = auto_attach
    ))
  }

  # CRAN shorthand: package or package@version
  parts <- strsplit(spec, "@", fixed = TRUE)[[1]]
  pkg_name <- trimws(parts[1])
  version <- if (length(parts) > 1) trimws(parts[2]) else NULL

  list(
    name = pkg_name,
    source = "cran",
    version = version,
    repo = NULL,
    ref = NULL,
    auto_attach = auto_attach
  )
}

.normalize_package_list_spec <- function(spec) {
  auto_attach <- isTRUE(spec$auto_attach) ||
    isTRUE(spec$attached) ||
    isTRUE(spec$load) ||
    isTRUE(spec$scaffold)

  pkg_name_raw <- spec$name %||% spec$package

  base_spec <- list(
    name = NULL,
    source = NULL,
    version = NULL,
    repo = NULL,
    ref = NULL
  )

  if (!is.null(pkg_name_raw)) {
    base_spec <- tryCatch(
      .normalize_package_string_spec(pkg_name_raw),
      error = function(e) {
        list(
          name = pkg_name_raw,
          source = NULL,
          version = NULL,
          repo = NULL,
          ref = NULL,
          auto_attach = FALSE
        )
      }
    )
  }

  source <- spec$source
  if (!is.null(source)) {
    source <- tolower(as.character(source))
    if (source %in% c("bioconductor", "bioc", "bio")) {
      source <- "bioc"
    }
  }
  source <- source %||% base_spec$source %||% "cran"

  repo <- spec$repo %||% spec$source_repo %||% base_spec$repo
  ref <- spec$ref %||% spec$branch %||% spec$tag %||% base_spec$ref
  version <- spec$version %||% spec$ver %||% base_spec$version

  name <- base_spec$name %||% pkg_name_raw

  if (source == "github") {
    if (is.null(repo)) {
      if (!is.null(pkg_name_raw) && grepl("/", pkg_name_raw, fixed = TRUE)) {
        repo <- sub("@.*$", "", pkg_name_raw)
        ref <- ref %||% sub("^.*@", "", pkg_name_raw)
        if (identical(repo, ref)) {
          ref <- NULL
        }
      }
    }

    if (is.null(repo)) {
      stop("GitHub package requires a 'repo' field or a 'name' containing 'owner/repo'")
    }

    name <- basename(repo)
    if (is.null(ref) || identical(ref, repo)) {
      ref <- base_spec$ref %||% "HEAD"
    }
    if (identical(ref, "")) {
      ref <- "HEAD"
    }
    version <- NULL
  } else if (source == "bioc") {
    name <- name %||% pkg_name_raw
    if (is.null(name)) {
      stop("Bioconductor package requires a 'name' field")
    }
    repo <- NULL
    ref <- NULL
  } else if (source == "cran") {
    name <- name %||% pkg_name_raw
    if (is.null(name)) {
      stop("CRAN package requires a 'name' field")
    }
    repo <- NULL
    ref <- NULL
  }

  list(
    name = name,
    source = source,
    version = version,
    repo = repo,
    ref = ref,
    auto_attach = auto_attach
  )
}

.ensure_biocmanager_installed <- function(use_renv = FALSE) {
  if (requireNamespace("BiocManager", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  if (use_renv) {
    renv::install("BiocManager")
  } else {
    message("Installing BiocManager from CRAN...")
    install.packages("BiocManager")
  }

  invisible(TRUE)
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

  source <- spec$source %||% "cran"

  if (identical(source, "github")) {
    # Install from GitHub
    pkg_ref <- if (!is.null(spec$ref) && spec$ref != "HEAD") {
      paste0(spec$repo, "@", spec$ref)
    } else {
      spec$repo
    }
    renv::install(pkg_ref)
  } else if (identical(source, "bioc")) {
    .ensure_biocmanager_installed(use_renv = TRUE)
    renv::install(paste0("bioc::", spec$name))
  } else if (identical(source, "cran")) {
    # Install from CRAN
    if (!is.null(spec$version)) {
      pkg_ref <- paste0(spec$name, "@", spec$version)
      renv::install(pkg_ref)
    } else {
      renv::install(spec$name)
    }
  } else {
    stop("Unsupported package source: ", source)
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
  source <- spec$source %||% "cran"

  if (identical(source, "github")) {
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
  } else if (identical(source, "bioc")) {
    .ensure_biocmanager_installed(use_renv = FALSE)
    message("Installing ", spec$name, " from Bioconductor...")
    BiocManager::install(spec$name, update = FALSE, ask = FALSE)
  } else if (identical(source, "cran")) {
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
  } else {
    stop("Unsupported package source: ", source)
  }

  invisible(TRUE)
}

#' Sync packages from settings.yml to renv
#'
#' Reads the packages list from settings.yml and installs them via renv,
#' then snapshots the result to renv.lock.
#'
#' @return Invisibly returns TRUE on success
#' @keywords internal
.sync_packages_to_renv <- function() {
  if (!renv_enabled()) {
    warning("renv is not enabled. Use renv_enable() first.")
    return(invisible(FALSE))
  }

  # Check if settings file exists
  tryCatch({
    config <- read_config()
  }, error = function(e) {
    warning("Settings file not found")
    return(invisible(FALSE))
  })

  if (is.null(config$packages) || length(config$packages) == 0) {
    return(invisible(TRUE))
  }

  # Install each package via renv
  for (pkg_spec in config$packages) {
    spec <- tryCatch(
      .parse_package_spec(pkg_spec),
      error = function(e) {
        warning("Failed to parse package specification: ", conditionMessage(e))
        return(NULL)
      }
    )

    if (is.null(spec)) {
      next
    }

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
  renv::snapshot(prompt = FALSE)

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
#' renv_snapshot()
#' }
renv_snapshot <- function(prompt = FALSE) {
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
#' renv_restore()
#' }
renv_restore <- function(prompt = FALSE) {
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
    stop("No renv.lock file found. Run renv_snapshot() first.")
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
#' renv_status()
#' }
renv_status <- function() {
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

#' Sync packages with renv.lock
#'
#' Resolves inconsistencies between installed packages and renv.lock by:
#' 1. Installing missing packages that are used in code
#' 2. Recording installed packages to renv.lock
#'
#' This is a convenience wrapper that calls renv::restore() followed by
#' renv::snapshot() to bring the project into a consistent state.
#'
#' @param prompt Logical; if TRUE, prompt before making changes
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' # Check status
#' renv_status()
#'
#' # Fix inconsistencies
#' renv_sync()
#' }
renv_sync <- function(prompt = FALSE) {
  if (!renv_enabled()) {
    stop(
      "renv is not enabled for this project.\n",
      "Use renv_enable() to enable renv integration."
    )
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  message("Synchronizing packages with renv.lock...")
  message("")

  # Step 1: Install missing packages
  message("1. Installing missing packages...")
  tryCatch({
    renv::restore(prompt = prompt)
  }, error = function(e) {
    # renv::restore() throws an error if nothing to restore, which is fine
    if (!grepl("nothing to restore", e$message, ignore.case = TRUE)) {
      warning("Error during restore: ", e$message)
    }
  })

  # Step 2: Record installed packages to renv.lock
  message("2. Recording installed packages to renv.lock...")
  renv::snapshot(prompt = prompt)

  message("")
  message(cli::col_green(cli::symbol$tick), " Packages synchronized!")
  message("")
  message("All packages are now consistent with renv.lock")

  invisible(TRUE)
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
#' renv_update()
#' renv_update(c("dplyr", "ggplot2"))
#' }
renv_update <- function(packages = NULL) {
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


#' List all packages from configuration
#'
#' Lists all packages defined in the configuration, showing the package name,
#' version pin (if specified), and source (CRAN or GitHub).
#'
#' @return Invisibly returns NULL after printing package list
#' @export
#'
#' @examples
#' \dontrun{
#' # List all packages
#' packages_list()
#' }


#' Install packages from configuration
#'
#' Installs all packages defined in the configuration that are not already installed.
#' This is the same logic used by scaffold(), but exposed as a standalone function.
#'
#' @return Invisibly returns TRUE on success
#' @export
#'
#' @examples
#' \dontrun{
#' # Install all configured packages
#' packages_install()
#' }
packages_install <- function() {
  config <- read_config()

  if (is.null(config$packages) || length(config$packages) == 0) {
    message("No packages found in configuration")
    return(invisible(TRUE))
  }

  # Use the same logic as scaffold()
  message("Installing packages from configuration...")
  .install_required_packages(config)
  message("\nPackages installed!")

  invisible(TRUE)
}


#' Update packages from configuration
#'
#' Updates packages defined in the configuration. If renv is enabled, uses renv::update().
#' Otherwise, reinstalls packages using standard installation methods.
#'
#' @param packages Character vector of specific packages to update, or NULL to update all
#' @return Invisibly returns TRUE on success
#' @export
#'
#' @examples
#' \dontrun{
#' # Update all packages
#' packages_update()
#'
#' # Update specific packages
#' packages_update(c("dplyr", "ggplot2"))
#' }
packages_update <- function(packages = NULL) {
  if (!renv_enabled()) {
    stop("renv is not enabled. Use renv_enable() first.")
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


#' List all packages from configuration
#'
#' Lists all packages defined in the configuration, showing the package name,
#' version pin (if specified), and source (CRAN or GitHub).
#'
#' @return Invisibly returns NULL after printing package list
#' @export
#'
#' @examples
#' \dontrun{
#' # List all packages
#' packages_list()
#' }
packages_list <- function() {
  config <- read_config()

  if (is.null(config$packages) || length(config$packages) == 0) {
    message("No packages found in configuration")
    return(invisible(NULL))
  }

  # Print formatted output
  message(sprintf("\n%d %s found:\n",
                  length(config$packages),
                  if (length(config$packages) == 1) "package" else "packages"))

  for (pkg_spec in config$packages) {
    spec <- tryCatch(
      .parse_package_spec(pkg_spec),
      error = function(e) {
        warning("Failed to parse package specification: ", conditionMessage(e))
        return(NULL)
      }
    )

    if (is.null(spec)) {
      next
    }

    source_label <- switch(
      spec$source,
      github = sprintf("GitHub: %s%s",
        spec$repo,
        if (!is.null(spec$ref) && spec$ref != "HEAD") paste0("@", spec$ref) else ""
      ),
      bioc = "Bioconductor",
      cran = "CRAN",
      toupper(spec$source)
    )

    version_label <- if (!is.null(spec$version)) sprintf(" (v%s)", spec$version) else ""

    message(sprintf("• %s [%s]%s", spec$name, source_label, version_label))
    message(sprintf("  Auto-attach: %s", if (isTRUE(spec$auto_attach)) "yes" else "no"))
    message("")
  }

  invisible(NULL)
}


#' Snapshot current package library (renv)
#'
#' Wrapper around `renv::snapshot()` that requires Framework's renv integration
#' to be enabled first.
#'
#' @param prompt Logical. If TRUE, renv prompts before writing the snapshot.
#' @return Invisibly returns TRUE on success.
#' @export
packages_snapshot <- function(prompt = FALSE) {
  if (!renv_enabled()) {
    stop("renv is not enabled. Use renv_enable() first.")
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  renv::snapshot(prompt = prompt)
  invisible(TRUE)
}

#' Restore packages from renv.lock
#'
#' Wrapper around `renv::restore()` that requires Framework's renv integration
#' to be enabled first.
#'
#' @param prompt Logical. If TRUE, renv prompts before restoring.
#' @return Invisibly returns TRUE on success.
#' @export
packages_restore <- function(prompt = FALSE) {
  if (!renv_enabled()) {
    stop("renv is not enabled. Use renv_enable() first.")
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  renv::restore(prompt = prompt)
  invisible(TRUE)
}

#' Show renv package status
#'
#' Wrapper around `renv::status()` that requires Framework's renv integration.
#'
#' @return The status object returned by `renv::status()`.
#' @export
packages_status <- function() {
  if (!renv_enabled()) {
    stop("renv is not enabled. Use renv_enable() first.")
  }

  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required but not installed")
  }

  renv::status()
}
