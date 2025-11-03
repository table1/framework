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
    unlink(file.path(temp_home, ".frameworkrc.json"))
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
  expect_true(file.exists(file.path(temp_home, ".frameworkrc.json")))

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
    unlink(file.path(temp_home, ".frameworkrc.json"))
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


test_that("configure_global writes JSON format", {
  temp_home <- tempdir()
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(file.path(temp_home, ".frameworkrc.json"))
  })

  Sys.setenv(HOME = temp_home)

  configure_global(settings = list(
    author = list(name = "Test User")
  ))

  rc_path <- file.path(temp_home, ".frameworkrc.json")
  expect_true(file.exists(rc_path))

  # Should be valid JSON
  json_content <- jsonlite::fromJSON(rc_path)
  expect_true(is.list(json_content))
  expect_equal(json_content$author$name, "Test User")
})
