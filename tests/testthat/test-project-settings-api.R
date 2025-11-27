test_that("project settings save preserves all extra_directories", {
  skip_on_cran()

  # Setup: Create a test project with initial extra directories
  test_dir <- tempdir()
  project_path <- file.path(test_dir, "test-project-settings")

  # Clean up from previous runs
  if (dir.exists(project_path)) {
    unlink(project_path, recursive = TRUE)
  }

  dir.create(project_path, recursive = TRUE)

  # Create initial settings.yml with existing extra directories
  initial_settings <- list(
    default = list(
      project_name = "Test Project",
      project_type = "project",
      extra_directories = list(
        list(
          key = "inputs_archive",
          label = "Archive",
          path = "inputs/archive",
          category = "input",
          `_id` = 111111
        ),
        list(
          key = "inputs_raw_data",
          label = "Raw Data",
          path = "inputs/raw/data",
          category = "input",
          `_id` = 222222
        )
      ),
      enabled = list(
        inputs_raw = TRUE,
        inputs_intermediate = TRUE,
        inputs_final = TRUE,
        inputs_archive = TRUE,
        inputs_raw_data = TRUE
      )
    )
  )

  yaml::write_yaml(initial_settings, file.path(project_path, "settings.yml"))

  # Simulate adding a NEW workspace directory (scripts)
  updated_settings <- initial_settings
  updated_settings$default$extra_directories <- c(
    updated_settings$default$extra_directories,
    list(
      list(
        key = "workspace_scripts",
        label = "Scripts",
        path = "workspace/scripts",
        category = "workspace",
        `_id` = 333333
      )
    )
  )
  updated_settings$default$enabled$workspace_scripts <- TRUE

  # Test: Save the updated settings
  # This simulates what the POST /api/project/<id>/settings endpoint does
  setwd(project_path)

  # Simulate the save logic from plumber.R
  settings_file <- "settings.yml"
  current_settings <- yaml::read_yaml(settings_file)

  # Update with new data (as the endpoint does)
  if (!is.null(updated_settings$default$extra_directories)) {
    extra_dirs <- updated_settings$default$extra_directories
    if (is.list(extra_dirs)) {
      names(extra_dirs) <- NULL  # Remove names to ensure array serialization
    }
    current_settings$default$extra_directories <- extra_dirs
  }

  if (!is.null(updated_settings$default$enabled)) {
    current_settings$default$enabled <- updated_settings$default$enabled
  }

  # Write back
  yaml::write_yaml(current_settings, settings_file)

  # Verify: Read back the settings
  saved_settings <- yaml::read_yaml(settings_file)

  # Test 1: All extra_directories should be present (2 original + 1 new = 3)
  expect_equal(length(saved_settings$default$extra_directories), 3)

  # Test 2: Original directories should still exist
  keys <- sapply(saved_settings$default$extra_directories, function(d) d$key)
  expect_true("inputs_archive" %in% keys)
  expect_true("inputs_raw_data" %in% keys)
  expect_true("workspace_scripts" %in% keys)

  # Test 3: All enabled states should be preserved
  expect_true(saved_settings$default$enabled$inputs_archive)
  expect_true(saved_settings$default$enabled$inputs_raw_data)
  expect_true(saved_settings$default$enabled$workspace_scripts)

  # Test 4: extra_directories should be an array (unnamed list)
  expect_null(names(saved_settings$default$extra_directories))

  # Cleanup
  unlink(project_path, recursive = TRUE)
})

test_that("connections API save writes new schema (databases + storage + defaults)", {
  skip_on_cran()
  skip_if_not_installed("yaml")

  # Setup project with split connections file
  test_dir <- tempdir()
  project_path <- file.path(test_dir, "test-connections-api")
  if (dir.exists(project_path)) unlink(project_path, recursive = TRUE)
  dir.create(file.path(project_path, "settings"), recursive = TRUE)

  # Seed config.yml referencing split connections file
  config <- list(
    default = list(
      project_name = "Test",
      project_type = "project",
      connections = "settings/connections.yml"
    )
  )
  yaml::write_yaml(config, file.path(project_path, "config.yml"))

  # Prepare body from UI (new schema)
  body <- list(
    default_database = "warehouse",
    default_storage_bucket = "s3_bucket",
    databases = list(
      warehouse = list(
        driver = "postgres",
        host = "localhost",
        port = "5432",
        database = "analytics",
        schema = "public",
        user = "analyst",
        password = "secret"
      )
    ),
    storage_buckets = list(
      s3_bucket = list(
        bucket = "my-bucket",
        region = "us-east-1",
        endpoint = "https://s3.amazonaws.com",
        access_key = "abc",
        secret_key = "xyz"
      )
    )
  )

  split_info <- framework:::.uses_split_file(project_path, "connections")

  # Simulate POST /api/project/<id>/connections logic
  connections_data <- list(
    default_database = body$default_database,
    default_storage_bucket = body$default_storage_bucket,
    databases = body$databases %||% list(),
    storage_buckets = body$storage_buckets %||% list()
  )

  dir.create(dirname(split_info$split_file), recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(list(connections = connections_data), split_info$split_file)

  # Validate saved connections.yml
  saved <- yaml::read_yaml(split_info$split_file)$connections
  expect_equal(saved$default_database, "warehouse")
  expect_equal(saved$default_storage_bucket, "s3_bucket")
  expect_true("warehouse" %in% names(saved$databases))
  expect_true("s3_bucket" %in% names(saved$storage_buckets))
  expect_equal(saved$databases$warehouse$driver, "postgres")
  expect_equal(saved$storage_buckets$s3_bucket$bucket, "my-bucket")
})

test_that("project settings save with data.frame conversion", {
  skip_on_cran()

  # Setup
  test_dir <- tempdir()
  project_path <- file.path(test_dir, "test-dataframe-conversion")

  if (dir.exists(project_path)) {
    unlink(project_path, recursive = TRUE)
  }

  dir.create(project_path, recursive = TRUE)

  initial_settings <- list(
    default = list(
      project_name = "Test Project",
      project_type = "project",
      extra_directories = list(),
      enabled = list(inputs_raw = TRUE)
    )
  )

  yaml::write_yaml(initial_settings, file.path(project_path, "settings.yml"))

  # Simulate jsonlite converting array to data.frame (as happens in plumber)
  json_str <- '[{"key":"inputs_new","label":"New","path":"inputs/new","category":"input","_id":123456}]'
  parsed <- jsonlite::fromJSON(json_str)

  # This will be a data.frame - simulate the conversion logic
  directories <- parsed
  if (is.data.frame(directories)) {
    directories <- lapply(1:nrow(directories), function(i) {
      as.list(directories[i, , drop = FALSE][1, ])
    })
  }

  # Remove names to ensure array
  if (is.list(directories)) {
    names(directories) <- NULL
  }

  # Test: Verify it's now an unnamed list (array)
  expect_true(is.list(directories))
  expect_null(names(directories))
  expect_equal(length(directories), 1)
  expect_equal(directories[[1]]$key, "inputs_new")

  # Cleanup
  unlink(project_path, recursive = TRUE)
})

test_that("project settings GET returns extra_directories as array", {
  skip_on_cran()

  # Setup: Create project with single extra directory (prone to becoming object)
  test_dir <- tempdir()
  project_path <- file.path(test_dir, "test-get-array")

  if (dir.exists(project_path)) {
    unlink(project_path, recursive = TRUE)
  }

  dir.create(project_path, recursive = TRUE)

  settings <- list(
    default = list(
      project_name = "Test",
      extra_directories = list(
        list(
          key = "inputs_test",
          label = "Test",
          path = "inputs/test",
          `_id` = 999
        )
      )
    )
  )

  yaml::write_yaml(settings, file.path(project_path, "settings.yml"))

  # Read back (simulating GET endpoint)
  loaded_settings <- yaml::read_yaml(file.path(project_path, "settings.yml"))
  settings_resolved <- loaded_settings$default

  # Apply the fix from plumber.R GET endpoint
  if (!is.null(settings_resolved$extra_directories)) {
    if (!is.null(names(settings_resolved$extra_directories)) &&
        length(names(settings_resolved$extra_directories)) > 0) {
      # It's a named list (single object) - wrap in unnamed list
      settings_resolved$extra_directories <- list(settings_resolved$extra_directories)
      names(settings_resolved$extra_directories) <- NULL
    } else {
      # Already unnamed list, just ensure no names
      names(settings_resolved$extra_directories) <- NULL
    }
  }

  # Test: Should be unnamed list (array)
  expect_null(names(settings_resolved$extra_directories))
  expect_equal(length(settings_resolved$extra_directories), 1)
  expect_equal(settings_resolved$extra_directories[[1]]$key, "inputs_test")

  # Cleanup
  unlink(project_path, recursive = TRUE)
})

test_that("enabled state persists for custom directories", {
  skip_on_cran()

  # Setup
  test_dir <- tempdir()
  project_path <- file.path(test_dir, "test-enabled-persist")

  if (dir.exists(project_path)) {
    unlink(project_path, recursive = TRUE)
  }

  dir.create(project_path, recursive = TRUE)

  # Initial state: no custom directories
  initial_settings <- list(
    default = list(
      project_name = "Test",
      extra_directories = list(),
      enabled = list(inputs_raw = TRUE, inputs_final = TRUE)
    )
  )

  yaml::write_yaml(initial_settings, file.path(project_path, "settings.yml"))

  # Add custom directory and enable it
  updated_enabled <- initial_settings$default$enabled
  updated_enabled$inputs_custom <- TRUE

  updated_extra <- list(
    list(key = "inputs_custom", label = "Custom", path = "inputs/custom", `_id` = 123)
  )

  # Save
  current <- yaml::read_yaml(file.path(project_path, "settings.yml"))
  current$default$extra_directories <- updated_extra
  current$default$enabled <- updated_enabled
  names(current$default$extra_directories) <- NULL

  yaml::write_yaml(current, file.path(project_path, "settings.yml"))

  # Reload
  reloaded <- yaml::read_yaml(file.path(project_path, "settings.yml"))

  # Test: enabled state should persist
  expect_true(reloaded$default$enabled$inputs_custom)
  expect_equal(length(reloaded$default$extra_directories), 1)
  expect_equal(reloaded$default$extra_directories[[1]]$key, "inputs_custom")

  # Cleanup
  unlink(project_path, recursive = TRUE)
})
