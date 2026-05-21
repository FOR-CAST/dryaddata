# Print methods for dryaddata objects

`dryaddata` returns deeply-nested lists from the Dryad API. To keep the
REPL readable, the package attaches lightweight S3 classes
(`dryad_search`, `dryad_datasets`, `dryad_dataset_versions`,
`dryad_version_files`, `dryad_dataset`, `dryad_version`, `dryad_file`)
and ships print methods that show the headline metadata plus a copyable
next-step command. The full structure remains available via `$data`,
`$records`, `$metadata`, and named fields.

## Usage

``` r
# S3 method for class 'dryad_search'
print(x, n = 10L, ...)

# S3 method for class 'dryad_datasets'
print(x, n = 10L, ...)

# S3 method for class 'dryad_dataset_versions'
print(x, n = 10L, ...)

# S3 method for class 'dryad_version_files'
print(x, n = 10L, ...)

# S3 method for class 'dryad_dataset'
print(x, ...)

# S3 method for class 'dryad_version'
print(x, ...)

# S3 method for class 'dryad_file'
print(x, ...)
```

## Arguments

- x:

  Object returned by a `dryaddata` wrapper.

- n:

  Integer. Maximum records to show. Default `10`.

- ...:

  Unused.

## Value

`x`, invisibly.

## Details

Pass `n` to control how many records the list-style printers show
(default 10; set to `Inf` to print all).
