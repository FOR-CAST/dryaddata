#' Search Dryad datasets
#'
#' Wraps `GET /search`. All filter arguments map directly to the underlying
#' query parameters described in the
#' [search documentation](https://github.com/datadryad/dryad-app/blob/main/documentation/apis/search.md).
#'
#' Multi-term `q` values are AND-ed together; prefix a term with `-` to
#' negate, and append `*` for prefix matching, e.g. `q = "carbon -ocean
#' soil*"`.
#'
#' @param q Free-text query string.
#' @param subject Subject keyword to filter by.
#' @param orcid Author ORCID (no URL prefix).
#' @param affiliation ROR identifier of an author affiliation
#'   (e.g. `"https://ror.org/02jx3x895"`).
#' @param funder ROR identifier of a funder.
#' @param award Award/grant number.
#' @param journal_issn,publication_issn Journal or publication ISSN.
#' @param published_since,published_before,modified_since,modified_before
#'   ISO 8601 timestamps (UTC).
#' @param per_page Results per page (max 100).
#' @param page Page number (1-indexed). Ignored when `all_pages = TRUE`.
#' @param all_pages If `TRUE`, automatically follow `_links.next` and combine
#'   results. Use with care for large queries.
#' @param max_pages Hard cap when `all_pages = TRUE`. Default `Inf`.
#'
#' @return A list with three elements:
#'   * `metadata`: `count`, `total`, HAL `links`, and (when paginating)
#'      the number of `pages` fetched.
#'   * `records`: the raw list of dataset objects exactly as returned by
#'     the API (handy for nested fields like authors or `_links`).
#'   * `data`: a data frame stacking the scalar fields, with nested fields
#'     as list-columns.
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' hits <- dryad_search(q = "soil", per_page = 5)
#' head(hits$data[, c("identifier", "title")])
#' }
#' @export
dryad_search <- function(
  q = NULL,
  subject = NULL,
  orcid = NULL,
  affiliation = NULL,
  funder = NULL,
  award = NULL,
  journal_issn = NULL,
  publication_issn = NULL,
  published_since = NULL,
  published_before = NULL,
  modified_since = NULL,
  modified_before = NULL,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
) {
  per_page <- check_count(per_page, "per_page")
  page <- check_count(page, "page")
  query <- list(
    q = q,
    subject = subject,
    orcid = orcid,
    affiliation = affiliation,
    funder = funder,
    award = award,
    journalISSN = journal_issn,
    publicationISSN = publication_issn,
    publishedSince = published_since,
    publishedBefore = published_before,
    modifiedSince = modified_since,
    modifiedBefore = modified_before,
    per_page = per_page,
    page = page
  )
  req <- dryad_request("search", query = query)
  payload <- dryad_perform_json(req)
  if (isTRUE(all_pages)) {
    paginate_all(
      payload,
      make_next_req(),
      what = "stash:datasets",
      max_pages = max_pages,
      class = "dryad_search"
    )
  } else {
    build_list_result(payload, what = "stash:datasets", class = "dryad_search")
  }
}
