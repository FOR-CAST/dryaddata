#' List Dryad datasets
#'
#' Wraps `GET /datasets`. Supports the optional filter parameters documented
#' by the API and HAL-style pagination.
#'
#' @param publication_issn,publication_name,manuscript_number,curation_status
#'   Optional filters. See the
#'   [API docs](https://datadryad.org/api) for accepted values
#'   (e.g. `curation_status` is one of `"In progress"`, `"Curation"`,
#'   `"Published"`, ...).
#' @inheritParams dryad_search
#'
#' @inherit dryad_search return
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_datasets(per_page = 3)
#' }
#' @export
dryad_datasets <- function(
  publication_issn = NULL,
  publication_name = NULL,
  manuscript_number = NULL,
  curation_status = NULL,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
) {
  per_page <- check_count(per_page, "per_page")
  page <- check_count(page, "page")
  query <- list(
    publicationISSN = publication_issn,
    publicationName = publication_name,
    manuscriptNumber = manuscript_number,
    curationStatus = curation_status,
    per_page = per_page,
    page = page
  )
  req <- dryad_request("datasets", query = query)
  payload <- dryad_perform_json(req)
  if (isTRUE(all_pages)) {
    paginate_all(
      payload,
      make_next_req(),
      what = "stash:datasets",
      max_pages = max_pages,
      class = "dryad_datasets"
    )
  } else {
    build_list_result(payload, what = "stash:datasets", class = "dryad_datasets")
  }
}

#' Get metadata for a single Dryad dataset
#'
#' Wraps `GET /datasets/{doi}`. The DOI may be given bare (`"10.5061/..."`),
#' prefixed (`"doi:10.5061/..."`), or as a full `https://doi.org/...` URL;
#' it is normalized and URL-encoded before being sent.
#'
#' @param doi A Dryad dataset DOI.
#'
#' @return A nested list containing the dataset metadata, exactly as
#'   returned by the API.
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_dataset("doi:10.5061/dryad.j1fd7")
#' }
#' @export
dryad_dataset <- function(doi) {
  doi <- normalize_doi(doi)
  path <- paste0("datasets/", utils::URLencode(doi, reserved = TRUE))
  req <- dryad_request(path)
  out <- dryad_perform_json(req)
  class(out) <- c("dryad_dataset", "list")
  out
}

#' List versions of a Dryad dataset
#'
#' Wraps `GET /datasets/{doi}/versions`.
#'
#' @param doi A Dryad dataset DOI (any accepted form).
#' @inheritParams dryad_search
#'
#' @inherit dryad_search return
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_dataset_versions("doi:10.5061/dryad.j1fd7")
#' }
#' @export
dryad_dataset_versions <- function(
  doi,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
) {
  doi <- normalize_doi(doi)
  per_page <- check_count(per_page, "per_page")
  page <- check_count(page, "page")
  path <- paste0("datasets/", utils::URLencode(doi, reserved = TRUE), "/versions")
  req <- dryad_request(path, query = list(per_page = per_page, page = page))
  payload <- dryad_perform_json(req)
  if (isTRUE(all_pages)) {
    paginate_all(
      payload,
      make_next_req(),
      what = "stash:versions",
      max_pages = max_pages,
      class = "dryad_dataset_versions"
    )
  } else {
    build_list_result(payload, what = "stash:versions", class = "dryad_dataset_versions")
  }
}
