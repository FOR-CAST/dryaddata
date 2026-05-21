test_that("dryad_download_file writes bytes to the destination", {
  local_dryad_sandbox()
  bytes <- charToRaw("col1,col2\n1,2\n3,4\n")
  dest <- withr::local_tempfile(fileext = ".csv")
  local_mock(mock_response(bytes, content_type = "text/csv"))
  p <- dryad_download_file(123456, path = dest)
  expect_equal(p, dest)
  expect_equal(readBin(p, raw(), n = length(bytes)), bytes)
})

test_that("dryad_download_file reuses an existing destination", {
  local_dryad_sandbox()
  dest <- withr::local_tempfile(fileext = ".csv")
  writeLines("cached", dest)
  ## No mocks queued: a network call would fail. The cache-hit branch
  ## short-circuits and returns the path unchanged.
  expect_message(p <- dryad_download_file(123456, path = dest), "Using cached file")
  expect_equal(p, dest)
  expect_equal(readLines(dest), "cached")
})

test_that("dryad_download_file uses metadata to pick a default filename", {
  local_dryad_sandbox()
  bytes <- charToRaw("hello")
  local_mock(sample_file_payload(123456L), mock_response(bytes, content_type = "text/csv"))
  p <- dryad_download_file(123456)
  expect_match(basename(p), "example\\.csv$")
  expect_true(file.exists(p))
})

test_that("dryad_download_dataset writes a zip to the cache", {
  local_dryad_sandbox()
  fake_zip <- as.raw(c(0x50, 0x4b, 0x03, 0x04, 0x0a, 0x00))
  local_mock(mock_response(fake_zip, content_type = "application/zip"))
  p <- dryad_download_dataset("doi:10.5061/dryad.j1fd7")
  expect_match(p, "\\.zip$")
  expect_true(file.exists(p))
})

test_that("on_too_large = 'error' surfaces the verbatim plain-text body", {
  local_dryad_sandbox()
  dest <- withr::local_tempfile(fileext = ".zip")
  local_mock(mock_response(
    "The dataset is too large for zip file generation. Please download each file individually.",
    status = 405L,
    content_type = "text/plain"
  ))
  expect_snapshot(
    error = TRUE,
    dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest, on_too_large = "error")
  )
})

test_that("JSON API error bodies use the error/message field", {
  local_dryad_sandbox()
  dest <- withr::local_tempfile(fileext = ".zip")
  local_mock(mock_response(
    list(error = "Unauthorized, must have current bearer token"),
    status = 401L
  ))
  expect_snapshot(error = TRUE, dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest))
})

test_that("non-interactive 'too large' falls back to per-file downloads", {
  local_dryad_sandbox()
  withr::local_options(rlang_interactive = FALSE)
  dest <- withr::local_tempfile(fileext = ".zip")
  local_mock(
    ## 1. The zip endpoint refuses.
    mock_response(
      "The dataset is too large for zip file generation.",
      status = 405L,
      content_type = "text/plain"
    ),
    ## 2. Dataset metadata, with the stash:version link to version 26724.
    list(
      `_links` = list(
        self = list(href = "/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7"),
        `stash:version` = list(href = "/api/v2/versions/26724")
      ),
      identifier = "doi:10.5061/dryad.j1fd7"
    ),
    ## 3. Version files listing.
    sample_version_files_payload(),
    ## 4 + 5. The two files in the listing.
    mock_response(charToRaw("col1,col2\n1,2\n"), content_type = "text/csv"),
    mock_response(charToRaw("hello"), content_type = "text/plain")
  )
  dir <- dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest)
  expect_equal(dir, sub("\\.zip$", "", dest))
  expect_true(dir.exists(dir))
  expect_setequal(list.files(dir), c("data.csv", "readme.txt"))
  expect_equal(readLines(file.path(dir, "readme.txt"), warn = FALSE), "hello")
})

test_that("on_too_large = 'files' skips the prompt even when interactive", {
  local_dryad_sandbox()
  withr::local_options(rlang_interactive = TRUE)
  dest <- withr::local_tempfile(fileext = ".zip")
  local_mock(
    mock_response(
      "The dataset is too large for zip file generation.",
      status = 405L,
      content_type = "text/plain"
    ),
    list(
      `_links` = list(
        self = list(href = "/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7"),
        `stash:version` = list(href = "/api/v2/versions/26724")
      ),
      identifier = "doi:10.5061/dryad.j1fd7"
    ),
    sample_version_files_payload(),
    mock_response(charToRaw("col1,col2\n1,2\n"), content_type = "text/csv"),
    mock_response(charToRaw("hello"), content_type = "text/plain")
  )
  dir <- dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest, on_too_large = "files")
  expect_true(dir.exists(dir))
  expect_setequal(list.files(dir), c("data.csv", "readme.txt"))
})

test_that("non-'too large' 405 responses are not intercepted", {
  local_dryad_sandbox()
  dest <- withr::local_tempfile(fileext = ".zip")
  local_mock(mock_response(
    "Some unrelated 405 reason.",
    status = 405L,
    content_type = "text/plain"
  ))
  expect_snapshot(error = TRUE, dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest))
})
