test_that("dryad_version fetches version metadata", {
  local_dryad_sandbox()
  local_mock(sample_version_payload(26724L))
  v <- dryad_version(26724)
  expect_type(v, "list")
  expect_equal(v$versionNumber, 1L)
})

test_that("dryad_version_files returns a data frame of files with derived ids", {
  local_dryad_sandbox()
  local_mock(sample_version_files_payload())
  f <- dryad_version_files(26724, per_page = 2)
  expect_s3_class(f$data, "data.frame")
  expect_true("path" %in% names(f$data))
  ## `id` is not a top-level field in Dryad's response — it's derived from
  ## `_links.self.href` (`/api/v2/files/<id>`). The vignette's
  ## `dryad_download_file(fl$data$id[1])` pattern depends on this.
  expect_equal(f$data$id, c(94868L, 94869L))
})

test_that("dryad_dataset_versions derives id from _links.self.href", {
  local_dryad_sandbox()
  local_mock(sample_versions_payload())
  vs <- dryad_dataset_versions("doi:10.5061/dryad.j1fd7", per_page = 2)
  expect_equal(vs$data$id, c(26724L, 26725L))
})

test_that("check_id rejects bad input", {
  check_id <- asNamespace("dryaddata")$check_id
  expect_snapshot(error = TRUE, check_id(-1, "version_id"))
  expect_snapshot(error = TRUE, check_id(c(1, 2), "version_id"))
})
