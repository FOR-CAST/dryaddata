test_that("dryad_vignette_live respects the env-var gate", {
  cache <- withr::local_tempdir()
  withr::local_envvar(DRYADDATA_BUILD_LIVE_VIGNETTES = NA, DRYADDATA_CACHE_DIR = cache)
  expect_false(dryad_vignette_live())

  withr::local_envvar(DRYADDATA_BUILD_LIVE_VIGNETTES = "true")
  expect_true(dryad_vignette_live())
})

test_that("dryad_vignette_live(require_credentials = TRUE) blocks without creds", {
  withr::local_envvar(
    DRYADDATA_BUILD_LIVE_VIGNETTES = "true",
    DRYAD_CLIENT_ID = NA,
    DRYAD_CLIENT_SECRET = NA
  )
  ## Suite-wide setup disables the keyring branch, so this resolves to no
  ## credentials regardless of what's in the dev's actual OS keychain.
  expect_false(dryad_vignette_live(require_credentials = TRUE))
})

test_that("dryad_vignette_live redirects the cache when active", {
  before <- dryad_cache_dir()
  withr::local_envvar(DRYADDATA_BUILD_LIVE_VIGNETTES = "true")
  on.exit(dryad_cache_dir(before), add = TRUE)
  expect_true(dryad_vignette_live())
  expect_false(identical(dryad_cache_dir(), before))
  expect_match(basename(dryad_cache_dir()), "^dryaddata-vignette-")
})
