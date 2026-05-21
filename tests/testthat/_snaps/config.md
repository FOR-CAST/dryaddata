# dryad_use_sandbox rejects non-logical input

    Code
      dryad_use_sandbox("yes")
    Condition
      Error in `dryad_use_sandbox()`:
      ! `sandbox` must be a single `TRUE` or `FALSE`.

# setter validates inputs

    Code
      dryad_base_url("")
    Condition
      Error in `dryad_base_url()`:
      ! `url` must be a non-empty character string.

---

    Code
      dryad_base_url(c("a", "b"))
    Condition
      Error in `dryad_base_url()`:
      ! `url` must be a non-empty character string.

