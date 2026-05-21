test_that("print.dryad_search summarizes results", {
  local_dryad_sandbox()
  local_mock(sample_datasets_payload(per_page = 2L, page = 1L, total = 2L))
  res <- dryad_search(q = "soil", per_page = 2)
  expect_s3_class(res, "dryad_search")
  expect_s3_class(res, "dryad_list")
  expect_snapshot(print(res))
})

test_that("print.dryad_dataset shows headline metadata + next steps", {
  local_dryad_sandbox()
  local_mock(sample_dataset_payload())
  ds <- dryad_dataset("doi:10.5061/dryad.j1fd7")
  expect_s3_class(ds, "dryad_dataset")
  expect_snapshot(print(ds))
})

test_that("print.dryad_version_files lists files with ids", {
  local_dryad_sandbox()
  local_mock(sample_version_files_payload())
  fl <- dryad_version_files(26724, per_page = 2)
  expect_s3_class(fl, "dryad_version_files")
  expect_snapshot(print(fl))
})

test_that("print.dryad_file shows id/size/type", {
  local_dryad_sandbox()
  local_mock(sample_file_payload(123456L))
  f <- dryad_file(123456)
  expect_s3_class(f, "dryad_file")
  expect_snapshot(print(f))
})

test_that("data, records, metadata remain accessible after classing", {
  local_dryad_sandbox()
  local_mock(sample_datasets_payload(per_page = 2L, page = 1L, total = 2L))
  res <- dryad_search(q = "soil", per_page = 2)
  expect_s3_class(res$data, "data.frame")
  expect_type(res$records, "list")
  expect_named(res$metadata, c("count", "total", "links"))
})

test_that("format_bytes formats bytes/KB/MB", {
  format_bytes <- asNamespace("dryaddata")$format_bytes
  expect_equal(format_bytes(0), "0 B")
  expect_equal(format_bytes(512), "512 B")
  expect_equal(format_bytes(2048), "2.0 KB")
  expect_equal(format_bytes(5 * 1024 * 1024), "5.0 MB")
})
