## HAL (Hypertext Application Language) helpers for Dryad list responses.
##
## Dryad list endpoints return:
##   { _links: {self, first, last, next, prev}, count, total,
##     _embedded: { "stash:datasets": [ ... ] } }
##
## `extract_records()` pulls out the list under `_embedded` regardless of the
## CURIE name. `paginate_all()` follows `_links.next` until exhausted.

extract_records <- function(payload, what = NULL) {
  emb <- payload[["_embedded"]]
  if (is.null(emb)) {
    return(list())
  }
  if (!is.null(what)) {
    rec <- emb[[what]] %||% emb[[paste0("stash:", what)]]
    if (is.null(rec)) {
      ## try to find any name matching the resource (case-insensitive endsWith)
      key <- grep(paste0(what, "$"), names(emb), value = TRUE, ignore.case = TRUE)
      if (length(key)) rec <- emb[[key[[1L]]]]
    }
    return(rec %||% list())
  }
  ## Fallback: take the first (typically only) embedded collection.
  emb[[1L]]
}

next_link <- function(payload) {
  nxt <- payload[["_links"]][["next"]][["href"]]
  if (is.null(nxt) || !nzchar(nxt)) {
    return(NULL)
  }
  nxt
}

build_list_result <- function(payload, what, class = NULL) {
  records <- extract_records(payload, what = what)
  records <- ensure_id_column(records)
  out <- list(
    metadata = list(
      count = payload[["count"]],
      total = payload[["total"]],
      links = payload[["_links"]]
    ),
    records = records,
    data = records_to_df(records)
  )
  if (length(class)) {
    class(out) <- c(class, "dryad_list", "list")
  }
  out
}

## Iterate `_links.next` until exhausted. `next_req(href, query)` should return
## an httr2 request for the given absolute URL. Returns a list with combined
## `records` and `data`, plus the metadata block from the *first* page.
paginate_all <- function(first_payload, next_req, what, max_pages = Inf, class = NULL) {
  out_records <- extract_records(first_payload, what)
  payload <- first_payload
  page <- 1L
  while (page < max_pages) {
    nxt <- next_link(payload)
    if (is.null(nxt)) {
      break
    }
    req <- next_req(nxt)
    payload <- dryad_perform_json(req)
    out_records <- c(out_records, extract_records(payload, what))
    page <- page + 1L
  }
  out_records <- ensure_id_column(out_records)
  out <- list(
    metadata = list(
      count = length(out_records),
      total = first_payload[["total"]],
      pages = page,
      links = first_payload[["_links"]]
    ),
    records = out_records,
    data = records_to_df(out_records)
  )
  if (length(class)) {
    class(out) <- c(class, "dryad_list", "list")
  }
  out
}

## Build a `next_req` for a HAL `_links.next.href` (which Dryad returns as a
## host-relative path like `/api/v2/...?page=N`). `dryad_request()` resolves
## absolute, host-relative, and base-relative forms uniformly.
make_next_req <- function(base_url = dryad_base_url(), authenticate = FALSE) {
  function(href) {
    dryad_request(href, authenticate = authenticate, base_url = base_url)
  }
}

## Many Dryad resources (versions, files) omit a top-level `id` field and
## only expose the integer id via `_links.self.href`. Derive it so list
## results carry a usable `id` column. Records that already have `id` are
## left untouched.
ensure_id_column <- function(records) {
  lapply(records, function(r) {
    if (!is.null(r$id)) {
      return(r)
    }
    href <- r[["_links"]][["self"]][["href"]]
    if (is.null(href)) {
      return(r)
    }
    m <- regmatches(href, regexec("/([0-9]+)/?(?:\\?.*)?$", href))[[1]]
    if (length(m) >= 2L) {
      r$id <- as.integer(m[[2L]])
    }
    r
  })
}
