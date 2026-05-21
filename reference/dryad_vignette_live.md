# Vignette-build helper

Internal hook used by the package's own vignettes (and downstream
packages that want the same convention). Returns `TRUE` when calling
chunks should evaluate against the live Dryad API and `FALSE` otherwise.

## Usage

``` r
dryad_vignette_live(require_credentials = FALSE)
```

## Arguments

- require_credentials:

  Logical. If `TRUE`, additionally requires OAuth credentials to be
  available (the downloading vignette uses this).

## Value

A single logical.

## Details

A chunk is "live" when:

- `DRYADDATA_BUILD_LIVE_VIGNETTES = "true"` is set in the build
  environment (opt-in; keeps R CMD check fast and deterministic), AND

- `require_credentials = FALSE`, OR
  [`dryad_has_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  reports `TRUE`.

As a side effect, when the result is `TRUE` the on-disk cache is
redirected to a fresh
[`tempfile()`](https://rdrr.io/r/base/tempfile.html) so the vignette
build never writes to the user's persistent cache.
