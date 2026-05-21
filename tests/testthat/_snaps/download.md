# on_too_large = 'error' surfaces the verbatim plain-text body

    Code
      dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest, on_too_large = "error")
    Condition
      Error in `httr2::req_perform()`:
      ! HTTP 405 Method Not Allowed.
      Dryad API request failed (HTTP 405).
      The dataset is too large for zip file generation. Please download each file individually.
      Use `dryad_version_files()` to list files and `dryad_download_file()` to fetch them individually.

# JSON API error bodies use the error/message field

    Code
      dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest)
    Condition
      Error in `httr2::req_perform()`:
      ! HTTP 401 Unauthorized.
      Dryad API request failed (HTTP 401).
      Unauthorized, must have current bearer token

# non-'too large' 405 responses are not intercepted

    Code
      dryad_download_dataset("doi:10.5061/dryad.j1fd7", path = dest)
    Condition
      Error in `httr2::req_perform()`:
      ! HTTP 405 Method Not Allowed.
      Dryad API request failed (HTTP 405).
      Some unrelated 405 reason.

