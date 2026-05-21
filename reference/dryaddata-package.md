# dryaddata: Programmatic access to the Dryad data repository

A modern R client for the Dryad REST API (version 2). Use it to search
datasets, retrieve dataset / version / file metadata, and download data
files or full dataset archives. Authenticated downloads use OAuth2
client credentials. Responses and downloads are cached on disk in a user
configurable location.

## Details

See
[dryaddata_options](https://for-cast.github.io/dryaddata/reference/dryaddata_options.md)
for the same listing as a standalone help page, and
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
for the one-call toggle between Dryad's production and sandbox
deployments.

## Quick start

    # Point the client at Dryad's sandbox while developing.
    dryad_use_sandbox()

    # Free-text search.
    hits <- dryad_search(q = "carbon", per_page = 5)
    hits$datasets[, c("identifier", "title")]

    # Pull metadata for one dataset and list its files.
    ds  <- dryad_dataset("doi:10.5061/dryad.j1fd7")
    fls <- dryad_version_files(ds$`_links`$`stash:version`$href)

## Options and environment variables

`dryaddata`'s behaviour is configured through R options and environment
variables. Lookup precedence is **explicit function argument \>
environment variable \> R option \> hard-coded default**. The OAuth
credentials follow a separate path described in
[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md).

- **API base URL**:

  Option `dryaddata.base_url`; env var `DRYAD_BASE_URL`. Default
  `"https://datadryad.org/api/v2"`. Toggle to the sandbox via
  [`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
  or set directly with
  [`dryad_base_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md).

- **OAuth token URL**:

  Option `dryaddata.token_url`; env var `DRYAD_TOKEN_URL`. Default
  `"https://datadryad.org/oauth/token"`. Used by
  [`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md).

- **Cache directory**:

  Option `dryaddata.cache_dir`; env var `DRYADDATA_CACHE_DIR`. Default
  `tools::R_user_dir("dryaddata", "cache")`. Holds both the HTTP
  response cache (`<cache_dir>/http/`) and downloaded files
  (`<cache_dir>/downloads/`). See
  [`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md).

- **Disable keyring**:

  Option `dryaddata.disable_keyring` (logical; default `FALSE`). When
  `TRUE`, the credential resolver skips the keyring branch entirely and
  only consults `DRYAD_CLIENT_ID` / `DRYAD_CLIENT_SECRET`. Useful in
  tests and CI; the package test suite sets this automatically.

- **OAuth client ID** (secret):

  Preferred: store in the OS keychain via
  [`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  under service `"dryaddata"`, username `"client_id"`. Fallback: env var
  `DRYAD_CLIENT_ID` in `~/.Renviron`. No R option (so the value is never
  recorded in plain text on disk).

- **OAuth client secret** (secret):

  Preferred: store in the OS keychain via
  [`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  under service `"dryaddata"`, username `"client_secret"`. Fallback: env
  var `DRYAD_CLIENT_SECRET` in `~/.Renviron`. No R option.

Avoid setting secrets with
[`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html) from a script:
the call lands in your command history and any saved `.Rhistory`. Use
[`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
or `~/.Renviron` instead.

## See also

Useful links:

- <https://github.com/FOR-CAST/dryaddata>

- <https://for-cast.github.io/dryaddata/>

- Report bugs at <https://github.com/FOR-CAST/dryaddata/issues>

## Author

**Maintainer**: Alex M Chubaty <achubaty@for-cast.ca>
([ORCID](https://orcid.org/0000-0001-7146-8135))

Authors:

- Alex M Chubaty <achubaty@for-cast.ca>
  ([ORCID](https://orcid.org/0000-0001-7146-8135))
