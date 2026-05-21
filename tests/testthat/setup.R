## Test-suite-wide safety net.
##
## 1. Belt-and-braces against accidental network egress: even though the
##    package only defines GET wrappers (no POST/PUT/PATCH/DELETE), strip
##    any real Dryad credentials and host overrides from the environment
##    for the duration of the suite, then point the package at the sandbox
##    host. Individual tests can still call `local_dryad_sandbox()` to seed
##    a fake token; without that, any attempted auth flow will fail loudly
##    rather than silently picking up a developer's `~/.Renviron` values.
##
## 2. Force the on-disk cache (HTTP responses and downloaded files) into a
##    suite-scoped tempdir so tests never touch the user's real cache.
##
## 3. Stub the `keyring` lookup so a developer who has stored real Dryad
##    credentials in their OS keychain cannot have them picked up by tests.
##    See `resolve_credential()` in R/auth.R.
suite_cache <- tempfile("dryaddata-tests-")
dir.create(suite_cache, recursive = TRUE)

withr::local_envvar(
  DRYAD_CLIENT_ID = NA,
  DRYAD_CLIENT_SECRET = NA,
  DRYAD_BASE_URL = "https://sandbox.datadryad.org/api/v2",
  DRYAD_TOKEN_URL = "https://sandbox.datadryad.org/oauth/token",
  DRYADDATA_CACHE_DIR = suite_cache,
  .local_envir = testthat::teardown_env()
)
withr::local_options(
  dryaddata.base_url = "https://sandbox.datadryad.org/api/v2",
  dryaddata.token_url = "https://sandbox.datadryad.org/oauth/token",
  dryaddata.cache_dir = suite_cache,
  .local_envir = testthat::teardown_env()
)
withr::defer(unlink(suite_cache, recursive = TRUE), envir = testthat::teardown_env())

## Disable the keyring branch of credential lookup so a developer with real
## Dryad credentials in their OS keychain cannot have them picked up by tests.
withr::local_options(dryaddata.disable_keyring = TRUE, .local_envir = testthat::teardown_env())
