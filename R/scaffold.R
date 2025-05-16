#' Initialize and load the project environment
#'
#' This function initializes the project environment by:
#' 1. Loading environment variables from .env
#' 2. Loading configuration from config.yml
#' 3. Installing required packages
#' 4. Loading all functions from the functions directory
#'
#' @export
scaffold <- function() {
  message("Scaffolding your project...")

  # Only load package if not already loaded
  if (!"package:framework" %in% search()) {
    message("Loading framework package...")
    library(framework)
  }

  .load_environment()
  config <<- .load_configuration()
  .install_required_packages(config)
  .load_libraries(config)
  .load_functions()

  # Source scaffold.R if it exists
  if (file.exists("scaffold")) {
    message("Sourcing scaffold...")
    source("scaffold")
  }
}

#' Load environment variables from .env file
#' @keywords internal
.load_environment <- function() {
  dotenv::load_dot_env()
}

#' Load configuration from config.yml
#' @keywords internal
.load_configuration <- function() {
  read_config()
}

#' Get package requirements from config
#' @param config Configuration object from config::get()
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
      list(
        name = pkg$name,
        load = isTRUE(pkg$attached) || isTRUE(pkg$load) || isTRUE(pkg$scaffold)
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
#' @param pkg Package name
#' @keywords internal
.install_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing package: %s", pkg))
    install.packages(pkg)
  }
}

#' Install required packages from config
#' @param config Configuration object from config::get()
#' @keywords internal
.install_required_packages <- function(config) {
  packages <- .get_package_requirements(config)
  for (pkg in packages) {
    .install_package(pkg$name)
  }
}

#' Load all libraries specified in config
#' @param config Configuration object from config::get()
#' @keywords internal
.load_libraries <- function(config) {
  packages <- .get_package_requirements(config)
  for (pkg in packages) {
    if (pkg$load) {
      message(sprintf("Loading library: %s", pkg$name))
      library(pkg$name, character.only = TRUE)
    }
  }
}

#' Load all R files from functions directory
#' @keywords internal
.load_functions <- function() {
  func_dir <- "functions"
  if (dir.exists(func_dir)) {
    func_files <- list.files(func_dir, pattern = "\\.R$", full.names = TRUE)
    for (file in func_files) {
      source(file)
    }
  } else {
    warning(sprintf("Functions directory '%s' not found", func_dir))
  }
}
