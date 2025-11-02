#' Launch Framework GUI
#'
#' Opens a beautiful web-based interface for Framework with documentation,
#' project management, and settings configuration.
#'
#' @param port Port number to use (default: 8080)
#' @param browse Automatically open browser (default: TRUE)
#'
#' @return Invisibly returns the httpuv server object
#'
#' @examples
#' \dontrun{
#' # Launch the GUI
#' gui()
#' framework_gui()
#'
#' # Launch on specific port
#' gui(port = 8888)
#' }
#'
#' @export
#' @rdname gui
framework_gui <- function(port = 0, browse = TRUE) {
  # Helper functions
  .json_response <- function(data, status = 200L) {
    list(
      status = status,
      headers = list(
        'Content-Type' = 'application/json',
        'Access-Control-Allow-Origin' = '*'
      ),
      body = jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")
    )
  }

  .parse_json_body <- function(req) {
    if (is.null(req$rook.input)) {
      return(list())
    }
    raw_body <- req$rook.input$read()
    if (length(raw_body) == 0) {
      return(list())
    }
    jsonlite::fromJSON(rawToChar(raw_body))
  }

  .serve_static_file <- function(file_path, content_type = "text/html") {
    if (file.exists(file_path)) {
      # Read binary files (images) as raw bytes
      is_binary <- grepl("^image/", content_type)
      body <- if (is_binary) {
        readBin(file_path, "raw", file.info(file_path)$size)
      } else {
        paste(readLines(file_path, warn = FALSE), collapse = "\n")
      }

      list(
        status = 200L,
        headers = list('Content-Type' = content_type),
        body = body
      )
    } else {
      list(
        status = 404L,
        headers = list('Content-Type' = 'text/plain'),
        body = "Not Found"
      )
    }
  }

  # HTTP app definition
  app <- list(
    call = function(req) {
      path <- req$PATH_INFO

      # Serve index.html for root
      if (path == "/" || path == "/index.html") {
        html_path <- system.file("gui/index.html", package = "framework")
        return(.serve_static_file(html_path, "text/html"))
      }

      # Serve static assets
      if (grepl("^/assets/", path)) {
        asset_path <- system.file(paste0("gui", path), package = "framework")
        content_type <- if (grepl("\\.css$", path)) {
          "text/css"
        } else if (grepl("\\.js$", path)) {
          "application/javascript"
        } else {
          "application/octet-stream"
        }
        return(.serve_static_file(asset_path, content_type))
      }

      # Serve static image files (logo, icons, etc.)
      if (grepl("\\.(png|jpg|jpeg|svg|ico)$", path)) {
        img_path <- system.file(paste0("gui", path), package = "framework")
        content_type <- if (grepl("\\.png$", path)) {
          "image/png"
        } else if (grepl("\\.jpg$|.jpeg$", path)) {
          "image/jpeg"
        } else if (grepl("\\.svg$", path)) {
          "image/svg+xml"
        } else if (grepl("\\.ico$", path)) {
          "image/x-icon"
        } else {
          "application/octet-stream"
        }
        return(.serve_static_file(img_path, content_type))
      }

      # Serve documentation JSON files
      if (grepl("^/docs/.*\\.json$", path)) {
        doc_path <- system.file(paste0("gui", path), package = "framework")
        if (file.exists(doc_path)) {
          doc_data <- jsonlite::fromJSON(doc_path)
          return(.json_response(doc_data))
        }
        return(.json_response(list(error = "Documentation not found"), 404L))
      }

      # API: Get global settings
      if (path == "/api/settings/get") {
        settings <- .read_frameworkrc()

        # Enrich projects with live metadata from settings.yml
        if (!is.null(settings$projects) && length(settings$projects) > 0) {
          settings$projects <- lapply(settings$projects, function(proj) {
            if (!is.null(proj$path) && dir.exists(proj$path)) {
              metadata <- .read_project_metadata(proj$path)
              # Merge, with metadata overriding any existing values
              modifyList(proj, metadata)
            } else {
              # Project directory doesn't exist anymore
              modifyList(proj, list(name = basename(proj$path), type = "unknown"))
            }
          })
        }

        return(.json_response(settings))
      }

      # API: Save global settings
      if (path == "/api/settings/save" && req$REQUEST_METHOD == "POST") {
        body <- .parse_json_body(req)
        tryCatch({
          .write_frameworkrc(body)
          return(.json_response(list(success = TRUE)))
        }, error = function(e) {
          return(.json_response(list(error = e$message), 500L))
        })
      }

      # API: Get current project context
      if (path == "/api/context") {
        context <- list(
          inProject = file.exists("config.yml") || file.exists("settings.yml"),
          projectPath = NULL,
          projectName = NULL,
          activeProject = NULL
        )

        if (context$inProject) {
          context$projectPath <- getwd()

          # Try to read project name from config
          config_file <- if (file.exists("config.yml")) "config.yml" else "settings.yml"
          tryCatch({
            cfg <- config::get(file = config_file)
            context$projectName <- cfg$project_name %||% basename(getwd())
          }, error = function(e) {
            context$projectName <- basename(getwd())
          })
        }

        # Check for active project in global config
        global_config <- .read_frameworkrc()
        if (!is.null(global_config$active_project)) {
          # Find the project in the projects list
          if (!is.null(global_config$projects) && length(global_config$projects) > 0) {
            matching_project <- NULL
            for (proj in global_config$projects) {
              if (proj$path == global_config$active_project) {
                matching_project <- proj
                break
              }
            }
            if (!is.null(matching_project)) {
              context$activeProject <- matching_project
            }
          }
        }

        return(.json_response(context))
      }

      # API: Set active project
      if (path == "/api/project/set-active" && req$REQUEST_METHOD == "POST") {
        body <- .parse_json_body(req)

        tryCatch({
          if (is.null(body$project_path)) {
            return(.json_response(list(error = "Project path required"), 400L))
          }

          # Read global config
          config <- .read_frameworkrc()

          # Set active project
          config$active_project <- body$project_path

          # Write updated config
          .write_frameworkrc(config)

          return(.json_response(list(success = TRUE)))
        }, error = function(e) {
          return(.json_response(list(error = e$message), 500L))
        })
      }

      # API: Get project config (if in a project)
      if (path == "/api/project/get") {
        if (file.exists("settings.yml")) {
          cfg <- config::get(file = "settings.yml")
          return(.json_response(cfg))
        }
        return(.json_response(list(error = "No project detected"), 404L))
      }

      # API: Create new project
      if (path == "/api/project/create" && req$REQUEST_METHOD == "POST") {
        body <- .parse_json_body(req)

        tryCatch({
          # Validate required fields
          if (is.null(body$project_dir) || nchar(body$project_dir) == 0) {
            return(.json_response(list(error = "Project directory required"), 400L))
          }

          if (dir.exists(body$project_dir)) {
            return(.json_response(list(error = "Directory already exists"), 400L))
          }

          # Clone template repository
          git_result <- system2(
            "git",
            c("clone", "--quiet", "https://github.com/table1/framework-project", body$project_dir),
            stdout = TRUE,
            stderr = TRUE
          )

          if (attr(git_result, "status") != 0 && !is.null(attr(git_result, "status"))) {
            return(.json_response(list(error = "Failed to clone template"), 500L))
          }

          # Change to project directory and run init
          old_wd <- getwd()
          on.exit(setwd(old_wd), add = TRUE)
          setwd(body$project_dir)

          init(
            project_name = body$project_name,
            type = body$type %||% "project",
            sensitive = body$sensitive %||% FALSE,
            use_git = body$use_git %||% TRUE,
            use_renv = body$use_renv %||% FALSE,
            attach_defaults = body$attach_defaults %||% TRUE,
            author_name = body$author_name,
            author_email = body$author_email,
            author_affiliation = body$author_affiliation,
            default_notebook_format = body$default_format %||% "quarto"
          )

          # Track project in global config
          .add_project_to_config(
            project_dir = body$project_dir,
            project_name = body$project_name %||% basename(body$project_dir),
            project_type = body$type %||% "project"
          )

          return(.json_response(list(
            success = TRUE,
            project_dir = body$project_dir
          )))

        }, error = function(e) {
          return(.json_response(list(error = e$message), 500L))
        })
      }

      # API: Resolve project root from file path
      if (path == "/api/project/resolve-root" && req$REQUEST_METHOD == "POST") {
        body <- .parse_json_body(req)

        tryCatch({
          if (is.null(body$file_path) || nchar(body$file_path) == 0) {
            return(.json_response(list(error = "File path required"), 400L))
          }

          file_path <- body$file_path

          # Start from the file's directory
          current_dir <- if (dir.exists(file_path)) {
            file_path
          } else {
            dirname(file_path)
          }

          # Traverse up looking for config.yml or settings.yml
          max_levels <- 10  # Safety limit
          found_root <- NULL

          for (i in 1:max_levels) {
            # Check for config files
            if (file.exists(file.path(current_dir, "config.yml")) ||
                file.exists(file.path(current_dir, "settings.yml"))) {
              found_root <- current_dir
              break
            }

            # Move up one directory
            parent_dir <- dirname(current_dir)

            # Stop if we've reached the root or can't go higher
            if (parent_dir == current_dir || parent_dir == "/") {
              break
            }

            current_dir <- parent_dir
          }

          if (is.null(found_root)) {
            return(.json_response(list(
              error = "Could not find Framework project root (no config.yml or settings.yml found)"
            ), 404L))
          }

          return(.json_response(list(
            project_root = found_root
          )))

        }, error = function(e) {
          return(.json_response(list(error = e$message), 500L))
        })
      }

      # API: Import existing project
      if (path == "/api/project/import" && req$REQUEST_METHOD == "POST") {
        body <- .parse_json_body(req)

        tryCatch({
          # Validate directory exists
          if (is.null(body$project_dir) || nchar(body$project_dir) == 0) {
            return(.json_response(list(error = "Project directory required"), 400L))
          }

          if (!dir.exists(body$project_dir)) {
            return(.json_response(list(error = "Directory does not exist"), 404L))
          }

          # Check for config.yml or settings.yml
          config_path <- NULL
          if (file.exists(file.path(body$project_dir, "config.yml"))) {
            config_path <- file.path(body$project_dir, "config.yml")
          } else if (file.exists(file.path(body$project_dir, "settings.yml"))) {
            config_path <- file.path(body$project_dir, "settings.yml")
          }

          if (is.null(config_path)) {
            return(.json_response(list(
              error = "Not a Framework project (no config.yml or settings.yml found)"
            ), 400L))
          }

          # Read project metadata
          cfg <- config::get(file = config_path)
          project_name <- cfg$project_name %||% basename(body$project_dir)
          project_type <- cfg$project_type %||% "project"

          # Add to registry
          .add_project_to_config(
            project_dir = body$project_dir,
            project_name = project_name,
            project_type = project_type
          )

          return(.json_response(list(
            success = TRUE,
            project_name = project_name,
            project_type = project_type
          )))

        }, error = function(e) {
          return(.json_response(list(error = e$message), 500L))
        })
      }

      # 404 for everything else
      list(
        status = 404L,
        headers = list('Content-Type' = 'text/plain'),
        body = "Not Found"
      )
    }
  )

  # Start server on safe port (avoid browser-blocked ports)
  # If port is 0 (auto), use a safe range: 8000-9000
  if (port == 0) {
    port <- 8080
  }
  server <- httpuv::startServer("127.0.0.1", port, app)
  url <- paste0("http://127.0.0.1:", server$getPort())

  message("\n")
  message("================================================================")
  message("Framework GUI")
  message("================================================================")
  message(sprintf("Running at: %s", url))
  message("Press Ctrl+C to stop")
  message("================================================================")
  message("\n")

  if (browse) {
    utils::browseURL(url)
  }

  # Keep server alive
  on.exit(httpuv::stopServer(server), add = TRUE)

  while (TRUE) {
    httpuv::service()
    Sys.sleep(0.01)
  }

  invisible(server)
}


# Helper to read project metadata from settings.yml
.read_project_metadata <- function(project_path) {
  # Default metadata if we can't read the file
  default_metadata <- list(
    name = basename(project_path),
    type = "project",
    author = NULL,
    author_email = NULL
  )

  # Try to find settings.yml or config.yml
  settings_file <- NULL
  if (file.exists(file.path(project_path, "settings.yml"))) {
    settings_file <- file.path(project_path, "settings.yml")
  } else if (file.exists(file.path(project_path, "config.yml"))) {
    settings_file <- file.path(project_path, "config.yml")
  } else {
    return(default_metadata)
  }

  # Try to read the settings
  tryCatch({
    settings <- config::get(file = settings_file)

    list(
      name = settings$project_name %||% basename(project_path),
      type = settings$project_type %||% "project",
      author = settings$author %||% NULL,
      author_email = settings$author_email %||% NULL
    )
  }, error = function(e) {
    default_metadata
  })
}


# Helper to read .framework.yml (with .frameworkrc fallback)
.read_frameworkrc <- function() {
  # Try new YAML file first
  framework_yml <- file.path(Sys.getenv("HOME"), ".framework.yml")
  frameworkrc <- file.path(Sys.getenv("HOME"), ".frameworkrc")

  # Migrate old .frameworkrc to .framework.yml if it exists
  if (file.exists(frameworkrc) && !file.exists(framework_yml)) {
    file.rename(frameworkrc, framework_yml)
    message("Migrated ~/.frameworkrc to ~/.framework.yml")
  }

  config_file <- if (file.exists(framework_yml)) framework_yml else frameworkrc

  if (!file.exists(config_file)) {
    return(list(
      author = list(
        name = "",
        email = "",
        affiliation = ""
      ),
      defaults = list(
        notebook_format = "quarto",
        ide = "vscode"
      ),
      projects = list()
    ))
  }

  # Try to read as YAML first
  tryCatch({
    config <- yaml::read_yaml(config_file)

    # If it's already in new format, return as-is
    if (!is.null(config$author) || !is.null(config$defaults) || !is.null(config$projects)) {
      # Ensure all sections exist
      if (is.null(config$author)) {
        config$author <- list(name = "", email = "", affiliation = "")
      }
      if (is.null(config$defaults)) {
        config$defaults <- list(notebook_format = "quarto", ide = "vscode")
      }
      if (is.null(config$projects)) {
        config$projects <- list()
      }
      return(config)
    }

    # If it's old shell-style format that yaml parsed as key-value pairs, migrate it
    return(.migrate_frameworkrc(config))

  }, error = function(e) {
    # If YAML parsing fails, try reading as old shell-style format
    lines <- readLines(config_file, warn = FALSE)
    lines <- lines[!grepl("^#", lines) & nchar(trimws(lines)) > 0]

    old_settings <- list()
    for (line in lines) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) == 2) {
        key <- trimws(parts[1])
        value <- trimws(gsub('^"|"$', '', parts[2]))
        old_settings[[key]] <- value
      }
    }

    return(.migrate_frameworkrc(old_settings))
  })
}

# Helper to migrate old format to new format
.migrate_frameworkrc <- function(old_config) {
  new_config <- list(
    author = list(
      name = old_config$FW_AUTHOR_NAME %||% "",
      email = old_config$FW_AUTHOR_EMAIL %||% "",
      affiliation = old_config$FW_AUTHOR_AFFILIATION %||% ""
    ),
    defaults = list(
      notebook_format = old_config$FW_DEFAULT_FORMAT %||% "quarto",
      ide = old_config$FW_IDES %||% old_config$FW_IDE %||% "vscode"
    ),
    projects = list()
  )

  # Write migrated config back
  .write_frameworkrc(new_config)

  new_config
}


# Helper to write .framework.yml
.write_frameworkrc <- function(settings) {
  framework_yml <- file.path(Sys.getenv("HOME"), ".framework.yml")

  # Normalize settings structure (handle both old and new format from GUI)
  if (!is.null(settings$author_name)) {
    # Old format from GUI, convert to new structure
    settings <- list(
      author = list(
        name = settings$author_name %||% "",
        email = settings$author_email %||% "",
        affiliation = settings$author_affiliation %||% ""
      ),
      defaults = list(
        notebook_format = settings$default_format %||% "quarto",
        ide = settings$ide %||% "vscode"
      ),
      projects = settings$projects %||% list()
    )
  }

  # Ensure all required sections exist
  if (is.null(settings$author)) {
    settings$author <- list(name = "", email = "", affiliation = "")
  }
  if (is.null(settings$defaults)) {
    settings$defaults <- list(notebook_format = "quarto", ide = "vscode")
  }
  if (is.null(settings$projects)) {
    settings$projects <- list()
  }

  yaml::write_yaml(settings, framework_yml)
  invisible(TRUE)
}

# Helper to add project to config
.add_project_to_config <- function(project_dir, project_name = NULL, project_type = NULL) {
  config <- .read_frameworkrc()

  # Create project entry - store only path and created date
  # Metadata (name, type, author) will be read from settings.yml when needed
  new_project <- list(
    path = normalizePath(project_dir, mustWork = FALSE),
    created = format(Sys.Date(), "%Y-%m-%d")
  )

  # Add to projects list
  if (is.null(config$projects)) {
    config$projects <- list()
  }

  # Check if project already exists (by path)
  if (length(config$projects) > 0) {
    existing_idx <- which(sapply(config$projects, function(p) p$path == new_project$path))
    if (length(existing_idx) > 0) {
      # Update existing entry
      config$projects[[existing_idx[1]]] <- new_project
    } else {
      # Add new entry
      config$projects[[length(config$projects) + 1]] <- new_project
    }
  } else {
    # First project
    config$projects <- list(new_project)
  }

  .write_frameworkrc(config)
  invisible(TRUE)
}


#' @export
#' @rdname gui
gui <- framework_gui


#' Stop GUI Server
#'
#' Stops a running Framework GUI server by port number or stops all running servers.
#'
#' @param port Port number of the server to stop. If NULL, stops all Framework GUI servers.
#' @param all Logical; if TRUE, stops all running Framework GUI servers.
#'
#' @return Invisibly returns TRUE if any servers were stopped, FALSE otherwise.
#'
#' @examples
#' \dontrun{
#' # Stop server on specific port
#' gui_stop(port = 8080)
#'
#' # Stop all Framework GUI servers
#' gui_stop(all = TRUE)
#' }
#'
#' @export
gui_stop <- function(port = NULL, all = FALSE) {
  # Find R processes running framework_gui or gui
  ps_output <- system2("ps", c("aux"), stdout = TRUE)
  gui_processes <- grep("framework_gui\\|httpuv.*8080", ps_output, value = TRUE)

  if (length(gui_processes) == 0) {
    message("No Framework GUI servers found running")
    return(invisible(FALSE))
  }

  pids <- sapply(strsplit(gui_processes, "\\s+"), function(x) x[2])

  if (!is.null(port) && !all) {
    # Try to find process on specific port
    port_processes <- grep(as.character(port), gui_processes, value = TRUE)
    if (length(port_processes) > 0) {
      port_pids <- sapply(strsplit(port_processes, "\\s+"), function(x) x[2])
      system2("kill", port_pids)
      message(sprintf("Stopped GUI server on port %d", port))
      return(invisible(TRUE))
    } else {
      message(sprintf("No GUI server found on port %d", port))
      return(invisible(FALSE))
    }
  } else if (all) {
    # Stop all GUI servers
    system2("kill", pids)
    message(sprintf("Stopped %d GUI server(s)", length(pids)))
    return(invisible(TRUE))
  }

  invisible(FALSE)
}


#' List Running GUI Servers
#'
#' Shows all currently running Framework GUI servers with their ports and PIDs.
#'
#' @return Invisibly returns a data frame of running servers, or NULL if none found.
#'
#' @examples
#' \dontrun{
#' gui_list()
#' }
#'
#' @export
gui_list <- function() {
  ps_output <- system2("ps", c("aux"), stdout = TRUE)
  gui_processes <- grep("framework_gui\\|httpuv.*8080", ps_output, value = TRUE)

  if (length(gui_processes) == 0) {
    message("No Framework GUI servers currently running")
    return(invisible(NULL))
  }

  message("\nRunning Framework GUI servers:")
  message("════════════════════════════════════════")

  for (proc in gui_processes) {
    parts <- strsplit(proc, "\\s+")[[1]]
    pid <- parts[2]
    message(sprintf("PID: %s", pid))
  }

  message("\nTo stop: gui_stop(all = TRUE)")

  invisible(gui_processes)
}


#' Restart GUI Server
#'
#' Stops any running GUI servers and starts a new one.
#'
#' @param port Port number to use (default: 8080)
#' @param browse Automatically open browser (default: TRUE)
#'
#' @return Invisibly returns the httpuv server object
#'
#' @examples
#' \dontrun{
#' # Restart GUI on default port
#' gui_restart()
#'
#' # Restart on specific port
#' gui_restart(port = 9090)
#' }
#'
#' @export
gui_restart <- function(port = 8080, browse = TRUE) {
  # Stop existing servers
  gui_stop(all = TRUE)

  # Give processes time to clean up
  Sys.sleep(0.5)

  # Start new server
  framework_gui(port = port, browse = browse)
}


#' @export
#' @rdname gui
gui_stop <- gui_stop

#' @export
#' @rdname gui
gui_list <- gui_list

#' @export
#' @rdname gui
gui_restart <- gui_restart
