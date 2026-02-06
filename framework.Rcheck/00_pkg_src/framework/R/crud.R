#' Generate database-appropriate parameter placeholders
#'
#' @param conn Database connection
#' @param n Number of placeholders needed
#' @return Character vector of placeholders
#' @keywords internal
.get_placeholders <- function(conn, n) {
  if (inherits(conn, "PqConnection")) {
    # PostgreSQL uses $1, $2, $3, etc.
    paste0("$", seq_len(n))
  } else {
    # Most databases use ?
    rep("?", n)
  }
}

#' Find records by column values
#'
#' Finds records in a table matching specified column values.
#' Supports soft-delete patterns where records have a deleted_at column.
#'
#' @param conn Database connection
#' @param table_name Name of the table to query
#' @param ... Named arguments for column = value pairs (e.g., email = "test@example.com")
#' @param with_trashed Whether to include soft-deleted records (default: FALSE).
#'   Only applies if deleted_at column exists in the table.
#'
#' @return A data frame with matching records, or empty data frame if none found
#'
#' @keywords internal
connection_find_by <- function(conn, table_name, ..., with_trashed = FALSE) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert_flag(with_trashed)

  # Get column-value pairs
  conditions <- list(...)

  if (length(conditions) == 0) {
    stop("At least one column-value pair must be provided")
  }

  # Validate all conditions are named
  if (is.null(names(conditions)) || any(names(conditions) == "")) {
    stop("All conditions must be named (e.g., email = 'test@example.com')")
  }

  # Check if deleted_at column exists
  has_deleted_at <- .has_column(conn, table_name, "deleted_at")

  # Build WHERE clauses with appropriate placeholders
  placeholders <- .get_placeholders(conn, length(conditions))
  where_clauses <- sprintf("%s = %s",
                           sapply(names(conditions), function(x) DBI::dbQuoteIdentifier(conn, x)),
                           placeholders)

  if (!with_trashed && has_deleted_at) {
    where_clauses <- c(where_clauses, "deleted_at IS NULL")
  }

  # Build query
  query <- sprintf(
    "SELECT * FROM %s WHERE %s",
    DBI::dbQuoteIdentifier(conn, table_name),
    paste(where_clauses, collapse = " AND ")
  )

  # Execute query
  tryCatch(
    DBI::dbGetQuery(conn, query, params = unname(conditions)),
    error = function(e) {
      stop(sprintf("Failed to query table '%s': %s", table_name, e$message))
    }
  )
}

#' Insert a record into a table
#'
#' Inserts a new record into a table with automatic timestamp handling.
#' If the table has created_at/updated_at columns, they will be set automatically.
#'
#' @param conn Database connection
#' @param table_name Name of the table
#' @param values Named list of column-value pairs
#' @param auto_timestamps Whether to automatically set created_at/updated_at (default: TRUE)
#'
#' @return The ID of the inserted record (if auto-increment ID exists), or number of rows affected
#'
#' @keywords internal
connection_insert <- function(conn, table_name, values, auto_timestamps = TRUE) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert_list(values, min.len = 1)

  if (is.null(names(values)) || any(names(values) == "")) {
    stop("All values must be named (e.g., list(name = 'Alice', age = 30))")
  }

  # Auto-add timestamps if enabled and columns exist
  if (auto_timestamps) {
    if (.has_column(conn, table_name, "created_at") && !"created_at" %in% names(values)) {
      values$created_at <- Sys.time()
    }
    if (.has_column(conn, table_name, "updated_at") && !"updated_at" %in% names(values)) {
      values$updated_at <- Sys.time()
    }
  }

  # Use DBI::dbAppendTable for cross-database compatibility
  # This handles parameter placeholders correctly for each database
  tryCatch({
    # Convert to data frame for dbAppendTable
    df <- as.data.frame(values, stringsAsFactors = FALSE)

    result <- DBI::dbAppendTable(conn, table_name, df)

    # Try to get last inserted ID (database-specific)
    last_id <- tryCatch({
      if (inherits(conn, "SQLiteConnection")) {
        DBI::dbGetQuery(conn, "SELECT last_insert_rowid() as id")$id
      } else if (inherits(conn, "PqConnection")) {
        # PostgreSQL requires RETURNING clause, which we didn't use
        # Return rows affected instead
        result
      } else if (inherits(conn, "MariaDBConnection")) {
        DBI::dbGetQuery(conn, "SELECT LAST_INSERT_ID() as id")$id
      } else if (inherits(conn, "Microsoft SQL Server")) {
        DBI::dbGetQuery(conn, "SELECT @@IDENTITY as id")$id
      } else {
        result
      }
    }, error = function(e) {
      result
    })

    last_id
  }, error = function(e) {
    stop(sprintf("Failed to insert into table '%s': %s", table_name, e$message))
  })
}

#' Update a record in a table
#'
#' Updates an existing record in a table with automatic timestamp handling.
#' If the table has an updated_at column, it will be set automatically.
#'
#' @param conn Database connection
#' @param table_name Name of the table
#' @param id The ID of the record to update
#' @param values Named list of column-value pairs to update
#' @param auto_timestamps Whether to automatically set updated_at (default: TRUE)
#'
#' @return Number of rows affected
#'
#' @keywords internal
connection_update <- function(conn, table_name, id, values, auto_timestamps = TRUE) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert(
    checkmate::check_integerish(id, len = 1),
    checkmate::check_string(id)
  )
  checkmate::assert_list(values, min.len = 1)

  if (is.null(names(values)) || any(names(values) == "")) {
    stop("All values must be named (e.g., list(name = 'Alice', age = 30))")
  }

  # Auto-update timestamp if enabled and column exists
  if (auto_timestamps && .has_column(conn, table_name, "updated_at") && !"updated_at" %in% names(values)) {
    values$updated_at <- Sys.time()
  }

  # Build UPDATE query with appropriate placeholders
  placeholders <- .get_placeholders(conn, length(values) + 1)  # +1 for id
  set_placeholders <- placeholders[1:length(values)]
  id_placeholder <- placeholders[length(values) + 1]

  set_clauses <- sprintf("%s = %s",
                         sapply(names(values), function(x) DBI::dbQuoteIdentifier(conn, x)),
                         set_placeholders)

  query <- sprintf(
    "UPDATE %s SET %s WHERE id = %s",
    DBI::dbQuoteIdentifier(conn, table_name),
    paste(set_clauses, collapse = ", "),
    id_placeholder
  )

  # Execute update
  tryCatch(
    DBI::dbExecute(conn, query, params = c(unname(values), list(id))),
    error = function(e) {
      stop(sprintf("Failed to update table '%s': %s", table_name, e$message))
    }
  )
}

#' Delete a record from a table
#'
#' Deletes a record from a table. Supports soft-delete pattern where records
#' have a deleted_at column. Hard-delete can be forced with soft = FALSE.
#'
#' @param conn Database connection
#' @param table_name Name of the table
#' @param id The ID of the record to delete
#' @param soft Whether to use soft-delete if available (default: TRUE)
#'
#' @return Number of rows affected
#'
#' @keywords internal
connection_delete <- function(conn, table_name, id, soft = TRUE) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert(
    checkmate::check_integerish(id, len = 1),
    checkmate::check_string(id)
  )
  checkmate::assert_flag(soft)

  # Check if soft-delete is possible
  has_deleted_at <- .has_column(conn, table_name, "deleted_at")

  if (soft && has_deleted_at) {
    # Soft-delete: set deleted_at timestamp
    placeholders <- .get_placeholders(conn, 2)  # deleted_at and id
    query <- sprintf(
      "UPDATE %s SET deleted_at = %s WHERE id = %s",
      DBI::dbQuoteIdentifier(conn, table_name),
      placeholders[1],
      placeholders[2]
    )
    params <- list(Sys.time(), id)
  } else {
    # Hard-delete: permanently remove record
    placeholder <- .get_placeholders(conn, 1)  # just id
    query <- sprintf(
      "DELETE FROM %s WHERE id = %s",
      DBI::dbQuoteIdentifier(conn, table_name),
      placeholder
    )
    params <- list(id)
  }

  # Execute delete
  tryCatch(
    DBI::dbExecute(conn, query, params = params),
    error = function(e) {
      stop(sprintf("Failed to delete from table '%s': %s", table_name, e$message))
    }
  )
}

#' Restore a soft-deleted record
#'
#' Restores a soft-deleted record by setting deleted_at to NULL.
#' Only works on tables with a deleted_at column.
#'
#' @param conn Database connection
#' @param table_name Name of the table
#' @param id The ID of the record to restore
#'
#' @return Number of rows affected
#'
#' @keywords internal
connection_restore <- function(conn, table_name, id) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert(
    checkmate::check_integerish(id, len = 1),
    checkmate::check_string(id)
  )

  # Check if soft-delete column exists
  if (!.has_column(conn, table_name, "deleted_at")) {
    stop(sprintf("Table '%s' does not have a deleted_at column (soft-delete not supported)", table_name))
  }

  # Restore record
  placeholder <- .get_placeholders(conn, 1)  # just id
  query <- sprintf(
    "UPDATE %s SET deleted_at = NULL WHERE id = %s",
    DBI::dbQuoteIdentifier(conn, table_name),
    placeholder
  )

  tryCatch(
    DBI::dbExecute(conn, query, params = list(id)),
    error = function(e) {
      stop(sprintf("Failed to restore record in table '%s': %s", table_name, e$message))
    }
  )
}
