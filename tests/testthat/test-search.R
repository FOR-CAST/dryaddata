test_that("dryad_search returns metadata + data frame envelope", {
  local_dryad_sandbox()
  local_mock(sample_datasets_payload(per_page = 2L, page = 1L, total = 2L))
  res <- dryad_search(q = "soil", per_page = 2)
  expect_named(res, c("metadata", "records", "data"))
  expect_s3_class(res$data, "data.frame")
  expect_equal(nrow(res$data), 2L)
  expect_true("title" %in% names(res$data))
})

test_that("all_pages follows _links.next", {
  local_dryad_sandbox()
  local_mock(
    sample_datasets_payload(per_page = 2L, page = 1L, total = 6L, next_page = 2L),
    sample_datasets_payload(per_page = 2L, page = 2L, total = 6L, next_page = 3L),
    sample_datasets_payload(per_page = 2L, page = 3L, total = 6L)
  )
  res <- dryad_search(q = "soil", per_page = 2, all_pages = TRUE)
  expect_equal(res$metadata$pages, 3L)
  expect_equal(nrow(res$data), 6L)
})

test_that("paginate_all handles host-relative _links.next.href", {
  local_dryad_sandbox()
  page1 <- sample_datasets_payload(per_page = 2L, page = 1L, total = 4L, next_page = 2L)
  ## Mimic Dryad's actual response: next href is host-relative.
  page1[["_links"]][["next"]][["href"]] <- "/api/v2/datasets?page=2&per_page=2"
  page2 <- sample_datasets_payload(per_page = 2L, page = 2L, total = 4L)
  local_mock(page1, page2)
  res <- dryad_search(q = "soil", per_page = 2, all_pages = TRUE)
  expect_equal(nrow(res$data), 4L)
})
