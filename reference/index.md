# Package index

## Search and metadata

Open endpoints — no credentials required.

- [`dryad_search()`](https://for-cast.github.io/dryaddata/reference/dryad_search.md)
  : Search Dryad datasets
- [`dryad_datasets()`](https://for-cast.github.io/dryaddata/reference/dryad_datasets.md)
  : List Dryad datasets
- [`dryad_dataset()`](https://for-cast.github.io/dryaddata/reference/dryad_dataset.md)
  : Get metadata for a single Dryad dataset
- [`dryad_dataset_versions()`](https://for-cast.github.io/dryaddata/reference/dryad_dataset_versions.md)
  : List versions of a Dryad dataset
- [`dryad_version()`](https://for-cast.github.io/dryaddata/reference/dryad_version.md)
  : Get metadata for a single dataset version
- [`dryad_version_files()`](https://for-cast.github.io/dryaddata/reference/dryad_version_files.md)
  : List files in a dataset version
- [`dryad_file()`](https://for-cast.github.io/dryaddata/reference/dryad_file.md)
  : Get metadata for a single Dryad file

## Download

Stream files and archives to disk. Requires OAuth2 credentials.

- [`dryad_download_dataset()`](https://for-cast.github.io/dryaddata/reference/dryad_download_dataset.md)
  [`dryad_download_version()`](https://for-cast.github.io/dryaddata/reference/dryad_download_dataset.md)
  [`dryad_download_file()`](https://for-cast.github.io/dryaddata/reference/dryad_download_dataset.md)
  : Download a Dryad dataset, version, or file

## Authentication

OAuth2 client-credentials helpers. Credentials are stored in the OS
keychain via the keyring package.

- [`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  [`dryad_clear_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  [`dryad_has_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  [`dryad_clear_token()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md)
  : Store, check, and clear Dryad credentials
- [`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md)
  : Authenticate against the Dryad API

## Configuration and caching

Host URLs, environment variables, and the on-disk cache.

- [`dryad_base_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md)
  [`dryad_token_url()`](https://for-cast.github.io/dryaddata/reference/dryad_base_url.md)
  : Dryad host configuration
- [`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
  : Switch between Dryad's sandbox and production hosts
- [`dryad_cache_dir()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  [`dryad_cache_list()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  [`dryad_cache_clear()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  [`dryad_cache_info()`](https://for-cast.github.io/dryaddata/reference/dryad_cache_dir.md)
  : Cache location and maintenance

## Package

- [`dryaddata`](https://for-cast.github.io/dryaddata/reference/dryaddata-package.md)
  [`dryaddata-package`](https://for-cast.github.io/dryaddata/reference/dryaddata-package.md)
  : dryaddata: Programmatic access to the Dryad data repository
- [`dryaddata_options`](https://for-cast.github.io/dryaddata/reference/dryaddata_options.md)
  [`dryaddata-options`](https://for-cast.github.io/dryaddata/reference/dryaddata_options.md)
  : Options and environment variables used by dryaddata
