test_that("startup message is shown once and then throttled for 8h", {
  cache <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_CACHE_DIR = cache)
  withr::local_options(dryaddata.cache_dir = NULL)

  should_show <- asNamespace("dryaddata")$should_show_startup_message
  touch <- asNamespace("dryaddata")$touch_startup_message_stamp
  stamp_path <- asNamespace("dryaddata")$startup_message_stamp_path

  ## First call: no stamp yet -> show.
  expect_true(should_show())

  ## After touching the stamp with "now", it should be throttled.
  touch(cache)
  expect_false(should_show())

  ## Backdate the stamp to >8h ago -> show again.
  Sys.setFileTime(stamp_path(cache), Sys.time() - 9 * 3600)
  expect_true(should_show())
})
