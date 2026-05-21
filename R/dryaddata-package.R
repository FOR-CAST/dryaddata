#' dryaddata: Programmatic access to the Dryad data repository
#'
#' A modern R client for the Dryad REST API (version 2). Use it to search
#' datasets, retrieve dataset / version / file metadata, and download data
#' files or full dataset archives. Authenticated downloads use OAuth2 client
#' credentials. Responses and downloads are cached on disk in a user
#' configurable location.
#'
#' @section Quick start:
#' ```r
#' # Point the client at Dryad's sandbox while developing.
#' dryad_use_sandbox()
#'
#' # Free-text search.
#' hits <- dryad_search(q = "carbon", per_page = 5)
#' hits$datasets[, c("identifier", "title")]
#'
#' # Pull metadata for one dataset and list its files.
#' ds  <- dryad_dataset("doi:10.5061/dryad.j1fd7")
#' fls <- dryad_version_files(ds$`_links`$`stash:version`$href)
#' ```
#'
#' @template options
#' @details
#' See [dryaddata_options] for the same listing as a standalone help page,
#' and [dryad_use_sandbox()] for the one-call toggle between Dryad's
#' production and sandbox deployments.
"_PACKAGE"
