test_that("configure_global reads current config when no settings provided", {
  # Create temp config file
  temp_config <- tempfile(fileext = ".json")
  old_rc <- Sys.getenv("HOME")
  temp_home <- tempdir()

  on.exit({
    Sys.setenv(HOME = old_rc)
    if (file.exists(temp_config)) unlink(temp_config)
  })

  # Mock home directory
  Sys.setenv(HOME = temp_home)

  # Call without settings - should return defaults
  result <- configure_global()

  expect_true(is.list(result))
  expect_true(!is.null(result$author))
  expect_true(!is.null(result$defaults))
})


test_that("configure_global updates author information", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Update author
  result <- configure_global(settings = list(
    author = list(
      name = "Test User",
      email = "test@example.com",
      affiliation = "Test Org"
    )
  ))

  expect_equal(result$author$name, "Test User")
  expect_equal(result$author$email, "test@example.com")
  expect_equal(result$author$affiliation, "Test Org")

  # Verify file was written
  settings_path <- file.path(temp_home, ".config", "framework", "settings.yml")
  expect_true(file.exists(settings_path))

  # Read back and verify
  saved <- read_frameworkrc()
  expect_equal(saved$author$name, "Test User")
})


test_that("configure_global updates defaults", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Update defaults
  result <- configure_global(settings = list(
    defaults = list(
      project_type = "presentation",
      notebook_format = "rmarkdown",
      ide = "rstudio",
      use_git = FALSE,
      seed = 12345
    )
  ))

  expect_equal(result$defaults$project_type, "presentation")
  expect_equal(result$defaults$notebook_format, "rmarkdown")
  expect_equal(result$defaults$ide, "rstudio")
  expect_false(result$defaults$use_git)
  expect_equal(result$defaults$seed, 12345)
})


test_that("configure_global validates project_type choices", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Invalid project type should error
  expect_error(
    configure_global(settings = list(
      defaults = list(project_type = "invalid")
    )),
    "project_type"
  )
})


test_that("configure_global validates notebook_format choices", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Invalid format should error
  expect_error(
    configure_global(settings = list(
      defaults = list(notebook_format = "invalid")
    )),
    "notebook_format"
  )
})


test_that("configure_global validates IDE choices", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Invalid IDE should error
  expect_error(
    configure_global(settings = list(
      defaults = list(ide = "invalid")
    )),
    "ide"
  )
})


test_that("configure_global validates boolean flags", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Invalid boolean should error
  expect_error(
    configure_global(settings = list(
      defaults = list(use_git = "yes")  # should be logical
    )),
    "flag"
  )
})


test_that("configure_global accepts numeric or character seed", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Numeric seed
  result1 <- configure_global(settings = list(
    defaults = list(seed = 12345)
  ))
  expect_equal(result1$defaults$seed, 12345)

  # Character seed
  result2 <- configure_global(settings = list(
    defaults = list(seed = "20250102")
  ))
  expect_equal(result2$defaults$seed, "20250102")
})


test_that("configure_global performs deep merge", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  # Set author first
  configure_global(settings = list(
    author = list(
      name = "First User",
      email = "first@example.com"
    )
  ))

  # Update just email - name should remain
  result <- configure_global(settings = list(
    author = list(
      email = "updated@example.com"
    )
  ))

  expect_equal(result$author$name, "First User")  # unchanged
  expect_equal(result$author$email, "updated@example.com")  # updated
})


test_that("configure_global can skip validation", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Should not error even with invalid data when validate = FALSE
  expect_silent(
    configure_global(
      settings = list(
        defaults = list(project_type = "invalid")
      ),
      validate = FALSE
    )
  )
})


test_that("configure_global writes YAML format", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  configure_global(settings = list(
    author = list(name = "Test User")
  ))

  settings_path <- file.path(temp_home, ".config", "framework", "settings.yml")
  expect_true(file.exists(settings_path))

  # Should be valid YAML
  yaml_content <- yaml::read_yaml(settings_path)
  expect_true(is.list(yaml_content))
  expect_equal(yaml_content$author$name, "Test User")
})


# Tests for extra_directories validation

test_that("configure_global accepts valid extra_directories", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Valid extra_directories
  result <- configure_global(settings = list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "inputs_archive", label = "Archive", path = "inputs/archive", type = "input"),
          list(key = "outputs_animations", label = "Animations", path = "outputs/animations", type = "output")
        )
      )
    )
  ))

  expect_equal(length(result$project_types$project$extra_directories), 2)
  expect_equal(result$project_types$project$extra_directories[[1]]$key, "inputs_archive")
  expect_equal(result$project_types$project$extra_directories[[2]]$type, "output")
})


test_that("configure_global rejects extra_directories with missing fields", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Missing 'key' field
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(label = "Archive", path = "inputs/archive", type = "input")
          )
        )
      )
    )),
    "missing required field 'key'"
  )

  # Missing 'type' field
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "test", label = "Test", path = "test")
          )
        )
      )
    )),
    "missing required field 'type'"
  )
})


test_that("configure_global rejects invalid extra_directories key format", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Key with hyphen (invalid)
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "my-dir", label = "My Dir", path = "my-dir", type = "input")
          )
        )
      )
    )),
    "must contain only letters, numbers, and underscores"
  )

  # Key with space (invalid)
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "my dir", label = "My Dir", path = "mydir", type = "input")
          )
        )
      )
    )),
    "must contain only letters, numbers, and underscores"
  )
})


test_that("configure_global rejects duplicate extra_directories keys", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Duplicate keys
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "test_dir", label = "Test 1", path = "test1", type = "input"),
            list(key = "test_dir", label = "Test 2", path = "test2", type = "input")
          )
        )
      )
    )),
    "duplicate extra_directories key 'test_dir'"
  )
})


test_that("configure_global rejects invalid extra_directories type", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Invalid type
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "test", label = "Test", path = "test", type = "invalid")
          )
        )
      )
    )),
    "type 'invalid' must be one of: input, workspace, output"
  )
})


test_that("configure_global rejects absolute paths in extra_directories", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Absolute path
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "test", label = "Test", path = "/absolute/path", type = "input")
          )
        )
      )
    )),
    "must be relative \\(no leading slash\\)"
  )
})


test_that("configure_global rejects path traversal in extra_directories", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Path traversal
  expect_error(
    configure_global(settings = list(
      project_types = list(
        project = list(
          extra_directories = list(
            list(key = "test", label = "Test", path = "../parent", type = "input")
          )
        )
      )
    )),
    "cannot contain '\\.\\.' \\(path traversal\\)"
  )
})


test_that("configure_global preserves extra_directories through modifyList", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Set initial extra_directories
  configure_global(settings = list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test1", label = "Test 1", path = "test1", type = "input")
        )
      )
    )
  ))

  # Update author (different field) - extra_directories should persist
  result <- configure_global(settings = list(
    author = list(name = "Updated User")
  ))

  # extra_directories should still exist
  expect_equal(length(result$project_types$project$extra_directories), 1)
  expect_equal(result$project_types$project$extra_directories[[1]]$key, "test1")

  # Now update extra_directories
  result2 <- configure_global(settings = list(
    project_types = list(
      project = list(
        extra_directories = list(
          list(key = "test2", label = "Test 2", path = "test2", type = "workspace")
        )
      )
    )
  ))

  # Should be replaced
  expect_equal(length(result2$project_types$project$extra_directories), 1)
  expect_equal(result2$project_types$project$extra_directories[[1]]$key, "test2")
  expect_equal(result2$project_types$project$extra_directories[[1]]$type, "workspace")
})
