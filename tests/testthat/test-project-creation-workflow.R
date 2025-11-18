# Integration tests for the full project creation workflow
# These tests verify that defaults from Framework Project Defaults (SettingsView)
# correctly flow through to newly created projects (NewProjectView)

test_that("New project inherits notebook_format default from global settings", {
  # Setup: temp directories
  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects")
  temp_project_dir <- file.path(temp_projects_root, "test-notebook-format")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Step 1: User sets defaults in Framework Project Defaults (SettingsView)
  # SettingsView saves notebook_format to defaults.notebook_format (top-level)
  framework::configure_global(settings = list(
    defaults = list(
      notebook_format = "rmarkdown",  # User chose RMarkdown instead of Quarto
      project_type = "project"
    )
  ), validate = FALSE)

  # Step 2: User creates new project via NewProjectView
  # NewProjectView loads defaults from GET /api/settings
  saved_settings <- framework::read_frameworkrc()

  # Simulate what NewProjectView does: load defaults and pass to project_create
  result <- framework::project_create(
    name = "Test Project",
    location = temp_project_dir,
    type = "project",
    author = list(name = "Test User", email = "test@example.com", affiliation = ""),
    scaffold = list(
      notebook_format = saved_settings$defaults$notebook_format,  # Should be "rmarkdown"
      seed_on_scaffold = FALSE,
      seed = "",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    packages = list(use_renv = FALSE, default_packages = list()),
    directories = list(),
    ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
    git = list(use_git = TRUE, hooks = list(), gitignore_content = "")
  )

  # Step 3: Verify created project has correct notebook_format in settings.yml
  expect_true(result$success)
  expect_true(dir.exists(temp_project_dir))

  # For split-file projects, scaffold settings are in settings/scaffold.yml
  scaffold_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "scaffold.yml"))
  expect_equal(scaffold_config$scaffold$notebook_format, "rmarkdown")
})


test_that("New project inherits positron setting from global settings", {
  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects-positron")
  temp_project_dir <- file.path(temp_projects_root, "test-positron")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # User enables Positron in Framework Project Defaults
  framework::configure_global(settings = list(
    defaults = list(
      positron = TRUE,  # User checked Positron checkbox
      project_type = "project"
    )
  ), validate = FALSE)

  saved_settings <- framework::read_frameworkrc()

  # Create project with positron setting from defaults
  result <- framework::project_create(
    name = "Test Positron Project",
    location = temp_project_dir,
    type = "project",
    author = list(name = "Test User", email = "test@example.com", affiliation = ""),
    scaffold = list(
      positron = saved_settings$defaults$positron,  # Should be TRUE
      notebook_format = "quarto",
      seed_on_scaffold = FALSE,
      seed = "",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    packages = list(use_renv = FALSE, default_packages = list()),
    directories = list(),
    ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
    git = list(use_git = TRUE, hooks = list(), gitignore_content = "")
  )

  expect_true(result$success)

  # For split-file projects, scaffold settings are in settings/scaffold.yml
  scaffold_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "scaffold.yml"))
  expect_equal(scaffold_config$scaffold$positron, TRUE)
})


test_that("New project inherits author information from global settings", {
  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects-author")
  temp_project_dir <- file.path(temp_projects_root, "test-author")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # User sets author info in Framework Project Defaults
  framework::configure_global(settings = list(
    author = list(
      name = "Jane Smith",
      email = "jane.smith@university.edu",
      affiliation = "University Research Lab"
    ),
    defaults = list(project_type = "project")
  ), validate = FALSE)

  saved_settings <- framework::read_frameworkrc()

  # Create project with author info from defaults
  result <- framework::project_create(
    name = "Test Author Project",
    location = temp_project_dir,
    type = "project",
    author = saved_settings$author,  # Load from global settings
    scaffold = list(
      notebook_format = "quarto",
      seed_on_scaffold = FALSE,
      seed = "",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    packages = list(use_renv = FALSE, default_packages = list()),
    directories = list(),
    ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
    git = list(use_git = TRUE, hooks = list(), gitignore_content = "")
  )

  expect_true(result$success)

  # For split-file projects, author is in settings/author.yml
  author_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "author.yml"))
  expect_equal(author_config$author$name, "Jane Smith")
  expect_equal(author_config$author$email, "jane.smith@university.edu")
  expect_equal(author_config$author$affiliation, "University Research Lab")
})


test_that("New project creation fails when required settings are missing", {
  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects-missing")
  temp_project_dir <- file.path(temp_projects_root, "test-missing")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Try to create project without required name parameter
  expect_error(
    framework::project_create(
      name = "",  # Empty name should fail validation
      location = temp_project_dir,
      type = "project"
    ),
    "Assertion on 'name' failed"
  )

  # Verify project directory was not created
  expect_false(dir.exists(temp_project_dir))
})


test_that("Full workflow: save defaults, create project, verify settings", {
  # This test simulates the complete user workflow:
  # 1. User opens Framework Project Defaults
  # 2. User sets notebook_format to "rmarkdown" and enables Positron
  # 3. User saves settings
  # 4. User creates new project
  # 5. Verify new project has correct settings

  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects-full-workflow")
  temp_project_dir <- file.path(temp_projects_root, "my-research-project")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
    config_dir <- file.path(temp_home, ".config", "framework")
    if (dir.exists(config_dir)) unlink(config_dir, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)

  # Step 1-3: User configures and saves Framework Project Defaults
  framework::configure_global(settings = list(
    author = list(
      name = "Research User",
      email = "research@institution.edu",
      affiliation = "Research Institution"
    ),
    defaults = list(
      project_type = "project",
      notebook_format = "rmarkdown",  # User prefers RMarkdown
      positron = TRUE,                # User uses Positron
      use_git = TRUE
    )
  ), validate = FALSE)

  # Step 4: User clicks "Create Project" in NewProjectView
  # NewProjectView loads global settings
  global_settings <- framework::read_frameworkrc()

  # NewProjectView calls project_create with defaults populated
  result <- framework::project_create(
    name = "My Research Project",
    location = temp_project_dir,
    type = global_settings$defaults$project_type,
    author = global_settings$author,
    scaffold = list(
      notebook_format = global_settings$defaults$notebook_format,
      positron = global_settings$defaults$positron,
      seed_on_scaffold = FALSE,
      seed = "",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    packages = list(use_renv = FALSE, default_packages = list()),
    directories = list(),
    ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
    git = list(
      use_git = global_settings$defaults$use_git,
      hooks = list(),
      gitignore_content = ""
    )
  )

  # Step 5: Verify project was created successfully with correct settings
  expect_true(result$success)
  expect_true(dir.exists(temp_project_dir))
  expect_true(file.exists(file.path(temp_project_dir, "settings.yml")))

  # For split-file projects, read from split files
  config <- yaml::read_yaml(file.path(temp_project_dir, "settings.yml"))
  scaffold_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "scaffold.yml"))
  author_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "author.yml"))

  # Verify all defaults were applied correctly
  expect_equal(scaffold_config$scaffold$notebook_format, "rmarkdown")
  expect_equal(scaffold_config$scaffold$positron, TRUE)
  expect_equal(author_config$author$name, "Research User")
  expect_equal(author_config$author$email, "research@institution.edu")
  expect_equal(author_config$author$affiliation, "Research Institution")
  expect_equal(config$default$project_type, "project")
})


test_that("Defaults work when global settings file doesn't exist", {
  # Verify graceful fallback to hardcoded defaults when no global config exists
  temp_home <- tempdir()
  temp_projects_root <- file.path(tempdir(), "test-projects-no-global")
  temp_project_dir <- file.path(temp_projects_root, "test-no-global")
  old_home <- Sys.getenv("HOME")

  on.exit({
    Sys.setenv(HOME = old_home)
    unlink(temp_projects_root, recursive = TRUE)
  })

  Sys.setenv(HOME = temp_home)
  # Don't create global config - simulate first-time user

  # Create project with explicit defaults (as NewProjectView would do)
  result <- framework::project_create(
    name = "Test No Global",
    location = temp_project_dir,
    type = "project",
    author = list(name = "", email = "", affiliation = ""),
    scaffold = list(
      notebook_format = "quarto",  # Framework default
      positron = FALSE,            # Framework default
      seed_on_scaffold = FALSE,
      seed = "",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    packages = list(use_renv = FALSE, default_packages = list()),
    directories = list(),
    ai = list(enabled = FALSE, assistants = c(), canonical_content = ""),
    git = list(use_git = TRUE, hooks = list(), gitignore_content = "")
  )

  expect_true(result$success)

  # For split-file projects, scaffold settings are in settings/scaffold.yml
  scaffold_config <- yaml::read_yaml(file.path(temp_project_dir, "settings", "scaffold.yml"))
  expect_equal(scaffold_config$scaffold$notebook_format, "quarto")  # Framework default
  expect_equal(scaffold_config$scaffold$positron, FALSE)            # Framework default
})
