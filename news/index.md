# Changelog

## dryaddata 0.0.1

- Initial release. Wrappers for the Dryad REST API v2: search datasets,
  retrieve dataset / version / file metadata, and download files or
  dataset archives. OAuth2 client-credentials authentication for
  protected endpoints. On-disk caching of responses and downloads,
  configurable via the `dryaddata.cache_dir` option or the
  `DRYADDATA_CACHE_DIR` environment variable.
- [`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
  toggles the active host between Dryad’s sandbox and production
  deployments; pass `FALSE` to switch back to production.
