#' Vignette-build helper
#'
#' Internal hook used by the package's own vignettes (and downstream
#' packages that want the same convention). Returns `TRUE` when calling
#' chunks should evaluate against the live Dryad API and `FALSE` otherwise.
#'
#' A chunk is "live" when:
#'
#' * `DRYADDATA_BUILD_LIVE_VIGNETTES = "true"` is set in the build
#'   environment (opt-in; keeps R CMD check fast and deterministic), AND
#' * `require_credentials = FALSE`, OR [dryad_has_credentials()] reports
#'   `TRUE`.
#'
#' As a side effect, when the result is `TRUE` the on-disk cache is
#' redirected to a fresh `tempfile()` so the vignette build never writes
#' to the user's persistent cache.
#'
#' @param require_credentials Logical. If `TRUE`, additionally requires
#'   OAuth credentials to be available (the downloading vignette uses this).
#'
#' @return A single logical.
#' @keywords internal
#' @export
dryad_vignette_live <- function(require_credentials = FALSE) {
  live <- identical(tolower(Sys.getenv("DRYADDATA_BUILD_LIVE_VIGNETTES")), "true")
  ok <- live && (!require_credentials || dryad_has_credentials())
  if (ok) {
    dryad_cache_dir(tempfile("dryaddata-vignette-"))
  }
  ok
}
