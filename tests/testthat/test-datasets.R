test_that("dryad_datasets returns a list/data.frame envelope", {
  local_dryad_sandbox()
  local_mock(sample_datasets_payload(per_page = 2L, page = 1L, total = 2L))
  res <- dryad_datasets(per_page = 2)
  expect_named(res, c("metadata", "records", "data"))
  expect_equal(nrow(res$data), 2L)
})

test_that("dryad_dataset normalizes DOIs", {
  local_dryad_sandbox()
  local_mock(sample_dataset_payload())
  ds <- dryad_dataset("https://doi.org/10.5061/dryad.j1fd7")
  expect_type(ds, "list")
  expect_equal(ds$identifier, "doi:10.5061/dryad.j1fd7")
})

test_that("dryad_dataset_versions wraps the versions endpoint", {
  local_dryad_sandbox()
  local_mock(sample_versions_payload())
  vs <- dryad_dataset_versions("doi:10.5061/dryad.j1fd7", per_page = 2)
  expect_s3_class(vs$data, "data.frame")
  expect_true("versionNumber" %in% names(vs$data))
})
