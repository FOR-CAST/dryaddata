# Download a Dryad dataset, version, or file

These functions download binary content from Dryad and write it to disk.
They require a valid OAuth2 bearer token (see
[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md));
set `DRYAD_CLIENT_ID` and `DRYAD_CLIENT_SECRET` in your environment
first.

## Usage

``` r
dryad_download_dataset(doi, path = NULL, overwrite = FALSE, unzip = FALSE)

dryad_download_version(
  version_id,
  path = NULL,
  overwrite = FALSE,
  unzip = FALSE
)

dryad_download_file(file_id, path = NULL, overwrite = FALSE)
```

## Arguments

- doi:

  Dataset DOI (any accepted form).

- path:

  Destination file path for the downloaded content. Use this when you
  need a specific filename or location (a project `data/` folder, a
  scratch volume, a
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html), etc.). When
  `NULL` (default), the file is written to a deterministic path inside
  [`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  and re-used on subsequent calls.

- overwrite:

  If `TRUE`, re-download even if the destination exists.

- unzip:

  If `TRUE` (dataset / version downloads only), the archive is extracted
  into a sibling directory and that directory is returned.

- version_id:

  Numeric or character dataset-version id.

- file_id:

  Numeric or character file id.

## Value

Absolute path to the downloaded file (or, with `unzip = TRUE`, to the
directory of extracted contents), invisibly.

## Details

By default the file is written to (and re-read from) the package's
download cache (under
[`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)).
Pass `path` to write to an explicit location instead. With
`overwrite = FALSE` (the default), an existing destination is returned
as-is, with no network call.

`dryad_download_dataset()` and `dryad_download_version()` fetch a
`application/zip` archive containing all files in the (latest) version
or specified version respectively. `dryad_download_file()` fetches the
bytes of a single file, using its server-side filename and MIME type.

## Examples

``` r
if (FALSE) { # \dontrun{
dryad_use_sandbox()

# 1. Write to a chosen destination. The example uses tempdir() so the
#    file is removed when the R session ends; replace it with any path
#    you want the file to live at.
dest <- file.path(tempdir(), "archiving.zip")
zip <- dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest)
file.info(zip)$size

# 2. Omit `path` to let the package write to its on-disk cache under
#    dryad_cache_dir(). A second identical call returns the cached
#    path without making a network request.
zip2 <- dryad_download_dataset("doi:10.5061/dryad.j1fd7")

# 3. A single file written to a chosen destination:
csv <- dryad_download_file(94868, path = file.path(tempdir(), "data.csv"))
} # }
```
