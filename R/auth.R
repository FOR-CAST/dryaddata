## OAuth2 client-credentials authentication for the Dryad API.
##
## Tokens are cached in an internal environment for the lifetime of the R session.
## A token is reused while at least 60 seconds remain before its advertised expiry.
##
## Credentials are looked up in this order:
##   1. Explicit `client_id` / `client_secret` arguments to `dryad_auth()`.
##   2. The `keyring` package (preferred: secrets live in the OS keychain).
##   3. Environment variables `DRYAD_CLIENT_ID` and `DRYAD_CLIENT_SECRET`,
##      typically set in `~/.Renviron`.
##
## The keyring entry uses service `"dryaddata"` and usernames `"client_id"` and
## `"client_secret"`. Use [dryad_set_credentials()] to populate it.

.dryad_token_cache <- new.env(parent = emptyenv())

DRYAD_KEYRING_SERVICE <- "dryaddata"

#' Authenticate against the Dryad API
#'
#' Acquires an OAuth2 access token using the *client credentials* grant and
#' caches it for the rest of the session. Subsequent calls reuse the cached
#' token until it nears expiry, at which point it is refreshed transparently.
#'
#' Credentials are looked up in this order:
#'
#' 1. Explicit `client_id` / `client_secret` arguments.
#' 2. The [keyring](https://r-lib.github.io/keyring/) package, under service
#'    `"dryaddata"` and usernames `"client_id"` / `"client_secret"`. This is
#'    the preferred storage: secrets live in the OS keychain rather than in
#'    a plain-text file on disk. See [dryad_set_credentials()].
#' 3. Environment variables `DRYAD_CLIENT_ID` / `DRYAD_CLIENT_SECRET`,
#'    typically set in `~/.Renviron`. Avoid `Sys.setenv()` in scripts;
#'    those calls land in your command history.
#'
#' The token endpoint is taken from [dryad_token_url()], which respects
#' [dryad_use_sandbox()].
#'
#' You usually do not need to call this function directly: any function that
#' requires authentication (notably the `dryad_download_*()` family) will
#' call it as needed.
#'
#' @param client_id,client_secret OAuth2 application credentials. When `NULL`
#'   (the default), the package looks them up from keyring then environment
#'   variables as described above. Supply directly to override.
#' @param force If `TRUE`, ignore any cached token and request a fresh one.
#'
#' @return Invisibly, a character scalar containing the access token.
#' @seealso [dryad_set_credentials()], [dryad_has_credentials()],
#'   [dryad_clear_token()]
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_auth() # uses keyring or env vars
#' }
#' @export
dryad_auth <- function(client_id = NULL, client_secret = NULL, force = FALSE) {
  client_id <- client_id %||% resolve_credential("client_id", "DRYAD_CLIENT_ID")
  client_secret <- client_secret %||% resolve_credential("client_secret", "DRYAD_CLIENT_SECRET")
  if (
    is.null(client_id) || is.null(client_secret) || !nzchar(client_id) || !nzchar(client_secret)
  ) {
    cli::cli_abort(c(
      "Dryad client credentials are not set.",
      "i" = "Preferred: run {.run dryad_set_credentials()} to store them in your OS keychain.",
      "i" = "Or set {.envvar DRYAD_CLIENT_ID} and {.envvar DRYAD_CLIENT_SECRET} in {.file ~/.Renviron}.",
      "i" = "Create an application at {.url https://datadryad.org/account} (or the sandbox equivalent)."
    ))
  }
  if (!force) {
    tok <- .dryad_token_cache$token
    exp <- .dryad_token_cache$expires_at
    if (!is.null(tok) && !is.null(exp) && exp > (Sys.time() + 60)) {
      return(invisible(tok))
    }
  }
  client <- httr2::oauth_client(
    id = client_id,
    secret = client_secret,
    token_url = dryad_token_url(),
    name = "dryaddata"
  )
  tk <- httr2::oauth_flow_client_credentials(client)
  .dryad_token_cache$token <- tk$access_token
  .dryad_token_cache$expires_at <- Sys.time() + (tk$expires_in %||% 36000)
  invisible(tk$access_token)
}

#' Store, check, and clear Dryad credentials
#'
#' `dryad_set_credentials()` saves your OAuth2 application's `client_id` and
#' `client_secret` in the OS keychain via the
#' [keyring](https://r-lib.github.io/keyring/) package. This is the preferred
#' way to make credentials available to [dryad_auth()]: secrets live in the
#' OS keychain rather than in a plain-text file, and they are unavailable to
#' other R sessions until the keyring is unlocked.
#'
#' `dryad_has_credentials()` reports whether credentials are available
#' (either in keyring or in environment variables). It does **not** unlock
#' or read any secret value, so it never prompts.
#'
#' `dryad_clear_token()` discards any cached access token; the next
#' authenticated call will request a new one. `dryad_clear_credentials()`
#' removes the stored credentials from the OS keychain.
#'
#' @param client_id,client_secret OAuth2 application credentials, as strings.
#'   If either is `NULL`, you will be prompted interactively.
#'
#' @return `dryad_set_credentials()` and `dryad_clear_credentials()` return
#'   `NULL` invisibly. `dryad_has_credentials()` returns `TRUE` / `FALSE`.
#'   `dryad_clear_token()` returns `NULL` invisibly.
#' @seealso [dryad_auth()]
#' @examples
#' dryad_has_credentials()
#' dryad_clear_token()
#'
#' \dontrun{
#' # Interactive; prompts for the values:
#' dryad_set_credentials()
#'
#' # Or non-interactive:
#' dryad_set_credentials("my-client-id", "my-client-secret")
#'
#' dryad_clear_credentials()
#' }
#' @export
dryad_set_credentials <- function(client_id = NULL, client_secret = NULL) {
  if (is.null(client_id)) {
    client_id <- keyring_prompt("Dryad client ID")
  }
  if (is.null(client_secret)) {
    client_secret <- keyring_prompt("Dryad client secret")
  }
  check_string(client_id, "client_id")
  check_string(client_secret, "client_secret")
  keyring::key_set_with_value(DRYAD_KEYRING_SERVICE, username = "client_id", password = client_id)
  keyring::key_set_with_value(
    DRYAD_KEYRING_SERVICE,
    username = "client_secret",
    password = client_secret
  )
  cli::cli_inform(c("v" = "Saved Dryad credentials to the OS keychain."))
  invisible(NULL)
}

#' @rdname dryad_set_credentials
#' @export
dryad_clear_credentials <- function() {
  for (u in c("client_id", "client_secret")) {
    tryCatch(keyring::key_delete(DRYAD_KEYRING_SERVICE, username = u), error = function(e) NULL)
  }
  cli::cli_inform(c("v" = "Removed Dryad credentials from the OS keychain."))
  invisible(NULL)
}

#' @rdname dryad_set_credentials
#' @export
dryad_has_credentials <- function() {
  ## Cheap env-var check first; never prompts.
  if (nzchar(Sys.getenv("DRYAD_CLIENT_ID")) && nzchar(Sys.getenv("DRYAD_CLIENT_SECRET"))) {
    return(TRUE)
  }
  ## Keyring check: only call key_list (cheap); do not unlock to read a value.
  if (isTRUE(getOption("dryaddata.disable_keyring", FALSE))) {
    return(FALSE)
  }
  entries <- tryCatch(keyring::key_list(DRYAD_KEYRING_SERVICE), error = function(e) NULL)
  if (is.null(entries) || !nrow(entries)) {
    return(FALSE)
  }
  all(c("client_id", "client_secret") %in% entries$username)
}

#' @rdname dryad_set_credentials
#' @export
dryad_clear_token <- function() {
  rm(list = ls(.dryad_token_cache), envir = .dryad_token_cache)
  invisible(NULL)
}

## Internal token accessor used by the request builder.
dryad_token <- function() {
  tok <- .dryad_token_cache$token
  exp <- .dryad_token_cache$expires_at
  if (is.null(tok) || is.null(exp) || exp <= (Sys.time() + 60)) {
    tok <- dryad_auth()
  }
  tok
}

## Internal: fetch a credential by name from keyring, falling back to env var.
## Returns NULL when neither source has a non-empty value.
## The `dryaddata.disable_keyring` option (set TRUE in the test suite) skips
## the keyring path entirely as a belt-and-braces safeguard.
resolve_credential <- function(keyring_username, env_var) {
  if (!isTRUE(getOption("dryaddata.disable_keyring", FALSE))) {
    entries <- tryCatch(keyring::key_list(DRYAD_KEYRING_SERVICE), error = function(e) NULL)
    if (!is.null(entries) && keyring_username %in% entries$username) {
      val <- tryCatch(
        keyring::key_get(DRYAD_KEYRING_SERVICE, username = keyring_username),
        error = function(e) NULL
      )
      if (!is.null(val) && nzchar(val)) {
        return(val)
      }
    }
  }
  v <- Sys.getenv(env_var)
  if (nzchar(v)) v else NULL
}

keyring_prompt <- function(label) {
  if (!interactive()) {
    cli::cli_abort("{label} must be supplied (non-interactive session).")
  }
  if (requireNamespace("askpass", quietly = TRUE)) {
    askpass::askpass(paste0(label, ":"))
  } else {
    getPass <- get0("readline", envir = baseenv())
    getPass(paste0(label, ": "))
  }
}
