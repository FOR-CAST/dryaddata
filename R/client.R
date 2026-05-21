## Internal HTTP plumbing built on httr2.
##
## - `dryad_request()` builds a base request for a path under the active API
##   base URL, with sane defaults (Accept JSON, throttling, retries, on-disk
##   response cache, classed error handler, package user-agent).
## - `dryad_perform_json()` performs the request and decodes the JSON body
##   into an R list.
## - `dryad_perform_file()` writes the response body to a file path.

DRYAD_USER_AGENT <- function() {
  paste0(
    "dryaddata/",
    utils::packageVersion("dryaddata"),
    " (+https://github.com/FOR-CAST/dryaddata)"
  )
}

dryad_request <- function(path, query = list(), authenticate = FALSE, base_url = dryad_base_url()) {
  url <- if (grepl("^https?://", path)) {
    path
  } else if (startsWith(path, "/")) {
    ## Host-relative (as returned in HAL `_links.next.href`).
    host <- sub("^(https?://[^/]+).*$", "\\1", base_url)
    paste0(host, path)
  } else {
    paste0(sub("/+$", "", base_url), "/", path)
  }
  ## Attach query params by manual string concatenation rather than
  ## `httr2::req_url_query()`. The latter parses then rebuilds the URL,
  ## decoding `%2F` in DOI-bearing paths back to `/` and breaking routing.
  if (length(query)) {
    query <- query[!vapply(query, is.null, logical(1))]
    if (length(query)) {
      pairs <- vapply(
        seq_along(query),
        function(i) {
          paste0(
            utils::URLencode(names(query)[i], reserved = TRUE),
            "=",
            utils::URLencode(as.character(query[[i]]), reserved = TRUE)
          )
        },
        character(1)
      )
      sep <- if (grepl("\\?", url)) "&" else "?"
      url <- paste0(url, sep, paste(pairs, collapse = "&"))
    }
  }
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, DRYAD_USER_AGENT())
  req <- httr2::req_headers(req, Accept = "application/json")
  rate <- if (authenticate) 240 / 60 else 30 / 60
  req <- httr2::req_throttle(req, rate = rate, realm = base_url)
  req <- httr2::req_retry(
    req,
    max_tries = 3L,
    retry_on_failure = TRUE,
    is_transient = is_transient_dryad
  )
  req <- httr2::req_error(req, body = dryad_error_body)
  if (authenticate) {
    req <- httr2::req_auth_bearer_token(req, dryad_token())
  } else {
    cache <- http_cache_dir()
    req <- httr2::req_cache(req, path = cache, use_on_error = TRUE, debug = FALSE)
  }
  req
}

dryad_perform_json <- function(req) {
  resp <- httr2::req_perform(req)
  type <- httr2::resp_content_type(resp)
  if (!grepl("json", type, fixed = TRUE)) {
    cli::cli_abort("Expected a JSON response but got {.val {type}} from {.url {resp$url}}.")
  }
  body <- httr2::resp_body_string(resp)
  jsonlite::fromJSON(body, simplifyVector = FALSE, simplifyDataFrame = FALSE)
}

dryad_perform_file <- function(req, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  resp <- httr2::req_perform(req, path = path)
  ## Real responses are written directly to `path` by httr2 and have an
  ## empty in-memory body. Mocked responses (used in tests) keep the body
  ## in memory; in that case write it to `path` here instead.
  if (!file.exists(path) && length(resp$body) > 0L) {
    writeBin(resp$body, path)
  }
  path
}

is_transient_dryad <- function(resp) {
  status <- httr2::resp_status(resp)
  status == 429L || status >= 500L
}

dryad_error_body <- function(resp) {
  status <- httr2::resp_status(resp)
  msg <- tryCatch(
    {
      body <- httr2::resp_body_json(resp, check_type = FALSE)
      body$error %||% body$message %||% NULL
    },
    error = function(e) NULL
  )
  if (is.null(msg)) {
    msg <- httr2::resp_status_desc(resp)
  }
  c(paste0("Dryad API request failed (HTTP ", status, ")."), "i" = msg)
}
