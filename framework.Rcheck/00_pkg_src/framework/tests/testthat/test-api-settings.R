# Skip API settings tests on CRAN - they write to user config directory

test_that("API /api/settings/save accepts valid settings", {
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

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


test_that("API /api/settings/save persists global.projects_root via JSON", {
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

  # Simulate exactly what the GUI sends
  request_body <- jsonlite::toJSON(list(
    global = list(
      projects_root = "/Users/test/new-projects"
    ),
    author = list(
      name = "Test User",
      email = "test@example.com"
    )
  ), auto_unbox = TRUE)

  # Parse with simplifyDataFrame = FALSE (like the API does)
  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)

  # Verify JSON parsed correctly
  expect_equal(body$global$projects_root, "/Users/test/new-projects")

  # Call configure_global (like the API does)
  result <- framework::configure_global(settings = body, validate = TRUE)

  # Verify return value
  expect_equal(result$global$projects_root, "/Users/test/new-projects")

  # Verify file was actually saved
  saved <- framework::read_frameworkrc()
  expect_equal(saved$global$projects_root, "/Users/test/new-projects")

  # Also verify by reading raw YAML
  settings_path <- file.path(fw_config_dir(), "settings.yml")
  saved_yaml <- yaml::read_yaml(settings_path)
  expect_equal(saved_yaml$global$projects_root, "/Users/test/new-projects")
})


test_that("API saves global.projects_root when sent with full payload like GUI", {
  skip_on_cran()
  
  cleanup <- setup_isolated_config()
  on.exit(cleanup())

  # This mimics the FULL payload the GUI sends (with all the extra fields)
  request_body <- jsonlite::toJSON(list(
    global = list(
      projects_root = "/Users/test/my-projects",
      home_dir = "/Users/test"
    ),
    author = list(
      name = "Test Author",
      email = "test@example.com",
      affiliation = "Test Org"
    ),
    defaults = list(
      project_type = "project",
      notebook_format = "quarto",
      ide = "vscode",
      use_git = TRUE,
      use_renv = FALSE,
      seed = "123",
      seed_on_scaffold = FALSE,
      ai_support = TRUE,
      ai_assistants = list("claude"),
      ai_canonical_file = "CLAUDE.md",
      scaffold = list(
        source_all_functions = TRUE,
        set_theme_on_scaffold = FALSE,
        seed_on_scaffold = FALSE,
        seed = "123"
      ),
      git_hooks = list(
        ai_sync = FALSE,
        data_security = FALSE
      ),
      packages = list(
        use_renv = FALSE,
        default_packages = list()
      )
    ),
    project_types = list(
      project = list(
        directories = list(
          notebooks = "notebooks",
          scripts = "scripts",
          functions = "functions"
        )
      )
    ),
    git = list(),
    privacy = list(
      secret_scan = FALSE,
      gitignore_template = "gitignore"
    )
  ), auto_unbox = TRUE)

  body <- jsonlite::fromJSON(request_body, simplifyDataFrame = FALSE)

  # Verify JSON parsed correctly
  expect_equal(body$global$projects_root, "/Users/test/my-projects")

  # Call configure_global
  result <- framework::configure_global(settings = body, validate = TRUE)

  # Verify return value has the path
  expect_equal(result$global$projects_root, "/Users/test/my-projects")

  # Verify file was saved correctly
  saved <- framework::read_frameworkrc()
  expect_equal(saved$global$projects_root, "/Users/test/my-projects")
})
