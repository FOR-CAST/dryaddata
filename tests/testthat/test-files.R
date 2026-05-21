test_that("dryad_file returns file metadata", {
  local_dryad_sandbox()
  local_mock(sample_file_payload(123456L))
  f <- dryad_file(123456)
  expect_type(f, "list")
  expect_equal(f$path, "example.csv")
})
