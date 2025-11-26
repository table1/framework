test_that("API /api/settings/save accepts valid settings", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Simulate what the API endpoint does: JSON -> R list -> configure_global
  request_body <- jsonlite::toJSON(list(
    author = list(
      name = "Test User",
      email = "test@example.com",
      affiliation = "Test Org"
    ),
    defaults = list(
      project_type = "project",
      notebook_format = "quarto"
    )
  ), auto_unbox = TRUE)

  # Parse with simplifyDataFrame = FALSE (like the API does)
  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)

  # Call configure_global (like the API does)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_true(result$success)

  # Verify settings were actually saved
  saved <- framework::read_frameworkrc()
  expect_equal(saved$author$name, "Test User")
  expect_equal(saved$defaults$project_type, "project")
})

test_that("API /api/settings/save persists git hooks and use_git flags", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # First save: enable git and specific hooks
  framework::configure_global(settings = list(
    defaults = list(
      use_git = TRUE,
      git_hooks = list(
        ai_sync = TRUE,
        data_security = FALSE,
        check_sensitive_dirs = TRUE
      )
    )
  ), validate = TRUE)

  saved <- framework::read_frameworkrc()
  expect_true(saved$defaults$use_git)
  expect_true(saved$defaults$git_hooks$ai_sync)
  expect_false(saved$defaults$git_hooks$data_security)
  expect_true(saved$defaults$git_hooks$check_sensitive_dirs)

  # Second save: disable git and flip hooks
  framework::configure_global(settings = list(
    defaults = list(
      use_git = FALSE,
      git_hooks = list(
        ai_sync = FALSE,
        data_security = TRUE,
        check_sensitive_dirs = FALSE
      )
    )
  ), validate = TRUE)

  saved <- framework::read_frameworkrc()
  expect_false(saved$defaults$use_git)
  expect_false(saved$defaults$git_hooks$ai_sync)
  expect_true(saved$defaults$git_hooks$data_security)
  expect_false(saved$defaults$git_hooks$check_sensitive_dirs)
})

test_that("API /api/settings/save persists scaffold behavior settings", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  framework::configure_global(settings = list(
    defaults = list(
      scaffold = list(
        source_all_functions = FALSE,
        set_theme_on_scaffold = TRUE,
        ggplot_theme = "theme_bw",
        seed_on_scaffold = TRUE,
        seed = "2024"
      )
    )
  ), validate = TRUE)

  saved <- framework::read_frameworkrc()
  expect_false(saved$defaults$scaffold$source_all_functions)
  expect_true(saved$defaults$scaffold$set_theme_on_scaffold)
  expect_equal(saved$defaults$scaffold$ggplot_theme, "theme_bw")
  expect_true(saved$defaults$scaffold$seed_on_scaffold)
  expect_equal(saved$defaults$scaffold$seed, "2024")
})

test_that("API /api/settings/save persists AI assistant settings", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  framework::configure_global(settings = list(
    defaults = list(
      ai_support = FALSE,
      ai_assistants = c("claude", "agents"),
      ai_canonical_file = "AGENTS.md"
    )
  ), validate = TRUE)

  saved <- framework::read_frameworkrc()
  expect_false(saved$defaults$ai_support)
  expect_equal(saved$defaults$ai_assistants, c("claude", "agents"))
  expect_equal(saved$defaults$ai_canonical_file, "AGENTS.md")

  # Flip back on and change canonical file
  framework::configure_global(settings = list(
    defaults = list(
      ai_support = TRUE,
      ai_assistants = c("claude"),
      ai_canonical_file = "CLAUDE.md"
    )
  ), validate = TRUE)

  saved <- framework::read_frameworkrc()
  expect_true(saved$defaults$ai_support)
  expect_equal(saved$defaults$ai_assistants, c("claude"))
  expect_equal(saved$defaults$ai_canonical_file, "CLAUDE.md")
})


test_that("API /api/settings/save validates extra_directories", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Test valid extra_directories
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "inputs_archive", label = "Archive", path = "inputs/archive", type = "input"),
          list(key = "outputs_animations", label = "Animations", path = "outputs/animations", type = "output")
        )
      )
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_true(result$success)

  # Verify extra_directories were saved
  saved <- framework::read_frameworkrc()
  expect_equal(length(saved$project_types$project$extra_directories), 2)
  expect_equal(saved$project_types$project$extra_directories[[1]]$key, "inputs_archive")
})


test_that("API /api/settings/save rejects invalid extra_directories", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Test invalid key format
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "my-invalid-key", label = "Test", path = "test", type = "input")
        )
      )
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_false(result$success)
  expect_match(result$error, "must contain only letters, numbers, and underscores")
})


test_that("API /api/settings/save rejects duplicate keys", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Test duplicate keys
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test_dir", label = "Test 1", path = "test1", type = "input"),
          list(key = "test_dir", label = "Test 2", path = "test2", type = "input")
        )
      )
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_false(result$success)
  expect_match(result$error, "duplicate extra_directories key")
})


test_that("API /api/settings/save rejects absolute paths", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Test absolute path
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test", label = "Test", path = "/absolute/path", type = "input")
        )
      )
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_false(result$success)
  expect_match(result$error, "must be relative")
})


test_that("API /api/settings/save rejects path traversal", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Test path traversal
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test", label = "Test", path = "../parent", type = "input")
        )
      )
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_false(result$success)
  expect_match(result$error, "path traversal")
})


test_that("API /api/settings/save handles JSON array serialization correctly", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Simulate how frontend sends data (with simplifyDataFrame = FALSE)
  request_body <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test1", label = "Test 1", path = "test1", type = "input"),
          list(key = "test2", label = "Test 2", path = "test2", type = "workspace")
        )
      )
    )
  ), auto_unbox = TRUE)

  # Parse with simplifyDataFrame = FALSE (like the API does)
  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)

  # Verify it's a list, not a data.frame
  expect_true(is.list(body$project_types$project$extra_directories))
  expect_false(is.data.frame(body$project_types$project$extra_directories))

  # Should save successfully
  result <- tryCatch({
    framework::configure_global(settings = body, validate = TRUE)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_true(result$success)

  # Verify it was saved correctly as an array
  saved <- framework::read_frameworkrc()
  expect_equal(length(saved$project_types$project$extra_directories), 2)
  expect_true(is.list(saved$project_types$project$extra_directories))
})


test_that("API /api/settings/save preserves extra_directories through updates", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # First save: Set extra_directories
  request1 <- jsonlite::toJSON(list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test1", label = "Test 1", path = "test1", type = "input")
        )
      )
    )
  ), auto_unbox = TRUE)

  body1 <- jsonlite::fromJSON(request1, simplifyDataFrame = FALSE)
  framework::configure_global(settings = body1, validate = TRUE)

  # Second save: Update different field (author)
  request2 <- jsonlite::toJSON(list(
    author = list(name = "Updated User")
  ), auto_unbox = TRUE)

  body2 <- jsonlite::fromJSON(request2, simplifyDataFrame = FALSE)
  framework::configure_global(settings = body2, validate = TRUE)

  # Verify extra_directories still exist
  saved <- framework::read_frameworkrc()
  expect_equal(length(saved$project_types$project$extra_directories), 1)
  expect_equal(saved$project_types$project$extra_directories[[1]]$key, "test1")
  expect_equal(saved$author$name, "Updated User")
})
