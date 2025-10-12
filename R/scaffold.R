#' Initialize and load the project environment
#'
#' This function initializes the project environment by:
#' 1. Standardizing the working directory (for notebooks in subdirectories)
#' 2. Loading environment variables from .env
#' 3. Loading configuration from config.yml
#' 4. Installing required packages
#' 5. Loading all functions from the functions directory
#'
#' @export
scaffold <- function(config_file = "config.yml") {
  # Standardize working directory first (for notebooks in subdirectories)
  standardize_wd()

  # Only load package if not already loaded
  if (!"package:framework" %in% search()) {
    message("Loading framework package...")
    library(framework)
  }

  .load_environment()

  # Unlock config if it exists and is locked (from previous scaffold calls)
  tryCatch({
    if (exists("config", envir = .GlobalEnv) && bindingIsLocked("config", .GlobalEnv)) {
      unlockBinding("config", .GlobalEnv)
    }
  }, error = function(e) {
    # Ignore binding check errors - config doesn't exist yet
  })

  config <<- .load_configuration(config_file)

  # Show educational message about renv (first scaffold only)
  .renv_nag()

  # Mark as scaffolded with timestamp
  .mark_scaffolded()

  .install_required_packages(config)
  .load_libraries(config)
  .load_functions()

  # Source scaffold.R if it exists
  if (file.exists("scaffold.R")) {
    source("scaffold.R")
  }
}

#' Load environment variables from .env file
#' @keywords internal
.load_environment <- function() {
  config <- read_config()

  if (!is.null(config$options$dotenv_location)) {
    dotenv_path <- config$options$dotenv_location

    if (dir.exists(dotenv_path)) {
      dotenv_path <- file.path(dotenv_path, ".env")
    }

    if (!file.exists(dotenv_path)) {
      stop(sprintf("Dotenv file not found at '%s'", dotenv_path))
    }

    dotenv::load_dot_env(dotenv_path)
  } else {
    dotenv::load_dot_env()
  }
}

#' Load configuration from config.yml
#' @keywords internal
.load_configuration <- function(config_file = "config.yml") {
  read_config(config_file)
}

#' Get package requirements from config
#' @param config Configuration object from read_config()
#' @keywords internal
.get_package_requirements <- function(config) {
  if (is.null(config$packages)) {
    return(character())
  }

  # Extract package names and their loading behavior
  packages <- lapply(config$packages, function(pkg) {
    if (is.character(pkg)) {
      # Simple string - just ensure installed
      list(name = pkg, load = FALSE)
    } else if (is.list(pkg)) {
      # List with loading behavior
      # Support: auto_attach (preferred), attached (backward compat), load, scaffold
      list(
        name = pkg$name,
        load = isTRUE(pkg$auto_attach) || isTRUE(pkg$attached) || isTRUE(pkg$load) || isTRUE(pkg$scaffold)
      )
    } else {
      NULL
    }
  })

  # Filter out NULLs and return
  packages <- packages[!sapply(packages, is.null)]
  packages
}

#' Install a package if not already installed
#' @param pkg_spec Package specification (may include version pin)
#' @keywords internal
.install_package <- function(pkg_spec) {
  # Parse the package specification
  spec <- .parse_package_spec(pkg_spec)

  # Check if already installed
  already_installed <- requireNamespace(spec$name, quietly = TRUE)

  # If installed and no version pin, skip
  if (already_installed && is.null(spec$version)) {
    return(invisible(TRUE))
  }

  # If installed with version pin, check version
  if (already_installed && !is.null(spec$version)) {
    installed_ver <- as.character(packageVersion(spec$name))
    if (installed_ver == spec$version) {
      return(invisible(TRUE))
    }
  }

  # Route installation based on renv status
  if (renv_enabled()) {
    .install_package_renv(spec)
  } else {
    .install_package_base(spec)
  }

  invisible(TRUE)
}

#' Install required packages from config
#' @param config Configuration object from read_config()
#' @keywords internal
.install_required_packages <- function(config) {
  packages <- .get_package_requirements(config)
  for (pkg in packages) {
    .install_package(pkg$name)
  }
}

#' Load all libraries specified in config
#' @param config Configuration object from read_config()
#' @keywords internal
.load_libraries <- function(config) {
  packages <- .get_package_requirements(config)

  # Check if verbose mode is enabled
  verbose <- isTRUE(config$options$verbose_scaffold)

  for (pkg in packages) {
    if (pkg$load) {
      if (verbose) {
        message(sprintf("Loading library: %s", pkg$name))
      }
      suppressPackageStartupMessages(
        library(pkg$name, character.only = TRUE)
      )
    }
  }
}

#' Load all R files from functions directories
#' @keywords internal
.load_functions <- function() {
  config <- read_config()

  # Get function directories from config (can be list or single value)
  func_dirs <- config$options$functions_dir

  # Default to "functions" if not configured
  if (is.null(func_dirs)) {
    func_dirs <- "functions"
  }

  # Ensure it's a list for consistent processing
  if (!is.list(func_dirs) && is.character(func_dirs)) {
    func_dirs <- as.list(func_dirs)
  }

  # Track if we loaded any functions
  loaded_any <- FALSE

  # Load functions from each directory
  for (func_dir in func_dirs) {
    if (dir.exists(func_dir)) {
      func_files <- list.files(func_dir, pattern = "\\.R$", full.names = TRUE)
      if (length(func_files) > 0) {
        for (file in func_files) {
          source(file, local = FALSE)
        }
        message(sprintf("Loaded %d function(s) from %s", length(func_files), func_dir))
        loaded_any <- TRUE
      }
    }
  }

  # Only warn if no directories exist at all
  if (!loaded_any && length(func_dirs) == 1 && func_dirs[[1]] == "functions") {
    # Silent if using default and it doesn't exist (common case)
    invisible(NULL)
  } else if (!loaded_any) {
    # Warn if user explicitly configured directories but none exist
    warning(sprintf("No function directories found: %s", paste(unlist(func_dirs), collapse = ", ")))
  }
}

#' Mark project as scaffolded
#' @keywords internal
.mark_scaffolded <- function() {
  if (!file.exists(".framework_scaffolded")) {
    # First scaffold - create marker with timestamp
    writeLines(
      paste("First scaffolded at:", Sys.time()),
      ".framework_scaffolded"
    )
  } else {
    # Update timestamp
    existing <- readLines(".framework_scaffolded", warn = FALSE)
    writeLines(
      c(existing, paste("Scaffolded at:", Sys.time())),
      ".framework_scaffolded"
    )
  }

  invisible(NULL)
}
