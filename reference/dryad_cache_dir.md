# Cache location and maintenance

`dryad_cache_dir()` returns (or sets) the on-disk directory the package
uses to cache HTTP responses (under `http/`) and downloaded files (under
`downloads/{datasets,versions,files}/`). The default is
`tools::R_user_dir("dryaddata", "cache")`.

## Usage

``` r
dryad_cache_dir(path = NULL)

dryad_cache_list(
  what = c("all", "http", "downloads", "datasets", "versions", "files")
)

dryad_cache_clear(
  what = c("all", "http", "downloads", "datasets", "versions", "files"),
  files = NULL
)

dryad_cache_info()
```

## Arguments

- path:

  When supplied to `dryad_cache_dir()`, sets the active cache directory
  (creating it if needed) and returns the path invisibly.

- what:

  Which subtree to inspect or clear. One of `"all"` (default), `"http"`,
  `"downloads"`, `"datasets"`, `"versions"`, `"files"`.

- files:

  Optional character vector of file paths to delete from the cache
  (typically taken from `dryad_cache_list()$path`). Paths outside
  `dryad_cache_dir()` are silently ignored.

## Value

- `dryad_cache_dir()`: a character scalar (the cache root).

- `dryad_cache_info()`: a data frame: `subtree`, `files`, `bytes`.

- `dryad_cache_list()`: a data frame: `path`, `subtree`, `bytes`,
  `mtime`. Empty (0 rows) when nothing is cached.

- `dryad_cache_clear()`: the number of files deleted, invisibly.

## Details

Lookup precedence: explicit argument \> `DRYADDATA_CACHE_DIR` env var \>
`dryaddata.cache_dir` option \> default.

`dryad_cache_info()` returns a per-subtree summary (file count and total
bytes), useful for a quick "how big is my cache?" check.

`dryad_cache_list()` returns a data frame with one row per cached file
(path, subtree, size, mtime). Filter by subtree and use the returned
`path` column to inspect, copy, or selectively delete files.

`dryad_cache_clear()` deletes cached files. By default it clears every
subtree. Pass `what` to target one (`"http"`, `"downloads"`, or one of
the download subtypes `"datasets"` / `"versions"` / `"files"`), or pass
`files = <character vector>` to remove specific paths. The `files`
argument is intersected with the cache root, so a path outside the cache
is silently ignored: `dryad_cache_clear()` can never delete a file
outside `dryad_cache_dir()`.

## Examples

``` r
withr::local_envvar(DRYADDATA_CACHE_DIR = tempfile("dryadcache"))
dryad_cache_dir()
#> [1] "/home/runner/.cache/R/dryaddata"
dryad_cache_info()
#>    subtree files bytes
#> 1     http     0     0
#> 2 datasets     0     0
#> 3 versions     0     0
#> 4    files     0     0

if (FALSE) { # \dontrun{
# After downloading a few things:
inv <- dryad_cache_list("datasets")
inv[order(-inv$bytes), ]               # biggest first

# Drop just the largest cached archive:
dryad_cache_clear(files = inv$path[which.max(inv$bytes)])

# Or clear an entire subtree:
dryad_cache_clear("http")
} # }

dryad_cache_clear()
#> Removed 0 cached files from /home/runner/.cache/R/dryaddata.
```
