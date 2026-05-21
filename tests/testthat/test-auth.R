test_that("dryad_has_credentials reflects environment", {
  withr::local_envvar(DRYAD_CLIENT_ID = NA, DRYAD_CLIENT_SECRET = NA)
  expect_false(dryad_has_credentials())

  withr::local_envvar(DRYAD_CLIENT_ID = "x", DRYAD_CLIENT_SECRET = "y")
  expect_true(dryad_has_credentials())
})

test_that("resolve_credential falls back to env var when keyring is disabled", {
  withr::local_envvar(DRYAD_CLIENT_ID = "from-env")
  withr::local_options(dryaddata.disable_keyring = TRUE)
  resolve_credential <- asNamespace("dryaddata")$resolve_credential
  expect_equal(resolve_credential("client_id", "DRYAD_CLIENT_ID"), "from-env")
})

test_that("resolve_credential returns NULL when nothing is set", {
  withr::local_envvar(DRYAD_CLIENT_ID = NA)
  withr::local_options(dryaddata.disable_keyring = TRUE)
  resolve_credential <- asNamespace("dryaddata")$resolve_credential
  expect_null(resolve_credential("client_id", "DRYAD_CLIENT_ID"))
})


test_that("dryad_auth without credentials errors with guidance", {
  withr::local_envvar(DRYAD_CLIENT_ID = NA, DRYAD_CLIENT_SECRET = NA)
  expect_snapshot(error = TRUE, dryad_auth())
})

test_that("dryad_clear_token empties the token cache", {
  local_dryad_sandbox()
  env <- asNamespace("dryaddata")$.dryad_token_cache
  expect_true(!is.null(env$token))
  dryad_clear_token()
  expect_null(env$token)
})
