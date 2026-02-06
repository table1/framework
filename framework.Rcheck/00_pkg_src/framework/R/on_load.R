# Package-internal environment for runtime state
# This avoids writing to .GlobalEnv which CRAN discourages
.framework_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname)
 {
  # Initialize internal state storage
  .framework_env$pools <- new.env(parent = emptyenv())
  .framework_env$initialized <- TRUE
}

.onAttach <- function(libname, pkgname) {
  # Silent load - framework is ready to use
  invisible()
}
