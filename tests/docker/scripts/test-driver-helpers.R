#!/usr/bin/env Rscript
# Test driver management helpers
# This script demonstrates the user-facing driver management functions

cat("\n=== Testing Driver Management Helpers ===\n\n")

# Load Framework
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::load_all(".")

# Test 1: Check driver status
cat("Test 1: Check driver status\n")
cat("----------------------------\n")
status <- drivers_status()

# Test 2: Check a valid connection (framework DB)
cat("\nTest 2: Check valid connection (framework)\n")
cat("-------------------------------------------\n")
diag <- connection_check("framework")
if (diag$ready) {
  cat("✓ Connection 'framework' is ready\n")
} else {
  cat("✗ Connection 'framework' not ready:\n")
  print(diag$messages)
}

# Test 3: Check an invalid connection
cat("\nTest 3: Check invalid connection\n")
cat("---------------------------------\n")
diag <- connection_check("nonexistent")

# Test 4: Check a connection that needs a driver (if config exists)
cat("\nTest 4: Check configured database connections\n")
cat("----------------------------------------------\n")

# Read config to see what connections exist
cfg <- tryCatch(
  config::get(file = "config.yml"),
  error = function(e) NULL
)

if (!is.null(cfg) && !is.null(cfg$connections)) {
  connection_names <- names(cfg$connections)
  cat(sprintf("Found %d configured connections: %s\n\n",
              length(connection_names),
              paste(connection_names, collapse = ", ")))

  for (conn_name in connection_names) {
    cat(sprintf("Checking '%s'...\n", conn_name))
    diag <- connection_check(conn_name)
    if (diag$ready) {
      cat(sprintf("  ✓ Ready (driver: %s)\n", diag$driver))
    } else {
      cat(sprintf("  ✗ Not ready (driver: %s)\n", diag$driver))
      cat(sprintf("    Issues: %s\n", paste(diag$messages, collapse = "; ")))
    }
  }
} else {
  cat("No connections configured in config.yml\n")
}

cat("\n=== Driver Helper Tests Complete ===\n\n")

# Show summary
cat("Available functions:\n")
cat("  • drivers_status()         - Check which drivers are installed\n")
cat("  • drivers_install(drivers) - Install database drivers\n")
cat("  • connection_check(name)   - Diagnose connection readiness\n\n")

cat("Example usage:\n")
cat("  # Check what's installed\n")
cat("  drivers_status()\n\n")

cat("  # Install a driver\n")
cat("  drivers_install('postgres')\n\n")

cat("  # Check if connection is ready\n")
cat("  diag <- connection_check('my_db')\n")
cat("  if (diag$ready) {\n")
cat("    conn <- connection_get('my_db')\n")
cat("  }\n\n")
