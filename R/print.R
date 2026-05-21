## S3 print methods so REPL output is scannable. The underlying data
## structure is unchanged -- `$data`, `$records`, `$metadata`, and all named
## fields are accessed exactly as before. These methods just summarize the
## common cases (search results, dataset metadata, file listings) and
## suggest the next step the user is likely to want.

#' Print methods for dryaddata objects
#'
#' `dryaddata` returns deeply-nested lists from the Dryad API. To keep the
#' REPL readable, the package attaches lightweight S3 classes
#' (`dryad_search`, `dryad_datasets`, `dryad_dataset_versions`,
#' `dryad_version_files`, `dryad_dataset`, `dryad_version`, `dryad_file`)
#' and ships print methods that show the headline metadata plus a copyable
#' next-step command. The full structure remains available via `$data`,
#' `$records`, `$metadata`, and named fields.
#'
#' Pass `n` to control how many records the list-style printers show
#' (default 10; set to `Inf` to print all).
#'
#' @param x Object returned by a `dryaddata` wrapper.
#' @param n Integer. Maximum records to show. Default `10`.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @name dryad-print
#' @keywords internal
NULL

## ---- list endpoints ---------------------------------------------------------

#' @export
#' @rdname dryad-print
print.dryad_search <- function(x, n = 10L, ...) {
  print_record_list(x, n = n, resource = "datasets")
}

#' @export
#' @rdname dryad-print
print.dryad_datasets <- function(x, n = 10L, ...) {
  print_record_list(x, n = n, resource = "datasets")
}

#' @export
#' @rdname dryad-print
print.dryad_dataset_versions <- function(x, n = 10L, ...) {
  print_record_list(x, n = n, resource = "versions")
}

#' @export
#' @rdname dryad-print
print.dryad_version_files <- function(x, n = 10L, ...) {
  print_record_list(x, n = n, resource = "files")
}

print_record_list <- function(x, n, resource) {
  count <- x$metadata$count %||% length(x$records) %||% 0L
  total <- x$metadata$total
  pages <- x$metadata$pages

  header <- switch(
    resource,
    datasets = "Dryad datasets",
    versions = "Dryad dataset versions",
    files = "Dryad version files",
    "Dryad records"
  )
  if (!is.null(total) && is.finite(total)) {
    cli::cli_text(
      "{cli::col_blue(cli::style_bold(header))}: {.val {count}} of {.val {total}}{if (!is.null(pages) && pages > 1L) paste0(' (', pages, ' pages fetched)') else ''}"
    )
  } else {
    cli::cli_text("{cli::col_blue(cli::style_bold(header))}: {.val {count}}")
  }

  if (count == 0L) {
    cli::cli_alert_info("No records.")
    return(invisible(x))
  }

  n_show <- if (is.infinite(n)) count else min(n, count)
  for (i in seq_len(n_show)) {
    rec <- x$records[[i]]
    print_record_summary(rec, i, resource)
  }
  if (n_show < count) {
    cli::cli_text("{.emph ... and {count - n_show} more record{?s}}")
  }
  cat("\n")
  print_followup_hint(resource)
  cli::cli_text(c(
    "i" = "Inspect with {.code $data} (data.frame), {.code $records} (raw list), or {.code $metadata}."
  ))
  invisible(x)
}

print_record_summary <- function(rec, i, resource) {
  if (resource == "datasets") {
    id <- rec$identifier %||% paste0("id-", rec$id %||% "?")
    title <- truncate_string(rec$title %||% "", 80L)
    cli::cli_text("{.val {i}}: {title}")
    cli::cli_text("  {cli::col_grey(id)}{format_meta_suffix(rec)}")
  } else if (resource == "versions") {
    id <- rec$id %||% extract_id_from_links(rec)
    vn <- rec$versionNumber
    when <- rec$lastModificationDate %||% rec$publicationDate
    cli::cli_text("{.val {i}}: version {.val {vn}} (id {.val {id %||% '?'}})")
    if (!is.null(when)) {
      cli::cli_text("  {cli::col_grey(paste0('modified: ', when))}")
    }
  } else if (resource == "files") {
    id <- rec$id %||% extract_id_from_links(rec)
    path <- rec$path %||% paste0("file-", id)
    cli::cli_text("{.val {i}}: {path}")
    parts <- c(
      paste0("id: ", id %||% "?"),
      if (!is.null(rec$size)) paste0("size: ", format_bytes(rec$size)),
      if (!is.null(rec$mimeType)) paste0("type: ", rec$mimeType)
    )
    cli::cli_text("  {cli::col_grey(paste(parts, collapse = '  |  '))}")
  }
}

format_meta_suffix <- function(rec) {
  bits <- c(
    if (!is.null(rec$publicationDate)) paste0("published: ", rec$publicationDate),
    if (!is.null(rec$authors) && length(rec$authors)) {
      paste0("authors: ", format_author_summary(rec$authors))
    }
  )
  if (!length(bits)) {
    return("")
  }
  paste0(" \u2014 ", paste(bits, collapse = " \u2022 "))
}

print_followup_hint <- function(resource) {
  hint <- switch(
    resource,
    datasets = c(
      "i" = "Get one with {.code dryad_dataset(\"<identifier>\")}.",
      "i" = "List its files with {.code dryad_version_files(<version_id>)}.",
      "i" = "Download with {.code dryad_download_dataset(\"<identifier>\")}."
    ),
    versions = c(
      "i" = "List files with {.code dryad_version_files(<id>)}.",
      "i" = "Download with {.code dryad_download_version(<id>)}."
    ),
    files = c("i" = "Download with {.code dryad_download_file(<id>)}."),
    NULL
  )
  if (length(hint)) {
    cli::cli_bullets(hint)
  }
}

## ---- single-item endpoints --------------------------------------------------

#' @export
#' @rdname dryad-print
print.dryad_dataset <- function(x, ...) {
  cli::cli_text("{cli::col_blue(cli::style_bold('Dryad dataset'))}: {x$title %||% '(no title)'}")
  rows <- c(
    "Identifier" = x$identifier,
    "Authors" = format_author_summary(x$authors),
    "Version" = format_version_summary(x),
    "Published" = x$publicationDate,
    "Curation" = x$curationStatus,
    "License" = format_license(x$license),
    "Storage" = if (!is.null(x$storageSize)) format_bytes(x$storageSize)
  )
  print_field_table(rows)
  if (!is.null(x$abstract)) {
    cat("\n")
    cli::cli_text("{cli::style_italic('Abstract:')} {truncate_string(x$abstract, 300L)}")
  }
  cat("\n")
  id <- x$identifier %||% ""
  cli::cli_bullets(c(
    "i" = "List versions: {.code dryad_dataset_versions(\"{id}\")}",
    "i" = "Download:      {.code dryad_download_dataset(\"{id}\")}",
    "i" = "Inspect nested fields with {.code $authors}, {.code $`_links`}, etc."
  ))
  invisible(x)
}

#' @export
#' @rdname dryad-print
print.dryad_version <- function(x, ...) {
  id <- x$id %||% extract_id_from_links(x)
  cli::cli_text(
    "{cli::col_blue(cli::style_bold('Dryad version'))}: id {.val {id %||% '?'}} (v{x$versionNumber %||% '?'})"
  )
  rows <- c("Title" = x$title, "Modified" = x$lastModificationDate, "Curation" = x$curationStatus)
  print_field_table(rows)
  cat("\n")
  if (!is.null(id)) {
    cli::cli_bullets(c(
      "i" = "List files: {.code dryad_version_files({id})}",
      "i" = "Download:   {.code dryad_download_version({id})}"
    ))
  }
  invisible(x)
}

#' @export
#' @rdname dryad-print
print.dryad_file <- function(x, ...) {
  id <- x$id %||% extract_id_from_links(x)
  cli::cli_text("{cli::col_blue(cli::style_bold('Dryad file'))}: {x$path %||% paste0('file-', id)}")
  rows <- c(
    "Id" = id,
    "Size" = if (!is.null(x$size)) format_bytes(x$size),
    "Type" = x$mimeType,
    "Status" = x$status,
    "Digest" = if (!is.null(x$digest)) paste0(x$digestType %||% "", " ", x$digest)
  )
  print_field_table(rows)
  cat("\n")
  if (!is.null(id)) {
    cli::cli_bullets(c("i" = "Download: {.code dryad_download_file({id})}"))
  }
  invisible(x)
}

## ---- helpers ----------------------------------------------------------------

print_field_table <- function(rows) {
  rows <- rows[!vapply(rows, function(v) is.null(v) || (length(v) == 1L && is.na(v)), logical(1))]
  if (!length(rows)) {
    return(invisible(NULL))
  }
  width <- max(nchar(names(rows)))
  for (nm in names(rows)) {
    val <- truncate_string(as.character(rows[[nm]]), 100L)
    cat("  ", format(nm, width = width), "  ", val, "\n", sep = "")
  }
}

format_author_summary <- function(authors) {
  if (!length(authors)) {
    return(NULL)
  }
  first <- authors[[1]]
  first_name <- paste(c(first$firstName, first$lastName), collapse = " ")
  if (length(authors) == 1L) {
    return(first_name)
  }
  sprintf(
    "%s and %d other%s",
    first_name,
    length(authors) - 1L,
    if (length(authors) > 2L) "s" else ""
  )
}

format_license <- function(license) {
  if (length(license) == 0L) {
    return(NULL)
  }
  if (is.list(license)) {
    return(license$name %||% license$url %||% license$id %||% NULL)
  }
  as.character(license)[[1L]]
}

format_version_summary <- function(x) {
  vn <- x$versionNumber
  if (is.null(vn)) {
    return(NULL)
  }
  paste0("v", vn)
}

format_bytes <- function(bytes) {
  if (!is.numeric(bytes) || !is.finite(bytes)) {
    return(NA_character_)
  }
  units <- c("B", "KB", "MB", "GB", "TB", "PB")
  i <- min(length(units), max(1L, floor(log(max(bytes, 1L), 1024)) + 1L))
  val <- bytes / (1024^(i - 1L))
  fmt <- if (i == 1L) "%.0f %s" else "%.1f %s"
  sprintf(fmt, val, units[i])
}

truncate_string <- function(x, max_chars = 60L) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  too_long <- nchar(x) > max_chars
  x[too_long] <- paste0(substr(x[too_long], 1L, max_chars - 1L), "\u2026")
  x
}

extract_id_from_links <- function(x) {
  href <- x[["_links"]][["self"]][["href"]]
  if (is.null(href)) {
    return(NULL)
  }
  m <- regmatches(href, regexec("/([0-9]+)/?$", href))[[1]]
  if (length(m) >= 2L) as.integer(m[[2L]]) else NULL
}
