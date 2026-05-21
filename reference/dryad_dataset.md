# Get metadata for a single Dryad dataset

Wraps `GET /datasets/{doi}`. The DOI may be given bare
(`"10.5061/..."`), prefixed (`"doi:10.5061/..."`), or as a full
`https://doi.org/...` URL; it is normalized and URL-encoded before being
sent.

## Usage

``` r
dryad_dataset(doi)
```

## Arguments

- doi:

  A Dryad dataset DOI.

## Value

A nested list containing the dataset metadata, exactly as returned by
the API.

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()
dryad_dataset("doi:10.5061/dryad.j1fd7")
} # }
```
