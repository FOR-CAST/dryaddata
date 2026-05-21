# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this is

`dryaddata` is an R package — a modern client for the
[Dryad](https://datadryad.org) REST API v2. Built on `httr2` with
minimal dependencies (`cli`, `httr2`, `jsonlite`, `rlang`). Replaces the
now-defunct rOpenSci `rdryad` package; do **not** consult `rdryad` for
design or copy its code — it targets an older API.

## Common commands

``` bash
# Regenerate NAMESPACE and man/*.Rd after editing roxygen comments.
Rscript -e 'devtools::document()'

# Run the full test suite (uses httr2::local_mocked_responses — no network).
Rscript -e 'devtools::test()'

# Run one test file or one test.
Rscript -e 'devtools::test_active_file("R/search.R")'
Rscript -e 'devtools::test_active_file("R/search.R", desc = "all_pages follows _links.next")'

# R CMD check — must pass 0/0/0 before committing.
Rscript -e 'devtools::check(args = c("--no-manual", "--as-cran"), quiet = TRUE)'

# Format R code — always run after editing.
air format .

# Verify all exported topics are in the pkgdown reference index.
Rscript -e 'pkgdown::check_pkgdown()'

# Build the full pkgdown site (requires the package be installed first).
Rscript -e 'devtools::install(quick = TRUE, upgrade = FALSE, build = FALSE, dependencies = FALSE)'
Rscript -e 'pkgdown::build_site(preview = FALSE, install = FALSE, devel = FALSE)'
```

## Architecture

The package is small (~1000 LOC) and organized by concern, with a single
internal request pipeline that every public function flows through.

### Request pipeline

`R/client.R` is the only place that talks to the network:

- `dryad_request(path, query, authenticate, base_url)` — builds the
  `httr2` request: applies the user-agent, JSON `Accept` header,
  throttling (30 req/min anonymous, 240 authenticated), retries on
  429/5xx, classed error body parser, and either an on-disk HTTP cache
  (anonymous) or a bearer token (authenticated). Public wrappers never
  touch `httr2` directly.
- `dryad_perform_json(req)` — performs and parses JSON.
- `dryad_perform_file(req, path)` — streams to disk. Contains a
  non-obvious fallback: under
  [`httr2::local_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.html),
  `req_perform(req, path=)` does **not** write the body to disk, so we
  manually `writeBin(resp$body, path)` if the file doesn’t exist after
  performing. Don’t delete that branch — the download tests rely on it.

### Configuration layering

Three knobs, each resolved through `resolve_setting()` in `R/config.R`
with precedence **explicit arg \> env var \> R option \> hard-coded
default**:

| Setting | Env var | Option | Default |
|----|----|----|----|
| API base URL | `DRYAD_BASE_URL` | `dryaddata.base_url` | `https://datadryad.org/api/v2` |
| OAuth token | `DRYAD_TOKEN_URL` | `dryaddata.token_url` | `https://datadryad.org/oauth/token` |
| Cache dir | `DRYADDATA_CACHE_DIR` | `dryaddata.cache_dir` | `tools::R_user_dir("dryaddata", "cache")` |

`dryad_use_sandbox(sandbox = TRUE)` flips both URLs at once; pass
`FALSE` to switch back to production. Credentials live only in env vars
(`DRYAD_CLIENT_ID`, `DRYAD_CLIENT_SECRET`).

**Sandbox vs production conventions** — apply these consistently: \*
Runnable roxygen `@examples` and the test suite target the **sandbox**.
New examples should call
[`dryad_use_sandbox()`](https://for-cast.github.io/dryaddata/reference/dryad_use_sandbox.md)
(or be wrapped `\dontrun{}`/`@examplesIf`), and new tests must go
through `local_dryad_sandbox()`. \* Vignettes, the README, and any setup
/ OAuth-registration instructions point users at **production**
(`https://datadryad.org`, `https://datadryad.org/account`). Mention the
sandbox only as an opt-in alternative for experimentation.

### HAL response envelope

Dryad uses HAL (`_links`, `_embedded`, CURIEs like `stash:datasets`).
`R/paginate.R` centralizes the traversal:

- `extract_records(payload, what)` finds the embedded collection by
  CURIE name with fallbacks.
- `build_list_result()` is what every list endpoint returns:
  `list(metadata = list(count, total, links), records = <raw list>, data = <data.frame>)`.
  `records_to_df()` in `R/utils.R` stacks shared scalar fields into
  columns and keeps nested fields as list-columns. Don’t flatten further
  — leave nesting to the caller.
- `paginate_all(first_payload, next_req, what, max_pages)` follows
  `_links.next` until exhausted; exposed via `all_pages = TRUE` on every
  list wrapper.

### Auth

`R/auth.R` implements OAuth2 client-credentials. The token lives in an
internal env (`.dryad_token_cache`) and is reused while ≥ 60 s remain
before expiry. `dryad_request(authenticate = TRUE)` calls
`dryad_token()`, which lazily authenticates. Anonymous GETs additionally
pass through
[`httr2::req_cache()`](https://httr2.r-lib.org/reference/req_cache.html)
(HTTP-cache-headers respected); authenticated requests skip that because
they may return user-scoped data.

**Credential lookup precedence** (in `resolve_credential()`): 1.
Explicit `client_id` / `client_secret` arg to
[`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md).
2. **`keyring`** (preferred) — service `"dryaddata"`, usernames
`"client_id"` / `"client_secret"`. Populate via
[`dryad_set_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md).
The `dryaddata.disable_keyring` option short-circuits this branch and is
set by the test suite (`tests/testthat/setup.R`) to prevent test runs
from touching a developer’s keychain. 3. Environment variables
`DRYAD_CLIENT_ID` / `DRYAD_CLIENT_SECRET` (typically in `~/.Renviron`).

`keyring` is in **Imports**, not Suggests — recommend it unconditionally
in user-facing docs; mention env vars only as a fallback for locked-down
or headless environments. Never recommend
[`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html) in scripts
(lands in command history).

### Read-only by design

The package defines **no write wrappers** (no
`POST`/`PUT`/`PATCH`/`DELETE`, no `req_method()`, no `req_body_*()`).
Every public function ultimately performs a `GET` — `dryad_request()` is
the only request builder and it never sets a method. If you ever add a
wrapper that mutates server state, audit the test suite at the same
time.

### Tests

Tests run in parallel (testthat 3, `Config/testthat/parallel: true`).
Worker count comes from `Sys.getenv("TESTTHAT_CPUS", "2")` — overridable
locally, defaults to 2 for CRAN-friendliness. Setup files load
independently in each worker, so `tests/testthat/setup.R` is safe under
parallel execution.

`tests/testthat/setup.R` runs once per test session and (a) strips real
`DRYAD_CLIENT_ID` / `DRYAD_CLIENT_SECRET` from the environment so a
developer’s `~/.Renviron` can never leak into a test run, (b) pins the
base/token URLs at the sandbox host, and (c) redirects the on-disk cache
into a suite-scoped tempdir. Keep that file in place — without it, test
runs on a developer machine with credentials would attempt real OAuth
against the sandbox.

Use
[`httr2::local_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.html)
(not `httptest2`). `tests/testthat/helper-dryaddata.R` provides:

- `local_dryad_sandbox()` — sets sandbox env vars, options, a per-test
  cache dir, and pre-seeds a fake bearer token so authenticated paths
  don’t try to call the OAuth endpoint.
- `mock_response(body, status, content_type)` — accepts a list
  (auto-JSON-encoded), raw, or character; returns an `httr2_response`.
- `local_mock(...)` — queues a sequence of canned responses.
- `sample_*_payload()` helpers — minimal HAL-shaped fixtures.

When adding a test that hits a new endpoint, build the payload in a
`sample_*_payload()` helper rather than inlining the JSON.

## Conventions specific to this codebase

- **No `httptest2`, no `crul`, no tidyverse imports.** Keep dependencies
  to the four already in `Imports`. If you need to add one, justify it
  first.
- **List endpoints always return the three-element envelope**
  (`metadata`, `records`, `data`). Don’t add wrappers that return bare
  records or bare data frames — consistency matters more than
  convenience here.
- **DOIs are accepted in any form** (`10.x/y`, `doi:10.x/y`,
  `https://doi.org/10.x/y`) and normalized via `normalize_doi()`. Always
  call it before encoding.
- **Examples that hit the network use `\dontrun{}`**, even ones gated by
  credentials. `@examplesIf dryad_has_credentials()` runs in R CMD check
  the moment a developer has `DRYAD_CLIENT_ID`/`DRYAD_CLIENT_SECRET` in
  their `.Renviron` and burns a live OAuth call. The download /
  [`dryad_auth()`](https://for-cast.github.io/dryaddata/reference/dryad_auth.md)
  examples deliberately do not auto-run.
- **Vignette chunks that hit live Dryad are gated on
  `DRYADDATA_BUILD_LIVE_VIGNETTES = "true"`.** Default for R CMD check
  is no-eval. Without this gate, every check has to make ~10+ anonymous
  calls, hits Dryad’s 30 req/min throttle, and either stalls for minutes
  or fails on rate-limited responses (we did this; it spawned several
  orphan R processes). The downloading vignette additionally requires
  [`dryad_has_credentials()`](https://for-cast.github.io/dryaddata/reference/dryad_set_credentials.md).
  Set the env var locally
  (`Sys.setenv(DRYADDATA_BUILD_LIVE_VIGNETTES = "true")`) before
  `devtools::build_vignettes()` / pkgdown / a manual check.
- **`air format .` after every edit.** It will reformat long argument
  lists and trailing-brace style — do not fight it.
- **Comment style.** True prose comments use a double-hash marker
  (`## ...`) at the start of the line; commented-out code uses a single
  hash (`# code`). This makes it easy to grep for “real” comments versus
  disabled code, and it matches the tidyverse style. `#'` is roxygen and
  is untouched.
- **No em-dashes in user-facing text** (R roxygen, vignettes, README,
  NEWS). CLAUDE.md and internal code comments may use them. Prefer `;`,
  `:`, `.`, `,`, or parentheses for the punctuation an em-dash would
  have carried.
- **No euphemistic language** in user-facing docs (“where the bytes
  land”, “baked in”, “just works”). Say what actually happens: “the file
  is written to …”; “OAuth2 authentication is included”.
