#' Execute code within a database transaction
#'
#' Wraps code execution in a database transaction with automatic
#' commit on success and rollback on error. This ensures atomicity
#' of multiple database operations.
#'
#' @param conn Database connection
#' @param code Expression or code block to execute within the transaction
#'
#' @return The result of the code expression
#'
#' @details
#' The function automatically:
#' - Begins a transaction with `DBI::dbBegin()`
#' - Executes the provided code
#' - Commits the transaction on success with `DBI::dbCommit()`
#' - Rolls back the transaction on error with `DBI::dbRollback()`
#'
#' Transactions are essential for maintaining data integrity when performing
#' multiple related operations. If any operation fails, all changes are rolled back.
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#'
#' # Basic transaction
#' connection_transaction(conn, {
#'   connection_insert(conn, "users", list(name = "Alice", age = 30))
#'   connection_insert(conn, "users", list(name = "Bob", age = 25))
#' })
#'
#' # Transaction with return value
#' result <- connection_transaction(conn, {
#'   id <- connection_insert(conn, "users", list(name = "Charlie", age = 35))
#'   user <- connection_find(conn, "users", id)
#'   user
#' })
#'
#' # Transaction with error handling
#' tryCatch({
#'   connection_transaction(conn, {
#'     connection_insert(conn, "users", list(name = "Invalid"))
#'     stop("Something went wrong")  # This will trigger rollback
#'   })
#' }, error = function(e) {
#'   message("Transaction failed: ", e$message)
#' })
#'
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_transaction <- function(conn, code) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")

  # Check if already in a transaction
  in_transaction <- tryCatch({
    DBI::dbGetInfo(conn)$transaction
  }, error = function(e) {
    # Some drivers don't support transaction status check
    FALSE
  })

  if (isTRUE(in_transaction)) {
    # Already inside a transaction - reuse outer transaction context
    return(force(code))
  }

  started_transaction <- TRUE
  begin_error <- tryCatch({
    DBI::dbBegin(conn)
    NULL
  }, error = function(e) {
    if (grepl("cannot start a transaction", e$message, ignore.case = TRUE)) {
      started_transaction <<- FALSE
      return(NULL)
    }
    e
  })

  if (!is.null(begin_error)) {
    stop(sprintf("Failed to begin transaction: %s", begin_error$message))
  }

  if (!started_transaction) {
    return(force(code))
  }

  # Execute code with rollback on error
  tryCatch({
    # Force evaluation of code
    result <- force(code)

    # Commit transaction on success
    DBI::dbCommit(conn)

    result
  }, error = function(e) {
    # Rollback transaction on error
    tryCatch({
      DBI::dbRollback(conn)
    }, error = function(rollback_error) {
      warning(sprintf("Failed to rollback transaction: %s", rollback_error$message))
    })

    stop(sprintf("Transaction failed and was rolled back: %s", e$message), call. = FALSE)
  })
}

#' Execute code with transaction if not already in one
#'
#' Similar to `connection_transaction()`, but only starts a new transaction
#' if not already in one. Useful for functions that can be called both
#' standalone and within an existing transaction.
#'
#' @param conn Database connection
#' @param code Expression or code block to execute
#'
#' @return The result of the code expression
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#'
#' # If called standalone, this will create a transaction
#' connection_with_transaction(conn, {
#'   connection_insert(conn, "users", list(name = "Alice", age = 30))
#' })
#'
#' # If called within an existing transaction, it will use that
#' connection_transaction(conn, {
#'   connection_with_transaction(conn, {
#'     connection_insert(conn, "users", list(name = "Bob", age = 25))
#'   })
#' })
#'
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_with_transaction <- function(conn, code) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")

  # Check if already in a transaction
  in_transaction <- tryCatch({
    DBI::dbGetInfo(conn)$transaction
  }, error = function(e) {
    FALSE
  })

  if (isTRUE(in_transaction)) {
    # Already in transaction, just execute code
    force(code)
  } else {
    # Not in transaction, create one
    connection_transaction(conn, code)
  }
}

#' Begin a database transaction
#'
#' Manually begin a database transaction. You must call `connection_commit()`
#' to save changes or `connection_rollback()` to discard them.
#'
#' **Note:** Using `connection_transaction()` is preferred as it automatically
#' handles commit/rollback. Use this only when you need manual control.
#'
#' @param conn Database connection
#'
#' @return NULL (invisible)
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#'
#' connection_begin(conn)
#' tryCatch({
#'   connection_insert(conn, "users", list(name = "Alice", age = 30))
#'   connection_insert(conn, "users", list(name = "Bob", age = 25))
#'   connection_commit(conn)
#' }, error = function(e) {
#'   connection_rollback(conn)
#'   stop(e)
#' })
#'
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_begin <- function(conn) {
  checkmate::assert_class(conn, "DBIConnection")

  tryCatch({
    DBI::dbBegin(conn)
  }, error = function(e) {
    stop(sprintf("Failed to begin transaction: %s", e$message))
  })

  invisible(NULL)
}

#' Commit a database transaction
#'
#' Commits the current transaction, making all changes permanent.
#'
#' @param conn Database connection
#'
#' @return NULL (invisible)
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#' connection_begin(conn)
#' connection_insert(conn, "users", list(name = "Alice", age = 30))
#' connection_commit(conn)
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_commit <- function(conn) {
  checkmate::assert_class(conn, "DBIConnection")

  tryCatch({
    DBI::dbCommit(conn)
  }, error = function(e) {
    stop(sprintf("Failed to commit transaction: %s", e$message))
  })

  invisible(NULL)
}

#' Rollback a database transaction
#'
#' Rolls back the current transaction, discarding all changes.
#'
#' @param conn Database connection
#'
#' @return NULL (invisible)
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#' connection_begin(conn)
#' connection_insert(conn, "users", list(name = "Alice", age = 30))
#' connection_rollback(conn)  # Discard changes
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_rollback <- function(conn) {
  checkmate::assert_class(conn, "DBIConnection")

  tryCatch({
    DBI::dbRollback(conn)
  }, error = function(e) {
    stop(sprintf("Failed to rollback transaction: %s", e$message))
  })

  invisible(NULL)
}
