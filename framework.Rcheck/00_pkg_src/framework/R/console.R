#' Capture console output and errors from an expression
#' @param expr Expression to evaluate
#' @return List containing status (boolean), console_output (character vector), and result (return value or error)
#' @export
capture_output <- function(expr) {
  # Initialize output vector
  output <- character()

  # Create a connection to capture output
  con <- textConnection("output", "w", local = TRUE)
  sink(con, type = "output")
  sink(con, type = "message")

  # Try to evaluate the expression
  result <- tryCatch(
    {
      eval(expr) # Return value will be the result
    },
    error = function(e) {
      e # Error will be the result
    }
  )

  # Restore output
  sink(type = "message")
  sink(type = "output")
  close(con)

  # Return status, console output, and result
  list(
    status = !inherits(result, "error"),
    console_output = output,
    result = result
  )
}
