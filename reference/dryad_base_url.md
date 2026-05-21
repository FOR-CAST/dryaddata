# Dryad host configuration

Get or set the API base URL and OAuth2 token URL used by the package.
Each accessor returns the current value invisibly when given an
argument.

## Usage

``` r
dryad_base_url(url = NULL)

dryad_token_url(url = NULL)
```

## Arguments

- url:

  A character string. When supplied, sets the active value (both the
  corresponding R option and process-level environment variable) and
  returns it invisibly. When `NULL`, returns the current value.

## Value

Character scalar.

## Details

Precedence: explicit argument \> environment variable \> R option \>
default.

## Examples

``` r
# Switch to the sandbox for the rest of the session.
dryad_use_sandbox()
dryad_base_url()
#> [1] "https://sandbox.datadryad.org/api/v2"
dryad_token_url()
#> [1] "https://sandbox.datadryad.org/oauth/token"

# Or set a custom value (e.g. a local mock server).
if (FALSE) { # \dontrun{
dryad_base_url("http://localhost:3000/api/v2")
} # }
```
