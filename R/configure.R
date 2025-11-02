#' Configure Author Information
#'
#' Interactively set author information in settings.yml (or settings.yml for legacy projects).
#' This information is
#' used in notebooks, reports, and other documents.
#'
#' @param name Character. Author name (optional, prompts if not provided)
#' @param email Character. Author email (optional, prompts if not provided)
#' @param affiliation Character. Author affiliation/institution (optional, prompts if not provided)
#' @param interactive Logical. If TRUE, prompts for missing values. Default TRUE.
#'
#' @return Invisibly returns updated config
#'
#' @examples
#' \dontrun{
#' # Interactive mode (prompts for all fields)
#' configure_author()
#'
#' # Provide values directly
#' configure_author(
#'   name = "Jane Doe",
#'   email = "jane@example.com",
#'   affiliation = "University of Example"
#' )
#' }
#'
#' @export
configure_author <- function(name = NULL, email = NULL, affiliation = NULL, interactive = TRUE) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(email, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(affiliation, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(interactive)

  # Read current config
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("settings.yml or config.yml not found. Run framework::init() first.")
  }

  config <- read_config(config_path)

  # Get current values for defaults
  current_name <- config$author$name
  current_email <- config$author$email
  current_affiliation <- config$author$affiliation

  # Interactive prompts if values not provided
  if (interactive) {
    if (is.null(name)) {
      default_msg <- if (!is.null(current_name)) sprintf(" [%s]", current_name) else ""
      cat(sprintf("Author name%s: ", default_msg))
      input <- readline()
      name <- if (nzchar(input)) input else current_name
    }

    if (is.null(email)) {
      default_msg <- if (!is.null(current_email)) sprintf(" [%s]", current_email) else ""
      cat(sprintf("Author email%s: ", default_msg))
      input <- readline()
      email <- if (nzchar(input)) input else current_email
    }

    if (is.null(affiliation)) {
      default_msg <- if (!is.null(current_affiliation)) sprintf(" [%s]", current_affiliation) else ""
      cat(sprintf("Author affiliation%s: ", default_msg))
      input <- readline()
      affiliation <- if (nzchar(input)) input else current_affiliation
    }
  }

  # Update config
  if (!is.null(name)) config$author$name <- name
  if (!is.null(email)) config$author$email <- email
  if (!is.null(affiliation)) config$author$affiliation <- affiliation

  # Write config
  write_config(config, config_path)

  message("\u2713 Author information updated in ", basename(config_path))
  if (!is.null(name)) message(sprintf("  Name: %s", name))
  if (!is.null(email)) message(sprintf("  Email: %s", email))
  if (!is.null(affiliation)) message(sprintf("  Affiliation: %s", affiliation))

  invisible(config)
}


#' Configure Data Source
#'
#' Interactively add a data source to settings.yml (or settings.yml for legacy projects). Data sources are defined
#' with dot-notation paths (e.g., "source.private.survey") and include metadata
#' like file path, type, and whether the data is locked.
#'
#' @param path Character. Dot-notation path for the data source (e.g., "source.private.survey")
#' @param file Character. File path to the data file
#' @param type Character. Data type: "csv", "tsv", "rds", "excel", "stata", "spss", "sas", or "auto"
#' @param locked Logical. If TRUE, file is read-only and errors on changes
#' @param interactive Logical. If TRUE, prompts for missing values. Default TRUE.
#'
#' @return Invisibly returns updated config
#'
#' @examples
#' \dontrun{
#' # Interactive mode
#' configure_data()
#'
#' # Provide values directly
#' configure_data(
#'   path = "source.private.survey",
#'   file = "inputs/raw/survey.csv",
#'   type = "csv",
#'   locked = TRUE
#' )
#' }
#'
#' @export
configure_data <- function(path = NULL, file = NULL, type = NULL, locked = FALSE, interactive = TRUE) {
  # Validate arguments
  checkmate::assert_string(path, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(file, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(type, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(locked)
  checkmate::assert_flag(interactive)

  # Read current config
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("settings.yml or config.yml not found. Run framework::init() first.")
  }

  config <- read_config(config_path)

  # Interactive prompts
  if (interactive) {
    if (is.null(path)) {
      cat("Data source path (e.g., 'source.private.survey'): ")
      path <- readline()
      if (!nzchar(path)) stop("Data source path is required")
    }

    if (is.null(file)) {
      cat("File path (e.g., 'inputs/raw/survey.csv'): ")
      file <- readline()
      if (!nzchar(file)) stop("File path is required")
    }

    if (is.null(type)) {
      cat("Data type [csv/tsv/rds/excel/stata/spss/sas/auto]: ")
      type_input <- readline()
      type <- if (nzchar(type_input)) type_input else "auto"
    }

    cat("Lock file (prevent modifications)? [y/N]: ")
    locked_input <- readline()
    if (tolower(locked_input) %in% c("y", "yes")) {
      locked <- TRUE
    }
  }

  # Validate type
  valid_types <- c("csv", "tsv", "rds", "excel", "stata", "spss", "sas", "auto")
  if (!type %in% valid_types) {
    stop(sprintf("Invalid type '%s'. Must be one of: %s",
                 type, paste(valid_types, collapse = ", ")))
  }

  # Parse dot-notation path and create nested structure
  path_parts <- strsplit(path, "\\.")[[1]]
  if (length(path_parts) < 1) {
    stop("Invalid data source path. Use dot notation (e.g., 'source.private.survey')")
  }

  # Build nested list
  data_entry <- list(
    path = file,
    type = type
  )
  if (locked) {
    data_entry$locked <- TRUE
  }

  # Navigate to the right location in config$data
  if (is.null(config$data)) {
    config$data <- list()
  }

  # Build nested structure by directly accessing config$data
  # This works because we're modifying config$data directly, not a copy
  if (length(path_parts) == 1) {
    # Simple path - direct assignment
    config$data[[path_parts[1]]] <- data_entry
  } else {
    # Nested path - build structure from top down
    # Create nested list structure recursively
    expr <- "config$data"
    for (i in seq_along(path_parts)) {
      part <- path_parts[i]
      if (i < length(path_parts)) {
        # Intermediate level - ensure it exists
        eval_expr <- parse(text = expr)
        current <- eval(eval_expr)
        if (is.null(current[[part]])) {
          # Create the intermediate level
          assign_expr <- sprintf("%s$%s <- list()", expr, part)
          eval(parse(text = assign_expr))
        }
        expr <- sprintf("%s$%s", expr, part)
      } else {
        # Last level - assign the data entry
        assign_expr <- sprintf("%s$%s <- data_entry", expr, part)
        eval(parse(text = assign_expr))
      }
    }
  }

  # Write config
  write_config(config, config_path)

  message(sprintf("\u2713 Data source '%s' added to %s", path, basename(config_path)))
  message(sprintf("  File: %s", file))
  message(sprintf("  Type: %s", type))
  if (locked) message("  Locked: yes")
  message(sprintf("\nLoad with: data_load(\"%s\")", path))

  invisible(config)
}


#' Configure Database Connection
#'
#' Interactively add a database connection to settings.yml (or settings.yml for legacy projects). Connections can be
#' defined inline or in a split file (settings/connections.yml).
#'
#' @param name Character. Connection name (e.g., "db", "warehouse")
#' @param driver Character. Database driver: "sqlite", "postgresql", "mysql", etc.
#' @param host Character. Database host (for network databases)
#' @param port Integer. Database port (for network databases)
#' @param database Character. Database name
#' @param user Character. Database user (for network databases)
#' @param password Character. Database password (stored in .env)
#' @param interactive Logical. If TRUE, prompts for missing values. Default TRUE.
#'
#' @return Invisibly returns updated config
#'
#' @examples
#' \dontrun{
#' # Interactive mode
#' configure_connection()
#'
#' # SQLite connection
#' configure_connection(
#'   name = "mydb",
#'   driver = "sqlite",
#'   database = "data/mydb.db"
#' )
#'
#' # PostgreSQL connection
#' configure_connection(
#'   name = "warehouse",
#'   driver = "postgresql",
#'   host = "localhost",
#'   port = 5432,
#'   database = "analytics",
#'   user = "analyst"
#' )
#' }
#'
#' @export
configure_connection <- function(name = NULL, driver = NULL, host = NULL,
                                  port = NULL, database = NULL, user = NULL,
                                  password = NULL, interactive = TRUE) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(driver, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(host, min.chars = 1, null.ok = TRUE)
  checkmate::assert_int(port, lower = 1, upper = 65535, null.ok = TRUE)
  checkmate::assert_string(database, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(user, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(password, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(interactive)

  # Read current config
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("settings.yml or config.yml not found. Run framework::init() first.")
  }

  config <- read_config(config_path)

  # Interactive prompts
  if (interactive) {
    if (is.null(name)) {
      cat("Connection name (e.g., 'db', 'warehouse'): ")
      name <- readline()
      if (!nzchar(name)) stop("Connection name is required")
    }

    if (is.null(driver)) {
      cat("Database driver [sqlite/postgresql/mysql]: ")
      driver <- readline()
      if (!nzchar(driver)) stop("Database driver is required")
    }

    # Different prompts based on driver
    if (driver == "sqlite") {
      if (is.null(database)) {
        cat("Database file path (e.g., 'data/mydb.db'): ")
        database <- readline()
        if (!nzchar(database)) stop("Database path is required")
      }
    } else {
      # Network database prompts
      if (is.null(host)) {
        cat("Host [localhost]: ")
        host_input <- readline()
        host <- if (nzchar(host_input)) host_input else "localhost"
      }

      if (is.null(port)) {
        default_port <- if (driver == "postgresql") 5432 else if (driver == "mysql") 3306 else NULL
        port_msg <- if (!is.null(default_port)) sprintf(" [%d]", default_port) else ""
        cat(sprintf("Port%s: ", port_msg))
        port_input <- readline()
        port <- if (nzchar(port_input)) as.integer(port_input) else default_port
      }

      if (is.null(database)) {
        cat("Database name: ")
        database <- readline()
        if (!nzchar(database)) stop("Database name is required")
      }

      if (is.null(user)) {
        cat("Username: ")
        user <- readline()
        if (!nzchar(user)) stop("Username is required")
      }

      # Suggest storing password in .env
      cat("\nFor security, store password in .env file.\n")
      cat(sprintf("Add this line to .env: %s_PASSWORD=your_password\n", toupper(name)))
      cat("Skip password prompt? [Y/n]: ")
      skip_pw <- readline()
      if (!tolower(skip_pw) %in% c("n", "no")) {
        password <- sprintf("!expr Sys.getenv(\"%s_PASSWORD\")", toupper(name))
      } else if (is.null(password)) {
        cat("Password (will be visible): ")
        password <- readline()
      }
    }
  }

  # Build connection config
  conn_config <- list(driver = driver)

  if (driver == "sqlite") {
    conn_config$database <- database
  } else {
    conn_config$host <- host
    if (!is.null(port)) conn_config$port <- port
    conn_config$database <- database
    if (!is.null(user)) conn_config$user <- user
    if (!is.null(password)) conn_config$password <- password
  }

  # Add to config
  if (is.null(config$connections)) {
    config$connections <- list()
  }
  config$connections[[name]] <- conn_config

  # Write config
  write_config(config, config_path)

  message(sprintf("\u2713 Connection '%s' added to %s", name, basename(config_path)))
  message(sprintf("  Driver: %s", driver))
  if (driver == "sqlite") {
    message(sprintf("  Database: %s", database))
  } else {
    message(sprintf("  Host: %s", host))
    if (!is.null(port)) message(sprintf("  Port: %d", port))
    message(sprintf("  Database: %s", database))
    if (!is.null(user)) message(sprintf("  User: %s", user))
  }
  message(sprintf("\nUse with: query_get(\"SELECT * FROM table\", \"%s\")", name))

  invisible(config)
}


#' Configure Package Dependencies
#'
#' Interactively add package dependencies to settings.yml (or settings.yml for legacy projects). Packages can be
#' installed from CRAN, GitHub, or Bioconductor, with version pinning support.
#'
#' @param package Character. Package name (e.g., "dplyr", "tidyverse/dplyr")
#' @param auto_attach Logical. If TRUE, package is loaded automatically during scaffold()
#' @param version Character. Version constraint (e.g., "@1.1.0", "@main" for GitHub)
#' @param interactive Logical. If TRUE, prompts for missing values. Default TRUE.
#'
#' @return Invisibly returns updated config
#'
#' @details
#' ## Package Specifications
#'
#' - CRAN: "dplyr", "ggplot2"
#' - CRAN with version: "dplyr@1.1.0"
#' - GitHub: "tidyverse/dplyr", "user/repo@branch"
#' - GitHub with tag: "user/repo@v1.2.3"
#'
#' @examples
#' \dontrun{
#' # Interactive mode
#' configure_packages()
#'
#' # Add CRAN package with auto-attach
#' configure_packages(
#'   package = "dplyr",
#'   auto_attach = TRUE
#' )
#'
#' # Add GitHub package
#' configure_packages(
#'   package = "tidyverse/dplyr@main",
#'   auto_attach = FALSE
#' )
#' }
#'
#' @export
configure_packages <- function(package = NULL, auto_attach = TRUE, version = NULL, interactive = TRUE) {
  # Validate arguments
  checkmate::assert_string(package, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(auto_attach)
  checkmate::assert_string(version, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(interactive)

  # Read current config
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("settings.yml or config.yml not found. Run framework::init() first.")
  }

  config <- read_config(config_path)

  # Interactive prompts
  if (interactive) {
    if (is.null(package)) {
      cat("Package name (e.g., 'dplyr', 'tidyverse/dplyr@main'): ")
      package <- readline()
      if (!nzchar(package)) stop("Package name is required")
    }

    if (is.null(version) && !grepl("@", package)) {
      cat("Version (optional, e.g., '@1.1.0' or leave blank): ")
      version_input <- readline()
      if (nzchar(version_input)) {
        version <- version_input
        if (!grepl("^@", version)) {
          version <- paste0("@", version)
        }
      }
    }

    cat("Auto-attach during scaffold()? [Y/n]: ")
    attach_input <- readline()
    if (tolower(attach_input) %in% c("n", "no")) {
      auto_attach <- FALSE
    }
  }

  # Combine package and version if provided
  if (!is.null(version) && !grepl("@", package)) {
    package <- paste0(package, version)
  }

  # Initialize packages list if needed
  if (is.null(config$packages)) {
    config$packages <- list()
  }

  # Check if package already exists
  package_base <- sub("@.*$", "", package)
  existing_idx <- NULL
  if (is.list(config$packages) && length(config$packages) > 0) {
    for (i in seq_along(config$packages)) {
      pkg <- config$packages[[i]]
      if (is.character(pkg)) {
        if (sub("@.*$", "", pkg) == package_base) {
          existing_idx <- i
          break
        }
      } else if (is.list(pkg)) {
        if (sub("@.*$", "", pkg$name) == package_base) {
          existing_idx <- i
          break
        }
      }
    }
  }

  # Add or update package
  pkg_entry <- list(name = package, auto_attach = auto_attach)

  if (!is.null(existing_idx)) {
    config$packages[[existing_idx]] <- pkg_entry
    message(sprintf("\u2713 Updated package '%s' in %s", package, basename(config_path)))
  } else {
    config$packages <- c(config$packages, list(pkg_entry))
    message(sprintf("\u2713 Added package '%s' to %s", package, basename(config_path)))
  }

  message(sprintf("  Auto-attach: %s", if (auto_attach) "yes" else "no"))
  message("\nRun scaffold() to install and load packages")

  # Write config
  write_config(config, config_path)

  invisible(config)
}


#' Configure Project Directories
#'
#' Interactively configure project directory structure in settings.yml (or settings.yml for legacy projects).
#' Directories control where Framework creates and looks for files.
#'
#' @param directory Character. Directory name to configure (e.g., "notebooks", "scripts")
#' @param path Character. Path for the directory
#' @param interactive Logical. If TRUE, prompts for missing values. Default TRUE.
#'
#' @return Invisibly returns updated config
#'
#' @details
#' ## Standard Directories
#'
#' - `notebooks` - Where make_notebook() creates files
#' - `scripts` - Where make_script() creates files
#' - `functions` - Where scaffold() looks for custom functions
#' - `inputs_raw` - Source data (gitignored)
#' - `inputs_intermediate` - Cleaned-but-input datasets
#' - `inputs_final` - Curated analytic datasets
#' - `inputs_reference` - External documentation/codebooks
#' - `outputs_private` - Working artifacts (tables/figures/models)
#' - `outputs_public` - Share-ready artifacts
#' - `outputs_docs` - Narrative/report outputs (private)
#' - `outputs_docs_public` - Narrative/report outputs (public)
#' - `cache` - Cached computation results
#' - `scratch` - Temporary workspace
#'
#' @examples
#' \dontrun{
#' # Interactive mode
#' configure_directories()
#'
#' # Set specific directory
#' configure_directories(
#'   directory = "notebooks",
#'   path = "analysis"
#' )
#' }
#'
#' @export
configure_directories <- function(directory = NULL, path = NULL, interactive = TRUE) {
  # Validate arguments
  checkmate::assert_string(directory, min.chars = 1, null.ok = TRUE)
  checkmate::assert_string(path, min.chars = 1, null.ok = TRUE)
  checkmate::assert_flag(interactive)

  # Read current config
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("settings.yml or config.yml not found. Run framework::init() first.")
  }

  config <- read_config(config_path)

  # Standard directory names
  standard_dirs <- c(
    "notebooks", "scripts", "functions",
    "inputs_raw", "inputs_intermediate", "inputs_final",
    "inputs_reference",
    "outputs_private", "outputs_public",
    "outputs_docs", "outputs_docs_public",
    "cache", "scratch"
  )

  # Interactive prompts
  if (interactive) {
    if (is.null(directory)) {
      cat("Directory name (e.g., 'notebooks', 'scripts'): ")
      cat(sprintf("\nStandard directories: %s\n", paste(standard_dirs, collapse = ", ")))
      cat("Directory: ")
      directory <- readline()
      if (!nzchar(directory)) stop("Directory name is required")
    }

    # Show current value if it exists
    current_path <- config$directories[[directory]]
    if (!is.null(current_path)) {
      cat(sprintf("Current path: %s\n", current_path))
    }

    if (is.null(path)) {
      cat(sprintf("New path for '%s': ", directory))
      path <- readline()
      if (!nzchar(path)) stop("Directory path is required")
    }
  }

  # Initialize directories if needed
  if (is.null(config$directories)) {
    config$directories <- list()
  }

  # Update directory
  config$directories[[directory]] <- path

  # Write config
  write_config(config, config_path)

  message(sprintf("\u2713 Directory '%s' set to '%s' in %s", directory, path, basename(config_path)))

  # Create directory if it doesn't exist
  if (!dir.exists(path)) {
    cat(sprintf("Create directory '%s'? [Y/n]: ", path))
    create_input <- if (interactive) readline() else "y"
    if (!tolower(create_input) %in% c("n", "no")) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
      message(sprintf("  Created directory: %s", path))
    }
  }

  invisible(config)
}
