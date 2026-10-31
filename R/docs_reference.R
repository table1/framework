# Writes docs/site/reference.json for the r.framework.pub docs site from the
# docs.db that docs_export() builds, so both come from the same Rd parse. The
# format is inst/schema/docs-reference.v1.json, shared with framework-py and
# fw; inst/schema/docs-site.md describes the site around it.

#' @keywords internal
.docs_write_reference <- function(db_path, path, version) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  reference <- .docs_reference(con, version)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  json <- jsonlite::toJSON(reference, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json, path, useBytes = TRUE)
  invisible(path)
}

#' @keywords internal
.docs_reference <- function(con, version) {
  q <- function(sql) DBI::dbGetQuery(con, sql)
  functions <- q("SELECT * FROM functions ORDER BY name")
  categories <- q("SELECT * FROM categories ORDER BY position")
  parameters <- q("SELECT * FROM parameters ORDER BY function_id, position")
  examples <- q("SELECT * FROM examples ORDER BY function_id, position")
  seealso <- q("SELECT * FROM seealso ORDER BY function_id, id")
  sections <- q("SELECT * FROM sections ORDER BY function_id, position")
  subsections <- q("SELECT * FROM subsections ORDER BY function_id, position")
  aliases <- q("SELECT * FROM aliases ORDER BY function_id, alias")

  # Reference ids must be URL-safe; R's exported helpers named .x are
  # internal and have no page
  id_ok <- grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", functions$name)
  functions <- functions[id_ok, , drop = FALSE]

  # Aliases point at their main entry, for links and see also
  target <- stats::setNames(functions$name, functions$name)
  alias_rows <- aliases[aliases$function_id %in% functions$id, , drop = FALSE]
  target[alias_rows$alias] <- functions$name[match(alias_rows$function_id, functions$id)]

  category_id <- stats::setNames(.docs_slug(categories$name), categories$id)
  if (anyNA(functions$category_id)) {
    categories <- rbind(categories, data.frame(
      id = NA_integer_, name = "Other", description = "Everything else",
      position = max(c(0L, categories$position)) + 1L
    ))
  }

  md <- function(text) .docs_link_refs(.docs_text(text), target)

  entries <- lapply(seq_len(nrow(functions)), function(i) {
    f <- functions[i, ]
    fid <- f$id
    title <- .docs_text(f$title) %||% f$name
    deprecated <- grepl("\\(Deprecated\\)", title)
    summary <- trimws(sub("\\s*\\(Deprecated\\)", "", title))

    defaults <- .docs_usage_defaults(.docs_text(f$usage), f$name)
    params <- parameters[parameters$function_id == fid, , drop = FALSE]
    params <- lapply(seq_len(nrow(params)), function(j) {
      name <- params$name[j]
      .docs_compact(list(
        name = name,
        default = defaults[[name]],
        description = md(params$description[j]) %||% ""
      ))
    })

    secs <- sections[sections$function_id == fid, , drop = FALSE]
    subs <- subsections[subsections$function_id == fid, , drop = FALSE]
    titled <- function(rows) {
      lapply(seq_len(nrow(rows)), function(j) {
        list(title = rows$title[j], content = md(rows$content[j]) %||% "")
      })
    }
    secs <- lapply(seq_len(nrow(secs)), function(j) {
      own <- subs[!is.na(subs$section_id) & subs$section_id == secs$id[j], , drop = FALSE]
      .docs_compact(list(
        title = secs$title[j],
        content = md(secs$content[j]) %||% "",
        subsections = if (nrow(own) > 0) titled(own)
      ))
    })
    # Subsections of @details are their own sections on the page
    secs <- c(secs, titled(subs[is.na(subs$section_id), , drop = FALSE]))

    exs <- examples[examples$function_id == fid, , drop = FALSE]
    exs <- lapply(seq_len(nrow(exs)), function(j) {
      code <- exs$code[j]
      list(code = code, runnable = exs$is_dontrun[j] == 0 && !grepl("^\\s*if \\(FALSE\\)", code))
    })

    refs <- seealso[seealso$function_id == fid, , drop = FALSE]
    see_also <- list()
    for (j in seq_len(nrow(refs))) {
      if (identical(refs$link_type[j], "url")) {
        if (grepl("^https://", refs$url[j])) {
          see_also <- c(see_also, list(list(title = refs$reference[j], url = refs$url[j])))
        }
      } else {
        # roxygen's [new()] links are stored as "new()"
        ref <- sub("\\(\\)$", "", refs$reference[j])
        if (!is.na(target[ref])) see_also <- c(see_also, list(unname(target[ref])))
      }
    }
    see_also <- unique(see_also)

    .docs_compact(list(
      id = f$name,
      name = f$name,
      kind = "function",
      category = if (is.na(f$category_id)) "other" else unname(category_id[as.character(f$category_id)]),
      summary = summary,
      usage = .docs_text(f$usage),
      description = md(f$description),
      details = md(f$details),
      parameters = if (length(params) > 0) params,
      returns = md(f$value),
      note = md(f$note),
      sections = if (length(secs) > 0) secs,
      examples = if (length(exs) > 0) exs,
      see_also = if (length(see_also) > 0) see_also,
      aliases = {
        a <- alias_rows$alias[alias_rows$function_id == fid]
        if (length(a) > 0) as.list(a)
      },
      lifecycle = if (deprecated) "deprecated"
    ))
  })

  cats <- lapply(seq_len(nrow(categories)), function(i) {
    cid <- categories$id[i]
    in_cat <- if (is.na(cid)) is.na(functions$category_id) else functions$category_id %in% cid
    common <- functions$name[in_cat & functions$is_common == 1]
    .docs_compact(list(
      id = if (is.na(cid)) "other" else unname(category_id[as.character(cid)]),
      title = categories$name[i],
      description = .docs_text(categories$description[i]),
      position = as.integer(categories$position[i]),
      common = if (length(common) > 0) as.list(common)
    ))
  })

  list(
    schema = "docs-reference.v1",
    product = "r",
    version = version,
    categories = cats,
    entries = entries
  )
}

# NA and empty strings from docs.db mean "not documented"
#' @keywords internal
.docs_text <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x[1]) || !nzchar(trimws(x[1]))) NULL else x[1]
}

#' @keywords internal
.docs_compact <- function(x) Filter(Negate(is.null), x)

#' @keywords internal
.docs_slug <- function(x) {
  gsub("(^-+|-+$)", "", gsub("[^a-z0-9]+", "-", tolower(x)))
}

# Default values by argument name, from the usage line
#' @keywords internal
.docs_usage_defaults <- function(usage, name) {
  if (is.null(usage)) return(list())
  exprs <- tryCatch(parse(text = usage, keep.source = FALSE), error = function(e) NULL)
  for (expr in exprs) {
    if (!is.call(expr) || !identical(as.character(expr[[1]]), name)) next
    args <- as.list(expr)[-1]
    arg_names <- names(args) %||% rep("", length(args))
    out <- list()
    for (k in which(nzchar(arg_names))) {
      out[[arg_names[k]]] <- paste(deparse(args[[k]], width.cutoff = 500L), collapse = " ")
    }
    return(out)
  }
  list()
}

# Turn `name()` into a link to that entry, outside code blocks
#' @keywords internal
.docs_link_refs <- function(text, target) {
  if (is.null(text)) return(NULL)
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  in_code <- FALSE
  for (i in seq_along(lines)) {
    if (grepl("^\\s*```", lines[i])) {
      in_code <- !in_code
      next
    }
    if (in_code) next
    line <- lines[i]
    m <- gregexpr("`([A-Za-z][A-Za-z0-9._]*)\\(\\)`", line)
    found <- regmatches(line, m)[[1]]
    for (code in unique(found)) {
      fn <- sub("^`(.*)\\(\\)`$", "\\1", code)
      if (!is.na(target[fn])) {
        line <- gsub(code, sprintf("[%s](ref:%s)", code, target[[fn]]), line, fixed = TRUE)
      }
    }
    lines[i] <- line
  }
  paste(lines, collapse = "\n")
}
