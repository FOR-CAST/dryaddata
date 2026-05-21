## Every test runs against Dryad's sandbox host with a per-test cache dir,
## a fake bearer token, and httr2-level response mocks.

local_dryad_sandbox <- function(envir = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = envir)
  withr::local_envvar(
    DRYAD_BASE_URL = "https://sandbox.datadryad.org/api/v2",
    DRYAD_TOKEN_URL = "https://sandbox.datadryad.org/oauth/token",
    DRYADDATA_CACHE_DIR = cache,
    DRYAD_CLIENT_ID = "test-id",
    DRYAD_CLIENT_SECRET = "test-secret",
    .local_envir = envir
  )
  withr::local_options(
    dryaddata.base_url = "https://sandbox.datadryad.org/api/v2",
    dryaddata.token_url = "https://sandbox.datadryad.org/oauth/token",
    dryaddata.cache_dir = cache,
    .local_envir = envir
  )
  ## Pre-seed a fake bearer token so authenticated requests skip the OAuth
  ## round-trip during tests.
  env <- asNamespace("dryaddata")$.dryad_token_cache
  env$token <- "test-token"
  env$expires_at <- Sys.time() + 3600
  withr::defer(dryad_clear_token(), envir = envir)
  invisible(cache)
}

## Build a mock response. body may be a list (serialized to JSON), a raw
## vector, or a character string.
mock_response <- function(body, status = 200L, content_type = "application/json") {
  if (is.list(body) && !inherits(body, "raw")) {
    body <- jsonlite::toJSON(body, auto_unbox = TRUE, null = "null")
    body <- charToRaw(body)
  } else if (is.character(body)) {
    body <- charToRaw(body)
  }
  httr2::response(status_code = status, headers = list(`Content-Type` = content_type), body = body)
}

## Convenience: install a sequence of canned responses for the duration of
## the calling test. Accepts a list of objects already built with
## mock_response(), or raw bodies/lists that will be wrapped.
local_mock <- function(..., envir = parent.frame()) {
  resps <- list(...)
  resps <- lapply(resps, function(r) {
    if (inherits(r, "httr2_response")) r else mock_response(r)
  })
  httr2::local_mocked_responses(resps, env = envir)
}

## Compact sample datasets fixture — two records with a few scalar plus a
## nested field, wrapped in the HAL envelope Dryad returns.
sample_datasets_payload <- function(per_page = 2L, page = 1L, total = 6L, next_page = NULL) {
  base <- "https://sandbox.datadryad.org/api/v2/datasets"
  qs <- function(p) paste0(base, "?page=", p, "&per_page=", per_page)
  records <- lapply(seq_len(per_page), function(i) {
    n <- (page - 1L) * per_page + i
    list(
      identifier = paste0("doi:10.5061/dryad.test", n),
      id = 1000L + n,
      title = paste0("Test dataset ", n),
      abstract = "Lorem ipsum.",
      authors = list(list(firstName = "A", lastName = paste0("B", n))),
      versionNumber = 1L,
      publicationDate = "2026-01-01"
    )
  })
  links <- list(
    self = list(href = qs(page)),
    first = list(href = qs(1L)),
    last = list(href = qs(ceiling(total / per_page)))
  )
  if (!is.null(next_page)) {
    links[["next"]] <- list(href = qs(next_page))
  }
  list(
    `_links` = links,
    count = per_page,
    total = total,
    `_embedded` = list(`stash:datasets` = records)
  )
}

sample_dataset_payload <- function(doi = "doi:10.5061/dryad.j1fd7") {
  list(
    identifier = doi,
    id = 12345L,
    title = "Example dataset",
    abstract = "A sandbox dataset used in tests.",
    authors = list(list(firstName = "Jane", lastName = "Doe")),
    versionNumber = 1L,
    publicationDate = "2026-01-01"
  )
}

sample_versions_payload <- function() {
  list(
    `_links` = list(self = list(href = "/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/versions")),
    count = 2L,
    total = 2L,
    `_embedded` = list(
      `stash:versions` = list(
        list(
          `_links` = list(self = list(href = "/api/v2/versions/26724")),
          versionNumber = 1L,
          lastModificationDate = "2026-01-01"
        ),
        list(
          `_links` = list(self = list(href = "/api/v2/versions/26725")),
          versionNumber = 2L,
          lastModificationDate = "2026-02-01"
        )
      )
    )
  )
}

## Single-version endpoint: no top-level id (id is in self href).
sample_version_payload <- function(id = 26724L) {
  list(
    `_links` = list(self = list(href = paste0("/api/v2/versions/", id))),
    versionNumber = 1L,
    title = "Example version",
    lastModificationDate = "2026-01-01"
  )
}

sample_version_files_payload <- function() {
  list(
    `_links` = list(self = list(href = "/api/v2/versions/26724/files")),
    count = 2L,
    total = 2L,
    `_embedded` = list(
      `stash:files` = list(
        list(
          `_links` = list(self = list(href = "/api/v2/files/94868")),
          path = "data.csv",
          size = 123L,
          mimeType = "text/csv",
          status = "created",
          digestType = "md5",
          digest = "deadbeef"
        ),
        list(
          `_links` = list(self = list(href = "/api/v2/files/94869")),
          path = "readme.txt",
          size = 45L,
          mimeType = "text/plain",
          status = "created",
          digestType = "md5",
          digest = "beadfeed"
        )
      )
    )
  )
}

## Single-file endpoint: no top-level id either.
sample_file_payload <- function(id = 123456L) {
  list(
    `_links` = list(self = list(href = paste0("/api/v2/files/", id))),
    path = "example.csv",
    size = 11L,
    mimeType = "text/csv",
    status = "created",
    digestType = "md5",
    digest = "deadbeef"
  )
}
