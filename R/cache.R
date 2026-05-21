#' Cache location and maintenance
#'
#' `dryad_cache_dir()` returns (or sets) the on-disk directory the package
#' uses to cache HTTP responses (under `http/`) and downloaded files
#' (under `downloads/{datasets,versions,files}/`). The default is
#' `tools::R_user_dir("dryaddata", "cache")`.
#'
#' Lookup precedence: explicit argument > `DRYADDATA_CACHE_DIR` env var >
#' `dryaddata.cache_dir` option > default.
#'
#' `dryad_cache_info()` returns a per-subtree summary (file count and
#' total bytes), useful for a quick "how big is my cache?" check.
#'
#' `dryad_cache_list()` returns a data frame with one row per cached
#' file (path, subtree, size, mtime). Filter by subtree and use the
#' returned `path` column to inspect, copy, or selectively delete files.
#'
#' `dryad_cache_clear()` deletes cached files. By default it clears every
#' subtree. Pass `what` to target one (`"http"`, `"downloads"`, or one of
#' the download subtypes `"datasets"` / `"versions"` / `"files"`), or
#' pass `files = <character vector>` to remove specific paths. The
#' `files` argument is intersected with the cache root, so a path
#' outside the cache is silently ignored: `dryad_cache_clear()` can
#' never delete a file outside `dryad_cache_dir()`.
#'
#' @param path When supplied to `dryad_cache_dir()`, sets the active cache
#'   directory (creating it if needed) and returns the path invisibly.
#' @param what Which subtree to inspect or clear. One of `"all"`
#'   (default), `"http"`, `"downloads"`, `"datasets"`, `"versions"`,
#'   `"files"`.
#' @param files Optional character vector of file paths to delete from
#'   the cache (typically taken from `dryad_cache_list()$path`). Paths
#'   outside `dryad_cache_dir()` are silently ignored.
#'
#' @return
#'   * `dryad_cache_dir()`: a character scalar (the cache root).
#'   * `dryad_cache_info()`: a data frame: `subtree`, `files`, `bytes`.
#'   * `dryad_cache_list()`: a data frame: `path`, `subtree`, `bytes`,
#'     `mtime`. Empty (0 rows) when nothing is cached.
#'   * `dryad_cache_clear()`: the number of files deleted, invisibly.
#'
#' @examples
#' withr::local_envvar(DRYADDATA_CACHE_DIR = tempfile("dryadcache"))
#' dryad_cache_dir()
#' dryad_cache_info()
#'
#' \dontrun{
#' # After downloading a few things:
#' inv <- dryad_cache_list("datasets")
#' inv[order(-inv$bytes), ]               # biggest first
#'
#' # Drop just the largest cached archive:
#' dryad_cache_clear(files = inv$path[which.max(inv$bytes)])
#'
#' # Or clear an entire subtree:
#' dryad_cache_clear("http")
#' }
#'
#' dryad_cache_clear()
#' @export
dryad_cache_dir <- function(path = NULL) {
  if (!is.null(path)) {
    check_string(path, "path")
    Sys.setenv(DRYADDATA_CACHE_DIR = path)
    options(dryaddata.cache_dir = path)
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    return(invisible(path))
  }
  root <- resolve_setting(
    env = "DRYADDATA_CACHE_DIR",
    opt = "dryaddata.cache_dir",
    default = tools::R_user_dir("dryaddata", "cache")
  )
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  root
}

CACHE_SUBTREES <- c("http", "downloads", "datasets", "versions", "files")

## Map a subtree name to its on-disk directory under the cache root.
cache_subtree_dir <- function(what, root = dryad_cache_dir()) {
  switch(
    what,
    http = file.path(root, "http"),
    downloads = file.path(root, "downloads"),
    datasets = file.path(root, "downloads", "datasets"),
    versions = file.path(root, "downloads", "versions"),
    files = file.path(root, "downloads", "files"),
    cli::cli_abort("Unknown cache subtree {.val {what}}.")
  )
}

## Assign a subtree label to every cached file based on its path relative
## to the cache root.
classify_cache_paths <- function(paths, root = dryad_cache_dir()) {
  rel <- substring(paths, nchar(root) + 2L)
  seg <- strsplit(rel, "/", fixed = TRUE)
  vapply(
    seg,
    function(s) {
      if (length(s) == 0L) {
        return(NA_character_)
      }
      if (s[[1L]] == "http") {
        return("http")
      }
      if (
        s[[1L]] == "downloads" && length(s) >= 2L && s[[2L]] %in% c("datasets", "versions", "files")
      ) {
        return(s[[2L]])
      }
      if (s[[1L]] == "downloads") {
        return("downloads")
      }
      "other"
    },
    character(1)
  )
}

#' @rdname dryad_cache_dir
#' @export
dryad_cache_list <- function(
  what = c("all", "http", "downloads", "datasets", "versions", "files")
) {
  what <- match.arg(what)
  root <- dryad_cache_dir()
  if (!dir.exists(root)) {
    return(empty_cache_listing())
  }
  paths <- list.files(root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  ## Drop the startup-message stamp file; it isn't cached content.
  paths <- paths[basename(paths) != ".last_startup_message"]
  if (!length(paths)) {
    return(empty_cache_listing())
  }
  info <- file.info(paths)
  out <- data.frame(
    path = paths,
    subtree = classify_cache_paths(paths, root),
    bytes = as.numeric(info$size),
    mtime = info$mtime,
    stringsAsFactors = FALSE
  )
  if (what == "all") {
    return(out)
  }
  if (what == "downloads") {
    keep <- out$subtree %in% c("downloads", "datasets", "versions", "files")
  } else {
    keep <- out$subtree == what
  }
  out[keep, , drop = FALSE]
}

empty_cache_listing <- function() {
  data.frame(
    path = character(),
    subtree = character(),
    bytes = numeric(),
    mtime = as.POSIXct(character()),
    stringsAsFactors = FALSE
  )
}

#' @rdname dryad_cache_dir
#' @export
dryad_cache_clear <- function(
  what = c("all", "http", "downloads", "datasets", "versions", "files"),
  files = NULL
) {
  root <- dryad_cache_dir()

  ## `files` arg takes precedence: delete only those paths.
  if (!is.null(files)) {
    if (!is.character(files)) {
      cli::cli_abort("{.arg files} must be a character vector of paths.")
    }
    files <- normalizePath(files, winslash = "/", mustWork = FALSE)
    root_n <- normalizePath(root, winslash = "/", mustWork = FALSE)
    in_cache <- startsWith(files, paste0(root_n, "/")) & file.exists(files)
    skipped <- sum(!in_cache)
    n <- sum(file.remove(files[in_cache]))
    cli::cli_inform(c(
      "v" = "Removed {n} file{?s} from {.path {root}}.",
      if (skipped > 0L) {
        c("i" = "Ignored {skipped} path{?s} outside the cache.")
      }
    ))
    return(invisible(n))
  }

  what <- match.arg(what)
  if (what == "all") {
    targets <- c(file.path(root, "http"), file.path(root, "downloads"))
  } else {
    targets <- cache_subtree_dir(what, root)
  }
  n <- 0L
  for (t in targets) {
    if (dir.exists(t)) {
      tf <- list.files(t, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
      n <- n + sum(file.remove(tf))
      unlink(t, recursive = TRUE)
    }
  }
  cli::cli_inform("Removed {n} cached file{?s} from {.path {root}}.")
  invisible(n)
}

#' @rdname dryad_cache_dir
#' @export
dryad_cache_info <- function() {
  inv <- dryad_cache_list("all")
  ## One row per subtree, in a stable order. Always include the canonical
  ## subtrees even when empty so the output is predictable.
  subs <- c("http", "datasets", "versions", "files")
  do.call(
    rbind,
    lapply(subs, function(s) {
      rows <- inv[inv$subtree == s, , drop = FALSE]
      data.frame(
        subtree = s,
        files = nrow(rows),
        bytes = if (nrow(rows)) sum(rows$bytes) else 0,
        stringsAsFactors = FALSE
      )
    })
  )
}

http_cache_dir <- function() {
  d <- file.path(dryad_cache_dir(), "http")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

download_cache_dir <- function(subtype = c("datasets", "versions", "files")) {
  subtype <- match.arg(subtype)
  d <- file.path(dryad_cache_dir(), "downloads", subtype)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}
