# Getting started with dryaddata

`dryaddata` is a thin, modern R client for the Dryad REST API (v2). It
helps you search and retrieve dataset metadata, walk through versions
and files, and download content. OAuth2 authentication and a shared
on-disk cache are built in.

``` r

library(dryaddata)
```

## Production by default

`dryaddata` is pointed at Dryad’s production deployment out of the box:

``` r

dryad_base_url()
#> [1] "https://datadryad.org/api/v2"
```

To register for OAuth2 credentials (needed for the `dryad_download_*()`
family), follow the setup steps in
[`vignette("downloading", package = "dryaddata")`](https://for-cast.github.io/dryaddata/articles/downloading.md).

If you want to experiment without touching production data, `dryaddata`
also supports Dryad’s public sandbox.
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
repoints both the API and the OAuth token URLs at the sandbox host;
`dryad_use_sandbox(FALSE)` reverses the change. The helper returns the
previous URLs invisibly so you can restore them. Sandbox accounts are
independent of production; register separately at
<https://sandbox.datadryad.org/account>.

## Anatomy of a list response

Endpoints that return lists (search, datasets, versions, files) all
share a common envelope:

``` r

hits <- dryad_search(q = "soil", per_page = 5)

names(hits)
#> [1] "metadata" "records"  "data"

hits$metadata$count   # records on this page
hits$metadata$total   # total matches across all pages
head(hits$data[, c("identifier", "title")])
```

- `metadata` holds counts and the raw HAL `_links` block (`self`,
  [`next`](https://rdrr.io/r/base/Control.html), `prev`, …).
- `records` is the untouched list of objects as returned by the API.
  Useful when you need a nested field like `authors` or `_links`.
- `data` is a tidy data frame that stacks scalar fields and keeps nested
  ones as list-columns.

## Walking from a DOI to bytes

``` r

ds <- dryad_dataset("doi:10.5061/dryad.j1fd7")
ds$title
ds$abstract

vs <- dryad_dataset_versions(ds$identifier)
latest <- vs$data$id[which.max(vs$data$versionNumber)]

fl <- dryad_version_files(latest)
fl$data[, c("path", "size", "mimeType")]
```

Downloading a file requires authenticated credentials (see
[`?dryad_auth`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md)).
The chunk below only runs when `DRYAD_CLIENT_ID` and
`DRYAD_CLIENT_SECRET` are set in the build environment.

Pass `path =` to set the destination file; otherwise the file is cached
at
[`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md).
The example uses [`tempdir()`](https://rdrr.io/r/base/tempfile.html) so
the downloaded file is removed when the R session ends.

``` r

csv_path <- dryad_download_file(
  fl$data$id[1],
  path = file.path(tempdir(), "first-file.csv")
)
csv_path
```

## Where to go next

- Pagination, filters, and the search query language:
  [`vignette("searching")`](https://for-cast.github.io/dryaddata/articles/searching.md).
- OAuth setup, the download cache, and large transfers:
  [`vignette("downloading")`](https://for-cast.github.io/dryaddata/articles/downloading.md).
