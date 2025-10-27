test_that(".install_cli_asset falls back to copy when forced", {
  tmp <- withr::local_tempdir()
  source_path <- file.path(tmp, "framework-shim")
  writeLines("#!/bin/sh\necho framework", source_path)
  Sys.chmod(source_path, "755")

  target_symlink <- file.path(tmp, "framework")
  result_symlink <- framework:::.install_cli_asset(source_path, target_symlink, "shim")
  expect_true(file.exists(target_symlink))
  expect_true(result_symlink$method %in% c("symlink", "copy"))

  Sys.setenv(FRAMEWORK_FORCE_COPY = "true")
  withr::defer(Sys.unsetenv("FRAMEWORK_FORCE_COPY"))

  target_copy <- file.path(tmp, "framework-copy")
  result_copy <- framework:::.install_cli_asset(source_path, target_copy, "shim")
  expect_true(file.exists(target_copy))
  expect_equal(result_copy$method, "copy")
})

test_that("cli_install user flow populates shim and global scripts", {
  skip_on_cran()

  tmp_home <- withr::local_tempdir()
  withr::local_envvar(HOME = tmp_home, FRAMEWORK_FORCE_COPY = "true")

  result <- framework::cli_install(use_installer = FALSE)

  bin_dir <- file.path(tmp_home, ".local", "bin")
  expect_true(dir.exists(bin_dir))
  expect_true(file.exists(file.path(bin_dir, "framework")))
  expect_true(file.exists(file.path(bin_dir, "framework-global")))
  expect_equal(result, file.path(bin_dir, "framework"))
})
