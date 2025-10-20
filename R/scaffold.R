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
  project_root <- standardize_wd()

  # Fail fast if not in a Framework project
  if (is.null(project_root) || !file.exists("config.yml")) {
    stop(
      "Could not locate a Framework project.\n",
      "scaffold() searches for a project by looking for:\n",
      "  - config.yml in current or parent directories\n",
      "  - .Rproj file with config.yml nearby\n",
      "  - Common subdirectories (notebooks/, scripts/, etc.)\n",
      "Current directory: ", getwd(), "\n",
      "To create a new project, use: init()"
    )
  }

  # Only load package if not already loaded
  if (!"package:framework" %in% search()) {
    message("Loading framework package...")
    library(framework)
  }

  .load_environment()

  # Remove old config if it exists and unlock if needed
  if (exists("config", envir = .GlobalEnv)) {
    tryCatch({
      unlockBinding("config", .GlobalEnv)
    }, error = function(e) {
      # Binding doesn't exist or isn't locked
    })
    suppressWarnings(rm(config, envir = .GlobalEnv))
  }

  # Assign config to global environment
  config_obj <- .load_configuration(config_file)
  assign("config", config_obj, envir = .GlobalEnv)

  # Mark as scaffolded with timestamp
  .mark_scaffolded()

  # Ensure framework database exists
  .ensure_framework_db()

  # Set random seed for reproducibility (if configured)
  .set_random_seed(config_obj)

  .install_required_packages(config_obj)
  .load_libraries(config_obj)
  .load_functions()

  # Source scaffold.R if it exists
  if (file.exists("scaffold.R")) {
    source("scaffold.R")
  }

  # Create initial commit after first successful scaffold (if in git repo and no commits yet)
  .commit_after_scaffold()

  # Check git status and provide helpful reminder
  .check_git_status()
}

#' Load environment variables from .env file
#' @keywords internal
.load_environment <- function() {
  config <- read_config()

  # Only check root level dotenv_location (not nested in options)
  if (!is.null(config$dotenv_location)) {
    dotenv_path <- config$dotenv_location

    if (dir.exists(dotenv_path)) {
      dotenv_path <- file.path(dotenv_path, ".env")
    }

    if (!file.exists(dotenv_path)) {
      stop(sprintf("Dotenv file not found at '%s'", dotenv_path))
    }

    dotenv::load_dot_env(dotenv_path)
  } else {
    # Only load .env if it exists (optional for projects without secrets)
    if (file.exists(".env")) {
      dotenv::load_dot_env()
    }
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

#' Ensure framework database exists
#' @keywords internal
.ensure_framework_db <- function() {
  if (!file.exists("framework.db")) {
    message(
      "\u26A0 Framework database not found. Creating framework.db...\n",
      "  This database tracks data integrity, cache, and results.\n",
      "  It's already in .gitignore and safe to commit the schema."
    )

    # Initialize the database
    tryCatch(
      {
        .init_db()
        message("\u2713 Framework database created successfully")
      },
      error = function(e) {
        warning(
          "Could not create framework.db: ", e$message, "\n",
          "Some Framework features (data tracking, caching, results) may not work.\n",
          "You can manually create it by running: framework:::.init_db()"
        )
      }
    )
  }

  invisible(NULL)
}

#' Set random seed for reproducibility
#' @param config Configuration object from read_config()
#' @keywords internal
#' @description
#' Sets the random seed for reproducibility. Checks for seed in this order:
#' 1. Project config.yml (seed: value)
#' 2. Global ~/.frameworkrc (FW_SEED)
#' 3. Skip seeding if both are NULL or empty
.set_random_seed <- function(config) {
  # Try project config first
  seed_value <- config$seed

  # Fall back to global frameworkrc if project seed not specified
  if (is.null(seed_value)) {
    global_seed <- Sys.getenv("FW_SEED", "")
    if (nzchar(global_seed)) {
      seed_value <- as.integer(global_seed)
    }
  }

  # Set seed if we have a valid value
  if (!is.null(seed_value) && !is.na(seed_value)) {
    set.seed(seed_value)
    message(sprintf(
      "\u2713 Random seed set to %s (for reproducibility). Override with set.seed() if needed.",
      seed_value
    ))
  }

  invisible(NULL)
}

#' Check git status and provide helpful reminder
#' @keywords internal
.check_git_status <- function() {
  # Check if git is available and we're in a repo
  git_available <- tryCatch({
    result <- system2("git", c("rev-parse", "--git-dir"), stdout = TRUE, stderr = TRUE)
    !is.null(attr(result, "status")) && attr(result, "status") == 0 || is.null(attr(result, "status"))
  }, error = function(e) FALSE, warning = function(w) FALSE)

  if (!git_available) {
    return(invisible(NULL))
  }

  # Check for uncommitted changes
  status_result <- tryCatch({
    system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = FALSE)
  }, error = function(e) NULL, warning = function(w) NULL)

  if (is.null(status_result) || length(status_result) == 0) {
    return(invisible(NULL))
  }

  # Count changes
  n_changes <- length(status_result)

  if (n_changes > 0) {
    message(sprintf(
      "\n\u26A0 Git: %d uncommitted file%s. Remember to commit your work!",
      n_changes,
      if (n_changes == 1) "" else "s"
    ))
  }

  invisible(NULL)
}

#' Create initial commit after first successful scaffold
#' @keywords internal
#' @note This function is now deprecated. Initial commits are created during init()
#'   instead of scaffold(). Kept for backward compatibility with older projects.
.commit_after_scaffold <- function() {
  # Check if git is available and we're in a repo
  git_available <- tryCatch({
    system("git rev-parse --git-dir > /dev/null 2>&1") == 0
  }, error = function(e) FALSE, warning = function(w) FALSE)

  if (!git_available) {
    return(invisible(NULL))
  }

  # Check if there are any commits yet
  has_commits <- tryCatch({
    system("git rev-parse HEAD > /dev/null 2>&1") == 0
  }, error = function(e) FALSE, warning = function(w) FALSE)

  # Only create commit if this is first scaffold (no commits yet)
  # This handles the case where older projects initialized before init() created commits
  if (!has_commits) {
    # No commits yet - add and commit everything
    tryCatch({
      # Add all files (including any created after init, like .github/)
      system("git add -A > /dev/null 2>&1")
      commit_result <- system("git commit -m \"Project initialized.\" > /dev/null 2>&1")
      if (commit_result == 0) {
        message("\u2713 Initial commit created")
      }
    }, error = function(e) {
      # Silent failure - user may not have git configured
      invisible(NULL)
    })
  }

  invisible(NULL)
}
