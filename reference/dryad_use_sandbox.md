# Switch between Dryad's sandbox and production hosts

Convenience wrapper that points
[`dryad_base_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md)
and
[`dryad_token_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md)
at Dryad's public sandbox or production deployment in a single call. The
sandbox accepts independent credentials and is the right target for
development; production is the default.

## Usage

``` r
dryad_use_sandbox(sandbox = TRUE)
```

## Arguments

- sandbox:

  Logical. `TRUE` (default) switches the active host to the sandbox
  (`https://sandbox.datadryad.org`); `FALSE` switches back to production
  (`https://datadryad.org`).

## Value

Invisibly, a named list with the *previous* `base_url` and `token_url`,
suitable for restoring later via
[`dryad_base_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md)
and
[`dryad_token_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md).

## Examples

``` r
old <- dryad_use_sandbox()
dryad_base_url() # https://sandbox.datadryad.org/api/v2
#> [1] "https://sandbox.datadryad.org/api/v2"
dryad_use_sandbox(FALSE)
dryad_base_url() # https://datadryad.org/api/v2
#> [1] "https://datadryad.org/api/v2"
# Restore prior values:
dryad_base_url(old$base_url)
dryad_token_url(old$token_url)
```
