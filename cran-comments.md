# CRAN Comments

## Resubmission

The GitHub repository moved from table1/framework to frameworktools/framework.
The URL and BugReports fields in DESCRIPTION now point to the new location.

## Update to 1.1.1

This is a patch release for a security bug in 1.1.0. Projects created with
`new_project()` and related helpers got no `.gitignore`, so the initial git
commit included the project's `.env` file, which holds database passwords.
Every project now gets a `.gitignore`, project creation checks that `.env` is
ignored before the first commit, and `git_security_audit()` gains a check for
tracked `.env` files. It also stops `new_project()` from opening the
optional GUI (which needs the suggested plumber package) when no user
settings exist; it now creates default settings instead. Two smaller fixes:
`scaffold()` now applies the project's random seed, and `data_add()` stores
project-relative paths.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

- Local: macOS 27.0.1, R 4.6.1 (`R CMD check --as-cran`)

## Downstream dependencies

There are no downstream dependencies.
