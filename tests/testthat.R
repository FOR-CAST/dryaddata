library(testthat)
library(dryaddata)

# Default to 2 parallel workers (CRAN-friendly) while honoring an explicit
# TESTTHAT_CPUS env var if the developer has set one.
Sys.setenv(TESTTHAT_CPUS = Sys.getenv("TESTTHAT_CPUS", "2"))

test_check("dryaddata")
