# Store, check, and clear Dryad credentials

`dryad_set_credentials()` saves your OAuth2 application's `client_id`
and `client_secret` in the OS keychain via the
[keyring](https://r-lib.github.io/keyring/) package. This is the
preferred way to make credentials available to
[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md):
secrets live in the OS keychain rather than in a plain-text file, and
they are unavailable to other R sessions until the keyring is unlocked.

## Usage

``` r
dryad_set_credentials(client_id = NULL, client_secret = NULL)

dryad_clear_credentials()

dryad_has_credentials()

dryad_clear_token()
```

## Arguments

- client_id, client_secret:

  OAuth2 application credentials, as strings. If either is `NULL`, you
  will be prompted interactively.

## Value

`dryad_set_credentials()` and `dryad_clear_credentials()` return `NULL`
invisibly. `dryad_has_credentials()` returns `TRUE` / `FALSE`.
`dryad_clear_token()` returns `NULL` invisibly.

## Details

`dryad_has_credentials()` reports whether credentials are available
(either in keyring or in environment variables). It does **not** unlock
or read any secret value, so it never prompts.

`dryad_clear_token()` discards any cached access token; the next
authenticated call will request a new one. `dryad_clear_credentials()`
removes the stored credentials from the OS keychain.

## See also

[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md)

## Examples

``` r
dryad_has_credentials()
#> Warning: Selecting ‘env’ backend. Secrets are stored in environment variables
#> [1] FALSE
dryad_clear_token()

if (FALSE) { # \dontrun{
# Interactive; prompts for the values:
dryad_set_credentials()

# Or non-interactive:
dryad_set_credentials("my-client-id", "my-client-secret")

dryad_clear_credentials()
} # }
```
