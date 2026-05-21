# check_id rejects bad input

    Code
      check_id(-1, "version_id")
    Condition
      Error:
      ! `version_id` must be a non-negative integer id.

---

    Code
      check_id(c(1, 2), "version_id")
    Condition
      Error:
      ! `version_id` must be a single non-missing id.

