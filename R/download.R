#' Download a Dryad dataset, version, or file
#'
#' These functions download binary content from Dryad and write it to disk.
#' They require a valid OAuth2 bearer token (see [dryad_auth()]); set
#' `DRYAD_CLIENT_ID` and `DRYAD_CLIENT_SECRET` in your environment first.
#'
#' By default the file is written to (and re-read from) the package's
#' download cache (under [dryad_cache_dir()]). Pass `path` to write to an
#' explicit location instead. With `overwrite = FALSE` (the default), an
#' existing destination is returned as-is, with no network call.
#'
#' `dryad_download_dataset()` and `dryad_download_version()` fetch a
#' `application/zip` archive containing all files in the (latest) version
#' or specified version respectively. `dryad_download_file()` fetches the
#' bytes of a single file, using its server-side filename and MIME type.
#'
#' Dryad refuses to generate a single zip for datasets above an internal
#' size limit, returning HTTP 405 with the body
#' `"The dataset is too large for zip file generation."`. When that
#' happens, `dryad_download_dataset()` and `dryad_download_version()`
#' fall back to downloading each file in the version individually into a
#' directory. The fallback behavior is controlled by `on_too_large`: in
#' interactive sessions the default `"ask"` prompts before downloading;
#' in non-interactive sessions it proceeds without prompting. Pass
#' `"files"` to skip the prompt or `"error"` to disable the fallback.
#'
#' @param doi Dataset DOI (any accepted form).
#' @param version_id Numeric or character dataset-version id.
#' @param file_id Numeric or character file id.
#' @param path Destination file path for the downloaded content. Use this
#'   when you need a specific filename or location (a project `data/`
#'   folder, a scratch volume, a `tempfile()`, etc.). When `NULL`
#'   (default), the file is written to a deterministic path inside
#'   [dryad_cache_dir()] and re-used on subsequent calls.
#' @param overwrite If `TRUE`, re-download even if the destination exists.
#' @param unzip If `TRUE` (dataset / version downloads only), the archive
#'   is extracted into a sibling directory and that directory is returned.
#'   Ignored when the per-file fallback runs (see `on_too_large`); files
#'   are then written to the directory directly.
#' @param on_too_large One of `"ask"` (the default), `"files"`, or
#'   `"error"`. Controls what happens when Dryad refuses to generate the
#'   zip because the dataset / version is too large. `"ask"` prompts in
#'   interactive sessions and falls back without prompting otherwise;
#'   `"files"` always falls back to per-file downloads; `"error"` rethrows
#'   the original HTTP error.
#'
#' @return Absolute path to the downloaded file (or, with `unzip = TRUE`
#'   or when the per-file fallback runs, to the directory of downloaded
#'   contents), invisibly.
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#'
#' # 1. Write to a chosen destination. The example uses tempdir() so the
#' #    file is removed when the R session ends; replace it with any path
#' #    you want the file to live at.
#' dest <- file.path(tempdir(), "archiving.zip")
#' zip <- dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest)
#' file.info(zip)$size
#'
#' # 2. Omit `path` to let the package write to its on-disk cache under
#' #    dryad_cache_dir(). A second identical call returns the cached
#' #    path without making a network request.
#' zip2 <- dryad_download_dataset("doi:10.5061/dryad.j1fd7")
#'
#' # 3. A single file written to a chosen destination:
#' csv <- dryad_download_file(94868, path = file.path(tempdir(), "data.csv"))
#'
#' # 4. Skip the interactive prompt and always fall back to per-file
#' #    downloads when the dataset exceeds Dryad's zip size limit.
#' dryad_download_dataset(
#'   "doi:10.5061/dryad.kprr4xhk6",
#'   on_too_large = "files"
#' )
#' }
#' @export
dryad_download_dataset <- function(
  doi,
  path = NULL,
  overwrite = FALSE,
  unzip = FALSE,
  on_too_large = c("ask", "files", "error")
) {
  on_too_large <- rlang::arg_match(on_too_large)
  doi <- normalize_doi(doi)
  encoded <- utils::URLencode(doi, reserved = TRUE)
  path <- path %||% file.path(download_cache_dir("datasets"), paste0(safe_filename(doi), ".zip"))
  with_too_large_fallback(
    expr = download_endpoint(
      api_path = paste0("datasets/", encoded, "/download"),
      path = path,
      overwrite = overwrite,
      unzip = unzip
    ),
    label = doi,
    files_dir = sub("\\.zip$", "", path, ignore.case = TRUE),
    resolve_version_id = function() dataset_latest_version_id(doi),
    overwrite = overwrite,
    on_too_large = on_too_large
  )
}

#' @rdname dryad_download_dataset
#' @export
dryad_download_version <- function(
  version_id,
  path = NULL,
  overwrite = FALSE,
  unzip = FALSE,
  on_too_large = c("ask", "files", "error")
) {
  on_too_large <- rlang::arg_match(on_too_large)
  id <- check_id(version_id, "version_id")
  path <- path %||% file.path(download_cache_dir("versions"), paste0("version-", id, ".zip"))
  with_too_large_fallback(
    expr = download_endpoint(
      api_path = paste0("versions/", id, "/download"),
      path = path,
      overwrite = overwrite,
      unzip = unzip
    ),
    label = paste0("version ", id),
    files_dir = sub("\\.zip$", "", path, ignore.case = TRUE),
    resolve_version_id = function() id,
    overwrite = overwrite,
    on_too_large = on_too_large
  )
}

#' @rdname dryad_download_dataset
#' @export
dryad_download_file <- function(file_id, path = NULL, overwrite = FALSE) {
  id <- check_id(file_id, "file_id")
  if (is.null(path)) {
    meta <- tryCatch(dryad_file(id), error = \(e) NULL)
    name <- meta$path %||% paste0("file-", id)
    path <- file.path(download_cache_dir("files"), id, safe_filename(name))
  }
  download_endpoint(
    api_path = paste0("files/", id, "/download"),
    path = path,
    overwrite = overwrite,
    unzip = FALSE
  )
}

download_endpoint <- function(api_path, path, overwrite, unzip) {
  if (!overwrite && file.exists(path)) {
    cli::cli_inform("Using cached file at {.path {path}}.")
  } else {
    req <- dryad_request(api_path, authenticate = TRUE)
    dryad_perform_file(req, path)
    cli::cli_inform("Downloaded to {.path {path}}.")
  }
  if (isTRUE(unzip)) {
    target <- sub("\\.zip$", "", path, ignore.case = TRUE)
    if (!dir.exists(target) || isTRUE(overwrite)) {
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      utils::unzip(path, exdir = target)
    }
    return(invisible(target))
  }
  invisible(path)
}

safe_filename <- function(x) {
  ## Replace path separators and characters that are not portable on Windows.
  out <- gsub("[\\\\/:*?\"<>|]+", "_", x)
  out <- gsub("\\s+", "_", out)
  sub("^_+", "", sub("_+$", "", out))
}

## Run `expr`, intercepting the "dataset too large" HTTP error and falling
## back to per-file downloads when `on_too_large` allows. `expr` is the raw
## download call; the other arguments describe how to recover.
##
## - label              : human-readable identifier for the dataset / version
##                        used in the prompt / informational messages
## - files_dir          : directory into which fallback files are written
## - resolve_version_id : zero-arg function that returns the version id whose
##                        files should be downloaded (looked up lazily so the
##                        happy path does not pay for an extra request)
## - overwrite          : passed through to per-file downloads
## - on_too_large       : "ask" / "files" / "error"
with_too_large_fallback <- function(
  expr,
  label,
  files_dir,
  resolve_version_id,
  overwrite,
  on_too_large
) {
  if (identical(on_too_large, "error")) {
    return(force(expr))
  }
  tryCatch(force(expr), httr2_http_405 = function(cnd) {
    msg <- tryCatch(error_message_from_resp(cnd$resp), error = function(e) "")
    if (!is_too_large_message(msg)) {
      stop(cnd)
    }
    if (!confirm_too_large_fallback(label, msg, on_too_large)) {
      stop(cnd)
    }
    download_version_files(
      version_id = resolve_version_id(),
      dir = files_dir,
      overwrite = overwrite
    )
  })
}

confirm_too_large_fallback <- function(label, msg, on_too_large) {
  if (identical(on_too_large, "files")) {
    cli::cli_inform(c(
      "i" = "Dryad declined to generate a zip for {.val {label}}: {msg}",
      "i" = "Downloading files individually."
    ))
    return(TRUE)
  }
  ## "ask": prompt interactively, otherwise proceed without prompting.
  if (!rlang::is_interactive()) {
    cli::cli_inform(c(
      "i" = "Dryad declined to generate a zip for {.val {label}}: {msg}",
      "i" = "Non-interactive session; downloading files individually."
    ))
    return(TRUE)
  }
  cli::cli_inform(c("!" = "Dryad declined to generate a zip for {.val {label}}.", "i" = msg))
  ans <- utils::menu(
    choices = c("Download files individually", "Abort"),
    title = "How would you like to proceed?"
  )
  identical(ans, 1L)
}

download_version_files <- function(version_id, dir, overwrite = FALSE) {
  files <- dryad_version_files(version_id, per_page = 100L, all_pages = TRUE)
  if (length(files$records) == 0L) {
    cli::cli_abort("Version {.val {version_id}} has no files to download.")
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  cli::cli_inform(
    "Downloading {length(files$records)} file{?s} from version {.val {version_id}} to {.path {dir}}."
  )
  paths <- character(length(files$records))
  for (i in seq_along(files$records)) {
    rec <- files$records[[i]]
    fid <- rec$id %||% extract_id_from_links(rec)
    if (is.null(fid)) {
      cli::cli_warn("Skipping a file in version {.val {version_id}} with no id.")
      next
    }
    name <- rec$path %||% paste0("file-", fid)
    dest <- file.path(dir, safe_filename(name))
    paths[i] <- dryad_download_file(fid, path = dest, overwrite = overwrite)
  }
  invisible(dir)
}

## Look up the latest version id for a dataset via the dataset metadata's
## HAL `stash:version` link. Falls back to listing versions if that link is
## missing (older datasets may not include it).
dataset_latest_version_id <- function(doi) {
  meta <- dryad_dataset(doi)
  href <- meta[["_links"]][["stash:version"]][["href"]]
  if (!is.null(href)) {
    id <- sub(".*/versions/([0-9]+).*", "\\1", href)
    if (nzchar(id) && id != href) {
      return(id)
    }
  }
  vers <- dryad_dataset_versions(doi, per_page = 100L, all_pages = TRUE)
  if (length(vers$records) == 0L) {
    cli::cli_abort("No versions found for dataset {.val {doi}}.")
  }
  last <- vers$records[[length(vers$records)]]
  id <- last$id %||% extract_id_from_links(last)
  if (is.null(id)) {
    cli::cli_abort("Could not determine the latest version id for {.val {doi}}.")
  }
  as.character(id)
}
