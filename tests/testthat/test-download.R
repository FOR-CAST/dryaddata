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
