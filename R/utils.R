check_string <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort("{.arg {arg}} must be a non-empty character string.", call = call)
  }
  invisible(x)
}

check_count <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1 || x != as.integer(x)) {
    cli::cli_abort("{.arg {arg}} must be a positive integer.", call = call)
  }
  invisible(as.integer(x))
}

check_doi <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  check_string(x, arg, call = call)
  if (!grepl("^(doi:)?10\\.\\S+/\\S+$", x)) {
    cli::cli_abort(
      c("{.arg {arg}} does not look like a DOI.", "i" = "Got {.val {x}}."),
      call = call
    )
  }
  invisible(x)
}

#' Normalize a DOI to Dryad's expected form
#'
#' Dryad's API identifies datasets by a string of the form `"doi:<doi>"`,
#' which then has to be URL-encoded into the request path. This helper accepts
#' the bare DOI, a `"doi:"` prefixed form, or a full `https://doi.org/...`
#' URL and returns the prefixed form (`"doi:10.xxxx/xxx"`).
#'
#' @param x Character. A DOI in any of the forms above.
#' @return Character scalar of the form `"doi:<doi>"`.
#' @keywords internal
#' @noRd
normalize_doi <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  check_string(x, arg, call = call)
  ## Strip an optional scheme + doi.org/dx.doi.org host.
  x <- sub("^(https?://)?(dx\\.)?doi\\.org/", "", x, ignore.case = TRUE)
  x <- sub("^doi:", "", x, ignore.case = TRUE)
  out <- paste0("doi:", x)
  check_doi(out, arg, call = call)
  out
}

## Treat list-of-records (the typical Dryad HAL "_embedded" payload) as a
## data.frame by stacking shared scalar columns. Nested elements (authors,
## keywords, _links, ...) are kept as list-columns so the original structure
## is preserved.
records_to_df <- function(records) {
  if (length(records) == 0L) {
    return(data.frame())
  }
  all_names <- unique(unlist(lapply(records, names), use.names = FALSE))
  cols <- lapply(all_names, function(nm) {
    vals <- lapply(records, \(r) r[[nm]])
    if (all(vapply(vals, is_atomic_scalar, logical(1)))) {
      vals <- lapply(vals, \(v) if (is.null(v)) NA else v)
      unlist(vals, use.names = FALSE)
    } else {
      vals
    }
  })
  names(cols) <- all_names
  structure(cols, class = "data.frame", row.names = seq_along(records))
}

is_atomic_scalar <- function(x) {
  is.null(x) || (is.atomic(x) && length(x) == 1L)
}
