# List files in a dataset version

Wraps `GET /versions/{id}/files`.

## Usage

``` r
dryad_version_files(
  version_id,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
)
```

## Arguments

- version_id:

  Numeric or character version id.

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
dryad_version_files(26724)
} # }
```
