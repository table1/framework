test_that(".parse_assistant_selection parses user input correctly", {
  # Test "all" option
  expect_equal(
    .parse_assistant_selection("4"),
    c("claude", "copilot", "agents")
  )

  # Test individual selections
  expect_equal(
    .parse_assistant_selection("1"),
    "claude"
  )

  expect_equal(
    .parse_assistant_selection("2"),
    "copilot"
  )

  expect_equal(
    .parse_assistant_selection("3"),
    "agents"
  )

  # Test comma-separated
  expect_equal(
    .parse_assistant_selection("1,3"),
    c("claude", "agents")
  )

  expect_equal(
    .parse_assistant_selection("1,2,3"),
    c("claude", "copilot", "agents")
  )

  # Test with spaces
  expect_equal(
    .parse_assistant_selection("1, 3"),
    c("claude", "agents")
  )

  # Test invalid input
  expect_equal(
    .parse_assistant_selection("5"),
    character(0)
  )

  expect_equal(
    .parse_assistant_selection("invalid"),
    character(0)
  )

  # Test empty
  expect_equal(
    .parse_assistant_selection(""),
    character(0)
  )
})


test_that(".create_ai_instructions creates correct files", {
  skip_on_cran()

  # Create temp directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test-ai-instructions")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)

  # Ensure clean state
  unlink(file.path(test_dir, "CLAUDE.md"), force = TRUE)
  unlink(file.path(test_dir, ".github"), recursive = TRUE, force = TRUE)
  unlink(file.path(test_dir, "AGENTS.md"), force = TRUE)

  # Test Claude
  .create_ai_instructions("claude", test_dir)
  expect_true(file.exists(file.path(test_dir, "CLAUDE.md")))

  # Test Copilot (creates .github directory)
  .create_ai_instructions("copilot", test_dir)
  expect_true(dir.exists(file.path(test_dir, ".github")))
  expect_true(file.exists(file.path(test_dir, ".github", "copilot-instructions.md")))

  # Test AGENTS.md
  .create_ai_instructions("agents", test_dir)
  expect_true(file.exists(file.path(test_dir, "AGENTS.md")))

  # Test multiple assistants
  test_dir2 <- file.path(temp_dir, "test-ai-multiple")
  dir.create(test_dir2, showWarnings = FALSE, recursive = TRUE)

  .create_ai_instructions(c("claude", "copilot", "agents"), test_dir2)
  expect_true(file.exists(file.path(test_dir2, "CLAUDE.md")))
  expect_true(file.exists(file.path(test_dir2, ".github", "copilot-instructions.md")))
  expect_true(file.exists(file.path(test_dir2, "AGENTS.md")))

  # Cleanup
  unlink(test_dir, recursive = TRUE)
  unlink(test_dir2, recursive = TRUE)
})


test_that(".create_ai_instructions file content is correct", {
  skip_on_cran()

  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test-ai-content")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)

  # Create CLAUDE.md
  .create_ai_instructions("claude", test_dir)

  # Read and verify content
  claude_content <- readLines(file.path(test_dir, "CLAUDE.md"), warn = FALSE)

  # Check for key Framework concepts
  expect_true(any(grepl("Framework", claude_content)))
  expect_true(any(grepl("scaffold\\(\\)", claude_content)))
  expect_true(any(grepl("data_read", claude_content)))
  expect_true(any(grepl("result_save", claude_content)))

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})


test_that(".create_ai_instructions handles empty assistants list", {
  skip_on_cran()

  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test-ai-empty")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)

  # Should not create any files
  .create_ai_instructions(character(0), test_dir)

  expect_false(file.exists(file.path(test_dir, "CLAUDE.md")))
  expect_false(file.exists(file.path(test_dir, ".github")))
  expect_false(file.exists(file.path(test_dir, "AGENTS.md")))

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})


test_that(".update_frameworkrc updates file correctly", {
  skip_on_cran()

  temp_dir <- tempdir()
  test_rc <- file.path(temp_dir, "test-frameworkrc")

  # Create initial .frameworkrc with some content
  writeLines(c(
    "# Framework configuration",
    'FW_AUTHOR_NAME="Test User"',
    'FW_AUTHOR_EMAIL="test@example.com"'
  ), test_rc)

  # Update with AI settings
  .update_frameworkrc(test_rc, "yes", c("claude", "agents"))

  # Read and verify
  content <- readLines(test_rc, warn = FALSE)

  expect_true(any(grepl('FW_AI_SUPPORT="yes"', content, fixed = TRUE)))
  expect_true(any(grepl('FW_AI_ASSISTANTS="claude,agents"', content, fixed = TRUE)))

  # Original content should still be there
  expect_true(any(grepl('FW_AUTHOR_NAME="Test User"', content, fixed = TRUE)))

  # Update again (should replace, not duplicate)
  .update_frameworkrc(test_rc, "never", character(0))

  content2 <- readLines(test_rc, warn = FALSE)
  expect_true(any(grepl('FW_AI_SUPPORT="never"', content2, fixed = TRUE)))
  expect_false(any(grepl('FW_AI_ASSISTANTS=', content2)))

  # Should only have one FW_AI_SUPPORT line
  ai_support_lines <- grep("^FW_AI_SUPPORT=", content2)
  expect_length(ai_support_lines, 1)

  # Cleanup
  unlink(test_rc)
})


test_that(".update_frameworkrc creates new file if it doesn't exist", {
  skip_on_cran()

  temp_dir <- tempdir()
  test_rc <- file.path(temp_dir, "test-frameworkrc-new")

  # Ensure file doesn't exist
  if (file.exists(test_rc)) {
    unlink(test_rc)
  }

  # Update (should create new file)
  .update_frameworkrc(test_rc, "yes", c("claude"))

  expect_true(file.exists(test_rc))

  content <- readLines(test_rc, warn = FALSE)
  expect_true(any(grepl('FW_AI_SUPPORT="yes"', content, fixed = TRUE)))
  expect_true(any(grepl('FW_AI_ASSISTANTS="claude"', content, fixed = TRUE)))

  # Cleanup
  unlink(test_rc)
})


test_that("AI instruction templates exist", {
  # Verify AI context template files are in package
  project_template <- system.file("templates", "ai-context.project.md", package = "framework")
  sensitive_template <- system.file("templates", "ai-context.project_sensitive.md", package = "framework")
  course_template <- system.file("templates", "ai-context.course.md", package = "framework")
  presentation_template <- system.file("templates", "ai-context.presentation.md", package = "framework")

  expect_true(file.exists(project_template))
  expect_true(file.exists(sensitive_template))
  expect_true(file.exists(course_template))
  expect_true(file.exists(presentation_template))
})


test_that("AI instruction templates are not empty", {
  # Check project template
  project_template <- system.file("templates", "ai-context.project.md", package = "framework")
  if (file.exists(project_template)) {
    project_content <- readLines(project_template, warn = FALSE)
    expect_gt(length(project_content), 10)
  }

  # Check sensitive template
  sensitive_template <- system.file("templates", "ai-context.project_sensitive.md", package = "framework")
  if (file.exists(sensitive_template)) {
    sensitive_content <- readLines(sensitive_template, warn = FALSE)
    expect_gt(length(sensitive_content), 10)
  }

  # Check course template
  course_template <- system.file("templates", "ai-context.course.md", package = "framework")
  if (file.exists(course_template)) {
    course_content <- readLines(course_template, warn = FALSE)
    expect_gt(length(course_content), 10)
  }

  # Check presentation template
  presentation_template <- system.file("templates", "ai-context.presentation.md", package = "framework")
  if (file.exists(presentation_template)) {
    presentation_content <- readLines(presentation_template, warn = FALSE)
    expect_gt(length(presentation_content), 10)
  }
})
