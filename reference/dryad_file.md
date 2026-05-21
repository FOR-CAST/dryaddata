# Get metadata for a single Dryad file

Wraps `GET /files/{id}`. Use this to look up size, MIME type, checksum,
and the human-readable filename before downloading the file with
[`dryad_download_file()`](https://for-cast.github.io/dryaddata/reference/dryad_download_dataset.md).

## Usage

``` r
dryad_file(file_id)
```

## Arguments

- file_id:

  Numeric or character Dryad file id.

## Value

A nested list with the file metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
dryad_file(123456)
} # }
```
