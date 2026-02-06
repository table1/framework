# Database test helpers
# Shared utilities for multi-database testing

#' Skip test if database driver not installed
skip_if_no_driver <- function(package_name, driver_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    testthat::skip(sprintf("%s package not installed (required for %s)", package_name, driver_name))
  }
}

#' Get test database connections
#' Returns list of available test database connections
get_test_connections <- function() {
  connections <- list()

  # SQLite (always available)
  connections$sqlite <- list(
    name = "test_sqlite",
    driver = "sqlite",
    database = tempfile(fileext = ".db")
  )

  # PostgreSQL (if Docker running)
  if (requireNamespace("RPostgres", quietly = TRUE)) {
    connections$postgres <- list(
      name = "test_postgres",
      driver = "postgres",
      host = Sys.getenv("TEST_POSTGRES_HOST", "localhost"),
      port = 5432,
      database = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }

  # MySQL (if Docker running)
  if (requireNamespace("RMariaDB", quietly = TRUE)) {
    connections$mysql <- list(
      name = "test_mysql",
      driver = "mysql",
      host = Sys.getenv("TEST_MYSQL_HOST", "localhost"),
      port = 3306,
      database = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }

  # MariaDB (if Docker running)
  if (requireNamespace("RMariaDB", quietly = TRUE)) {
    connections$mariadb <- list(
      name = "test_mariadb",
      driver = "mariadb",
      host = Sys.getenv("TEST_MARIADB_HOST", "localhost"),
      port = 3307,
      database = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }

  # DuckDB (file-based)
  if (requireNamespace("duckdb", quietly = TRUE)) {
    connections$duckdb <- list(
      name = "test_duckdb",
      driver = "duckdb",
      database = tempfile(fileext = ".duckdb")
    )
  }

  connections
}

#' Create a test connection
create_test_connection <- function(config) {
  tryCatch({
    switch(config$driver,
      sqlite = DBI::dbConnect(RSQLite::SQLite(), config$database),
      postgres = DBI::dbConnect(
        RPostgres::Postgres(),
        host = config$host,
        port = config$port,
        dbname = config$database,
        user = config$user,
        password = config$password
      ),
      mysql = ,
      mariadb = DBI::dbConnect(
        RMariaDB::MariaDB(),
        host = config$host,
        port = config$port,
        dbname = config$database,
        user = config$user,
        password = config$password
      ),
      duckdb = DBI::dbConnect(duckdb::duckdb(), config$database),
      stop("Unknown driver: ", config$driver)
    )
  }, error = function(e) {
    NULL  # Return NULL if connection fails (Docker not running, etc.)
  })
}

#' Check if a database is available
is_database_available <- function(config) {
  conn <- create_test_connection(config)
  if (is.null(conn)) {
    return(FALSE)
  }
  DBI::dbDisconnect(conn)
  TRUE
}

#' Create a test table with soft-delete support
create_test_table <- function(conn, table_name = "test_users", with_soft_delete = TRUE) {
  # Determine SQL based on database type
  if (inherits(conn, "SQLiteConnection")) {
    sql <- sprintf("
      CREATE TABLE %s (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        age INTEGER,
        created_at TEXT,
        updated_at TEXT%s
      )",
      table_name,
      if (with_soft_delete) ",\n        deleted_at TEXT" else ""
    )
  } else if (inherits(conn, "PqConnection")) {
    sql <- sprintf("
      CREATE TABLE %s (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255) UNIQUE,
        age INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP%s
      )",
      table_name,
      if (with_soft_delete) ",\n        deleted_at TIMESTAMP NULL" else ""
    )
  } else if (inherits(conn, "MariaDBConnection")) {
    sql <- sprintf("
      CREATE TABLE %s (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255) UNIQUE,
        age INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP%s
      )",
      table_name,
      if (with_soft_delete) ",\n        deleted_at TIMESTAMP NULL" else ""
    )
  } else if (inherits(conn, "duckdb_connection")) {
    sql <- sprintf("
      CREATE TABLE %s (
        id INTEGER PRIMARY KEY,
        name VARCHAR,
        email VARCHAR UNIQUE,
        age INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP%s
      )",
      table_name,
      if (with_soft_delete) ",\n        deleted_at TIMESTAMP" else ""
    )
  } else {
    # Generic SQL
    sql <- sprintf("
      CREATE TABLE %s (
        id INTEGER PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255),
        age INTEGER%s
      )",
      table_name,
      if (with_soft_delete) ",\n        deleted_at TIMESTAMP" else ""
    )
  }

  DBI::dbExecute(conn, sql)
}

#' Clean up test table
drop_test_table <- function(conn, table_name = "test_users") {
  tryCatch({
    DBI::dbExecute(conn, sprintf("DROP TABLE IF EXISTS %s", table_name))
  }, error = function(e) {
    # Ignore errors (table might not exist)
  })
}
