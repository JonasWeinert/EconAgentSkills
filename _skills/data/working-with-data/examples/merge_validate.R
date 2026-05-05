# merge_validate.R
# ---------------------------------------------------------------
# dplyr joins with explicit anti-join inspection and key-uniqueness
# assertions. Equivalent in spirit to Stata's merge ... assert(match)
# and pandas' validate=.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
})

merge_with_validation <- function(master, using, by, how = "left") {
  stopifnot(!anyDuplicated(master[, by]),
            !anyDuplicated(using[, by]),
            !any(is.na(master[, by])),
            !any(is.na(using[, by])))

  only_master <- anti_join(master, using, by = by)
  only_using  <- anti_join(using, master, by = by)
  message(sprintf("[%s join on %s] both>=%d, only_master=%d, only_using=%d",
                  how,
                  paste(by, collapse = "+"),
                  min(nrow(master), nrow(using)),
                  nrow(only_master), nrow(only_using)))

  out <- switch(
    how,
    "inner" = inner_join(master, using, by = by),
    "left"  = left_join(master,  using, by = by),
    "right" = right_join(master, using, by = by),
    "full"  = full_join(master,  using, by = by),
    stop(sprintf("Unknown join: %s", how))
  )

  stopifnot(!anyDuplicated(out[, by]))
  out
}

# Demo on synthetic data
master <- tibble::tibble(
  hhid    = c(1, 2, 3, 4, 5),
  region  = c("N", "N", "S", "S", "E"),
  treated = c(0, 1, 0, 1, 0)
)

using <- tibble::tibble(
  hhid       = c(1, 2, 3, 4, 6),
  outcome_y  = c(1.2, 1.4, 0.9, 1.1, 0.7)
)

out <- merge_with_validation(master, using, by = "hhid", how = "left")
print(out)
