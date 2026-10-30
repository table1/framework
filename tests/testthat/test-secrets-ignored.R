test_that("new_project() writes a .gitignore and never commits .env", {
  skip_if(!nzchar(Sys.which("git")), "git not installed")
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  parent <- withr::local_tempdir()
  location <- file.path(parent, "smoke")
  suppressMessages(new_project(name = "Smoke Study", location = location, type = "project", browse = FALSE))

  expect_true(file.exists(file.path(location, ".gitignore")))
  expect_true(file.exists(file.path(location, ".env")))
  tracked <- system2("git", c("-C", location, "ls-files"), stdout = TRUE)
  expect_false(".env" %in% tracked)
  expect_true(".gitignore" %in% tracked)
})

test_that("the safety net adds .env to a .gitignore that misses it", {
  dir <- withr::local_tempdir()
  writeLines("*.csv", file.path(dir, ".gitignore"))
  expect_true(suppressMessages(framework:::.ensure_secrets_ignored(dir)))
  expect_true(".env" %in% readLines(file.path(dir, ".gitignore")))
  expect_false(framework:::.ensure_secrets_ignored(dir))
})

test_that("git_security_audit() fails when .env is tracked", {
  skip_if(!nzchar(Sys.which("git")), "git not installed")
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  yaml::write_yaml(list(default = list(project_type = "project")), "settings.yml")
  writeLines("DB_PASS=secret", ".env")
  writeLines("DB_PASS=", ".env.example")
  system2("git", c("init", "-q"))
  system2("git", c("add", "-f", ".env", ".env.example", "settings.yml"))

  result <- suppressMessages(git_security_audit(check_git_history = FALSE, verbose = FALSE))
  row <- result$summary[result$summary$check == "secrets_exposure", ]
  expect_identical(row$status, "fail")
  expect_identical(result$findings$secrets_exposure$file, ".env")
})

test_that("a later !.env line cannot re-include .env", {
  dir <- withr::local_tempdir()
  writeLines(c(".env", "*.csv", "!.env"), file.path(dir, ".gitignore"))
  expect_true(suppressMessages(framework:::.ensure_secrets_ignored(dir)))
  expect_identical(utils::tail(readLines(file.path(dir, ".gitignore")), 1), ".env")

  skip_if(!nzchar(Sys.which("git")), "git not installed")
  writeLines("SECRET=1", file.path(dir, ".env"))
  system2("git", c("-C", dir, "init", "-q"))
  expect_true(framework:::.secrets_ignored_by_git(dir))
  writeLines(c(".env", "!.env"), file.path(dir, ".gitignore"))
  expect_false(framework:::.secrets_ignored_by_git(dir))
})

test_that("project creation does not commit .env when .gitignore content negates it", {
  skip_if(!nzchar(Sys.which("git")), "git not installed")
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  parent <- withr::local_tempdir()
  location <- file.path(parent, "negated")
  suppressMessages(project_create(
    name = "Negated", location = location, type = "project",
    git = list(use_git = TRUE, hooks = list(), gitignore_content = ".env\n!.env")
  ))
  tracked <- system2("git", c("-C", location, "ls-files"), stdout = TRUE)
  expect_false(".env" %in% tracked)
})
