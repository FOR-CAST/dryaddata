# dryaddata 0.0.2

* `dryad_download_dataset()` and `dryad_download_version()` gain an `on_too_large` argument and now fall back to downloading each file in the version individually when Dryad refuses to generate a single zip (HTTP 405 "The dataset is too large for zip file generation."). In interactive sessions the default `"ask"` prompts before downloading; in non-interactive sessions it proceeds without prompting. Pass `"files"` to always skip the prompt or `"error"` to keep the previous behavior.
* HTTP error messages now surface the API's plain-text response body verbatim, rather than collapsing it to a generic status description (e.g. "Method Not Allowed").

# dryaddata 0.0.1

* Initial release. Wrappers for the Dryad REST API v2: search datasets, retrieve dataset / version / file metadata, and download files or dataset archives. OAuth2 client-credentials authentication for protected endpoints. On-disk caching of responses and downloads, configurable via the `dryaddata.cache_dir` option or the `DRYADDATA_CACHE_DIR` environment variable.
* `dryad_use_sandbox()` toggles the active host between Dryad's sandbox and production deployments; pass `FALSE` to switch back to production.
