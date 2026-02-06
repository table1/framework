# Test helper functions

# Create an isolated config environment for tests
# This prevents tests from modifying real user config
setup_isolated_config <- function() {
  temp_config <- tempfile("fw_config_")
  dir.create(temp_config, recursive = TRUE)
  old_value <- Sys.getenv("FW_CONFIG_HOME", unset = NA)
  Sys.setenv(FW_CONFIG_HOME = temp_config)

  # Return cleanup function
  function() {
    if (is.na(old_value)) {
      Sys.unsetenv("FW_CONFIG_HOME")
    } else {
      Sys.setenv(FW_CONFIG_HOME = old_value)
    }
    unlink(temp_config, recursive = TRUE)
  }
}

# Create a temporary test directory
create_test_dir <- function() {
  dir <- tempfile("framework_test_")
  dir.create(dir, recursive = TRUE)
  dir
}

# Clean up test directory
cleanup_test_dir <- function(dir) {
  if (dir.exists(dir)) {
    unlink(dir, recursive = TRUE)
  }
}

# Create a minimal test project structure
create_test_project <- function(dir = create_test_dir(), type = "project") {
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(dir)

  # Create minimal project structure manually for tests
  # Create basic directories
  dir.create("inputs/raw", recursive = TRUE, showWarnings = FALSE)
  dir.create("inputs/intermediate", recursive = TRUE, showWarnings = FALSE)
  dir.create("inputs/final", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/private", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/private/cache", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/public", recursive = TRUE, showWarnings = FALSE)
  dir.create("notebooks", showWarnings = FALSE)
  dir.create("scripts", showWarnings = FALSE)
  dir.create("functions", showWarnings = FALSE)

  # Create settings directory for connections
  dir.create("settings", showWarnings = FALSE)

  # Create minimal settings.yml (now the primary config file)
  config_content <- list(
    default = list(
      project_name = "TestProject",
      project_type = type,
      directories = list(
        notebooks = "notebooks",
        scripts = "scripts",
        functions = "functions",
        inputs_raw = "inputs/raw",
        inputs_intermediate = "inputs/intermediate",
        inputs_final = "inputs/final",
        outputs_private = "outputs/private",
        outputs_public = "outputs/public",
        cache = "outputs/private/cache"
      ),
      packages = list("dplyr"),
      data = list(),
      connections = "settings/connections.yml"
    )
  )
  yaml::write_yaml(config_content, "settings.yml")

  # Create connections config with framework database
  connections_content <- list(
    options = list(default_connection = "framework"),
    connections = list(
      framework = list(
        driver = "sqlite",
        database = "framework.db"
      )
    )
  )
  yaml::write_yaml(connections_content, "settings/connections.yml")

  # Create framework.db with required tables
  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  # Create data table

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS data (
      name TEXT PRIMARY KEY,
      path TEXT,
      type TEXT,
      delimiter TEXT,
      locked INTEGER DEFAULT 0,
      encrypted INTEGER DEFAULT 0,
      hash TEXT,
      last_read_at TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ")

  # Create cache table
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS cache (
      name TEXT PRIMARY KEY,
      hash TEXT,
      expire_at TEXT,
      last_read_at TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ")

  # Create results table
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS results (
      name TEXT PRIMARY KEY,
      type TEXT,
      blind INTEGER DEFAULT 0,
      comment TEXT,
      hash TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ")

  # Create connections table
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS connections (
      name TEXT PRIMARY KEY,
      driver TEXT,
      host TEXT,
      port INTEGER,
      database TEXT,
      username TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ")

  # Create meta table (for scaffold history, etc.)
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ")

  dir
}

# Check if SQLite database exists and has expected tables
check_framework_db <- function(db_path = "framework.db") {
  if (!file.exists(db_path)) return(FALSE)

  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(conn))

  tables <- DBI::dbListTables(conn)
  expected <- c("data", "cache", "results", "connections")

  all(expected %in% tables)
}
