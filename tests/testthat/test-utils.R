test_that("normalize_doi handles common input forms", {
  normalize_doi <- asNamespace("dryaddata")$normalize_doi
  expect_equal(normalize_doi("10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
  expect_equal(normalize_doi("doi:10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
  expect_equal(normalize_doi("https://doi.org/10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
  expect_equal(normalize_doi("https://dx.doi.org/10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
  ## Scheme-less doi.org shorthand (the form the user pasted that hit a 404).
  expect_equal(normalize_doi("doi.org/10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
  expect_equal(normalize_doi("dx.doi.org/10.5061/dryad.j1fd7"), "doi:10.5061/dryad.j1fd7")
})

test_that("normalize_doi rejects garbage with a clear error", {
  normalize_doi <- asNamespace("dryaddata")$normalize_doi
  expect_snapshot(error = TRUE, normalize_doi("not-a-doi"))
})

test_that("records_to_df stacks scalar fields and keeps nested as lists", {
  records_to_df <- asNamespace("dryaddata")$records_to_df
  recs <- list(
    list(id = 1L, title = "A", authors = list(list(name = "X"))),
    list(id = 2L, title = "B", authors = list(list(name = "Y")))
  )
  df <- records_to_df(recs)
  expect_s3_class(df, "data.frame")
  expect_equal(df$id, c(1L, 2L))
  expect_equal(df$title, c("A", "B"))
  expect_type(df$authors, "list")
  expect_equal(length(df$authors), 2L)
})

test_that("safe_filename strips path-unsafe characters", {
  safe_filename <- asNamespace("dryaddata")$safe_filename
  expect_equal(safe_filename("doi:10.5061/dryad.j1fd7"), "doi_10.5061_dryad.j1fd7")
  expect_equal(safe_filename("hello world?.csv"), "hello_world_.csv")
})

test_that("check_doi rejects nonsense", {
  check_doi <- asNamespace("dryaddata")$check_doi
  expect_snapshot(error = TRUE, check_doi("not-a-doi"))
})
