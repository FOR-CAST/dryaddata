# List versions of a Dryad dataset

Wraps `GET /datasets/{doi}/versions`.

## Usage

``` r
dryad_dataset_versions(
  doi,
  per_page = 20L,
  page = 1L,
  all_pages = FALSE,
  max_pages = Inf
)
```

## Arguments

- doi:

  A Dryad dataset DOI (any accepted form).

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
dryad_dataset_versions("doi:10.5061/dryad.j1fd7")
} # }
```
