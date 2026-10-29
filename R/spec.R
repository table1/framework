#' Resolve a Project Spec from Layers
#'
#' Merges spec layers into one complete project spec, the input to
#' `project_create()`. This is the only implementation of the merge: the
#' framework.pub cloud and the `fw` CLI send unmerged layers, and R resolves
#' them.
#'
#' The package defaults for the project type are always the bottom layer. The
#' given layers are applied on top, in order. The project type is taken from
#' the last layer that sets `type` (default `"project"`).
#'
#' Merge rules:
#' - Objects merge by key, and a later layer wins.
#' - A key set to `NULL` (JSON `null`) removes it.
#' - Entries of `files`, `skills`, `extra_directories`,
#'   `packages$default_packages`, `connections$databases`, and
#'   `connections$storage_buckets` are replaced whole, never merged field by
#'   field.
#' - `git$gitignore_content` is concatenated, with a comment naming the layer
#'   each block came from. The base gitignore template is chosen after merging,
#'   from the project type and `security$sensitive`.
#' - Empty lists are no-ops, so an empty JSON object and an empty JSON array
#'   mean the same thing.
#'
#' @param layers A list of layers, bottom to top. Each element is either a
#'   layer (a named list in spec shape) or a list with `kind`, `key`,
#'   `version`, and `layer`, as in `.framework/layers.json`.
#' @param name Project name. Overrides any `name` in the layers.
#' @param author Optional author list (`name`, `email`, `affiliation`).
#'   Overrides any `author` in the layers.
#' @param check If `TRUE` (default), stop when the resolved spec is invalid.
#'
#' @return The resolved spec as a named list. Attribute `"conflicts"` holds a
#'   data frame of keys set by more than one layer (`path`, `layers`).
#'
#' @examples
#' spec <- spec_resolve(
#'   list(list(security = list(sensitive = TRUE))),
#'   name = "My study"
#' )
#' spec$security$sensitive
#'
#' @seealso [project_create()]
#' @export
spec_resolve <- function(layers = list(), name, author = NULL, check = TRUE) {
  checkmate::assert_list(layers)
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_list(author, null.ok = TRUE)
  checkmate::assert_flag(check)

  entries <- .spec_normalize_layers(layers)

  type <- "project"
  for (entry in entries) {
    if (!is.null(entry$layer$type)) type <- entry$layer$type
  }
  checkmate::assert_choice(type, .spec_types())

  state <- list(
    spec = list(),
    gitignore = list(),
    setters = list()
  )
  all_entries <- c(list(list(label = "package defaults", layer = .spec_package_defaults(type))), entries)
  for (entry in all_entries) {
    state <- .spec_apply_layer(state, entry$layer, entry$label)
  }

  spec <- state$spec
  spec$type <- type
  spec$name <- name
  if (!is.null(author)) spec$author <- utils::modifyList(spec$author %||% list(), author)
  spec <- .spec_finalize(spec, state$gitignore)

  if (check) {
    problems <- spec_check(spec)
    if (length(problems) > 0) {
      stop(
        "The resolved project spec is invalid:\n",
        paste0("  - ", problems, collapse = "\n"),
        call. = FALSE
      )
    }
  }

  attr(spec, "conflicts") <- .spec_conflicts(state$setters)
  spec
}


#' Check a Resolved Project Spec
#'
#' Checks a resolved spec for the problems `project_create()` cannot recover
#' from: missing sections, unknown values, and paths that would write outside
#' the project. The JSON Schema in `inst/schema/spec.v1.json` describes the
#' same shape for other tools.
#'
#' @param spec A resolved spec, as returned by [spec_resolve()].
#' @return A character vector of problems, empty when the spec is valid.
#' @seealso [spec_resolve()]
#' @export
spec_check <- function(spec) {
  checkmate::assert_list(spec)
  problems <- character()
  add <- function(...) problems <<- c(problems, sprintf(...))

  required <- c(
    "spec_version", "name", "type", "author", "directories", "extra_directories",
    "render_dirs", "packages", "git", "ai", "scaffold", "connections",
    "security", "env", "data_hooks", "files", "skills"
  )
  for (key in setdiff(required, names(spec))) add("missing section '%s'", key)
  unknown <- setdiff(names(spec), c(required, "quarto", "source"))
  for (key in unknown) add("unknown section '%s'", key)

  if (!identical(as.integer(spec$spec_version), 1L)) {
    add("spec_version must be 1, got %s", format(spec$spec_version))
  }
  if (!is.null(spec$type) && !spec$type %in% .spec_types()) {
    add("unknown project type '%s'", spec$type)
  }

  for (path in .spec_map_paths) {
    value <- spec[[path]]
    if (length(value) > 0 && (!is.list(value) || is.null(names(value)) || any(!nzchar(names(value))))) {
      add("%s must be an object keyed by name, not a list", paste(path, collapse = "."))
    }
  }

  check_path <- function(path, where) {
    if (!.spec_is_safe_path(path)) add("%s: path '%s' must be relative and stay inside the project", where, path)
  }
  for (key in names(spec$directories)) check_path(spec$directories[[key]], paste0("directories.", key))
  for (key in names(spec$render_dirs)) check_path(spec$render_dirs[[key]], paste0("render_dirs.", key))
  for (key in names(spec$extra_directories)) {
    path <- spec$extra_directories[[key]]$path
    if (is.null(path)) add("extra_directories.%s: missing path", key) else check_path(path, paste0("extra_directories.", key))
  }
  for (path in names(spec$files)) {
    check_path(path, "files")
    if (!is.character(spec$files[[path]]$content)) add("files.%s: missing content", path)
  }

  for (pkg in names(spec$packages$default_packages)) {
    source <- spec$packages$default_packages[[pkg]]$source
    if (!isTRUE(source %in% c("cran", "github", "bioc"))) {
      add("packages.default_packages.%s: source must be cran, github, or bioc", pkg)
    }
  }

  unknown_assistants <- setdiff(names(spec$ai$assistants), names(.ai_assistant_table()))
  for (a in unknown_assistants) add("ai.assistants: unknown assistant '%s'", a)
  if (!isTRUE(spec$ai$agents_md %in% c("stub", "none"))) add("ai.agents_md must be 'stub' or 'none'")

  for (skill in names(spec$skills)) {
    entry <- spec$skills[[skill]]
    if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", skill)) add("skills: invalid skill name '%s'", skill)
    if (isTRUE(entry$package)) {
      if (!nzchar(system.file("templates", "skills", skill, "SKILL.md", package = "framework"))) {
        add("skills.%s: not shipped with this version of framework", skill)
      }
    } else if (is.character(entry$content)) {
      declared <- .spec_skill_name(entry$content)
      if (!identical(declared, skill)) {
        add("skills.%s: SKILL.md frontmatter name is '%s'", skill, declared %||% "missing")
      }
      for (path in names(entry$files)) check_path(path, paste0("skills.", skill, ".files"))
    } else {
      add("skills.%s: needs either package: true or content", skill)
    }
  }

  for (var in names(spec$env)) {
    if (!grepl("^[A-Za-z_][A-Za-z0-9_]*$", var)) add("env: invalid variable name '%s'", var)
  }
  for (key in names(spec$data_hooks)) {
    if (!grepl("^[^:]+\\.R::[A-Za-z.][A-Za-z0-9._]*$", spec$data_hooks[[key]])) {
      add("data_hooks.%s: expected 'path/to/file.R::function'", key)
    }
  }

  problems
}


# Internals -------------------------------------------------------------------

.spec_types <- function() c("project", "project_sensitive", "course", "presentation", "bare")

# Entries whose values are replaced whole when a later layer sets them.
.spec_atomic_maps <- c(
  "files", "skills", "extra_directories", "packages/default_packages",
  "connections/databases", "connections/storage_buckets"
)

.spec_normalize_layers <- function(layers) {
  lapply(seq_along(layers), function(i) {
    entry <- layers[[i]]
    is_envelope_entry <- is.list(entry) && "layer" %in% names(entry) &&
      all(names(entry) %in% c("kind", "key", "version", "layer"))
    if (is_envelope_entry) {
      label <- paste(c(entry$kind %||% paste("layer", i), entry$key, if (!is.null(entry$version)) paste0("v", entry$version)), collapse = " ")
      list(label = label, layer = entry$layer %||% list())
    } else {
      list(label = paste("layer", i), layer = entry %||% list())
    }
  })
}

.spec_apply_layer <- function(state, layer, label) {
  for (path in .spec_map_paths) {
    value <- tryCatch(layer[[path]], error = function(e) NULL)
    if (is.list(value) && length(value) > 0 && is.null(names(value))) {
      stop(sprintf(
        "Layer '%s': %s must be an object keyed by name, not a list",
        label, paste(path, collapse = ".")
      ), call. = FALSE)
    }
  }

  gitignore <- layer$git$gitignore_content
  if (!is.null(gitignore) && nzchar(paste(gitignore, collapse = ""))) {
    state$gitignore[[length(state$gitignore) + 1]] <- list(label = label, text = paste(gitignore, collapse = "\n"))
  }
  if (!is.null(layer$git)) layer$git$gitignore_content <- NULL

  merged <- .spec_merge(state$spec, layer, path = character(), label = label, setters = state$setters)
  state$spec <- merged$value
  state$setters <- merged$setters
  state
}

# Recursively merge `layer` into `base`. Returns list(value, setters), where
# setters records which layer set each leaf and to what (for conflicts).
.spec_merge <- function(base, layer, path, label, setters) {
  base <- base %||% list()
  for (key in names(layer)) {
    key_path <- c(path, key)
    path_str <- paste(key_path, collapse = "/")
    value <- layer[[key]]

    if (is.null(value)) {
      base[[key]] <- NULL
      setters[[path_str]] <- c(setters[[path_str]], list(list(label = label, value = "<removed>")))
      next
    }

    parent_str <- paste(path, collapse = "/")
    atomic_entry <- parent_str %in% .spec_atomic_maps
    is_object <- is.list(value) && !is.null(names(value))

    if (!atomic_entry && is_object && (is.null(base[[key]]) || is.list(base[[key]]))) {
      merged <- .spec_merge(base[[key]], value, key_path, label, setters)
      base[[key]] <- merged$value
      setters <- merged$setters
    } else if (is.list(value) && length(value) == 0) {
      # Empty object or array: no-op, but make sure the section exists.
      if (is.null(base[[key]])) base[key] <- list(list())
    } else {
      base[[key]] <- value
      setters[[path_str]] <- c(setters[[path_str]], list(list(label = label, value = value)))
    }
  }
  list(value = base, setters = setters)
}

.spec_conflicts <- function(setters) {
  # A conflict is a key set to different values by more than one layer.
  # Package defaults are the baseline and never count.
  conflicting <- Filter(function(entries) {
    entries <- Filter(function(e) !identical(e$label, "package defaults"), entries)
    length(unique(vapply(entries, `[[`, "", "label"))) > 1 &&
      length(unique(lapply(entries, `[[`, "value"))) > 1
  }, setters)
  layers <- vapply(conflicting, function(entries) {
    labels <- vapply(entries, `[[`, "", "label")
    paste(unique(setdiff(labels, "package defaults")), collapse = ", ")
  }, character(1))
  data.frame(
    path = names(conflicting),
    layers = unname(layers),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

.spec_finalize <- function(spec, gitignore_blocks) {
  spec$spec_version <- 1L
  spec$security$sensitive <- isTRUE(spec$security$sensitive)
  if (spec$security$sensitive && !identical(spec$type, "bare") && is.null(spec$skills[["framework-sensitive-data"]])) {
    spec$skills[["framework-sensitive-data"]] <- list(package = TRUE)
  }

  # Assistants: keep only those set to TRUE
  assistants <- spec$ai$assistants %||% list()
  spec$ai$assistants <- assistants[vapply(assistants, isTRUE, logical(1))]
  spec$ai$agents_md <- spec$ai$agents_md %||% "stub"

  spec$git$gitignore_content <- .spec_gitignore(spec$type, spec$security$sensitive, gitignore_blocks)
  spec <- .spec_mark_maps(spec)

  order <- c(
    "spec_version", "name", "type", "author", "directories", "extra_directories",
    "render_dirs", "packages", "git", "ai", "scaffold", "quarto", "connections",
    "security", "env", "data_hooks", "files", "skills", "source"
  )
  spec[c(intersect(order, names(spec)), setdiff(names(spec), order))]
}

# Paths whose values are JSON objects. R cannot tell an empty object from an
# empty array, so empty maps are given names to serialize as {}.
.spec_map_paths <- list(
  "directories", "extra_directories", "render_dirs", "env", "data_hooks",
  "files", "skills", c("packages", "default_packages"), c("git", "hooks"),
  c("ai", "assistants"), c("connections", "databases"),
  c("connections", "storage_buckets")
)

.spec_mark_maps <- function(spec) {
  for (path in .spec_map_paths) {
    value <- spec[[path]]
    if (is.null(value) || length(value) == 0) spec[[path]] <- stats::setNames(list(), character())
  }
  spec
}

.spec_gitignore <- function(type, sensitive, blocks) {
  template <- if (isTRUE(sensitive)) {
    "gitignore-sensitive"
  } else {
    switch(type,
      course = "gitignore-course",
      presentation = "gitignore-presentation",
      project_sensitive = "gitignore-sensitive",
      "gitignore-project"
    )
  }
  path <- system.file("templates", template, package = "framework")
  base <- if (nzchar(path)) paste(readLines(path, warn = FALSE), collapse = "\n") else ""
  extra <- vapply(blocks, function(b) sprintf("\n# --- from %s ---\n%s", b$label, b$text), character(1))
  paste(c(base, extra), collapse = "\n")
}

.spec_is_safe_path <- function(path) {
  is.character(path) && length(path) == 1 && nzchar(path) &&
    !grepl("^(/|[A-Za-z]:|~)", path) &&
    !grepl("\\\\", path) &&
    !any(strsplit(path, "/", fixed = TRUE)[[1]] == "..")
}

.spec_skill_name <- function(content) {
  lines <- strsplit(content, "\r?\n")[[1]]
  if (length(lines) == 0 || !identical(trimws(lines[1]), "---")) return(NULL)
  end <- which(trimws(lines[-1]) == "---")[1]
  if (is.na(end)) return(NULL)
  front <- tryCatch(yaml::yaml.load(paste(lines[2:end], collapse = "\n")), error = function(e) NULL)
  front$name
}

# The package defaults layer for a project type, built from
# inst/settings/global-settings-default.yml (never the user's own settings,
# which arrive as their own layer).
.spec_package_defaults <- function(type) {
  path <- system.file("settings", "global-settings-default.yml", package = "framework")
  config <- tryCatch(yaml::read_yaml(path), error = function(e) {
    stop(sprintf("Failed to read package defaults '%s': %s", path, conditionMessage(e)), call. = FALSE)
  })
  defaults <- config$defaults %||% list()
  type_config <- config$project_types[[type]] %||% list()

  packages <- list()
  for (pkg in defaults$packages$default_packages %||% list()) {
    packages[[pkg$name]] <- list(source = pkg$source %||% "cran", auto_attach = isTRUE(pkg$auto_attach))
  }

  assistants <- list()
  for (a in defaults$ai$assistants %||% list()) assistants[[a]] <- TRUE

  skills <- list()
  if (!identical(type, "bare")) {
    for (s in .ai_skills_for_type(type)) skills[[s]] <- list(package = TRUE)
  }

  list(
    author = list(name = "", email = "", affiliation = ""),
    directories = if (identical(type, "bare")) list() else type_config$directories %||% list(),
    extra_directories = list(),
    render_dirs = .default_render_dirs_for_type(type),
    packages = list(use_renv = isTRUE(defaults$packages$use_renv), default_packages = packages),
    git = list(use_git = defaults$git$initialize %||% TRUE, hooks = defaults$git$hooks %||% list()),
    ai = list(enabled = isTRUE(defaults$ai$enabled), assistants = assistants, agents_md = "stub"),
    scaffold = utils::modifyList(defaults$scaffold %||% list(), type_config$scaffold %||% list()),
    quarto = .spec_quarto_defaults(defaults$quarto, type),
    connections = .spec_connections_from_settings(defaults$connections),
    security = list(sensitive = identical(type, "project_sensitive")),
    env = .spec_env_from_raw(defaults$env$raw),
    data_hooks = list(),
    files = list(),
    skills = skills
  )
}

.spec_quarto_defaults <- function(quarto, type) {
  quarto <- quarto %||% list()
  root <- .default_root_render_dir_for_type(type)
  if (!is.null(root)) quarto$render_dir <- root
  quarto
}

# Convert the settings-file connection shape to the spec shape.
.spec_connections_from_settings <- function(connections) {
  connections <- connections %||% list()
  if (!is.null(connections$databases) || !is.null(connections$storage_buckets)) {
    return(connections)
  }
  list(
    default_database = connections$options$default_connection,
    default_storage_bucket = NULL,
    databases = connections$connections %||% list(),
    storage_buckets = list()
  )
}

.spec_env_from_raw <- function(raw) {
  if (is.null(raw) || !nzchar(raw)) return(list())
  lines <- trimws(strsplit(raw, "\r?\n")[[1]])
  lines <- lines[nzchar(lines) & !startsWith(lines, "#") & grepl("=", lines, fixed = TRUE)]
  env <- list()
  for (line in lines) {
    eq <- regexpr("=", line, fixed = TRUE)
    env[[substr(line, 1, eq - 1)]] <- substr(line, eq + 1, nchar(line))
  }
  env
}
