# Authenticate against the Dryad API

Acquires an OAuth2 access token using the *client credentials* grant and
caches it for the rest of the session. Subsequent calls reuse the cached
token until it nears expiry, at which point it is refreshed
transparently.

## Usage

``` r
dryad_auth(client_id = NULL, client_secret = NULL, force = FALSE)
```

## Arguments

- client_id, client_secret:

  OAuth2 application credentials. When `NULL` (the default), the package
  looks them up from keyring then environment variables as described
  above. Supply directly to override.

- force:

  If `TRUE`, ignore any cached token and request a fresh one.

## Value

Invisibly, a character scalar containing the access token.

## Details

Credentials are looked up in this order:

1.  Explicit `client_id` / `client_secret` arguments.

2.  The [keyring](https://r-lib.github.io/keyring/) package, under
    service `"dryaddata"` and usernames `"client_id"` /
    `"client_secret"`. This is the preferred storage: secrets live in
    the OS keychain rather than in a plain-text file on disk. See
    [`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md).

3.  Environment variables `DRYAD_CLIENT_ID` / `DRYAD_CLIENT_SECRET`,
    typically set in `~/.Renviron`. Avoid
    [`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html) in scripts;
    those calls land in your command history.

The token endpoint is taken from
[`dryad_token_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md),
which respects
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md).

You usually do not need to call this function directly: any function
that requires authentication (notably the `dryad_download_*()` family)
will call it as needed.

## See also

[`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md),
[`dryad_has_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md),
[`dryad_clear_token()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
dryad_auth() # uses keyring or env vars
} # }
```
