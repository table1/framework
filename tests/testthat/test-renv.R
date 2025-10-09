test_that("renv_enabled() detects marker file", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Clean up any existing marker
  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_false(renv_enabled())

  writeLines("timestamp", ".framework_renv_enabled")
  expect_true(renv_enabled())

  file.remove(".framework_renv_enabled")
})

test_that("renv_enabled() returns FALSE when marker doesn't exist", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_false(renv_enabled())
})

test_that(".parse_package_spec() handles simple package names", {
  result <- .parse_package_spec("dplyr")

  expect_equal(result$name, "dplyr")
  expect_null(result$version)
  expect_equal(result$source, "cran")
  expect_null(result$repo)
  expect_null(result$ref)
})

test_that(".parse_package_spec() handles version pins", {
  result <- .parse_package_spec("dplyr@1.1.0")

  expect_equal(result$name, "dplyr")
  expect_equal(result$version, "1.1.0")
  expect_equal(result$source, "cran")
})

test_that(".parse_package_spec() handles GitHub repos without ref", {
  result <- .parse_package_spec("tidyverse/dplyr")

  expect_equal(result$name, "dplyr")
  expect_equal(result$repo, "tidyverse/dplyr")
  expect_equal(result$ref, "HEAD")
  expect_equal(result$source, "github")
  expect_null(result$version)
})

test_that(".parse_package_spec() handles GitHub repos with ref", {
  result <- .parse_package_spec("tidyverse/dplyr@main")

  expect_equal(result$name, "dplyr")
  expect_equal(result$repo, "tidyverse/dplyr")
  expect_equal(result$ref, "main")
  expect_equal(result$source, "github")
})

test_that(".parse_package_spec() handles GitHub repos with branch", {
  result <- .parse_package_spec("user/repo@feature-branch")

  expect_equal(result$name, "repo")
  expect_equal(result$repo, "user/repo")
  expect_equal(result$ref, "feature-branch")
  expect_equal(result$source, "github")
})

test_that(".parse_package_spec() trims whitespace", {
  result <- .parse_package_spec("  dplyr  ")

  expect_equal(result$name, "dplyr")
  expect_equal(result$source, "cran")
})

test_that(".mark_scaffolded() creates marker on first run", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_scaffolded")) {
    file.remove(".framework_scaffolded")
  }

  .mark_scaffolded()

  expect_true(file.exists(".framework_scaffolded"))
  content <- readLines(".framework_scaffolded")
  expect_true(grepl("^First scaffolded at:", content[1]))

  file.remove(".framework_scaffolded")
})

test_that(".mark_scaffolded() appends on subsequent runs", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_scaffolded")) {
    file.remove(".framework_scaffolded")
  }

  # First run
  .mark_scaffolded()
  content1 <- readLines(".framework_scaffolded")
  expect_length(content1, 1)

  # Second run
  Sys.sleep(0.1) # Ensure different timestamp
  .mark_scaffolded()
  content2 <- readLines(".framework_scaffolded")
  expect_length(content2, 2)
  expect_true(grepl("^First scaffolded at:", content2[1]))
  expect_true(grepl("^Scaffolded at:", content2[2]))

  file.remove(".framework_scaffolded")
})

test_that(".renv_nag() shows message on first scaffold", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Clean up
  if (file.exists(".framework_scaffolded")) file.remove(".framework_scaffolded")
  if (file.exists(".framework_renv_enabled")) file.remove(".framework_renv_enabled")

  # Create minimal config without renv_nag option
  writeLines("default:\n  options:\n    renv_nag: true", "config.yml")

  # Should show message on first scaffold
  expect_message(.renv_nag(), "Reproducibility Tip")

  # Clean up
  file.remove("config.yml")
})

test_that(".renv_nag() suppressed on second scaffold", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Clean up
  if (file.exists(".framework_scaffolded")) file.remove(".framework_scaffolded")
  if (file.exists(".framework_renv_enabled")) file.remove(".framework_renv_enabled")

  # Create scaffold marker with timestamp (not first scaffold)
  writeLines("First scaffolded at: 2025-01-01", ".framework_scaffolded")

  # Create minimal config
  writeLines("default:\n  options:\n    renv_nag: true", "config.yml")

  # Should NOT show message (returns NULL invisibly)
  expect_invisible(.renv_nag())

  # Clean up
  file.remove(".framework_scaffolded")
  file.remove("config.yml")
})

test_that(".renv_nag() suppressed when renv_nag is FALSE in config", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Clean up
  if (file.exists(".framework_scaffolded")) file.remove(".framework_scaffolded")
  if (file.exists(".framework_renv_enabled")) file.remove(".framework_renv_enabled")

  # Create minimal config with renv_nag: false
  writeLines("default:\n  options:\n    renv_nag: false", "config.yml")

  # Should NOT show message
  expect_invisible(.renv_nag())

  # Clean up
  file.remove("config.yml")
})

test_that(".renv_nag() suppressed when renv is enabled", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Clean up
  if (file.exists(".framework_scaffolded")) file.remove(".framework_scaffolded")

  # Enable renv
  writeLines("timestamp", ".framework_renv_enabled")

  # Create minimal config
  writeLines("default:\n  options:\n    renv_nag: true", "config.yml")

  # Should NOT show message when renv is enabled
  expect_invisible(.renv_nag())

  # Clean up
  file.remove(".framework_renv_enabled")
  file.remove("config.yml")
})

test_that("packages_snapshot() requires renv to be enabled", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_error(
    packages_snapshot(),
    "renv is not enabled"
  )
})

test_that("packages_restore() requires renv to be enabled", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_error(
    packages_restore(),
    "renv is not enabled"
  )
})

test_that("packages_status() requires renv to be enabled", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_error(
    packages_status(),
    "renv is not enabled"
  )
})

test_that("packages_update() requires renv to be enabled", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".framework_renv_enabled")) {
    file.remove(".framework_renv_enabled")
  }

  expect_error(
    packages_update(),
    "renv is not enabled"
  )
})

test_that(".update_gitignore_for_renv() creates .gitignore if missing", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  if (file.exists(".gitignore")) file.remove(".gitignore")

  .update_gitignore_for_renv()

  expect_true(file.exists(".gitignore"))
  content <- readLines(".gitignore")
  expect_true(any(grepl("^# renv$", content)))
  expect_true(any(grepl("renv/library/", content)))

  file.remove(".gitignore")
})

test_that(".update_gitignore_for_renv() appends to existing .gitignore", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Create existing .gitignore
  writeLines(c("*.Rproj", ".Rhistory"), ".gitignore")

  .update_gitignore_for_renv()

  content <- readLines(".gitignore")
  expect_true(any(grepl("^\\*\\.Rproj$", content)))
  expect_true(any(grepl("^# renv$", content)))
  expect_true(any(grepl("renv/library/", content)))

  file.remove(".gitignore")
})

test_that(".update_gitignore_for_renv() doesn't duplicate entries", {
  test_dir <- tempdir()
  orig_wd <- getwd()
  setwd(test_dir)
  on.exit(setwd(orig_wd))

  # Create .gitignore with renv entries already
  writeLines(c("*.Rproj", "# renv", "renv/library/"), ".gitignore")

  .update_gitignore_for_renv()

  content <- readLines(".gitignore")
  renv_headers <- sum(grepl("^# renv$", content))
  expect_equal(renv_headers, 1) # Should only have one header

  file.remove(".gitignore")
})
