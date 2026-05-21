# List Dryad datasets

Wraps `GET /datasets`. Supports the optional filter parameters
documented by the API and HAL-style pagination.

## Usage

``` r
dryad_datasets(
  publication_issn = NULL,
  publication_name = NULL,
  manuscript_number = NULL,
  curation_status = NULL,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
)
```

## Arguments

- publication_issn, publication_name, manuscript_number,
  curation_status:

  Optional filters. See the [API docs](https://datadryad.org/api) for
  accepted values (e.g. `curation_status` is one of `"In progress"`,
  `"Curation"`, `"Published"`, ...).

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

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
dryad_datasets(per_page = 3)
} # }
```
