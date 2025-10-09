# CLAUDE.md - Development Standards

This document defines coding standards and conventions for AI assistants working on the Framework package.

## Documentation Organization

### Directory Structure
```
docs/
├── CLAUDE.md           # This file - development standards
├── debug/              # Bug reports, fix logs, debugging sessions
├── architecture/       # Design documents, architecture decisions
└── api/                # API documentation and guides
```

### File Naming
- Use `UPPERCASE.md` for important meta-documents (CLAUDE.md, README.md)
- Use `lowercase_with_underscores.md` for regular documentation
- Use descriptive names that indicate content (e.g., `BUG_FIXES.md`, `SECURITY_AUDIT.md`)

## Package Conventions

### Configuration Files

Framework follows the conventions of the `config` package by Posit:

- Configuration files use environment sections (e.g., "default", "production", "development")
- The `config::get()` function handles reading these environment-aware configs
- `write_config()` automatically wraps configurations in a "default" section to maintain compatibility
- `read_config()` uses `config::get()` to handle environment sections and `!expr` evaluation
- When reading with `yaml::read_yaml()` directly, you'll see the raw structure including environment wrappers
- When reading with `read_config()`, the environment section is automatically resolved

**Example:**
```r
# Writing a config
config <- list(
  data = list(example = "data/example.csv"),
  packages = c("dplyr", "ggplot2")
)
write_config(config, "config.yml")

# File structure (with auto-wrapped "default" section):
# default:
#   data:
#     example: data/example.csv
#   packages:
#     - dplyr
#     - ggplot2

# Reading with read_config() (environment section resolved):
cfg <- read_config("config.yml")
cfg$data$example  # "data/example.csv"

# Reading with yaml::read_yaml() (raw structure with default wrapper):
raw <- yaml::read_yaml("config.yml")
raw$default$data$example  # "data/example.csv"
```

## Code Quality Standards

### Defensive Programming Principles

**Every exported function MUST follow these defensive programming practices:**

1. **Validate ALL arguments at function entry** using `checkmate`
2. **Wrap all external operations in try/catch** (database, file I/O, network, external packages)
3. **Clean up resources** using `on.exit()` with `add = TRUE`
4. **Provide contextual error messages** that help users fix the problem
5. **Fail fast** - check preconditions before doing work

**Why This Matters:**
- **User experience:** Clear, actionable error messages instead of cryptic failures
- **Security:** Prevents injection attacks and validates untrusted input
- **Reliability:** Catches errors early before corrupting state
- **Debugging:** Errors include context about what failed and why
- **Resource safety:** Database connections, file handles always cleaned up

### Error Handling

**ALWAYS use try/catch blocks** for:
- Database operations
- File I/O operations
- External package calls
- Network requests
- Any operation that might fail

**Good Example:**
```r
data <- tryCatch(
  readLines(file_path),
  error = function(e) {
    stop(sprintf("Failed to read file '%s': %s", file_path, e$message))
  }
)
```

**Bad Example:**
```r
data <- readLines(file_path)  # No error handling!
```

### Argument Validation

**CRITICAL: ALWAYS use the `checkmate` package for argument validation.**

The codebase uses `checkmate` for all type-checking and argument validation. This provides:
- Consistent, clear error messages
- Better performance (compiled C code)
- Comprehensive edge case handling (NA, NULL, empty, etc.)
- Reduced code verbosity

#### **Standard Validation Patterns**

**String Arguments:**
```r
# Non-empty string
checkmate::assert_string(name, min.chars = 1)

# Optional string
checkmate::assert_string(path, null.ok = TRUE)

# String from choices
checkmate::assert_choice(format, c("csv", "tsv", "rds"))
```

**Numeric Arguments:**
```r
# Positive number
checkmate::assert_number(count, lower = 1)

# Optional number with bounds
checkmate::assert_number(expire_after, lower = 0, null.ok = TRUE)

# Integer
checkmate::assert_int(id, lower = 1)

# Count (non-negative integer)
checkmate::assert_count(n)
```

**Logical Arguments:**
```r
# Single TRUE/FALSE value (flag)
checkmate::assert_flag(recursive)

# Logical vector
checkmate::assert_logical(mask, any.missing = FALSE)
```

**Complex Types:**
```r
# List
checkmate::assert_list(config, min.len = 1)

# Data frame
checkmate::assert_data_frame(data, min.rows = 1)

# Class/inheritance
checkmate::assert_class(conn, "DBIConnection")

# File/directory
checkmate::assert_file_exists(file_path)
checkmate::assert_directory_exists(dir_path)
```

**Multiple Valid Types (Compound Assertions):**
```r
# Either a flag OR a function
checkmate::assert(
  checkmate::check_flag(refresh),
  checkmate::check_function(refresh)
)

# Either integer or string ID
checkmate::assert(
  checkmate::check_integerish(id, len = 1),
  checkmate::check_string(id)
)
```

#### **Complete Function Example**

```r
#' Example function showing checkmate usage
#' @param name Result name (non-empty string)
#' @param value Result value (any R object)
#' @param type Result type from allowed choices
#' @param public Whether result is public (flag)
#' @param expire_after Optional expiration in hours (positive number or NULL)
#' @export
my_function <- function(name, value, type, public = FALSE, expire_after = NULL) {
  # Validate all arguments upfront
  checkmate::assert_string(name, min.chars = 1)
  # value can be any type, no validation needed
  checkmate::assert_choice(type, c("model", "analysis", "report"))
  checkmate::assert_flag(public)
  checkmate::assert_number(expire_after, lower = 0, null.ok = TRUE)

  # Function logic here...
}
```

### Error Messages

Error messages should be:
1. **Specific** - Include the problematic value/file/operation
2. **Actionable** - Tell user what went wrong and how to fix it
3. **Consistent** - Use sprintf() for formatting

**Good Examples:**
```r
stop(sprintf("File not found: %s", file_path))
stop(sprintf("Argument 'type' must be 'csv' or 'rds', got: %s", type))
stop(sprintf("Failed to connect to database '%s': %s", db_name, e$message))
```

**Bad Examples:**
```r
stop("Error")
stop("Something went wrong")
stop("Invalid argument")
```

### Resource Management

**ALWAYS clean up resources** using `on.exit()`:

```r
my_function <- function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), "database.db")
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  temp_file <- tempfile()
  on.exit(unlink(temp_file), add = TRUE)

  # Function logic...
  # Resources will be cleaned up even if function errors
}
```

### Complete Function Template

**Use this template for ALL exported functions:**

```r
#' Brief description of what function does
#'
#' Longer description explaining behavior, edge cases, and usage.
#'
#' @param name Non-empty string identifying the resource
#' @param value Any R object to process
#' @param type Type from allowed choices
#' @param public Flag indicating public visibility (default: FALSE)
#' @param path Optional path to file (default: NULL)
#'
#' @return Description of return value
#'
#' @examples
#' \dontrun{
#' result <- my_function("example", data.frame(x = 1:5), type = "analysis")
#' }
#'
#' @export
my_function <- function(name, value, type, public = FALSE, path = NULL) {
  # 1. VALIDATE ALL ARGUMENTS (using checkmate)
  checkmate::assert_string(name, min.chars = 1)
  # value can be any type - no validation needed
  checkmate::assert_choice(type, c("model", "analysis", "report"))
  checkmate::assert_flag(public)
  checkmate::assert_file_exists(path, null.ok = TRUE)

  # 2. ACQUIRE RESOURCES (with error handling and cleanup)
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      stop(sprintf("Failed to connect to database: %s", e$message))
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # 3. PERFORM OPERATIONS (wrap in try/catch with context)
  result <- tryCatch(
    DBI::dbGetQuery(con, "SELECT * FROM table WHERE name = ?", list(name)),
    error = function(e) {
      stop(sprintf("Failed to query table for '%s': %s", name, e$message))
    }
  )

  # 4. VALIDATE RESULTS (check postconditions)
  if (nrow(result) == 0) {
    stop(sprintf("No results found for name '%s'", name))
  }

  # 5. RETURN VALUE
  return(result)
}
```

### Database Operations Template

```r
#' Database operation with full defensive programming
#' @param id Record identifier (integer or string)
#' @param conn Database connection
#' @export
db_operation <- function(id, conn) {
  # 1. Validate arguments
  checkmate::assert(
    checkmate::check_integerish(id, len = 1),
    checkmate::check_string(id)
  )
  checkmate::assert_class(conn, "DBIConnection")

  # 2. Execute with error handling
  result <- tryCatch(
    DBI::dbGetQuery(conn, "SELECT * FROM table WHERE id = ?", list(id)),
    error = function(e) {
      stop(sprintf("Database query failed for ID '%s': %s", id, e$message))
    }
  )

  # 3. Validate results
  if (nrow(result) == 0) {
    stop(sprintf("Record not found: %s", id))
  }

  return(result)
}
```

## Testing Standards

### Test Organization

- One test file per source file: `test-[module].R`
- Group related tests using `test_that()`
- Use descriptive test names that explain what is being tested

### Test Structure

```r
test_that("function_name does what it should", {
  # 1. Setup
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # 2. Execute
  result <- my_function("test_input")

  # 3. Assert
  expect_equal(result$value, expected_value)
  expect_true(file.exists("expected_file.txt"))
})
```

### Test Helpers

Use `tests/testthat/helper.R` for shared test utilities:
- Project creation functions
- Cleanup functions
- Assertion helpers
- Mock data generators

## Documentation Standards

### Roxygen2 Comments

**Required for all exported functions:**

```r
#' Brief description of what function does
#'
#' Longer description explaining behavior, edge cases, and usage.
#' Can span multiple lines.
#'
#' @param arg1 Description of first argument
#' @param arg2 Description of second argument (default: "value")
#' @param ... Additional arguments passed to underlying function
#'
#' @return Description of return value
#'
#' @examples
#' \dontrun{
#' result <- my_function("input", arg2 = "custom")
#' }
#'
#' @export
my_function <- function(arg1, arg2 = "default", ...) {
  # Implementation
}
```

**For internal functions:**

```r
#' Brief description
#' @keywords internal
.internal_function <- function() {
  # Implementation
}
```

## Git Commit Standards

### Commit Messages

Format:
```
<type>: <short description>

<optional longer description>
<optional context about why this change was needed>
```

Types:
- `fix:` - Bug fixes
- `feat:` - New features
- `refactor:` - Code restructuring without behavior change
- `test:` - Adding or updating tests
- `docs:` - Documentation changes
- `style:` - Code formatting, no logic change
- `perf:` - Performance improvements
- `chore:` - Build process, dependencies, etc.

**Example:**
```
fix: .set_data() now stores complete metadata in database

The function was only storing name, encrypted, and hash fields,
but the database schema includes path, type, delimiter, and locked.
Updated SQL statements and all callers to pass complete metadata.

Fixes #42
```

## Code Review Checklist

Before submitting code, verify:

### Defensive Programming
- [ ] **ALL arguments validated** using `checkmate::assert_*()` functions
- [ ] **ALL external operations wrapped** in try/catch (database, file I/O, network, external packages)
- [ ] **Resources cleaned up** with `on.exit(..., add = TRUE)`
- [ ] **Error messages are contextual** with sprintf() including what failed and why
- [ ] **Preconditions checked** before doing work (fail fast)

### Type Checking (checkmate)
- [ ] String arguments use `checkmate::assert_string()`
- [ ] Numeric arguments use `checkmate::assert_number()` or `checkmate::assert_int()`
- [ ] Logical flags use `checkmate::assert_flag()`
- [ ] Optional arguments use `null.ok = TRUE`
- [ ] Choices validated with `checkmate::assert_choice()`
- [ ] Files validated with `checkmate::assert_file_exists()`
- [ ] Complex types validated with `checkmate::assert_class()`, `checkmate::assert_list()`, etc.

### Error Handling
- [ ] Database operations have try/catch with "Failed to ..." context
- [ ] File operations have try/catch with file path in error message
- [ ] Network operations have try/catch with descriptive errors
- [ ] All errors use `sprintf()` for formatting with relevant context

### Documentation & Testing
- [ ] Functions have roxygen2 documentation with `@param` and `@return`
- [ ] Tests added for new functionality
- [ ] Tests added for bug fixes
- [ ] Edge cases tested (NULL, NA, empty, invalid types)

### Code Quality
- [ ] No commented-out code
- [ ] No debug print statements
- [ ] No manual validation (use checkmate instead)
- [ ] Consistent error message format

## Future Considerations

### Planned Improvements

1. **Add error code system**
   - Unique codes for each error type
   - Easier debugging and documentation
   - Machine-readable error handling

2. **Add schema migration system**
   - Handle database schema changes gracefully
   - Version tracking in database
   - Automatic migration on package load

3. **Refactor existing validation to checkmate**
   - Phase 1: Add checkmate to new functions only
   - Phase 2: High-priority exported functions (data_load, query_get, etc.)
   - Phase 3: Replace manual validation in existing functions
   - Phase 4: Internal functions

## References

- [R Packages Book](https://r-pkgs.org/) - Hadley Wickham & Jenny Bryan
- [Advanced R](https://adv-r.hadley.nz/) - Hadley Wickham
- [R Package Primer](https://kbroman.org/pkg_primer/) - Karl Broman
- [checkmate Package](https://mllg.github.io/checkmate/) - Fast and Versatile Argument Checks
