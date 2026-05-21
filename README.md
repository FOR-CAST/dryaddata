# dryaddata

<!-- badges: start -->
[![R-CMD-check](https://github.com/FOR-CAST/dryaddata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/FOR-CAST/dryaddata/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`dryaddata` is a modern R client for the [Dryad](https://datadryad.org)
data repository's [REST API (v2)](https://datadryad.org/api). It lets you
search and inspect datasets, traverse versions and files, and download
content. OAuth2 authentication and an on-disk cache for responses and
downloaded files are included.

## Installation

``` r
# install.packages("pak")
pak::pak("FOR-CAST/dryaddata")
```

## Quick start

`dryaddata` talks to Dryad's production deployment (<https://datadryad.org>) by default.

``` r
library(dryaddata)

# Search.
hits <- dryad_search(q = "soil", per_page = 5)
hits$data[, c("identifier", "title")]

# Inspect a single dataset.
ds <- dryad_dataset("doi:10.5061/dryad.j1fd7")
ds$title
ds$authors

# List versions and files.
vs <- dryad_dataset_versions("doi:10.5061/dryad.j1fd7")
fl <- dryad_version_files(vs$data$id[1])
```

To experiment without touching production data, call `dryad_use_sandbox()`
to repoint at <https://sandbox.datadryad.org>; `dryad_use_sandbox(FALSE)`
reverses it.

## Downloading data

File and archive downloads require an authenticated session.

**1. Register an OAuth2 application** at <https://datadryad.org/account>
(or <https://sandbox.datadryad.org/account> for the sandbox). Dryad will
issue a `client ID` and `client secret`.

**2. Store the credentials in your OS keychain (recommended).**
`dryaddata` uses the [keyring](https://r-lib.github.io/keyring/) package
so secrets live in the OS keychain (Keychain on macOS, Credential Manager
on Windows, Secret Service on Linux), never in a plain-text file or your
command history:

``` r
dryad_set_credentials()  # interactive; prompts for client_id and client_secret
```

After that, `dryad_auth()` finds them automatically. Pass `path =` to
write the file to a specific location, or omit it to write the file to
the package cache at `dryad_cache_dir()`:

``` r
# Specify a destination file:
zip_path <- dryad_download_dataset(
  "doi:10.5061/dryad.j1fd7",
  path = file.path(tempdir(), "archiving.zip")
)
csv_path <- dryad_download_file(file_id = 123456, path = "data/raw.csv")

# Or omit `path` to use the cache (a second identical call returns the
# cached path without making a network request):
zip_cached <- dryad_download_dataset("doi:10.5061/dryad.j1fd7")
```

If you cannot use a keyring (headless CI, locked-down environments),
`dryaddata` falls back to environment variables. Put them in
`~/.Renviron` (`usethis::edit_r_environ()` will open it):

```
DRYAD_CLIENT_ID=...
DRYAD_CLIENT_SECRET=...
```

Then restart R. **Do not** use `Sys.setenv()` from a script: the secret
ends up in your command history. Prefer the keyring path above.

Downloads are written under `dryad_cache_dir()` and re-used on subsequent
calls. Override the cache location with the `dryaddata.cache_dir` option
or the `DRYADDATA_CACHE_DIR` environment variable.

## Configuration cheat sheet

| Setting          | Option                 | Env var                |  Keyring entry                       |
|------------------|------------------------|------------------------|--------------------------------------|
| API base URL     | `dryaddata.base_url`   | `DRYAD_BASE_URL`       | -                                    |
| OAuth token URL  | `dryaddata.token_url`  | `DRYAD_TOKEN_URL`      | -                                    |
| Cache directory  | `dryaddata.cache_dir`  | `DRYADDATA_CACHE_DIR`  | -                                    |
| OAuth client ID  | -                      | `DRYAD_CLIENT_ID`      | service `"dryaddata"`, user `"client_id"`     |
| OAuth secret     | -                      | `DRYAD_CLIENT_SECRET`  | service `"dryaddata"`, user `"client_secret"` |

## Documentation

* `vignette("dryaddata")`: getting started.
* `vignette("searching", package = "dryaddata")`: query syntax and pagination.
* `vignette("downloading", package = "dryaddata")`: authentication and caching.
* Full reference at <https://for-cast.github.io/dryaddata/>.
