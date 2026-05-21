.onLoad <- function(libname, pkgname) {
  ## Settings (base URL, cache dir, token URL) are resolved lazily through
  ## resolve_setting(); we deliberately do not write to user state at load.
  invisible(NULL)
}

.onAttach <- function(libname, pkgname) {
  if (!interactive() || !should_show_startup_message()) {
    return(invisible(NULL))
  }
  cache <- tryCatch(dryad_cache_dir(), error = function(e) NULL)
  if (is.null(cache)) {
    return(invisible(NULL))
  }
  packageStartupMessage(cli::format_message(c(
    "{.pkg dryaddata} caches responses and downloads in {.path {cache}}.",
    "i" = "Change the location with {.code dryaddata::dryad_cache_dir(\"<path>\")} or by setting {.envvar DRYADDATA_CACHE_DIR}.",
    "i" = "See {.help dryaddata::dryaddata_options} for all options.",
    "i" = "Suppress this message with {.code suppressPackageStartupMessages(library(dryaddata))}."
  )))
  tryCatch(touch_startup_message_stamp(cache), error = function(e) NULL)
  invisible(NULL)
}

## Throttle the startup message to at most once every 8 hours. The stamp is
## a zero-byte file inside the cache root; users who clear or relocate the
## cache will see the message again on the next attach (which is the right
## thing; they're configuring the package fresh).
STARTUP_MESSAGE_INTERVAL_SECS <- 8 * 3600

should_show_startup_message <- function() {
  cache <- tryCatch(dryad_cache_dir(), error = function(e) NULL)
  if (is.null(cache)) {
    return(FALSE)
  }
  stamp <- startup_message_stamp_path(cache)
  if (!file.exists(stamp)) {
    return(TRUE)
  }
  age <- as.numeric(difftime(Sys.time(), file.mtime(stamp), units = "secs"))
  is.finite(age) && age >= STARTUP_MESSAGE_INTERVAL_SECS
}

touch_startup_message_stamp <- function(cache = dryad_cache_dir()) {
  stamp <- startup_message_stamp_path(cache)
  dir.create(dirname(stamp), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(stamp)) {
    file.create(stamp)
  }
  Sys.setFileTime(stamp, Sys.time())
  invisible(stamp)
}

startup_message_stamp_path <- function(cache = dryad_cache_dir()) {
  file.path(cache, ".last_startup_message")
}
