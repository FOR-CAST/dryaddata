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
#'
#' @return Absolute path to the downloaded file (or, with `unzip = TRUE`,
#'   to the directory of extracted contents), invisibly.
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
#' }
#' @export
dryad_download_dataset <- function(doi, path = NULL, overwrite = FALSE, unzip = FALSE) {
  doi <- normalize_doi(doi)
  encoded <- utils::URLencode(doi, reserved = TRUE)
  path <- path %||% file.path(download_cache_dir("datasets"), paste0(safe_filename(doi), ".zip"))
  download_endpoint(
    api_path = paste0("datasets/", encoded, "/download"),
    path = path,
    overwrite = overwrite,
    unzip = unzip
  )
}

#' @rdname dryad_download_dataset
#' @export
dryad_download_version <- function(version_id, path = NULL, overwrite = FALSE, unzip = FALSE) {
  id <- check_id(version_id, "version_id")
  path <- path %||% file.path(download_cache_dir("versions"), paste0("version-", id, ".zip"))
  download_endpoint(
    api_path = paste0("versions/", id, "/download"),
    path = path,
    overwrite = overwrite,
    unzip = unzip
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
