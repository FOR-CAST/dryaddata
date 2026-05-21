#' Dryad host configuration
#'
#' Get or set the API base URL and OAuth2 token URL used by the package.
#' Each accessor returns the current value invisibly when given an argument.
#'
#' Precedence: explicit argument > environment variable > R option > default.
#'
#' @param url A character string. When supplied, sets the active value (both
#'   the corresponding R option and process-level environment variable) and
#'   returns it invisibly. When `NULL`, returns the current value.
#'
#' @return Character scalar.
#'
#' @examples
#' # Switch to the sandbox for the rest of the session.
#' dryad_use_sandbox()
#' dryad_base_url()
#' dryad_token_url()
#'
#' # Or set a custom value (e.g. a local mock server).
#' \dontrun{
#' dryad_base_url("http://localhost:3000/api/v2")
#' }
#' @export
dryad_base_url <- function(url = NULL) {
  if (!is.null(url)) {
    check_string(url, "url")
    Sys.setenv(DRYAD_BASE_URL = url)
    options(dryaddata.base_url = url)
    return(invisible(url))
  }
  resolve_setting(
    env = "DRYAD_BASE_URL",
    opt = "dryaddata.base_url",
    default = "https://datadryad.org/api/v2"
  )
}

#' @rdname dryad_base_url
#' @export
dryad_token_url <- function(url = NULL) {
  if (!is.null(url)) {
    check_string(url, "url")
    Sys.setenv(DRYAD_TOKEN_URL = url)
    options(dryaddata.token_url = url)
    return(invisible(url))
  }
  resolve_setting(
    env = "DRYAD_TOKEN_URL",
    opt = "dryaddata.token_url",
    default = "https://datadryad.org/oauth/token"
  )
}

#' Switch between Dryad's sandbox and production hosts
#'
#' Convenience wrapper that points [dryad_base_url()] and [dryad_token_url()]
#' at Dryad's public sandbox or production deployment in a single call. The
#' sandbox accepts independent credentials and is the right target for
#' development; production is the default.
#'
#' @param sandbox Logical. `TRUE` (default) switches the active host to the
#'   sandbox (`https://sandbox.datadryad.org`); `FALSE` switches back to
#'   production (`https://datadryad.org`).
#'
#' @return Invisibly, a named list with the *previous* `base_url` and
#'   `token_url`, suitable for restoring later via [dryad_base_url()] and
#'   [dryad_token_url()].
#'
#' @examples
#' old <- dryad_use_sandbox()
#' dryad_base_url() # https://sandbox.datadryad.org/api/v2
#' dryad_use_sandbox(FALSE)
#' dryad_base_url() # https://datadryad.org/api/v2
#' # Restore prior values:
#' dryad_base_url(old$base_url)
#' dryad_token_url(old$token_url)
#' @export
dryad_use_sandbox <- function(sandbox = TRUE) {
  if (!is.logical(sandbox) || length(sandbox) != 1L || is.na(sandbox)) {
    cli::cli_abort("{.arg sandbox} must be a single {.code TRUE} or {.code FALSE}.")
  }
  previous <- list(base_url = dryad_base_url(), token_url = dryad_token_url())
  if (sandbox) {
    dryad_base_url("https://sandbox.datadryad.org/api/v2")
    dryad_token_url("https://sandbox.datadryad.org/oauth/token")
  } else {
    dryad_base_url("https://datadryad.org/api/v2")
    dryad_token_url("https://datadryad.org/oauth/token")
  }
  invisible(previous)
}

resolve_setting <- function(env, opt, default) {
  v <- Sys.getenv(env, unset = NA)
  if (!is.na(v) && nzchar(v)) {
    return(v)
  }
  v <- getOption(opt)
  if (!is.null(v) && nzchar(v)) {
    return(v)
  }
  default
}
