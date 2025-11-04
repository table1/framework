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

#* Get global settings and projects list
#* @get /api/settings/get
function() {
  settings <- framework::read_frameworkrc()

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

  return(settings)
}

#* Save global settings
#* @post /api/settings/save
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody)

  tryCatch({
    # Use unified configure_global function for validation and persistence
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
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
        result <- lapply(names(obj), function(key) {
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
        names(result) <- names(obj)
        return(result)
      } else {
        obj
      }
    }

    settings_resolved <- resolve_file_refs(settings, project$path)

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

  tryCatch({
    old_wd <- getwd()
    setwd(project$path)
    on.exit(setwd(old_wd))

    # Save author settings
    if (!is.null(body$author)) {
      if (file.exists("settings/author.yml")) {
        yaml::write_yaml(list(author = body$author), "settings/author.yml")
      }
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
    if (!is.null(body$project_name) || !is.null(body$project_type)) {
      settings_file <- if (file.exists("settings.yml")) "settings.yml" else "config.yml"
      current_settings <- yaml::read_yaml(settings_file)

      if (!is.null(body$project_name)) {
        current_settings$default$project_name <- body$project_name
      }
      if (!is.null(body$project_type)) {
        current_settings$default$project_type <- body$project_type
      }

      yaml::write_yaml(current_settings, settings_file)
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
    return(list(connections = list(), options = list()))
  }

  tryCatch({
    connections_data <- yaml::read_yaml(connections_file)
    list(
      connections = connections_data$connections %||% list(),
      options = connections_data$options %||% list()
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
    connections_file <- file.path(project$path, "settings/connections.yml")

    # Save connections
    yaml::write_yaml(list(
      options = body$options %||% list(),
      connections = body$connections %||% list()
    ), connections_file)

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
    raw_packages <- packages_data$packages %||% list()

    # Normalize packages - handle both string format and object format
    normalized_packages <- lapply(raw_packages, function(pkg) {
      if (is.character(pkg)) {
        # Simple string format: "dplyr" -> {name: dplyr, source: cran, auto_attach: true}
        list(
          name = pkg,
          source = "cran",
          auto_attach = TRUE
        )
      } else if (is.list(pkg)) {
        # Object format - ensure defaults
        list(
          name = pkg$name %||% "",
          source = pkg$source %||% "cran",
          auto_attach = if (is.null(pkg$auto_attach)) TRUE else pkg$auto_attach
        )
      } else {
        # Fallback
        list(name = "", source = "cran", auto_attach = TRUE)
      }
    })

    list(packages = normalized_packages)
  }, error = function(e) {
    list(error = paste("Failed to read packages:", e$message))
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
    packages_file <- file.path(project$path, "settings/packages.yml")

    # Save packages - ensure proper list structure
    packages_list <- body$packages %||% list()

    # If it's a data frame, convert to list of lists
    if (is.data.frame(packages_list)) {
      packages_list <- lapply(seq_len(nrow(packages_list)), function(i) {
        as.list(packages_list[i, ])
      })
    }

    yaml::write_yaml(list(
      packages = packages_list
    ), packages_file)

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

#* Search CRAN packages
#* @get /api/packages/search
#* @param q Search query
function(q = "") {
  if (q == "" || nchar(q) < 2) {
    return(list(packages = list()))
  }

  tryCatch({
    # Get available CRAN packages
    available <- available.packages(repos = "https://cloud.r-project.org")

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
        name = as.character(row["Package"]),
        version = as.character(row["Version"]),
        title = if (!is.na(row["Title"])) as.character(row["Title"]) else "",
        author = author,
        source = "cran"
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

  tryCatch({
    directories_file <- file.path(project$path, "settings/directories.yml")

    # Save directories
    yaml::write_yaml(list(
      directories = body$directories %||% list()
    ), directories_file)

    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
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
          if (length(parts) >= 2) {
            key <- trimws(parts[1])
            value <- trimws(paste(parts[-1], collapse = "="))

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

#* Create a new Framework project
#* @post /api/project/create
#* @param req The request object
function(req) {
  body <- jsonlite::fromJSON(req$postBody)

  tryCatch({
    # Create the project
    framework::init(
      project_dir = body$project_dir,
      project_name = body$project_name,
      project_type = body$project_type,
      author_name = body$author_name,
      author_email = body$author_email,
      author_affiliation = body$author_affiliation,
      ides = body$ides,
      use_git = body$use_git,
      use_renv = body$use_renv,
      ai_support = body$ai_support,
      ai_assistants = body$ai_assistants
    )

    # Add to project registry
    project_id <- framework::add_project_to_config(body$project_dir)

    list(success = TRUE, path = body$project_dir, id = project_id)
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
