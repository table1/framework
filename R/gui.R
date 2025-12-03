#' Setup Framework (First-Time Configuration)
#'
#' Initializes Framework's global configuration and launches the GUI for
#' first-time setup. This is the recommended entry point for new users.
#'
#' Use this function after installing Framework to:
#' - Set your author name and email
#' - Configure default packages for new projects
#' - Set IDE preferences (VS Code, RStudio)
#' - Configure other global defaults
#'
#' @param port Port number to use (default: 8080)
#' @param browse Automatically open browser (default: TRUE)
#'
#' @return Invisibly returns the plumber server object
#'
#' @examples
#' \dontrun{
#' # First-time setup
#' framework::setup()
#' }
#'
#' @seealso [gui()] for launching the GUI without initialization check
#'
#' @export
setup <- function(port = 8080, browse = TRUE) {
  # Ensure global config exists
  init_global_config()

  # Launch GUI
  gui(port = port, browse = browse)
}

#' Launch Framework GUI
#'
#' Opens a beautiful web-based interface for Framework with documentation,
#' project management, and settings configuration.
#'
#' @param port Port number to use (default: 8080)
#' @param browse Automatically open browser (default: TRUE)
#'
#' @return Invisibly returns the plumber server object
#'
#' @examples
#' \dontrun{
#' # Launch the GUI
#' framework::gui()
#'
#' # Launch on specific port
#' framework::gui(port = 8888)
#' }
#'
#' @seealso [setup()] for first-time configuration
#'
#' @export
gui <- function(port = 8080, browse = TRUE) {
  # Check if we're in development mode (loaded via devtools::load_all)
  is_dev_mode <- FALSE
  pkg_path <- find.package("framework")
  if (file.exists(file.path(pkg_path, "DESCRIPTION"))) {
    # We're in a development directory structure
    is_dev_mode <- TRUE
    dev_root <- pkg_path
  }

  # Find GUI assets directory
  if (is_dev_mode) {
    gui_path <- file.path(dev_root, "inst", "gui")
  } else {
    gui_path <- system.file("gui", package = "framework")
  }
  if (gui_path == "" || !dir.exists(gui_path)) {
    stop("GUI assets not found. Please rebuild the package with `npm run deploy`.")
  }

  # Find plumber API file
  if (is_dev_mode) {
    plumber_file <- file.path(dev_root, "inst", "plumber.R")
  } else {
    plumber_file <- system.file("plumber.R", package = "framework")
  }
  if (plumber_file == "" || !file.exists(plumber_file)) {
    stop("Plumber API file not found.")
  }

  # Create plumber API
  pr <- plumber::plumber$new(plumber_file)

  # Add static file serving filter for GUI assets
  pr$filter("static", function(req, res) {
    # Only handle non-API requests
    if (!grepl("^/api/", req$PATH_INFO)) {
      # Determine file path
      path <- req$PATH_INFO
      if (path == "/" || path == "") {
        path <- "/index.html"
      }

      file_path <- file.path(gui_path, gsub("^/", "", path))

      if (file.exists(file_path)) {
        # Determine content type
        ext <- tools::file_ext(file_path)
        content_type <- switch(ext,
          html = "text/html",
          css = "text/css",
          js = "application/javascript",
          json = "application/json",
          png = "image/png",
          jpg = "image/jpeg",
          jpeg = "image/jpeg",
          gif = "image/gif",
          svg = "image/svg+xml",
          ico = "image/x-icon",
          "application/octet-stream"
        )

        # Read file
        is_binary <- grepl("^image/", content_type) || ext == "ico"
        if (is_binary) {
          body <- readBin(file_path, "raw", file.info(file_path)$size)
        } else {
          body <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
        }

        res$status <- 200
        res$setHeader("Content-Type", content_type)
        res$body <- body
        return(res)
      }
    }

    plumber::forward()
  })

  # Enable CORS
  pr$filter("cors", function(req, res) {
    res$setHeader("Access-Control-Allow-Origin", "*")
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    res$setHeader("Access-Control-Allow-Headers", "Content-Type")

    if (req$REQUEST_METHOD == "OPTIONS") {
      res$status <- 200
      return(list())
    } else {
      plumber::forward()
    }
  })

  # Print startup message
  cat("\n================================================================\n")
  cat("Framework GUI\n")
  cat("================================================================\n")
  cat("Running at: http://127.0.0.1:", port, "\n", sep = "")
  cat("Press Ctrl+C to stop\n")
  cat("================================================================\n\n")

  # Open browser if requested
  if (browse) {
    utils::browseURL(paste0("http://127.0.0.1:", port))
  }

  # Run the server (blocking until Ctrl+C)
  pr$run(port = port, host = "127.0.0.1")
}
