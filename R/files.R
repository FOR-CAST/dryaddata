#' Get metadata for a single Dryad file
#'
#' Wraps `GET /files/{id}`. Use this to look up size, MIME type, checksum,
#' and the human-readable filename before downloading the file with
#' [dryad_download_file()].
#'
#' @param file_id Numeric or character Dryad file id.
#'
#' @return A nested list with the file metadata.
#'
#' @examples
#' \dontrun{
#' dryad_use_sandbox()
#' dryad_file(123456)
#' }
#' @export
dryad_file <- function(file_id) {
  id <- check_id(file_id, "file_id")
  req <- dryad_request(paste0("files/", id))
  out <- dryad_perform_json(req)
  class(out) <- c("dryad_file", "list")
  out
}
