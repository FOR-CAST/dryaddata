# Downloading data from Dryad

Read endpoints on Dryad are open. File and archive downloads, however,
require an authenticated OAuth2 session. This vignette walks through the
one-time setup, day-to-day downloads, and the on-disk cache.

``` r

library(dryaddata)
```

`dryaddata` targets Dryad’s production deployment by default. (For
exploration without touching real data you can switch to the public
sandbox with
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md);
revert with `dryad_use_sandbox(FALSE)`.)

## Register an OAuth application

1.  Sign in to Dryad via ORCID at <https://datadryad.org/account>.
2.  Open *API applications* and create one. Dryad will issue a *client
    ID* and *client secret*.

(Organizational, publisher, and journal accounts must be requested via
`help@datadryad.org`; see Dryad’s [API accounts
guide](https://github.com/datadryad/dryad-app/blob/main/documentation/apis/api_accounts.md).
The sandbox accepts independent credentials registered at
<https://sandbox.datadryad.org/account>.)

## Store the credentials in your OS keychain (recommended)

`dryaddata` uses the [keyring](https://r-lib.github.io/keyring/) package
to store and read credentials. This is the recommended path: secrets
live in the OS keychain (Keychain on macOS, Credential Manager on
Windows, Secret Service on Linux) and never appear in a plain-text file
or your command history.

``` r

# Interactive: prompts twice (client ID, client secret):
dryad_set_credentials()

# Or non-interactive, e.g. from a parameterized script:
dryad_set_credentials("my-client-id", "my-client-secret")
```

You can verify the credentials are visible to the package. `key_list`
returns the entries without unlocking them:

``` r

dryad_has_credentials()
keyring::key_list("dryaddata")
```

To remove them later:

``` r

dryad_clear_credentials()
```

## Fallback: environment variables

If you cannot use a keyring (locked-down environments, headless CI),
`dryaddata` will also read `DRYAD_CLIENT_ID` and `DRYAD_CLIENT_SECRET`
from your environment. Put them in `~/.Renviron`
(`usethis::edit_r_environ()` opens it), one per line:

    DRYAD_CLIENT_ID=...
    DRYAD_CLIENT_SECRET=...

Then restart R. Do **not** put `Sys.setenv(DRYAD_CLIENT_SECRET = "...")`
in a script: the secret will land in your command history and any saved
`.Rhistory`. The keyring path above avoids this entirely.

``` r

dryad_has_credentials()
```

[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md)
exchanges credentials for an access token using the *client credentials*
grant. You almost never need to call it directly; the download functions
request a token on demand and cache it in the session until it nears
expiry.

## Where do downloads go?

Every download function takes a `path` argument that sets the
destination file on disk:

- **`path = NULL`** (default): the file is written to a deterministic
  path under the package cache at
  [`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  (see the next section). A second identical call returns the cached
  path immediately without making a network request.
- **`path = "<some file>"`**: the file is written to the location you
  specify. Use this when you need a specific filename or directory (a
  project `data/` folder, a scratch volume, a
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html), etc.).

Setting `overwrite = TRUE` forces a re-download even when the
destination already exists.

## Downloading a single file

The examples below write files into a temporary directory so the
vignette build is self-contained. In a real script, replace
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) with a persistent
location such as a project `data/` folder.

``` r

fl <- dryad_version_files(26724L)

# Write the file to a specific destination:
csv_path <- dryad_download_file(
  fl$data$id[1],
  path = file.path(tempdir(), "data.csv")
)
csv_path
readLines(csv_path, n = 3)

# Or omit `path` to use the package cache:
csv_cached <- dryad_download_file(fl$data$id[1])
```

## Downloading a full dataset

To download all files in one request, fetch the version archive. Pass
`path =` to set the destination file:

``` r

zip_path <- dryad_download_dataset(
  "doi:10.5061/dryad.j1fd7",
  path = file.path(tempdir(), "archiving.zip")
)
unzip(zip_path, list = TRUE)
```

Or, get the contents extracted in place:

``` r

dir_path <- dryad_download_dataset(
  "doi:10.5061/dryad.j1fd7",
  path = file.path(tempdir(), "archiving.zip"),
  unzip = TRUE
)
list.files(dir_path)
```

[`dryad_download_version()`](https://for-cast.github.io/dryaddata/reference/dryad_download_dataset.md)
works the same way but pins to a specific version id.

## The cache

All downloads land under
[`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
(default: `tools::R_user_dir("dryaddata", "cache")`):

    <cache_dir>/
    ├── http/         # cached metadata GETs (managed by httr2)
    └── downloads/
        ├── datasets/
        ├── versions/
        └── files/

- [`dryad_cache_info()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  reports the file count and size of each subtree.
- [`dryad_cache_clear()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  empties one or all subtrees.
- `dryad_cache_dir("path")` relocates the cache (also pinned by the
  `DRYADDATA_CACHE_DIR` environment variable).

Subsequent calls to a download function with the same identifier reuse
the cached file unless you pass `overwrite = TRUE`.

``` r

dryad_cache_info()
dryad_cache_clear("http")
```

## Tips for large transfers

- Pass `path = ...` to a `dryad_download_*()` call to write directly to
  a scratch volume instead of the cache.
- The 30 request/minute anonymous rate limit applies to metadata calls;
  authenticated metadata calls get 240/minute. The client uses
  [`httr2::req_throttle()`](https://httr2.r-lib.org/reference/req_throttle.html)
  to keep you under both limits automatically.
- Downloads are streamed to disk; there is no in-memory copy of the
  response body.
