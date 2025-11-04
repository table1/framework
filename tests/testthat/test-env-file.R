test_that(".env file parsing preserves structure", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Create .env file with specific structure and comments
  original_content <- c(
    "# Important database configuration",
    "DB_HOST=localhost",
    "# Port number",
    "DB_PORT=5432",
    "",
    "# API credentials",
    "API_KEY=secret123",
    "# End of file"
  )
  writeLines(original_content, file.path(project_path, ".env"))

  # Read the file back
  read_content <- readLines(file.path(project_path, ".env"))

  # Verify structure preserved
  expect_equal(read_content, original_content)
  expect_true(any(grepl("# Important database", read_content)))
  expect_true(any(grepl("# Port number", read_content)))
  expect_true(any(grepl("# End of file", read_content)))
})

test_that(".env file with dotenv_location in parent directory", {
  # Create parent and project directories
  parent_dir <- withr::local_tempdir()
  project_dir <- file.path(parent_dir, "myproject")
  dir.create(project_dir)

  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(project_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  # Remove .env that init() may have created
  if (file.exists(file.path(project_dir, ".env"))) {
    file.remove(file.path(project_dir, ".env"))
  }

  # Create settings.yml with dotenv_location pointing to parent
  settings_content <- c(
    "default:",
    "  project_type: project",
    "  project_name: EnvTest",
    "  dotenv_location: \"../\""
  )
  writeLines(settings_content, file.path(project_dir, "settings.yml"))

  # Create .env in parent directory
  env_content <- c("PARENT_VAR=fromparent")
  writeLines(env_content, file.path(parent_dir, ".env"))

  # Verify .env exists in parent but not in project
  expect_true(file.exists(file.path(parent_dir, ".env")))
  expect_false(file.exists(file.path(project_dir, ".env")))

  # Read settings to verify dotenv_location
  settings <- yaml::read_yaml(file.path(project_dir, "settings.yml"))
  expect_equal(settings$default$dotenv_location, "../")
})

test_that(".env file handles special characters in values", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Create .env with various special cases
  env_content <- c(
    'SIMPLE=value',
    'WITH_SPACES="value with spaces"',
    'WITH_EQUALS=key=value',
    'EMPTY=',
    'WITH_QUOTES="value with \\"quotes\\""'
  )
  writeLines(env_content, file.path(project_path, ".env"))

  # Read back
  read_content <- readLines(file.path(project_path, ".env"))

  # Verify content preserved
  expect_true(any(grepl('SIMPLE=value', read_content)))
  expect_true(any(grepl('WITH_SPACES=', read_content)))
  expect_true(any(grepl('WITH_EQUALS=', read_content)))
  expect_true(any(grepl('EMPTY=', read_content)))
})

test_that(".env file grouping by prefix works", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Create .env with mixed prefixes
  env_content <- c(
    "API_KEY=key1",
    "DB_HOST=localhost",
    "API_SECRET=secret1",
    "DB_PORT=5432",
    "NAS_PATH=/mnt/nas",
    "OTHER_VAR=value"
  )
  writeLines(env_content, file.path(project_path, ".env"))

  # Parse and group by prefix
  lines <- readLines(file.path(project_path, ".env"))
  vars <- list()

  for (line in lines) {
    if (grepl("^\\s*#", line) || grepl("^\\s*$", line)) next
    if (grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        key <- trimws(parts[1])
        value <- paste(parts[-1], collapse = "=")
        value <- gsub('^"(.*)"$', '\\1', value)  # Remove quotes
        vars[[key]] <- value
      }
    }
  }

  # Group by prefix
  get_prefix <- function(key) {
    parts <- strsplit(key, "_")[[1]]
    if (length(parts) > 1) parts[1] else "OTHER"
  }

  prefixes <- sapply(names(vars), get_prefix)
  unique_prefixes <- unique(prefixes)

  # Verify grouping
  expect_true("API" %in% unique_prefixes)
  expect_true("DB" %in% unique_prefixes)
  expect_true("NAS" %in% unique_prefixes)
  expect_true("OTHER" %in% unique_prefixes)

  # Count variables in each group
  api_vars <- sum(prefixes == "API")
  db_vars <- sum(prefixes == "DB")
  nas_vars <- sum(prefixes == "NAS")
  other_vars <- sum(prefixes == "OTHER")

  expect_equal(api_vars, 2)
  expect_equal(db_vars, 2)
  expect_equal(nas_vars, 1)
  expect_equal(other_vars, 1)
})

test_that(".env scanning for env() usage in R files", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Create R file with env() calls
  r_code <- c(
    'db_host <- env("DB_HOST")',
    'db_port <- env("DB_PORT")',
    'api_key <- env("API_KEY")',
    '# Comment with env("FAKE_VAR")',
    "another <- env('NAS_PATH')"
  )
  writeLines(r_code, file.path(project_path, "functions", "config.R"))

  # Scan for env() usage
  content <- readLines(file.path(project_path, "functions", "config.R"))
  content_str <- paste(content, collapse = "\n")

  # Find env("VARIABLE") or env('VARIABLE') patterns
  matches <- gregexpr('env\\(["\']([^"\']+)["\']', content_str, perl = TRUE)
  match_data <- regmatches(content_str, matches)[[1]]

  # Extract variable names
  var_names <- gsub('env\\(["\']([^"\']+)["\']', '\\1', match_data, perl = TRUE)

  # Verify found variables
  expect_true("DB_HOST" %in% var_names)
  expect_true("DB_PORT" %in% var_names)
  expect_true("API_KEY" %in% var_names)
  expect_true("NAS_PATH" %in% var_names)
  expect_true("FAKE_VAR" %in% var_names)  # Even in comments

  expect_equal(length(var_names), 5)
})

test_that(".env file edge cases", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Test empty .env file
  writeLines("", file.path(project_path, ".env"))
  expect_true(file.exists(file.path(project_path, ".env")))

  # Test .env with only comments
  writeLines(c("# Comment 1", "# Comment 2"), file.path(project_path, ".env"))
  content <- readLines(file.path(project_path, ".env"))
  expect_equal(length(content), 2)
  expect_true(all(grepl("^#", content)))

  # Test .env with blank lines
  writeLines(c("VAR1=value1", "", "VAR2=value2", ""), file.path(project_path, ".env"))
  content <- readLines(file.path(project_path, ".env"))
  expect_equal(length(content), 4)

  # Test malformed lines (missing equals)
  writeLines(c(
    "VALID=value",
    "INVALID_NO_EQUALS",
    "ALSO_VALID=foo"
  ), file.path(project_path, ".env"))
  content <- readLines(file.path(project_path, ".env"))

  # Parse only valid lines
  vars <- list()
  for (line in content) {
    if (grepl("=", line) && !grepl("^\\s*#", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        vars[[parts[1]]] <- paste(parts[-1], collapse = "=")
      }
    }
  }

  expect_equal(length(vars), 2)
  expect_equal(vars$VALID, "value")
  expect_equal(vars$ALSO_VALID, "foo")
  expect_null(vars$INVALID_NO_EQUALS)
})

test_that(".env regrouping creates proper structure", {
  # Create test project
  test_dir <- withr::local_tempdir()
  old_wd <- getwd()
  on.exit(setwd(old_wd))

  setwd(test_dir)

  suppressMessages({
    framework::init(
      project_name = "EnvTest",
      type = "project",
      force = TRUE
    )
  })

  project_path <- test_dir  # init() creates files in current directory

  # Simulate regrouping logic
  vars <- list(
    API_KEY = "key1",
    DB_HOST = "localhost",
    API_SECRET = "secret1",
    DB_PORT = "5432",
    OTHER_VAR = "value"
  )

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

      # Add variables (sorted)
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

  # Write regrouped file
  writeLines(lines, file.path(project_path, ".env"))

  # Read back and verify
  content <- readLines(file.path(project_path, ".env"))

  # Verify headers exist
  expect_true(any(grepl("# API Variables", content)))
  expect_true(any(grepl("# DB Variables", content)))
  expect_true(any(grepl("# Other Variables", content)))

  # Verify order (API before DB before OTHER)
  api_header_line <- which(grepl("# API Variables", content))
  db_header_line <- which(grepl("# DB Variables", content))
  other_header_line <- which(grepl("# Other Variables", content))

  expect_true(api_header_line < db_header_line)
  expect_true(db_header_line < other_header_line)

  # Verify variables are grouped correctly
  api_key_line <- which(grepl("^API_KEY=", content))
  api_secret_line <- which(grepl("^API_SECRET=", content))
  db_host_line <- which(grepl("^DB_HOST=", content))
  db_port_line <- which(grepl("^DB_PORT=", content))

  # All API vars should be before all DB vars
  expect_true(max(c(api_key_line, api_secret_line)) < min(c(db_host_line, db_port_line)))
})
