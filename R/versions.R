#' Get metadata for a single dataset version
#'
#' Wraps `GET /versions/{id}`.
#'
#' @param version_id Numeric or character version id, as reported in
#'   [dryad_dataset_versions()].
#'
#' @return A nested list with the version metadata.
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_version(26724)
#' }
#' @export
dryad_version <- function(version_id) {
  id <- check_id(version_id, "version_id")
  req <- dryad_request(paste0("versions/", id))
  out <- dryad_perform_json(req)
  class(out) <- c("dryad_version", "list")
  out
}

#' List files in a dataset version
#'
#' Wraps `GET /versions/{id}/files`.
#'
#' @param version_id Numeric or character version id.
#' @inheritParams dryad_search
#'
#' @inherit dryad_search return
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_version_files(26724)
#' }
#' @export
dryad_version_files <- function(
  version_id,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
) {
  id <- check_id(version_id, "version_id")
  per_page <- check_count(per_page, "per_page")
  page <- check_count(page, "page")
  req <- dryad_request(
    paste0("versions/", id, "/files"),
    query = list(per_page = per_page, page = page)
  )
  payload <- dryad_perform_json(req)
  if (isTRUE(all_pages)) {
    paginate_all(
      payload,
      make_next_req(),
      what = "stash:files",
      max_pages = max_pages,
      class = "dryad_version_files"
    )
  } else {
    build_list_result(payload, what = "stash:files", class = "dryad_version_files")
  }
}

check_id <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a single non-missing id.", call = call)
  }
  if (is.numeric(x)) {
    if (x != as.integer(x) || x < 0) {
      cli::cli_abort("{.arg {arg}} must be a non-negative integer id.", call = call)
    }
    return(as.character(as.integer(x)))
  }
  check_string(x, arg, call = call)
  x
}
