# Get metadata for a single dataset version

Wraps `GET /versions/{id}`.

## Usage

``` r
dryad_version(version_id)
```

## Arguments

- version_id:

  Numeric or character version id, as reported in
  [`dryad_dataset_versions()`](https://for-cast.github.io/dryaddata/reference/dryad_dataset_versions.md).

## Value

A nested list with the version metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
dryad_version(26724)
} # }
```
