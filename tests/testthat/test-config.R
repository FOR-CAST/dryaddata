test_that("base url and token url respect env and option precedence", {
  withr::local_envvar(DRYAD_BASE_URL = NA, DRYAD_TOKEN_URL = NA)
  withr::local_options(dryaddata.base_url = NULL, dryaddata.token_url = NULL)

  expect_equal(dryad_base_url(), "https://datadryad.org/api/v2")
  expect_equal(dryad_token_url(), "https://datadryad.org/oauth/token")

  withr::local_options(dryaddata.base_url = "https://opt.example/api/v2")
  expect_equal(dryad_base_url(), "https://opt.example/api/v2")

  withr::local_envvar(DRYAD_BASE_URL = "https://env.example/api/v2")
  expect_equal(dryad_base_url(), "https://env.example/api/v2")
})

test_that("dryad_use_sandbox toggles host between sandbox and production", {
  withr::local_envvar(DRYAD_BASE_URL = NA, DRYAD_TOKEN_URL = NA)
  withr::local_options(dryaddata.base_url = NULL, dryaddata.token_url = NULL)

  prev <- dryad_use_sandbox()
  expect_equal(dryad_base_url(), "https://sandbox.datadryad.org/api/v2")
  expect_equal(dryad_token_url(), "https://sandbox.datadryad.org/oauth/token")
  expect_type(prev, "list")
  expect_named(prev, c("base_url", "token_url"))

  dryad_use_sandbox(FALSE)
  expect_equal(dryad_base_url(), "https://datadryad.org/api/v2")
  expect_equal(dryad_token_url(), "https://datadryad.org/oauth/token")
})

test_that("dryad_use_sandbox rejects non-logical input", {
  expect_snapshot(error = TRUE, dryad_use_sandbox("yes"))
})

test_that("setter validates inputs", {
  expect_snapshot(error = TRUE, dryad_base_url(""))
  expect_snapshot(error = TRUE, dryad_base_url(c("a", "b")))
})
