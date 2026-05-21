# Search Dryad datasets

Wraps `GET /search`. All filter arguments map directly to the underlying
query parameters described in the [search
documentation](https://github.com/datadryad/dryad-app/blob/main/documentation/apis/search.md).

## Usage

``` r
dryad_search(
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
)
```

## Arguments

- q:

  Free-text query string.

- subject:

  Subject keyword to filter by.

- orcid:

  Author ORCID (no URL prefix).

- affiliation:

  ROR identifier of an author affiliation (e.g.
  `"https://ror.org/02jx3x895"`).

- funder:

  ROR identifier of a funder.

- award:

  Award/grant number.

- journal_issn, publication_issn:

  Journal or publication ISSN.

- published_since, published_before, modified_since, modified_before:

  ISO 8601 timestamps (UTC).

- per_page:

  Results per page (max 100).

- page:

  Page number (1-indexed). Ignored when `all_pages = TRUE`.

- all_pages:

  If `TRUE`, automatically follow `_links.next` and combine results. Use
  with care for large queries.

- max_pages:

  Hard cap when `all_pages = TRUE`. Default `Inf`.

## Value

A list with three elements:

- `metadata`: `count`, `total`, HAL `links`, and (when paginating) the
  number of `pages` fetched.

- `records`: the raw list of dataset objects exactly as returned by the
  API (handy for nested fields like authors or `_links`).

- `data`: a data frame stacking the scalar fields, with nested fields as
  list-columns.

## Details

Multi-term `q` values are AND-ed together; prefix a term with `-` to
negate, and append `*` for prefix matching, e.g.
`q = "carbon -ocean soil*"`.

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
hits <- dryad_search(q = "soil", per_page = 5)
head(hits$data[, c("identifier", "title")])
} # }
```
