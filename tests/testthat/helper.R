# Test helper functions

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
create_test_project <- function(dir = create_test_dir(), type = "presentation") {
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(dir)

  # Initialize the project
  suppressMessages(init(project_name = "TestProject", type = type, force = TRUE))

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
