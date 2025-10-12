#' @keywords internal
.onAttach <- function(libname, pkgname) {
  # Check if CLI is installed
  cli_installed <- Sys.which("framework") != ""

  if (!cli_installed) {
    packageStartupMessage(
      "Framework loaded! \U0001F389\n\n",
      "Tip: Install the CLI for quick project creation:\n",
      "  framework::install_cli()\n\n",
      "Then use: framework new myproject"
    )
  }
}
