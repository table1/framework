local_git_project <- function(hooks = list(data_security = TRUE), env = parent.frame()) {
  skip_if(!nzchar(Sys.which("git")), "git not installed")
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(dir, .local_envir = env)
  system2("git", c("init", "-q"), stdout = FALSE, stderr = FALSE)
  yaml::write_yaml(list(default = list(
    project_type = "project_sensitive",
    directories = list(inputs_raw = "inputs/raw"),
    git = list(hooks = hooks)
  )), "settings.yml")
  dir
}

test_that("git_hooks_install writes the shared script and replaces Framework hooks only", {
  local_git_project()
  shared <- readLines(system.file("hooks", "pre-commit", package = "framework"))
  expect_true(any(grepl("Framework pre-commit hook", shared)))

  expect_true(git_hooks_install(verbose = FALSE))
  expect_identical(readLines(".git/hooks/pre-commit"), shared)

  # R 1.x hooks are replaced without force
  writeLines(c("#!/usr/bin/env bash", "# Framework Git Hooks", "exit 0"), ".git/hooks/pre-commit")
  expect_true(git_hooks_install(verbose = FALSE))
  expect_identical(readLines(".git/hooks/pre-commit"), shared)

  # Someone else's hook is kept unless forced
  writeLines(c("#!/bin/sh", "echo mine"), ".git/hooks/pre-commit")
  expect_false(git_hooks_install(verbose = FALSE))
  expect_identical(readLines(".git/hooks/pre-commit"), c("#!/bin/sh", "echo mine"))
  expect_false(git_hooks_uninstall(verbose = FALSE))
  expect_true(git_hooks_install(force = TRUE, verbose = FALSE))
  expect_true(git_hooks_uninstall(verbose = FALSE))
  expect_false(file.exists(".git/hooks/pre-commit"))
})

test_that("git_hooks_install follows core.hooksPath", {
  local_git_project()
  system2("git", c("config", "core.hooksPath", "githooks"), stdout = FALSE, stderr = FALSE)
  expect_true(git_hooks_install(verbose = FALSE))
  expect_true(file.exists("githooks/pre-commit"))
  expect_false(file.exists(".git/hooks/pre-commit"))
})

test_that(".hook_run passes outside a project and blocks tracked private data", {
  dir <- withr::local_tempdir()
  withr::with_dir(dir, expect_identical(.hook_run("pre-commit"), 0L))

  local_git_project()
  expect_identical(suppressMessages(.hook_run("pre-commit")), 0L)
  expect_identical(suppressMessages(.hook_run("post-commit")), 1L)

  dir.create("inputs/private", recursive = TRUE)
  write.csv(data.frame(id = 1:3), "inputs/private/ids.csv", row.names = FALSE)
  writeLines("inputs/private/", ".gitignore")
  system2("git", c("add", "-f", "inputs/private/ids.csv"), stdout = FALSE, stderr = FALSE)
  expect_message(status <- .hook_run("pre-commit"), "Data security check failed")
  expect_identical(status, 1L)
})

test_that("check_sensitive_dirs warns and continues without a terminal", {
  local_git_project(hooks = list(check_sensitive_dirs = TRUE))
  dir.create("outputs/private", recursive = TRUE)
  dir.create("notes/confidential", recursive = TRUE)
  writeLines("outputs/private/", ".gitignore")
  expect_identical(.hook_unignored_sensitive_dirs(), "notes/confidential")

  testthat::local_mocked_bindings(.hook_confirm = function(question) NA)
  expect_message(status <- .hook_run("pre-commit"), "Non-interactive mode")
  expect_identical(status, 0L)

  testthat::local_mocked_bindings(.hook_confirm = function(question) FALSE)
  expect_message(status <- .hook_run("pre-commit"), "Commit aborted")
  expect_identical(status, 1L)
})

test_that("the ai_sync hook is removed", {
  local_git_project(hooks = list(ai_sync = TRUE))
  # An old ai_sync: true alone installs nothing
  expect_false(git_hooks_install(verbose = FALSE))
  expect_false(file.exists(".git/hooks/pre-commit"))
  expect_identical(.hook_run("pre-commit"), 0L)
  expect_error(git_hooks_enable("ai_sync", verbose = FALSE), "removed in framework 2.0")
  expect_true(git_hooks_disable("ai_sync", verbose = FALSE))
  expect_false(yaml::read_yaml("settings.yml")$default$git$hooks$ai_sync)
  expect_false("ai_sync" %in% suppressMessages(git_hooks_list())$hook)
})

test_that("ai_sync_context() is deprecated", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  expect_warning(try(ai_sync_context(verbose = FALSE), silent = TRUE), "deprecated")
})
