# Options and environment variables used by dryaddata

Reference page that lists every R option and environment variable the
package consults, alongside their defaults and accessor functions.

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

[`dryad_base_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md),
[`dryad_token_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md),
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md),
[`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md),
[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md),
[`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
