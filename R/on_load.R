.onLoad <- function(libname, pkgname) {
  # Create package environment if it doesn't exist
  if (!exists(".framework", envir = .GlobalEnv)) {
    assign(".framework", new.env(), envir = .GlobalEnv)
  }
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Framework loaded.")
}
