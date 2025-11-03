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
