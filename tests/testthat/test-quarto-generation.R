test_that("project_create generates Quarto configs with render output dirs", {
  skip_on_cran()

  tmp <- withr::local_tempdir()
  project_dir <- file.path(tmp, "standard")

  directories <- list(
    notebooks = "notebooks",
    docs = "docs"
  )
  render_dirs <- list(
    notebooks = "outputs/notebooks",
    docs = "outputs/docs"
  )

  result <- project_create(
    name = "Standard Quarto",
    location = project_dir,
    type = "project",
    directories = directories,
    render_dirs = render_dirs,
    packages = list(use_renv = FALSE, default_packages = list()),
    author = list(name = "", email = "", affiliation = ""),
    ai = list(enabled = FALSE, assistants = list()),
    git = list(initialize = FALSE, hooks = list()),
    scaffold = list(seed_on_scaffold = FALSE, set_theme_on_scaffold = FALSE)
  )

  expect_true(result$success)

  # Root config exists
  expect_true(file.exists(file.path(project_dir, "_quarto.yml")))

  # Source _quarto.yml files exist with relative output-dir
  notebooks_yaml <- yaml::read_yaml(file.path(project_dir, "notebooks", "_quarto.yml"))
  docs_yaml <- yaml::read_yaml(file.path(project_dir, "docs", "_quarto.yml"))

  expect_equal(notebooks_yaml$project$`output-dir`, "../outputs/notebooks")
  expect_equal(notebooks_yaml$format$html$theme, "default")
  expect_equal(docs_yaml$project$`output-dir`, "../outputs/docs")
})

test_that("course project uses revealjs for slides render dir", {
  skip_on_cran()

  tmp <- withr::local_tempdir()
  project_dir <- file.path(tmp, "course")

  directories <- list(
    slides = "slides",
    assignments = "assignments"
  )
  render_dirs <- list(
    slides = "rendered/slides",
    assignments = "rendered/assignments"
  )

  result <- project_create(
    name = "Course Quarto",
    location = project_dir,
    type = "course",
    directories = directories,
    render_dirs = render_dirs,
    packages = list(use_renv = FALSE, default_packages = list()),
    author = list(name = "", email = "", affiliation = ""),
    ai = list(enabled = FALSE, assistants = list()),
    git = list(initialize = FALSE, hooks = list()),
    scaffold = list(seed_on_scaffold = FALSE, set_theme_on_scaffold = FALSE)
  )

  expect_true(result$success)

  slides_yaml <- yaml::read_yaml(file.path(project_dir, "slides", "_quarto.yml"))
  expect_equal(slides_yaml$project$`output-dir`, "../rendered/slides")
  expect_true(!is.null(slides_yaml$format$revealjs))
})
