test_that("cache dir respects env var and option", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  expect_equal(normalizePath(dryad_cache_dir()), normalizePath(d))

  d2 <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = NA)
  withr::local_options(dryaddata.cache_dir = d2)
  expect_equal(normalizePath(dryad_cache_dir()), normalizePath(d2))
})

## Populate a fake cache layout so the list / clear / info helpers have
## something realistic to operate on.
populate_cache <- function(root) {
  dir.create(file.path(root, "http"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "downloads", "datasets"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "downloads", "versions"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "downloads", "files", "94868"), recursive = TRUE, showWarnings = FALSE)
  writeLines("h", file.path(root, "http", "abc.json"))
  writeBin(as.raw(1:10), file.path(root, "downloads", "datasets", "ds-A.zip"))
  writeBin(as.raw(1:20), file.path(root, "downloads", "versions", "v-1.zip"))
  writeBin(as.raw(1:30), file.path(root, "downloads", "files", "94868", "f.csv"))
  invisible(root)
}

test_that("dryad_cache_list() returns per-file info classified by subtree", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  populate_cache(d)

  all <- dryad_cache_list()
  expect_s3_class(all, "data.frame")
  expect_named(all, c("path", "subtree", "bytes", "mtime"))
  expect_setequal(all$subtree, c("http", "datasets", "versions", "files"))
  expect_equal(nrow(all), 4L)
  expect_true(all(file.exists(all$path)))

  expect_equal(sort(dryad_cache_list("files")$bytes), 30)
  expect_setequal(dryad_cache_list("downloads")$subtree, c("datasets", "versions", "files"))
})

test_that("dryad_cache_list() returns an empty data frame for a fresh cache", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  out <- dryad_cache_list()
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0L)
  expect_named(out, c("path", "subtree", "bytes", "mtime"))
})

test_that("dryad_cache_info() reports per-subtree counts and bytes", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  populate_cache(d)

  info <- dryad_cache_info()
  expect_s3_class(info, "data.frame")
  expect_named(info, c("subtree", "files", "bytes"))
  expect_equal(info$files[info$subtree == "http"], 1L)
  expect_equal(info$files[info$subtree == "datasets"], 1L)
  expect_equal(info$bytes[info$subtree == "files"], 30)
})

test_that("dryad_cache_clear() handles subtree, downloads, and 'all'", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  populate_cache(d)

  expect_message(n <- dryad_cache_clear("datasets"), "Removed 1")
  expect_equal(n, 1L)
  expect_equal(dryad_cache_info()$files[dryad_cache_info()$subtree == "datasets"], 0L)
  ## files / versions / http untouched.
  expect_equal(sum(dryad_cache_info()$files), 3L)

  expect_message(n2 <- dryad_cache_clear("downloads"), "Removed 2")
  expect_equal(n2, 2L)
  ## http still has 1 file left.
  expect_equal(sum(dryad_cache_info()$files), 1L)

  populate_cache(d)
  expect_message(n3 <- dryad_cache_clear(), "Removed 4")
  expect_equal(n3, 4L)
  expect_equal(sum(dryad_cache_info()$files), 0L)
})

test_that("dryad_cache_clear(files = ...) deletes only listed paths", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)
  populate_cache(d)

  inv <- dryad_cache_list("datasets")
  expect_message(n <- dryad_cache_clear(files = inv$path), "Removed 1")
  expect_equal(n, 1L)
  expect_false(file.exists(inv$path[1]))
  ## Other subtrees untouched.
  expect_equal(sum(dryad_cache_info()$files), 3L)
})

test_that("dryad_cache_clear(files = ...) refuses paths outside the cache", {
  d <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = d)
  withr::local_options(dryaddata.cache_dir = NULL)

  outside <- tempfile()
  writeLines("dangerous", outside)
  expect_message(n <- dryad_cache_clear(files = outside), "Ignored 1 path outside the cache")
  expect_equal(n, 0L)
  expect_true(file.exists(outside))
})
