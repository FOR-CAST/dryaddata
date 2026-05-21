# normalize_doi rejects garbage with a clear error

    Code
      normalize_doi("not-a-doi")
    Condition
      Error:
      ! `"not-a-doi"` does not look like a DOI.
      i Got "doi:not-a-doi".

# check_doi rejects nonsense

    Code
      check_doi("not-a-doi")
    Condition
      Error:
      ! `"not-a-doi"` does not look like a DOI.
      i Got "not-a-doi".

