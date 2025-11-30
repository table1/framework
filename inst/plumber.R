# Framework GUI API
# This file defines all API endpoints for the Framework GUI using plumber

#* @apiTitle Framework GUI API
#* @apiDescription RESTful API for Framework GUI application
#* @plumber
function(pr) {
  # Configure JSON serializer to auto-unbox single-element arrays and properly handle NULL
  pr$registerHooks(list(
    preroute = function() {
      pr$setSerializer(plumber::serializer_json(auto_unbox = TRUE, null = "null"))
    }
  ))
}

# Helper function to read project metadata from settings file
.read_project_metadata <- function(project_path) {
  default_metadata <- list(
    name = basename(project_path),
    type = "project",
    author = NULL,
    author_email = NULL
  )

  settings_file <- NULL
  if (file.exists(file.path(project_path, "settings.yml"))) {
    settings_file <- file.path(project_path, "settings.yml")
  } else if (file.exists(file.path(project_path, "config.yml"))) {
    settings_file <- file.path(project_path, "config.yml")
  } else {
    return(default_metadata)
  }

  tryCatch({
    # Use yaml::read_yaml instead of config::get to avoid S3 class serialization issues
    settings_raw <- yaml::read_yaml(settings_file)
    settings <- settings_raw$default %||% settings_raw

    # Handle author field - could be a string (file reference) or an object
    author_name <- NULL
    author_email <- NULL

    if (!is.null(settings$author)) {
      if (is.character(settings$author) && length(settings$author) == 1 && grepl("\\.yml$", settings$author)) {
        # It's a file reference - try to read it
        author_file <- file.path(project_path, settings$author)
        if (file.exists(author_file)) {
          author_data <- tryCatch({
            yaml::read_yaml(author_file)
          }, error = function(e) NULL)

          if (!is.null(author_data) && !is.null(author_data$author)) {
            author_name <- author_data$author$name
            author_email <- author_data$author$email
          }
        }
      } else if (is.list(settings$author)) {
        # It's an object directly
        author_name <- settings$author$name
        author_email <- settings$author$email
      } else if (is.character(settings$author)) {
        # It's just a string name
        author_name <- settings$author
      }
    }

    list(
      name = as.character(settings$project_name %||% basename(project_path))[1],
      type = as.character(settings$project_type %||% "project")[1],
      author = if (!is.null(author_name)) as.character(author_name)[1] else NULL,
      author_email = if (!is.null(author_email)) as.character(author_email)[1] else NULL
    )
  }, error = function(e) {
    default_metadata
  })
}

.sanitize_relative_path <- function(path_value) {
  if (is.null(path_value) || is.na(path_value) || path_value == "") {
    return(NULL)
  }

  cleaned <- gsub("\\\\", "/", as.character(path_value)[1])
  cleaned <- gsub("^\\./", "", cleaned)

  if (grepl("\\.\\.", cleaned, fixed = TRUE)) {
    stop("Invalid path")
  }

  cleaned
}

#* Get global settings (simple endpoint for new project wizard)
#* @get /api/settings
#* @serializer unboxedJSON
function() {
  cat("[DEBUG] Using plumber.R at:", getwd(), "\n", file = stderr())
  settings_path <- path.expand("~/.config/framework/settings.yml")
  first_run <- !file.exists(settings_path)

  settings <- framework::read_frameworkrc()
  cat("[DEBUG] Author object:", names(settings$author), "\n", file = stderr())

  # Expand ~ in projects_root for frontend display and provide home directory
  settings$global$home_dir <- path.expand("~")
  if (!is.null(settings$global$projects_root)) {
    settings$global$projects_root <- path.expand(settings$global$projects_root)
  }

  # Flatten nested v2 structure to v1 flat structure for UI compatibility
  # UI expects flat defaults.* fields, not nested defaults.scaffold.*, etc.
  if (!is.null(settings$defaults)) {
    defaults_flat <- list()

    # Basic fields
    defaults_flat$project_type <- settings$defaults$project_type %||% "project"

    # Scaffold fields - flatten to root of defaults
    # IMPORTANT: Use field names that UI expects (notebook_format not default_format)
    if (!is.null(settings$defaults$scaffold)) {
      defaults_flat$seed_on_scaffold <- isTRUE(settings$defaults$scaffold$seed_on_scaffold)
      defaults_flat$seed <- settings$defaults$scaffold$seed %||% settings$defaults$seed
      defaults_flat$ide <- settings$defaults$scaffold$ide %||% settings$defaults$ide %||% "vscode"
      defaults_flat$positron <- isTRUE(settings$defaults$scaffold$positron %||% settings$defaults$positron)
      defaults_flat$notebook_format <- settings$defaults$scaffold$notebook_format %||% settings$defaults$notebook_format %||% "quarto"
    } else {
      # Fallback to flat fields if no nested scaffold
      defaults_flat$seed_on_scaffold <- isTRUE(settings$defaults$seed_on_scaffold)
      defaults_flat$seed <- settings$defaults$seed
      defaults_flat$ide <- settings$defaults$ide %||% "vscode"
      defaults_flat$positron <- isTRUE(settings$defaults$positron)
      defaults_flat$notebook_format <- settings$defaults$notebook_format %||% "quarto"
    }

    # renv - flatten from packages.use_renv to use_renv
    defaults_flat$use_renv <- if (!is.null(settings$defaults$packages$use_renv)) {
      isTRUE(settings$defaults$packages$use_renv)
    } else {
      isTRUE(settings$defaults$use_renv)
    }

    # Packages - convert to flat array
    defaults_flat$default_packages <- if (!is.null(settings$defaults$packages$default_packages)) {
      # Already structured from v2
      pkg_list <- settings$defaults$packages$default_packages
    } else if (!is.null(settings$defaults$packages) && is.list(settings$defaults$packages)) {
      # v1 format - packages is the list itself
      pkg_list <- settings$defaults$packages
    } else {
      list()
    }

    # Normalize packages to array of objects
    if (is.list(pkg_list) && length(pkg_list) > 0) {
      result <- lapply(pkg_list, function(pkg) {
        if (is.character(pkg) && length(pkg) == 1) {
          # Single string like "dplyr"
          list(name = pkg, auto_attach = TRUE)
        } else if (is.list(pkg) && !is.null(pkg$name)) {
          # Already proper format
          list(
            name = as.character(pkg$name),
            auto_attach = isTRUE(pkg$auto_attach)
          )
        } else {
          NULL
        }
      })
      defaults_flat$default_packages <- I(Filter(Negate(is.null), result))
    } else {
      defaults_flat$default_packages <- I(list())
    }

    # AI assistants - ensure it's an array at root defaults.ai_assistants
    ai_assistants_value <- settings$defaults$ai$assistants %||%
                           settings$defaults$ai_assistants %||%
                           "claude"

    if (is.character(ai_assistants_value)) {
      # Split comma-separated string or wrap single value
      if (grepl(",", ai_assistants_value)) {
        defaults_flat$ai_assistants <- I(strsplit(ai_assistants_value, ",\\s*")[[1]])
      } else {
        defaults_flat$ai_assistants <- I(c(ai_assistants_value))
      }
    } else if (is.list(ai_assistants_value) || is.vector(ai_assistants_value)) {
      defaults_flat$ai_assistants <- I(as.character(ai_assistants_value))
    } else {
      defaults_flat$ai_assistants <- I(c("claude"))
    }

    # AI support boolean
    defaults_flat$ai_support <- isTRUE(settings$defaults$ai$enabled %||%
                                       settings$defaults$ai_support %||%
                                       TRUE)

    defaults_flat$ai_canonical_file <- settings$defaults$ai$canonical_file %||%
                                       settings$defaults$ai_canonical_file %||%
                                       "CLAUDE.md"

    # Git hooks - flatten
    if (!is.null(settings$defaults$git$hooks)) {
      defaults_flat$git_hooks <- list(
        ai_sync = isTRUE(settings$defaults$git$hooks$ai_sync),
        data_security = isTRUE(settings$defaults$git$hooks$data_security),
        check_sensitive_dirs = isTRUE(settings$defaults$git$hooks$check_sensitive_dirs)
      )
    } else if (!is.null(settings$defaults$git_hooks)) {
      defaults_flat$git_hooks <- list(
        ai_sync = isTRUE(settings$defaults$git_hooks$ai_sync),
        data_security = isTRUE(settings$defaults$git_hooks$data_security),
        check_sensitive_dirs = isTRUE(settings$defaults$git_hooks$check_sensitive_dirs)
      )
    } else {
      defaults_flat$git_hooks <- list(
        ai_sync = FALSE,
        data_security = FALSE,
        check_sensitive_dirs = FALSE
      )
    }

    # Author info - check both defaults and author object (author object takes precedence)
    defaults_flat$author_name <- if (!is.null(settings$defaults$author_name)) settings$defaults$author_name else settings$author$name
    defaults_flat$author_email <- if (!is.null(settings$defaults$author_email)) settings$defaults$author_email else settings$author$email
    defaults_flat$author_affiliation <- if (!is.null(settings$defaults$author_affiliation)) settings$defaults$author_affiliation else settings$author$affiliation

    # Directories - preserve as-is
    defaults_flat$directories <- settings$defaults$directories %||% list()

    # Quarto settings - preserve as-is
    defaults_flat$quarto <- settings$defaults$quarto %||% list()

    # .env defaults - preserve as-is
    defaults_flat$env <- settings$defaults$env %||% list()

    # Connections defaults - preserve as-is
    defaults_flat$connections <- settings$defaults$connections %||% list()

    # Add alias for backwards compatibility (tests/UI may expect default_format)
    defaults_flat$default_format <- defaults_flat$notebook_format

    # Scaffold object for compatibility with new UI
    defaults_flat$scaffold <- list(
      seed_on_scaffold = defaults_flat$seed_on_scaffold,
      seed = defaults_flat$seed,
      ide = defaults_flat$ide,
      ides = defaults_flat$ide,  # Alias for backwards compatibility
      positron = defaults_flat$positron
    )

    # Replace nested structure with flat
    settings$defaults <- defaults_flat
  }

  # Add metadata about settings state
  settings$meta$first_run <- first_run
  settings$meta$settings_path <- settings_path

  return(settings)
}

#* Get global settings and projects list (legacy endpoint)
#* @get /api/settings/get
#* @serializer unboxedJSON
function() {
  settings_path <- path.expand("~/.config/framework/settings.yml")
  first_run <- !file.exists(settings_path)

  settings <- framework::read_frameworkrc()

  # DEBUG: Log what we're returning
  message("[API GET /api/settings/get] global.projects_root from read: ",
          settings$global$projects_root %||% "NULL")

  # Check if v1 format (no meta.version or version < 2)
  needs_migration <- is.null(settings$meta$version) || settings$meta$version < 2

  if (needs_migration) {
    message("Auto-migrating settings from v1 to v2...")

    # Build v2 structure
    settings_v2 <- list(
      meta = list(version = 2, description = "Framework global settings"),
      author = settings$author %||% list(
        name = "Your Name",
        email = "your.email@example.com",
        affiliation = "Your Institution"
      ),
      global = list(
        projects_root = settings$projects_root %||% "~/projects"
      ),
      defaults = list(
        project_type = settings$defaults$project_type %||% "project",
        scaffold = list(
          seed_on_scaffold = settings$defaults$seed_on_scaffold %||% FALSE,
          seed = settings$defaults$seed %||% "123",
          set_theme_on_scaffold = settings$defaults$set_theme_on_scaffold %||% FALSE,
          ggplot_theme = settings$defaults$ggplot_theme %||% "theme_minimal",
          notebook_format = settings$defaults$notebook_format %||% "quarto",
          ide = settings$defaults$ide %||% "vscode"
        ),
        packages = list(
          use_renv = settings$defaults$use_renv %||% FALSE,
          default_packages = if (!is.null(settings$defaults$packages) && is.list(settings$defaults$packages)) {
            # Convert to proper structure if needed, filtering out malformed entries
            result <- lapply(settings$defaults$packages, function(pkg) {
              if (is.character(pkg) && length(pkg) == 1) {
                # Single string like "dplyr"
                list(name = pkg, auto_attach = TRUE)
              } else if (is.list(pkg) && !is.null(pkg$name)) {
                # Already proper format
                list(name = as.character(pkg$name), auto_attach = isTRUE(pkg$auto_attach))
              } else {
                # Skip arrays, malformed entries, etc.
                NULL
              }
            })
            # Filter out NULLs and unbox to force JSON array
            filtered <- Filter(Negate(is.null), result)
            if (length(filtered) == 0) character(0) else filtered
          } else {
            character(0)
          }
        ),
        ai = list(
          enabled = settings$defaults$ai_support %||% TRUE,
          canonical_file = settings$defaults$ai_canonical_file %||% "CLAUDE.md",
          preferred_assistant = settings$defaults$ai_assistants %||% "claude",
          assistants = I(if (is.character(settings$defaults$ai_assistants)) {
            strsplit(settings$defaults$ai_assistants, ",\\s*")[[1]]
          } else {
            c("claude")
          })
        ),
        git = list(
          initialize = settings$defaults$use_git %||% TRUE,
          gitignore_template = settings$privacy$gitignore_template %||% "gitignore-project",
          hooks = list(
            ai_sync = settings$defaults$git_hooks$ai_sync %||% FALSE,
            data_security = settings$defaults$git_hooks$data_security %||% FALSE
          )
        )
      ),
      templates = settings$templates %||% list(),
      project_types = settings$project_types %||% list(),
      projects = settings$projects %||% list()
    )

    settings <- settings_v2

    # Save migrated settings back to disk
    framework::write_frameworkrc(settings)
  }

  # Enrich projects with live metadata
  if (!is.null(settings$projects) && length(settings$projects) > 0) {
    settings$projects <- lapply(settings$projects, function(proj) {
      if (!is.null(proj$path) && dir.exists(proj$path)) {
        metadata <- .read_project_metadata(proj$path)
        modifyList(proj, metadata)
      } else {
        modifyList(proj, list(name = basename(proj$path), type = "unknown"))
      }
    })
  }

  # Add metadata about settings state
  settings$meta$first_run <- first_run
  settings$meta$settings_path <- settings_path

  # CRITICAL FIX: Empty packages list becomes {} in JSON instead of []
  # Force it to be an array by using I() wrapper
  if (!is.null(settings$defaults$packages) && is.list(settings$defaults$packages) && length(settings$defaults$packages) == 0) {
    settings$defaults$packages <- I(list())
  }

  # DEBUG: Log final returned value
  message("[API GET /api/settings/get] Returning global.projects_root: ",
          settings$global$projects_root %||% "NULL")

  return(settings)
}

#* Get settings catalog (simple endpoint for new project wizard)
#* @get /api/settings-catalog
function() {
  framework::load_settings_catalog()
}

#* Get settings catalog metadata and defaults (legacy endpoint)
#* @get /api/settings/catalog
function() {
  framework::load_settings_catalog()
}

#* Fetch template contents for editing
#* @get /api/templates/<name>
function(name) {
  contents <- framework::read_framework_template(name)
  list(success = TRUE, name = name, contents = contents)
}

#* Update a template's contents
#* @post /api/templates/<name>
#* @param req The request object
function(name, req) {
  body <- jsonlite::fromJSON(req$postBody)
  framework::write_framework_template(name, body$contents %||% "")
  list(success = TRUE)
}

#* Reset a template back to defaults
#* @delete /api/templates/<name>
function(name) {
  framework::reset_framework_template(name)
  list(success = TRUE)
}

#* Save global settings
#* @post /api/settings/save
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)

  # DEBUG: Log what we received
  message("[API /api/settings/save] Received body$global$projects_root: ",
          body$global$projects_root %||% "NULL")
  message("[API /api/settings/save] Received body$projects_root: ",
          body$projects_root %||% "NULL")

  tryCatch({
    # Use unified configure_global function for validation and persistence
    framework::configure_global(settings = body, validate = TRUE)

    # DEBUG: Verify what was saved
    saved <- framework::read_frameworkrc()
    message("[API /api/settings/save] After save, global.projects_root: ",
            saved$global$projects_root %||% "NULL")

    list(success = TRUE)
  }, error = function(e) {
    message("ERROR: ", e$message)
    message("Traceback: ", paste(as.character(sys.calls()), collapse = "\n"))
    list(success = FALSE, error = e$message)
  })
}

#* Get current project context
#* @get /api/context
function() {
  context <- list(
    inProject = file.exists("config.yml") || file.exists("settings.yml"),
    projectPath = NULL,
    projectName = NULL
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

  return(context)
}

#* Get project by ID
#* @get /api/project/<id>
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        # Enrich with live metadata from settings file
        if (dir.exists(proj$path)) {
          metadata <- .read_project_metadata(proj$path)
          return(modifyList(proj, metadata))
        } else {
          return(proj)
        }
      }
    }
  }

  list(error = "Project not found")
}

#* Get data catalog for a project
#* @get /api/project/<id>/data
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Find settings file
  settings_file <- NULL
  if (file.exists(file.path(project$path, "settings.yml"))) {
    settings_file <- file.path(project$path, "settings.yml")
  } else if (file.exists(file.path(project$path, "config.yml"))) {
    settings_file <- file.path(project$path, "config.yml")
  } else {
    return(list(data = list()))
  }

  # Read settings and extract data catalog
  tryCatch({
    old_wd <- getwd()
    setwd(project$path)
    on.exit(setwd(old_wd))

    # Use yaml::read_yaml instead of config::get
    settings_raw <- yaml::read_yaml(settings_file)
    settings <- settings_raw$default %||% settings_raw

    # Get data section
    data_catalog <- settings$data

    # If data points to a file, read it
    if (is.character(data_catalog) && length(data_catalog) == 1 && grepl("\\.yml$", data_catalog)) {
      data_file <- file.path(project$path, data_catalog)
      if (file.exists(data_file)) {
        data_settings <- yaml::read_yaml(data_file)
        data_catalog <- data_settings$data
      }
    }

    list(data = data_catalog %||% list())
  }, error = function(e) {
    list(error = paste("Failed to read data catalog:", e$message))
  })
}

#* Save data catalog for a project
#* @post /api/project/<id>/data
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody, simplifyVector = FALSE)
  if (is.null(body$data)) {
    return(list(error = "Missing data payload"))
  }

  # Locate primary settings file
  settings_file <- NULL
  if (file.exists(file.path(project$path, "settings.yml"))) {
    settings_file <- file.path(project$path, "settings.yml")
  } else if (file.exists(file.path(project$path, "config.yml"))) {
    settings_file <- file.path(project$path, "config.yml")
  } else {
    return(list(error = "No settings file found"))
  }

  tryCatch({
    old_wd <- getwd()
    setwd(project$path)
    on.exit(setwd(old_wd))

    settings_raw <- yaml::read_yaml(settings_file)
    has_default <- !is.null(settings_raw$default)
    settings <- settings_raw$default %||% settings_raw

    data_ref <- settings$data
    if (is.character(data_ref) && length(data_ref) == 1 && grepl("\\.yml$", data_ref)) {
      data_file <- file.path(project$path, data_ref)
      dir.create(dirname(data_file), recursive = TRUE, showWarnings = FALSE)
      yaml::write_yaml(list(data = body$data), data_file)
    } else {
      settings$data <- body$data
      if (has_default) {
        settings_raw$default <- settings
        yaml::write_yaml(settings_raw, settings_file)
      } else {
        yaml::write_yaml(settings, settings_file)
      }
    }

    list(success = TRUE)
  }, error = function(e) {
    list(error = paste("Failed to save data catalog:", e$message))
  })
}

#* Get all settings for a project
#* @get /api/project/<id>/settings
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Find settings file
  settings_file <- NULL
  if (file.exists(file.path(project$path, "settings.yml"))) {
    settings_file <- file.path(project$path, "settings.yml")
  } else if (file.exists(file.path(project$path, "config.yml"))) {
    settings_file <- file.path(project$path, "config.yml")
  } else {
    return(list(error = "No settings file found"))
  }

  # Read all settings including delegated files
  tryCatch({
    old_wd <- getwd()
    setwd(project$path)
    on.exit(setwd(old_wd))

    # Use yaml::read_yaml instead of config::get to avoid S3 class issues
    settings_raw <- yaml::read_yaml(settings_file)
    settings <- settings_raw$default %||% settings_raw

    # Recursively resolve any file references in settings
    resolve_file_refs <- function(obj, base_path, parent_key = NULL) {
      if (is.list(obj)) {
        obj_names <- names(obj)

        if (is.null(obj_names)) {
          # Unnamed list (array) - process each element by index
          result <- lapply(seq_along(obj), function(i) {
            item <- obj[[i]]
            if (is.list(item)) {
              return(resolve_file_refs(item, base_path, parent_key))
            }
            item
          })
        } else {
          # Named list (object) - process by key with file reference resolution
          result <- lapply(obj_names, function(key) {
            item <- obj[[key]]
            if (is.character(item) && length(item) == 1 && grepl("\\.yml$", item)) {
              # This might be a file reference
              file_path <- file.path(base_path, item)
              if (file.exists(file_path)) {
                tryCatch({
                  sub_yaml <- yaml::read_yaml(file_path)
                  # Extract the content under the matching key
                  # e.g., for author.yml containing "author: {...}", extract just {...}
                  if (!is.null(sub_yaml[[key]])) {
                    return(sub_yaml[[key]])
                  }
                  # Otherwise return the whole thing
                  return(sub_yaml)
                }, error = function(e) item)
              }
            }
            if (is.list(item)) {
              return(resolve_file_refs(item, base_path, key))
            }
            item
          })
          names(result) <- obj_names
        }
        return(result)
      } else {
        obj
      }
    }

    settings_resolved <- resolve_file_refs(settings, project$path)

    # Read .gitignore file if it exists
    gitignore_path <- file.path(project$path, ".gitignore")
    if (file.exists(gitignore_path)) {
      gitignore_content <- paste(readLines(gitignore_path, warn = FALSE), collapse = "\n")
      settings_resolved$gitignore <- gitignore_content
    } else {
      settings_resolved$gitignore <- ""
    }

    # CRITICAL: Ensure extra_directories is always an array (unnamed list)
    # YAML parser can convert single-element arrays to named lists (objects)
    if (!is.null(settings_resolved$extra_directories)) {
      # If it's a named list (has names), convert to unnamed list
      if (!is.null(names(settings_resolved$extra_directories)) && length(names(settings_resolved$extra_directories)) > 0) {
        # It's a named list (single object) - wrap in unnamed list
        settings_resolved$extra_directories <- list(settings_resolved$extra_directories)
        # Remove names to ensure it serializes as array
        names(settings_resolved$extra_directories) <- NULL
      } else {
        # It's already an unnamed list, just ensure no names
        names(settings_resolved$extra_directories) <- NULL
      }
    }

    # Return full settings
    list(settings = settings_resolved, project_path = project$path)
  }, error = function(e) {
    list(error = paste("Failed to read settings:", e$message))
  })
}

#* Save project settings
#* @post /api/project/<id>/settings
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody)

  # DEBUG: Log what we received
  message("[DEBUG] Received extra_directories: ", jsonlite::toJSON(body$extra_directories, auto_unbox = TRUE))
  message("[DEBUG] Received enabled: ", jsonlite::toJSON(body$enabled, auto_unbox = TRUE))
  message("[DEBUG] extra_directories length: ", length(body$extra_directories))
  message("[DEBUG] extra_directories class: ", class(body$extra_directories))

  # CRITICAL: jsonlite converts arrays of objects to data.frames or weird column-wise structures
  # Convert back to proper array of objects (list of lists)
  if (!is.null(body$extra_directories) && length(body$extra_directories) > 0) {
    if (is.data.frame(body$extra_directories)) {
      # Data frame: each row is an object
      body$extra_directories <- lapply(1:nrow(body$extra_directories), function(i) {
        as.list(body$extra_directories[i, , drop = FALSE][1, ])
      })
    } else if (is.list(body$extra_directories)) {
      # Check if it's column-wise (all values for each field)
      # Heuristic: if first element is a vector, it's column-wise
      if (length(body$extra_directories) > 0 && (is.vector(body$extra_directories[[1]]) || is.list(body$extra_directories[[1]]))) {
        # Check if the last element is a proper object (new directory added)
        last_elem <- body$extra_directories[[length(body$extra_directories)]]
        if (is.list(last_elem) && !is.null(names(last_elem)) && "key" %in% names(last_elem)) {
          # Last element is a proper object, rest are column-wise
          # Extract the proper object and reconstruct the rest
          new_dir <- last_elem

          # The previous elements are columns - reconstruct objects from columns
          num_fields <- length(body$extra_directories) - 1
          if (num_fields > 0 && length(body$extra_directories[[1]]) > 0) {
            num_objects <- length(body$extra_directories[[1]])
            field_names <- c("key", "label", "path", "type", "_id", "render_for")

            reconstructed <- lapply(1:num_objects, function(i) {
              obj <- list()
              for (j in 1:min(num_fields, length(field_names))) {
                field_name <- field_names[j]
                if (j <= length(body$extra_directories)) {
                  obj[[field_name]] <- body$extra_directories[[j]][i]
                }
              }
              obj
            })

            # Combine reconstructed objects with the new directory
            body$extra_directories <- c(reconstructed, list(new_dir))
          } else {
            # Only the new directory
            body$extra_directories <- list(new_dir)
          }
        }
      }
    }
  }

  message("[DEBUG] After conversion, extra_directories: ", jsonlite::toJSON(body$extra_directories, auto_unbox = TRUE))

  tryCatch({
    old_wd <- getwd()
    setwd(project$path)
    on.exit(setwd(old_wd))

    # Save author settings
    if (!is.null(body$author)) {
      author_file <- "settings/author.yml"
      if (file.exists(author_file)) {
        message("Saving author to: ", author_file)
        message("Author data: ", jsonlite::toJSON(body$author, auto_unbox = TRUE))
        yaml::write_yaml(list(author = body$author), author_file)
        message("Author file saved successfully")
      } else {
        message("Author file does not exist: ", author_file)
      }
    } else {
      message("No author data in request body")
    }

    # Save directories settings
    if (!is.null(body$directories)) {
      if (file.exists("settings/directories.yml")) {
        yaml::write_yaml(list(directories = body$directories), "settings/directories.yml")
      }
    }

    # Save options settings
    if (!is.null(body$options)) {
      if (file.exists("settings/options.yml")) {
        yaml::write_yaml(list(options = body$options), "settings/options.yml")
      }
    }

    # Save git settings
    if (!is.null(body$git)) {
      if (file.exists("settings/git.yml")) {
        yaml::write_yaml(list(git = body$git), "settings/git.yml")
      }
    }

    # Save ai settings
    if (!is.null(body$ai)) {
      if (file.exists("settings/ai.yml")) {
        yaml::write_yaml(list(ai = body$ai), "settings/ai.yml")
      }
    }

    # Update main settings.yml if needed
    if (!is.null(body$project_name) || !is.null(body$project_type) || !is.null(body$extra_directories) || !is.null(body$enabled)) {
      settings_file <- if (file.exists("settings.yml")) "settings.yml" else "config.yml"
      current_settings <- yaml::read_yaml(settings_file)

      if (!is.null(body$project_name)) {
        current_settings$default$project_name <- body$project_name
      }
      if (!is.null(body$project_type)) {
        current_settings$default$project_type <- body$project_type
      }
      if (!is.null(body$extra_directories)) {
        # Ensure it's saved as an array (unnamed list) not an object
        extra_dirs <- body$extra_directories
        if (is.list(extra_dirs)) {
          names(extra_dirs) <- NULL  # Remove names to ensure array serialization
        }
        current_settings$default$extra_directories <- extra_dirs
      }
      if (!is.null(body$enabled)) {
        # Save enabled state for directories (includes extra directories)
        current_settings$default$enabled <- body$enabled
      }

      yaml::write_yaml(current_settings, settings_file)

      # DEBUG: Verify what was actually saved
      verification <- yaml::read_yaml(settings_file)
      message("[DEBUG] After save, file contains ", length(verification$default$extra_directories), " extra directories")
      message("[DEBUG] After save, extra_directories keys: ", paste(sapply(verification$default$extra_directories, function(d) d$key), collapse = ", "))
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Get project connections
#* @get /api/project/<id>/connections
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Check if connections file exists
  connections_file <- file.path(project$path, "settings/connections.yml")
  if (!file.exists(connections_file)) {
    return(list(
      default_database = NULL,
      default_storage_bucket = NULL,
      databases = list(),
      storage_buckets = list()
    ))
  }

  tryCatch({
    connections_data <- yaml::read_yaml(connections_file)
    list(
      default_database = connections_data$default_database,
      default_storage_bucket = connections_data$default_storage_bucket,
      databases = connections_data$databases %||% list(),
      storage_buckets = connections_data$storage_buckets %||% list()
    )
  }, error = function(e) {
    list(error = paste("Failed to read connections:", e$message))
  })
}

#* Save project connections
#* @post /api/project/<id>/connections
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody)

  tryCatch({
    # Check if using split file or inline approach
    split_info <- .uses_split_file(project$path, "connections")

    connections_data <- list(
      default_database = body$default_database,
      default_storage_bucket = body$default_storage_bucket,
      databases = body$databases %||% list(),
      storage_buckets = body$storage_buckets %||% list()
    )

    if (split_info$use_split) {
      # Write to split file: settings/connections.yml
      dir.create(dirname(split_info$split_file), recursive = TRUE, showWarnings = FALSE)
      yaml::write_yaml(list(connections = connections_data), split_info$split_file)
    } else {
      # Write inline to main settings file
      settings_raw <- yaml::read_yaml(split_info$main_file)
      has_default <- !is.null(settings_raw$default)
      settings <- settings_raw$default %||% settings_raw

      settings$connections <- connections_data

      if (has_default) {
        settings_raw$default <- settings
        yaml::write_yaml(settings_raw, split_info$main_file)
      } else {
        yaml::write_yaml(settings, split_info$main_file)
      }
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Get project packages
#* @get /api/project/<id>/packages
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Check if packages file exists
  packages_file <- file.path(project$path, "settings/packages.yml")
  if (!file.exists(packages_file)) {
    return(list(packages = list()))
  }

  tryCatch({
    packages_data <- yaml::read_yaml(packages_file)
    packages_obj <- packages_data$packages %||% list()

    # Extract use_renv flag (defaults to FALSE)
    use_renv <- if (!is.null(packages_obj$use_renv)) as.logical(packages_obj$use_renv)[1] else FALSE

    # Get the packages list - could be under default_packages or directly in packages
    raw_packages <- if (!is.null(packages_obj$default_packages)) {
      packages_obj$default_packages
    } else if (is.list(packages_obj) && (is.null(names(packages_obj)) || all(names(packages_obj) == ""))) {
      # Old format: packages was a direct array
      packages_obj
    } else {
      list()
    }

    # Handle legacy comma-separated string format
    if (is.character(raw_packages) && length(raw_packages) == 1) {
      # Split comma-separated string: "dplyr,ggplot2,readr" -> ["dplyr", "ggplot2", "readr"]
      raw_packages <- strsplit(raw_packages, "\\s*,\\s*")[[1]]
      raw_packages <- trimws(raw_packages)
      raw_packages <- raw_packages[nchar(raw_packages) > 0]
    }

    # Normalize packages - handle both string format and object format
    normalized_packages <- lapply(raw_packages, function(pkg) {
      if (is.character(pkg) && length(pkg) == 1) {
        # Simple string format: "dplyr" -> {name: dplyr, source: cran, auto_attach: true}
        list(
          name = unname(as.character(pkg))[1],
          source = "cran",
          auto_attach = TRUE
        )
      } else if (is.list(pkg) && !is.null(names(pkg))) {
        # Object format - ensure defaults and extract scalars
        list(
          name = if (!is.null(pkg$name)) unname(as.character(pkg$name))[1] else "",
          source = if (!is.null(pkg$source)) unname(as.character(pkg$source))[1] else "cran",
          auto_attach = if (!is.null(pkg$auto_attach)) as.logical(pkg$auto_attach)[1] else TRUE
        )
      } else {
        # Skip invalid entries
        NULL
      }
    })

    # Remove NULL entries
    normalized_packages <- Filter(Negate(is.null), normalized_packages)

    # Ensure unnamed list for JSON array serialization
    names(normalized_packages) <- NULL

    list(
      use_renv = use_renv,
      packages = normalized_packages
    )
  }, error = function(e) {
    list(error = paste("Failed to read packages:", e$message))
  })
}

#* Get project AI settings
#* @get /api/project/<id>/ai
#* @param id Project ID
#* @param canonical_file Optional canonical file to preview content for
function(id, canonical_file = NULL) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  settings_file <- NULL
  if (file.exists(file.path(project$path, "settings.yml"))) {
    settings_file <- file.path(project$path, "settings.yml")
  } else if (file.exists(file.path(project$path, "config.yml"))) {
    settings_file <- file.path(project$path, "config.yml")
  } else {
    return(list(error = "No settings file found"))
  }

  tryCatch({
    settings_raw <- yaml::read_yaml(settings_file)
    settings <- settings_raw$default %||% settings_raw

    ai_config <- settings$ai %||% list()
    ai_ref <- NULL

    if (is.character(ai_config) && length(ai_config) == 1 && grepl("\\.yml$", ai_config)) {
      ai_ref <- ai_config
      ai_file <- file.path(project$path, ai_config)
      if (file.exists(ai_file)) {
        ai_yaml <- yaml::read_yaml(ai_file)
        if (!is.null(ai_yaml$ai)) {
          ai_config <- ai_yaml$ai
        } else {
          ai_config <- ai_yaml
        }
      } else {
        ai_config <- list()
      }
    }

    enabled <- as.logical(ai_config$enabled %||% FALSE)[1]
    canonical <- as.character(ai_config$canonical_file %||% "CLAUDE.md")[1]
    assistants_raw <- ai_config$assistants %||% list()

    assistants <- if (is.list(assistants_raw) || is.vector(assistants_raw)) {
      as.list(unique(as.character(unlist(assistants_raw))))
    } else {
      list()
    }

    requested_file <- .sanitize_relative_path(canonical_file %||% canonical %||% "CLAUDE.md")
    if (is.null(requested_file) || requested_file == "") {
      requested_file <- "CLAUDE.md"
    }

    canonical_path <- file.path(project$path, requested_file)
    canonical_exists <- file.exists(canonical_path)
    canonical_content <- ""

    if (canonical_exists) {
      canonical_content <- paste(readLines(canonical_path, warn = FALSE), collapse = "\n")
    }

    list(
      success = TRUE,
      ai = list(
        enabled = enabled,
        canonical_file = canonical,
        assistants = assistants,
        canonical_content = canonical_content,
        content_file = requested_file,
        content_exists = canonical_exists,
        reference = ai_ref
      )
    )
  }, error = function(e) {
    list(error = paste("Failed to load AI settings:", e$message))
  })
}

#* Get project Git settings
#* @get /api/project/<id>/git
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  tryCatch({
    git_file <- file.path(project$path, "settings/git.yml")
    settings_file <- NULL
    if (file.exists(file.path(project$path, "settings.yml"))) {
      settings_file <- file.path(project$path, "settings.yml")
    } else if (file.exists(file.path(project$path, "config.yml"))) {
      settings_file <- file.path(project$path, "config.yml")
    } else {
      return(list(error = "No settings file found"))
    }

    settings_raw <- yaml::read_yaml(settings_file)
    has_default <- !is.null(settings_raw$default)
    settings <- settings_raw$default %||% settings_raw
    use_split_file <- is.character(settings$git) && grepl("\\.yml$", settings$git)

    git_data <- list()
    base_git <- if (!use_split_file && is.list(settings$git)) settings$git else list()
    if (use_split_file && file.exists(git_file)) {
      git_yaml <- yaml::read_yaml(git_file)
      git_data <- git_yaml$git %||% git_yaml
    } else if (!use_split_file && is.list(settings$git)) {
      git_data <- settings$git
    }

    git_settings <- list(
      initialize = as.logical(git_data$initialize %||% git_data$enabled %||% TRUE)[1],
      user_name = as.character(git_data$user_name %||% base_git$user_name %||% "")[1],
      user_email = as.character(git_data$user_email %||% base_git$user_email %||% "")[1],
      hooks = list(
        ai_sync = as.logical(git_data$hooks$ai_sync %||% FALSE)[1],
        data_security = as.logical(git_data$hooks$data_security %||% FALSE)[1],
        check_sensitive_dirs = as.logical(git_data$hooks$check_sensitive_dirs %||% FALSE)[1]
      )
    )

    list(success = TRUE, git = git_settings)
  }, error = function(e) {
    list(error = paste("Failed to read git settings:", e$message))
  })
}

#* Save project packages
#* @post /api/project/<id>/packages
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)

  tryCatch({
    # Check if using split file or inline approach
    split_info <- .uses_split_file(project$path, "packages")

    # Extract use_renv flag and packages list
    use_renv <- as.logical(body$use_renv %||% FALSE)[1]
    packages_list <- body$packages %||% list()

    # Convert to proper unnamed list for YAML array serialization
    # Each package should be a named list (object) in an unnamed list (array)
    if (length(packages_list) > 0) {
      packages_list <- lapply(packages_list, function(pkg) {
        # Ensure it's a proper named list
        list(
          name = as.character(pkg$name %||% "")[1],
          source = as.character(pkg$source %||% "cran")[1],
          auto_attach = as.logical(pkg$auto_attach %||% TRUE)[1]
        )
      })
      # Remove names to force array serialization
      names(packages_list) <- NULL
    }

    packages_data <- list(
      use_renv = use_renv,
      default_packages = packages_list
    )

    if (split_info$use_split) {
      # Write to split file: settings/packages.yml
      dir.create(dirname(split_info$split_file), recursive = TRUE, showWarnings = FALSE)
      yaml::write_yaml(
        list(packages = packages_data),
        split_info$split_file,
        column.major = FALSE
      )
    } else {
      # Write inline to main settings file
      settings_raw <- yaml::read_yaml(split_info$main_file)
      has_default <- !is.null(settings_raw$default)
      settings <- settings_raw$default %||% settings_raw

      settings$packages <- packages_data

      if (has_default) {
        settings_raw$default <- settings
        yaml::write_yaml(settings_raw, split_info$main_file)
      } else {
        yaml::write_yaml(settings, split_info$main_file)
      }
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Save project AI settings
#* @post /api/project/<id>/ai
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)

  tryCatch({
    canonical_relative <- body$canonical_file %||% "CLAUDE.md"
    canonical_relative <- .sanitize_relative_path(canonical_relative) %||% "CLAUDE.md"
    assistants_raw <- body$assistants %||% list()
    assistant_values <- if (is.list(assistants_raw) || is.vector(assistants_raw)) {
      as.list(unique(as.character(unlist(assistants_raw))))
    } else {
      list()
    }

    new_ai_config <- list(
      enabled = as.logical(body$enabled %||% FALSE)[1],
      canonical_file = canonical_relative,
      assistants = assistant_values
    )

    canonical_path <- file.path(project$path, canonical_relative)

    # Check if using split file or inline approach
    split_info <- .uses_split_file(project$path, "ai")

    if (split_info$use_split) {
      # Write to split file
      dir.create(dirname(split_info$split_file), recursive = TRUE, showWarnings = FALSE)
      yaml::write_yaml(list(ai = new_ai_config), split_info$split_file)
    } else {
      # Write inline to main settings file
      settings_raw <- yaml::read_yaml(split_info$main_file)
      has_default <- !is.null(settings_raw$default)
      settings <- settings_raw$default %||% settings_raw

      settings$ai <- new_ai_config

      if (has_default) {
        settings_raw$default <- settings
        yaml::write_yaml(settings_raw, split_info$main_file)
      } else {
        yaml::write_yaml(settings, split_info$main_file)
      }
    }

    if (!is.null(body$canonical_content)) {
      dir.create(dirname(canonical_path), recursive = TRUE, showWarnings = FALSE)
      canonical_text <- as.character(body$canonical_content)[1]
      canonical_lines <- strsplit(canonical_text, "\r?\n", perl = TRUE)[[1]]
      writeLines(canonical_lines, canonical_path, sep = "\n")
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Regenerate AI context file for a project
#* Updates dynamic sections marked with <!-- @framework:regenerate -->
#* @post /api/project/<id>/ai/regenerate
#* @param id Project ID
#* @param req The request object (optional body with sections to regenerate)
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(success = FALSE, error = "Project not found"))
  }

  tryCatch({
    # Parse optional body for specific sections to regenerate
    sections <- NULL
    if (!is.null(req$postBody) && nchar(req$postBody) > 0) {
      body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)
      sections <- body$sections  # NULL means all sections
    }

    # Get AI file name from project config
    settings_file <- file.path(project$path, "settings.yml")
    ai_file <- "CLAUDE.md"  # Default

    if (file.exists(settings_file)) {
      settings <- tryCatch(yaml::read_yaml(settings_file), error = function(e) list())
      settings <- settings$default %||% settings
      ai_file <- settings$ai$canonical_file %||% "CLAUDE.md"
    }

    # Call ai_regenerate
    framework::ai_regenerate(
      project_path = project$path,
      sections = sections,
      ai_file = ai_file
    )

    # Read regenerated content to return
    ai_path <- file.path(project$path, ai_file)
    content <- if (file.exists(ai_path)) {
      paste(readLines(ai_path, warn = FALSE), collapse = "\n")
    } else {
      NULL
    }

    list(
      success = TRUE,
      message = "AI context regenerated",
      ai_file = ai_file,
      content = content
    )
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Save project Git settings
#* @post /api/project/<id>/git
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)

  tryCatch({
    # Check if using split file or inline approach
    split_info <- .uses_split_file(project$path, "git")

    hooks_payload <- body$hooks %||% list()

    git_data <- list(
      initialize = as.logical(body$initialize %||% TRUE)[1],
      user_name = as.character(body$user_name %||% "")[1],
      user_email = as.character(body$user_email %||% "")[1],
      hooks = list(
        ai_sync = as.logical(hooks_payload$ai_sync %||% FALSE)[1],
        data_security = as.logical(hooks_payload$data_security %||% FALSE)[1],
        check_sensitive_dirs = as.logical(hooks_payload$check_sensitive_dirs %||% FALSE)[1]
      )
    )

    if (split_info$use_split) {
      # Write to split file: settings/git.yml
      dir.create(dirname(split_info$split_file), recursive = TRUE, showWarnings = FALSE)
      yaml::write_yaml(list(git = git_data), split_info$split_file)
    } else {
      # Write inline to main settings file
      settings_raw <- yaml::read_yaml(split_info$main_file)
      has_default <- !is.null(settings_raw$default)
      settings <- settings_raw$default %||% settings_raw

      settings$git <- git_data

      if (has_default) {
        settings_raw$default <- settings
        yaml::write_yaml(settings_raw, split_info$main_file)
      } else {
        yaml::write_yaml(settings, split_info$main_file)
      }
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Search CRAN packages
#* @get /api/packages/search
#* @param q Search query
#* @param source Package source (cran, bioconductor, github)
function(q = "", source = "cran") {
  if (q == "" || nchar(q) < 2) {
    return(list(packages = list()))
  }

  tryCatch({
    # Determine repository based on source
    if (source == "bioconductor") {
      # Bioconductor repositories
      repos <- c(
        "https://bioconductor.org/packages/release/bioc",
        "https://bioconductor.org/packages/release/data/annotation",
        "https://bioconductor.org/packages/release/data/experiment"
      )
    } else if (source == "cran") {
      repos <- "https://cloud.r-project.org"
    } else {
      # GitHub doesn't have a package listing API we can easily search
      return(list(packages = list()))
    }

    # Get available packages
    available <- available.packages(repos = repos)

    # Filter by search term (case-insensitive)
    matches <- grepl(tolower(q), tolower(available[, "Package"]))
    matching_rows <- available[matches, , drop = FALSE]

    # Limit to first 20 results
    matching_rows <- head(matching_rows, 20)

    # Return as unnamed list (array in JSON) with metadata
    results <- lapply(seq_len(nrow(matching_rows)), function(i) {
      row <- matching_rows[i, ]

      # Extract author from Maintainer field (format: "Name <email>")
      maintainer <- if (!is.na(row["Maintainer"])) as.character(row["Maintainer"]) else ""
      author <- gsub("\\s*<.*>\\s*", "", maintainer)  # Remove email part

      list(
        name = unname(as.character(row["Package"]))[1],
        version = unname(as.character(row["Version"]))[1],
        title = if (!is.na(row["Title"])) unname(as.character(row["Title"]))[1] else "",
        author = author,
        source = source
      )
    })
    names(results) <- NULL  # Ensure unnamed for JSON array

    list(packages = results)
  }, error = function(e) {
    list(packages = list(), error = e$message)
  })
}

#* Get project directories
#* @get /api/project/<id>/directories
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Check if directories file exists
  directories_file <- file.path(project$path, "settings/directories.yml")
  if (!file.exists(directories_file)) {
    return(list(directories = list()))
  }

  tryCatch({
    directories_data <- yaml::read_yaml(directories_file)
    list(
      directories = directories_data$directories %||% list()
    )
  }, error = function(e) {
    list(error = paste("Failed to read directories:", e$message))
  })
}

#* Save project directories
#* Add custom directories to a project
#* @post /api/project/<id>/directories
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody)

  # Get the directories array from the request body
  directories <- body$directories

  # Debug logging
  cat("[DEBUG] Received directories request\n")
  cat(sprintf("[DEBUG] directories class: %s\n", class(directories)))
  cat(sprintf("[DEBUG] directories length: %d\n", length(directories)))
  cat("[DEBUG] directories structure:\n")
  print(str(directories))

  if (is.null(directories) || length(directories) == 0) {
    return(list(success = FALSE, error = "No directories provided"))
  }

  # jsonlite converts arrays of objects to data.frames by default
  # Convert data.frame to list of lists (each row becomes a directory object)
  if (is.data.frame(directories)) {
    directories <- lapply(1:nrow(directories), function(i) {
      as.list(directories[i, , drop = FALSE][1, ])
    })
  }

  # Track results for each directory
  results <- list()
  errors <- list()

  # Process each directory
  for (i in seq_along(directories)) {
    dir_spec <- directories[[i]]

    # Debug logging
    cat(sprintf("[DEBUG] dir_spec class: %s\n", class(dir_spec)))
    cat(sprintf("[DEBUG] dir_spec structure:\n"))
    print(str(dir_spec))

    # Validate required fields
    if (is.null(dir_spec$key) || is.null(dir_spec$label) || is.null(dir_spec$path)) {
      errors[[length(errors) + 1]] <- sprintf(
        "Directory %d missing required fields (key, label, or path)", i
      )
      next
    }

    # Call the project_add_directory function
    result <- framework::project_add_directory(
      project_path = project$path,
      key = dir_spec$key,
      label = dir_spec$label,
      path = dir_spec$path
    )

    if (result$success) {
      results[[length(results) + 1]] <- result$directory
    } else {
      errors[[length(errors) + 1]] <- sprintf(
        "%s: %s", dir_spec$key, result$error
      )
    }
  }

  # Return summary
  if (length(errors) > 0 && length(results) == 0) {
    # All failed
    return(list(
      success = FALSE,
      error = paste(errors, collapse = "; ")
    ))
  } else if (length(errors) > 0) {
    # Partial success
    return(list(
      success = TRUE,
      created = results,
      errors = errors,
      message = sprintf(
        "Created %d director%s with %d error%s",
        length(results),
        if (length(results) == 1) "y" else "ies",
        length(errors),
        if (length(errors) == 1) "" else "s"
      )
    ))
  } else {
    # All succeeded
    return(list(
      success = TRUE,
      created = results,
      message = sprintf(
        "Successfully created %d director%s",
        length(results),
        if (length(results) == 1) "y" else "ies"
      )
    ))
  }
}

#* Get project security settings
#* @get /api/project/<id>/security
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Check if security file exists
  security_file <- file.path(project$path, "settings/security.yml")
  if (!file.exists(security_file)) {
    return(list(security = list()))
  }

  tryCatch({
    security_data <- yaml::read_yaml(security_file)
    list(
      security = security_data$security %||% list()
    )
  }, error = function(e) {
    list(error = paste("Failed to read security:", e$message))
  })
}

#* Save project security settings
#* @post /api/project/<id>/security
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody)

  tryCatch({
    security_file <- file.path(project$path, "settings/security.yml")

    # Save security
    yaml::write_yaml(list(
      security = body$security %||% list()
    ), security_file)

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Get project .env file with usage analysis
#* @get /api/project/<id>/env
#* @param id Project ID
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Check for dotenv_location in settings
  dotenv_location <- "."
  settings_file <- NULL
  if (file.exists(file.path(project$path, "settings.yml"))) {
    settings_file <- file.path(project$path, "settings.yml")
  } else if (file.exists(file.path(project$path, "config.yml"))) {
    settings_file <- file.path(project$path, "config.yml")
  }

  if (!is.null(settings_file)) {
    tryCatch({
      settings_raw <- yaml::read_yaml(settings_file)
      settings <- settings_raw$default %||% settings_raw
      if (!is.null(settings$dotenv_location)) {
        dotenv_location <- settings$dotenv_location
      }
    }, error = function(e) {
      # Continue with default location
    })
  }

  env_file <- file.path(project$path, dotenv_location, ".env")

  # Read current .env variables
  variables <- list()
  if (file.exists(env_file)) {
    tryCatch({
      lines <- readLines(env_file, warn = FALSE)
      for (line in lines) {
        # Skip comments and empty lines
        if (grepl("^\\s*#", line) || grepl("^\\s*$", line)) {
          next
        }

        # Parse KEY=VALUE
        if (grepl("=", line)) {
          parts <- strsplit(line, "=", fixed = TRUE)[[1]]
          key <- trimws(parts[1])

          if (nzchar(key)) {
            value <- if (length(parts) > 1) trimws(paste(parts[-1], collapse = "=")) else ""

            # Remove quotes if present
            value <- gsub('^"(.*)"$', '\\1', value)
            value <- gsub("^'(.*)'$", '\\1', value)

            variables[[key]] <- value
          }
        }
      }
    }, error = function(e) {
      # Continue with empty variables if read fails
    })
  }

  # Scan project for env() references
  tryCatch({
    # Find all R and YAML files
    r_files <- list.files(project$path, pattern = "\\.(R|r)$", recursive = TRUE, full.names = TRUE)
    yaml_files <- list.files(project$path, pattern = "\\.(yml|yaml)$", recursive = TRUE, full.names = TRUE)
    all_files <- c(r_files, yaml_files)

    # Track env variable usage
    env_usage <- list()

    for (filepath in all_files) {
      # Skip node_modules, renv, etc
      if (grepl("node_modules|renv|\\.git", filepath)) next

      content <- tryCatch(readLines(filepath, warn = FALSE), error = function(e) NULL)
      if (is.null(content)) next

      # Find env("VARIABLE") patterns
      matches <- gregexpr('env\\(["\']([^"\']+)["\']', paste(content, collapse = "\n"), perl = TRUE)
      if (matches[[1]][1] != -1) {
        match_text <- regmatches(paste(content, collapse = "\n"), matches)[[1]]
        var_names <- gsub('env\\(["\']([^"\']+)["\'].*', '\\1', match_text)

        for (var_name in var_names) {
          relative_path <- gsub(paste0("^", project$path, "/?"), "", filepath)
          if (is.null(env_usage[[var_name]])) {
            env_usage[[var_name]] <- list()
          }
          env_usage[[var_name]] <- c(env_usage[[var_name]], relative_path)
        }
      }
    }

    # Group variables by prefix
    groups <- list()
    all_vars <- unique(c(names(variables), names(env_usage)))

    for (var_name in all_vars) {
      # Extract prefix (everything before first underscore)
      prefix <- "Other"
      if (grepl("_", var_name)) {
        prefix <- strsplit(var_name, "_", fixed = TRUE)[[1]][1]
      }

      if (is.null(groups[[prefix]])) {
        groups[[prefix]] <- list()
      }

      groups[[prefix]][[var_name]] <- list(
        value = variables[[var_name]] %||% "",
        defined = !is.null(variables[[var_name]]),
        used = !is.null(env_usage[[var_name]]),
        used_in = if (!is.null(env_usage[[var_name]])) unique(env_usage[[var_name]]) else list()
      )
    }

    # Also return raw content for raw editor mode
    raw_content <- ""
    if (file.exists(env_file)) {
      raw_content <- paste(readLines(env_file, warn = FALSE), collapse = "\n")
    }

    list(
      variables = variables,
      groups = groups,
      raw_content = raw_content,
      exists = file.exists(env_file)
    )
  }, error = function(e) {
    # Fallback to simple variables list
    list(
      variables = variables,
      groups = list(),
      exists = file.exists(env_file),
      error = paste("Failed to analyze usage:", e$message)
    )
  })
}

#* Save project .env file
#* @post /api/project/<id>/env
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  body <- jsonlite::fromJSON(req$postBody)

  tryCatch({
    # Check for dotenv_location in settings
    dotenv_location <- "."
    settings_file <- NULL
    if (file.exists(file.path(project$path, "settings.yml"))) {
      settings_file <- file.path(project$path, "settings.yml")
    } else if (file.exists(file.path(project$path, "config.yml"))) {
      settings_file <- file.path(project$path, "config.yml")
    }

    if (!is.null(settings_file)) {
      tryCatch({
        settings_raw <- yaml::read_yaml(settings_file)
        settings <- settings_raw$default %||% settings_raw
        if (!is.null(settings$dotenv_location)) {
          dotenv_location <- settings$dotenv_location
        }
      }, error = function(e) {
        # Continue with default location
      })
    }

    env_file <- file.path(project$path, dotenv_location, ".env")

    # If saving raw content, just write it directly
    if (!is.null(body$raw_content)) {
      writeLines(strsplit(body$raw_content, "\n")[[1]], env_file)
      return(list(success = TRUE))
    }

    # If regroup flag is set, rewrite file grouped by prefix
    if (!is.null(body$regroup) && body$regroup == TRUE) {
      # Group variables by prefix
      vars <- body$variables
      if (is.null(vars) || length(vars) == 0) {
        writeLines(c("# Environment Variables", ""), env_file)
        return(list(success = TRUE))
      }

      # Extract prefixes
      get_prefix <- function(key) {
        parts <- strsplit(key, "_")[[1]]
        if (length(parts) > 1) parts[1] else "OTHER"
      }

      prefixes <- sapply(names(vars), get_prefix)
      unique_prefixes <- unique(prefixes)
      # Sort prefixes, with OTHER last
      unique_prefixes <- c(sort(unique_prefixes[unique_prefixes != "OTHER"]), "OTHER")
      unique_prefixes <- unique_prefixes[unique_prefixes %in% prefixes]

      # Build lines
      lines <- c("# Environment Variables", "# Grouped by prefix", "")

      for (prefix in unique_prefixes) {
        keys_in_prefix <- names(vars)[prefixes == prefix]
        if (length(keys_in_prefix) > 0) {
          # Add section header
          if (prefix == "OTHER") {
            lines <- c(lines, "# Other Variables")
          } else {
            lines <- c(lines, sprintf("# %s Variables", toupper(prefix)))
          }

          # Add variables
          for (key in sort(keys_in_prefix)) {
            value <- vars[[key]]
            if (grepl(" ", value)) {
              lines <- c(lines, sprintf('%s="%s"', key, value))
            } else {
              lines <- c(lines, sprintf('%s=%s', key, value))
            }
          }
          lines <- c(lines, "")
        }
      }

      writeLines(lines, env_file)
      return(list(success = TRUE))
    }

    # Otherwise, preserve original file structure and only update values
    if (file.exists(env_file)) {
      # Read existing file
      lines <- readLines(env_file, warn = FALSE)
      updated_keys <- character(0)

      # Update existing keys while preserving structure
      for (i in seq_along(lines)) {
        line <- lines[i]

        # Skip comments and empty lines
        if (grepl("^\\s*#", line) || grepl("^\\s*$", line)) {
          next
        }

        # Parse KEY=VALUE
        if (grepl("=", line)) {
          parts <- strsplit(line, "=", fixed = TRUE)[[1]]
          if (length(parts) >= 2) {
            key <- trimws(parts[1])

            # If this key is in our update, replace the value
            if (!is.null(body$variables[[key]])) {
              new_value <- body$variables[[key]]
              # Quote values that contain spaces
              if (grepl(" ", new_value)) {
                lines[i] <- sprintf('%s="%s"', key, new_value)
              } else {
                lines[i] <- sprintf('%s=%s', key, new_value)
              }
              updated_keys <- c(updated_keys, key)
            }
          }
        }
      }

      # Add any new keys that weren't in the original file
      new_keys <- setdiff(names(body$variables), updated_keys)
      if (length(new_keys) > 0) {
        lines <- c(lines, "", "# Added variables")
        for (key in new_keys) {
          value <- body$variables[[key]]
          if (grepl(" ", value)) {
            lines <- c(lines, sprintf('%s="%s"', key, value))
          } else {
            lines <- c(lines, sprintf('%s=%s', key, value))
          }
        }
      }

      writeLines(lines, env_file)
    } else {
      # File doesn't exist, create new one
      lines <- c(
        "# Environment Variables",
        "# WARNING: This file contains sensitive credentials - do not commit to version control",
        ""
      )

      if (!is.null(body$variables) && length(body$variables) > 0) {
        for (key in names(body$variables)) {
          value <- body$variables[[key]]
          if (grepl(" ", value)) {
            lines <- c(lines, sprintf('%s="%s"', key, value))
          } else {
            lines <- c(lines, sprintf('%s=%s', key, value))
          }
        }
      }

      writeLines(lines, env_file)
    }

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Create a new Framework project (new endpoint)
#* @post /api/projects/create
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody)

  # Convert extra_directories from data frame to list of lists if needed
  extra_dirs <- body$extra_directories %||% list()
  if (is.data.frame(extra_dirs)) {
    extra_dirs <- lapply(seq_len(nrow(extra_dirs)), function(i) {
      as.list(extra_dirs[i, , drop = FALSE])
    })
  }

  tryCatch({
    # Call new project_create() function with full configuration
    result <- framework::project_create(
      name = body$name,
      location = body$location,
      type = body$type %||% "project",
      author = body$author %||% list(name = "", email = "", affiliation = ""),
      packages = body$packages %||% list(use_renv = FALSE, default_packages = list()),
      directories = body$directories %||% list(),
      extra_directories = extra_dirs,
      ai = body$ai %||% list(enabled = FALSE, assistants = c(), canonical_content = ""),
      git = body$git %||% list(use_git = TRUE, hooks = list(), gitignore_content = ""),
      scaffold = body$scaffold %||% list(
        seed_on_scaffold = FALSE,
        seed = "123",
        set_theme_on_scaffold = FALSE,
        ggplot_theme = "theme_minimal"
      ),
      connections = body$connections %||% NULL,
      env = body$env %||% NULL,
      quarto = body$quarto %||% NULL,
      render_dirs = body$render_dirs %||% NULL
    )

    result
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Resolve project root directory
#* @post /api/project/resolve-root
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody)
  project_dir <- body$project_dir

  # Expand tilde in path
  if (grepl("^~", project_dir)) {
    project_dir <- path.expand(project_dir)
  }

  # Convert to absolute path
  project_dir <- normalizePath(project_dir, mustWork = FALSE)

  list(resolved_path = project_dir)
}

#* Remove project from Framework (untrack)
#* @post /api/projects/<id>/untrack
#* @param id The project ID
function(id) {
  tryCatch({
    # Get project path from registry
    projects <- framework::list_projects()
    project <- projects[projects$id == id, ]

    if (nrow(project) == 0) {
      return(list(success = FALSE, error = "Project not found"))
    }

    # Remove from registry
    framework::remove_project_from_config(id)

    list(success = TRUE, message = "Project removed from Framework")
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Delete project entirely (files and registry)
#* @post /api/projects/<id>/delete
#* @param id The project ID
function(id) {
  tryCatch({
    # Get project path from registry
    projects <- framework::list_projects()
    project <- projects[projects$id == id, ]

    if (nrow(project) == 0) {
      return(list(success = FALSE, error = "Project not found"))
    }

    project_path <- project$path[1]

    # Delete directory
    if (dir.exists(project_path)) {
      unlink(project_path, recursive = TRUE)
    }

    # Remove from registry
    framework::remove_project_from_config(id)

    list(success = TRUE, message = "Project deleted")
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Import an existing Framework project
#* @post /api/project/import
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody)
  project_dir <- body$project_dir

  # Validate project directory
  if (!dir.exists(project_dir)) {
    return(list(error = "Directory does not exist"))
  }

  # Check if it's a Framework project
  has_settings <- file.exists(file.path(project_dir, "settings.yml"))
  has_config <- file.exists(file.path(project_dir, "config.yml"))

  if (!has_settings && !has_config) {
    return(list(error = "Not a Framework project (no settings.yml or config.yml found)"))
  }

  # Add to registry
  tryCatch({
    project_id <- framework::add_project_to_config(project_dir)

    list(success = TRUE, id = project_id)
  }, error = function(e) {
    list(error = e$message)
  })
}

#* Regenerate Quarto configuration files for a project
#* @post /api/project/<id>/quarto/regenerate
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  # Find project
  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  # Parse request body for options
  body <- if (!is.null(req$postBody) && nchar(req$postBody) > 0) {
    jsonlite::fromJSON(req$postBody)
  } else {
    list()
  }

  backup <- if (!is.null(body$backup)) as.logical(body$backup) else TRUE

  # Regenerate Quarto configs
  tryCatch({
    result <- framework::quarto_regenerate(
      project_path = project$path,
      backup = backup
    )

    if (result$success) {
      list(
        success = TRUE,
        message = sprintf("Regenerated %d Quarto configuration file(s)", result$count),
        files = result$regenerated,
        backed_up = result$backed_up,
        backup_location = result$backup_location
      )
    } else {
      list(error = "Failed to regenerate Quarto configurations")
    }
  }, error = function(e) {
    list(error = paste("Error regenerating Quarto configs:", e$message))
  })
}

#* List Quarto configuration files for a project
#* @get /api/project/<id>/quarto/files
function(id) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  settings_path <- if (file.exists(file.path(project$path, "settings.yml"))) {
    file.path(project$path, "settings.yml")
  } else {
    file.path(project$path, "config.yml")
  }

  if (!file.exists(settings_path)) {
    return(list(error = "Project settings not found"))
  }

  cfg <- yaml::read_yaml(settings_path)
  defaults <- cfg$default %||% list()
  directories <- defaults$directories %||% list()
  render_dirs <- defaults$render_dirs %||% list()

  files <- list()

  # Root _quarto.yml
  root_path <- file.path(project$path, "_quarto.yml")
  files[[length(files) + 1]] <- list(
    key = "root",
    label = "Root _quarto.yml",
    path = root_path,
    exists = file.exists(root_path),
    contents = if (file.exists(root_path)) paste(readLines(root_path, warn = FALSE), collapse = "\n") else ""
  )

  # Per-render directory _quarto.yml (source dirs keyed by render_dirs)
  if (length(render_dirs) > 0) {
    for (render_key in names(render_dirs)) {
      source_dir <- directories[[render_key]] %||% render_key
      if (is.null(source_dir) || !nzchar(source_dir)) next
      file_path <- file.path(project$path, source_dir, "_quarto.yml")
      files[[length(files) + 1]] <- list(
        key = render_key,
        label = sprintf("%s/_quarto.yml", source_dir),
        path = file_path,
        exists = file.exists(file_path),
        contents = if (file.exists(file_path)) paste(readLines(file_path, warn = FALSE), collapse = "\n") else ""
      )
    }
  }

  list(success = TRUE, files = files)
}

#* Save Quarto configuration files for a project
#* @post /api/project/<id>/quarto/files
#* @param id Project ID
#* @param req The request object
function(id, req) {
  config <- framework::read_frameworkrc()
  project_id <- as.integer(id)

  project <- NULL
  if (!is.null(config$projects) && length(config$projects) > 0) {
    for (proj in config$projects) {
      if (!is.null(proj$id) && proj$id == project_id) {
        project <- proj
        break
      }
    }
  }

  if (is.null(project)) {
    return(list(error = "Project not found"))
  }

  if (is.null(req$postBody) || !nzchar(req$postBody)) {
    return(list(error = "No files provided"))
  }

  body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = FALSE)
  files <- body$files
  if (is.null(files) || length(files) == 0) {
    return(list(error = "No files provided"))
  }

  # Handle case where jsonlite converts single-element array differently
  if (is.data.frame(files)) {
    files <- lapply(1:nrow(files), function(i) as.list(files[i, ]))
  }

  written <- list()
  for (i in seq_along(files)) {
    file_spec <- files[[i]]
    target_path <- file_spec$path %||% ""
    if (!nzchar(target_path)) next

    # Safety: ensure path is inside project
    normalized <- normalizePath(target_path, winslash = "/", mustWork = FALSE)
    project_root <- normalizePath(project$path, winslash = "/", mustWork = TRUE)
    if (!startsWith(normalized, project_root)) {
      next
    }

    dir.create(dirname(normalized), recursive = TRUE, showWarnings = FALSE)
    writeLines(file_spec$contents %||% "", normalized)
    written[[length(written) + 1]] <- normalized
  }

  list(success = TRUE, written = written)
}
