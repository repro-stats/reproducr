# Breaking changes database for reproducr
#
# Each entry documents a known case where a package update changed the
# *behaviour* of a function in a way that can silently alter analytical
# results without producing an error or warning.
#
# Schema per entry:
#   from_version : character  — last "safe" version (exclusive lower bound)
#   to_version   : character  — last version where the risk applies (inclusive upper bound)
#   risk         : character  — "high" | "medium" | "low"
#                   high   = output values can change silently
#                   medium = argument renamed/deprecated; may error or change output
#                   low    = minor behavioural note; output unlikely to differ
#   description  : character  — plain-English explanation for the user
#   reference    : character  — URL to official changelog / NEWS entry
#   closed       : logical    — TRUE if the window is intentionally closed (skipped by
#                               check_db_staleness(); used for historical base R changes)
#   closed_reason: character  — explanation of why the window was deliberately closed
#
# To contribute: add entries following this schema and open a PR.
# Keys are "pkg::fn" strings matching qualified call detection in audit_script().
#
# ---- Version window design principles ----------------------------------------
#
# Each entry uses a half-open interval (from_version, to_version]:
#
#   A call is flagged only if:
#     installed version > from_version  AND  installed version <= to_version
#
# The window should close when the ecosystem has moved on. A breaking change
# is only an ACTIVE risk if users might realistically be comparing results
# produced by versions on DIFFERENT SIDES of the change. Once the entire
# R community has moved past the breaking version, the flag becomes noise.
#
# Rules for setting to_version:
#
#   1. PERMANENT PACKAGE CHANGES (e.g. dplyr 1.1.0 summarise grouping):
#      Keep the window open with a high ceiling (e.g. "1.1.9" or "9.9.9")
#      because any user upgrading from before to after the change is at risk.
#      Close the window only if a future version reverts or compensates.
#
#   2. HISTORICAL BASE R CHANGES (e.g. R 3.6.0 RNG, R 4.0.0 hclust):
#      Close the window at the patch series where the change occurred.
#      Example: R 3.6.0 RNG change -> to_version = "3.6.9"
#      Rationale: by 2024+, all active R users are on R >= 4.x and are
#      all on the same side of the change. Flagging them is a false positive.
#      The risk only applies to teams actively comparing output between
#      R <= 3.5 and R >= 3.6, which is rare in modern practice.
#      Mark these entries with closed = TRUE so check_db_staleness() skips them.
#
#   3. TRANSITIONAL CHANGES (e.g. readr 2.0 backend switch):
#      Set to_version to the last version of the new behaviour's adoption
#      period. If the new behaviour is now universal, close the window.
#
# Examples:
#   R 3.6.0 RNG    -> from = "3.5.99", to = "3.6.9",  closed = TRUE
#   R 4.0.0 hclust -> from = "3.6.99", to = "4.0.9",  closed = TRUE
#   dplyr summarise -> from = "1.0.99", to = "1.2.9"  (window stays open)
#   readr read_csv  -> from = "1.4.99", to = "2.2.9"  (window stays open)
#
# When in doubt, prefer a narrower window. A missed flag is better than
# a false positive that erodes trust in the tool.
# ------------------------------------------------------------------------------

.BREAKING_CHANGES_DB <- list(

  # ---- broom ---------------------------------------------------------------

  "broom::tidy" = list(
    list(
      from_version = "0.7.99",
      to_version   = "1.0.9",
      risk         = "medium",
      description  = paste0(
        "In broom 0.8.0, tidy() renamed columns for several model ",
        "types (e.g. 'statistic' became 'z' for glm). Code selecting ",
        "columns by name from tidy() output will silently select ",
        "wrong columns or error."
      ),
      reference = "https://broom.tidymodels.org/news/index.html"
    )
  ),

  # ---- caret ---------------------------------------------------------------

  "caret::train" = list(
    list(
      from_version = "6.0.99",
      to_version   = "7.0.9",
      risk         = "medium",
      description  = paste0(
        "In caret 7.0.0, the train() function underwent significant ",
        "interface changes including updated default resampling methods ",
        "and model tuning behaviour. Results from caret 6.x models may ",
        "not replicate exactly under caret 7.x without pinning the ",
        "version and resampling seed."
      ),
      reference = "https://cran.r-project.org/web/packages/caret/news/news.html"
    )
  ),

  # ---- data.table ----------------------------------------------------------

  "data.table::fread" = list(
    list(
      from_version = "1.13.99",
      to_version   = "1.18.9",
      risk         = "medium",
      description  = paste0(
        "In data.table 1.14.0, fread() improved column type detection, ",
        "which may cause some columns to parse differently. Specify ",
        "colClasses explicitly to guarantee consistent ingestion across ",
        "versions."
      ),
      reference = "https://github.com/Rdatatable/data.table/blob/master/NEWS.md"
    )
  ),

  "data.table::melt" = list(
    list(
      from_version = "1.13.99",
      to_version   = "1.18.9",
      risk         = "low",
      description  = paste0(
        "In data.table 1.14.0, melt() changed the default class of the ",
        "'variable' column from factor to character. Code that uses ",
        "factor levels from the variable column will silently fail or ",
        "produce different orderings."
      ),
      reference = "https://github.com/Rdatatable/data.table/blob/master/NEWS.md"
    )
  ),

  # ---- dplyr ---------------------------------------------------------------

  "dplyr::across" = list(
    list(
      from_version = "1.0.99",
      to_version   = "1.2.9",
      risk         = "medium",
      description  = paste0(
        "In dplyr 1.1.0, across() changed column naming when .names ",
        "uses the {col}_{fn} pattern with multiple functions. The ",
        "function label changed from the function name to the ",
        "list-element name. Column names in output data frames may ",
        "differ silently."
      ),
      reference = "https://dplyr.tidyverse.org/news/index.html#dplyr-110"
    )
  ),

  "dplyr::filter" = list(
    list(
      from_version = "0.8.99",
      to_version   = "1.2.9",
      risk         = "medium",
      description  = paste0(
        "In dplyr 1.0.0, filter() began issuing warnings (later errors) ",
        "when passed list inputs or non-logical vectors. Code using ",
        "filter() with indirect conditions may silently return wrong rows ",
        "or now error."
      ),
      reference = "https://dplyr.tidyverse.org/news/index.html#dplyr-100"
    )
  ),

  "dplyr::mutate" = list(
    list(
      from_version = "1.0.99",
      to_version   = "1.2.9",
      risk         = "low",
      description  = paste0(
        "In dplyr 1.1.0, mutate() gained a .by argument as an ",
        "alternative to group_by(). Existing code is unaffected, but ",
        "per-operation grouping via .by does not retain grouping in the ",
        "result."
      ),
      reference = "https://dplyr.tidyverse.org/news/index.html#dplyr-110"
    )
  ),

  "dplyr::summarise" = list(
    list(
      from_version = "1.0.99",
      to_version   = "1.2.9",
      risk         = "high",
      description  = paste0(
        "In dplyr 1.1.0, summarise() changed its default grouping ",
        "behaviour: it now drops the last grouping level and returns an ",
        "ungrouped data frame by default (.groups = 'drop_last'). Code ",
        "that relied on the result being grouped will produce silently ",
        "different results."
      ),
      reference = "https://dplyr.tidyverse.org/news/index.html#dplyr-110"
    )
  ),

  "dplyr::summarize" = list(
    list(
      from_version = "1.0.99",
      to_version   = "1.2.9",
      risk         = "high",
      description  = paste0(
        "In dplyr 1.1.0, summarize() changed its default grouping ",
        "behaviour: it now drops the last grouping level by default ",
        "(.groups = 'drop_last'). Code relying on retained grouping ",
        "structure will produce different results."
      ),
      reference = "https://dplyr.tidyverse.org/news/index.html#dplyr-110"
    )
  ),

  # ---- ggplot2 -------------------------------------------------------------

  "ggplot2::aes" = list(
    list(
      from_version = "3.4.99",
      to_version   = "4.0.9",
      risk         = "medium",
      description  = paste0(
        "In ggplot2 3.5.0, aes() tightened evaluation rules. Bare column ",
        "names that previously resolved from the global environment now ",
        "require explicit scoping. Code using non-standard evaluation ",
        "patterns outside data may silently drop aesthetics or error."
      ),
      reference = "https://ggplot2.tidyverse.org/news/index.html"
    )
  ),

  "ggplot2::geom_histogram" = list(
    list(
      from_version = "3.3.99",
      to_version   = "4.0.9",
      risk         = "low",
      description  = paste0(
        "In ggplot2 3.4.0, geom_histogram() improved its default binwidth ",
        "selection algorithm. Visual output (bin boundaries, counts per bin) ",
        "may differ slightly from earlier versions when binwidth is not ",
        "specified."
      ),
      reference = "https://ggplot2.tidyverse.org/news/index.html"
    )
  ),

  "ggplot2::scale_colour_continuous" = list(
    list(
      from_version = "3.3.99",
      to_version   = "4.0.9",
      risk         = "low",
      description  = paste0(
        "In ggplot2 3.4.0, the default continuous colour scale changed ",
        "from a blue gradient to a viridis-based scale. Saved plots and ",
        "reports generated after upgrading will use different colours."
      ),
      reference = "https://ggplot2.tidyverse.org/news/index.html"
    )
  ),

  # ---- lme4 ----------------------------------------------------------------

  "lme4::lmer" = list(
    list(
      from_version = "1.1.28",
      to_version   = "2.0.9",
      risk         = "low",
      description  = paste0(
        "Between lme4 1.1.29 and 1.1.30, default optimizer tolerances were ",
        "adjusted. Borderline models may converge to slightly different ",
        "parameter estimates. Results are typically equivalent within ",
        "rounding, but exact reproduction requires pinning the lme4 version."
      ),
      reference = "https://cran.r-project.org/web/packages/lme4/news/news.html"
    )
  ),

  # ---- lubridate -----------------------------------------------------------

  "lubridate::period" = list(
    list(
      from_version = "1.8.99",
      to_version   = "1.9.9",
      risk         = "medium",
      description  = paste0(
        "In lubridate 1.9.0, period() and duration arithmetic revised ",
        "timezone and DST handling. Date calculations that span ",
        "daylight-saving boundaries may return different results."
      ),
      reference = "https://lubridate.tidyverse.org/news/index.html"
    )
  ),

  "lubridate::ymd" = list(
    list(
      from_version = "1.8.99",
      to_version   = "1.9.9",
      risk         = "low",
      description  = paste0(
        "In lubridate 1.9.0, date-parsing functions (ymd, mdy, dmy, etc.) ",
        "improved handling of ambiguous formats. Previously silently-parsed ",
        "dates may now fail or parse differently."
      ),
      reference = "https://lubridate.tidyverse.org/news/index.html"
    )
  ),

  # ---- purrr ---------------------------------------------------------------

  "purrr::map" = list(
    list(
      from_version = "0.3.99",
      to_version   = "1.2.9",
      risk         = "medium",
      description  = paste0(
        "In purrr 1.0.0, map() changed error handling: it now errors on ",
        "missing elements and .default was removed. Code relying on silent ",
        "NULL returns for missing elements will now fail or produce ",
        "different results."
      ),
      reference = "https://purrr.tidyverse.org/news/index.html"
    )
  ),

  "purrr::map_df" = list(
    list(
      from_version = "0.3.99",
      to_version   = "1.2.9",
      risk         = "medium",
      description  = paste0(
        "In purrr 1.0.0, map_df() was soft-deprecated in favour of ",
        "map() |> list_rbind(). Behaviour may differ for edge cases ",
        "involving NULL elements or varying column structures."
      ),
      reference = "https://purrr.tidyverse.org/news/index.html"
    )
  ),

  # ---- readr ---------------------------------------------------------------

  "readr::read_csv" = list(
    list(
      from_version = "1.4.99",
      to_version   = "2.2.9",
      risk         = "high",
      description  = paste0(
        "In readr 2.0.0, read_csv() switched from a custom parser to the ",
        "vroom backend. Column type guessing improved but changed: previously ",
        "numeric columns may now parse as character (or vice versa) depending ",
        "on the data. Always specify col_types explicitly for reproducible ",
        "ingestion."
      ),
      reference = "https://readr.tidyverse.org/news/index.html"
    )
  ),

  "readr::read_tsv" = list(
    list(
      from_version = "1.4.99",
      to_version   = "2.2.9",
      risk         = "high",
      description  = paste0(
        "In readr 2.0.0, read_tsv() switched to the vroom backend. Column ",
        "type guessing changed; results may differ. Specify col_types ",
        "explicitly."
      ),
      reference = "https://readr.tidyverse.org/news/index.html"
    )
  ),

  # ---- rstan ---------------------------------------------------------------

  "rstan::extract" = list(
    list(
      from_version = "2.17.99",
      to_version   = "2.32.9",
      risk         = "medium",
      description  = paste0(
        "rstan::extract() defaults to permuted = TRUE, which merges and ",
        "randomly permutes draws from all chains before returning them. ",
        "Code that relies on draw order for convergence diagnostics, ",
        "sequential analysis, or reproducible posterior summaries will ",
        "produce different results across runs without explicit ",
        "permuted = FALSE. Always specify the permuted argument explicitly."
      ),
      reference = "https://mc-stan.org/rstan/reference/stanfit-method-extract.html"
    )
  ),

  "rstan::stan" = list(
    list(
      from_version = "2.21.99",
      to_version   = "2.32.9",
      risk         = "high",
      description  = paste0(
        "In rstan 2.26, Stan introduced a new array declaration syntax. ",
        "The old syntax (e.g. 'real x[N]') is deprecated and removed in ",
        "Stan 2.33. Models compiled with rstan < 2.26 using old syntax may ",
        "fail to compile or produce unexpected results with rstan >= 2.26. ",
        "Update Stan model code to the new array syntax: 'array[N] real x'."
      ),
      reference = "https://mc-stan.org/docs/reference-manual/postfix-brackets-array-syntax.html"
    )
  ),

  # ---- stats / base R ------------------------------------------------------
  # NOTE: These entries are marked closed = TRUE because the version windows
  # are deliberately narrow — the changes are historical and all active R users
  # are on the same side of them. check_db_staleness() skips closed entries.

  "stats::hclust" = list(
    list(
      from_version = "3.6.99",
      to_version   = "4.0.9",
      risk         = "high",
      description  = paste0(
        "In R 4.0.0, hclust() changed its tie-breaking rule for equal ",
        "distances. Dendrograms for datasets with tied distance values will ",
        "differ between R 3.x and R 4.x."
      ),
      reference = "https://cran.r-project.org/doc/manuals/r-release/NEWS.html",
      closed       = TRUE,
      closed_reason = paste0(
        "Window deliberately closed at R 4.0.9. All active R users are on ",
        "R >= 4.x and on the same side of this change."
      )
    )
  ),

  "stats::rbinom" = list(
    list(
      from_version = "3.5.99",
      to_version   = "3.6.9",
      risk         = "high",
      description  = paste0(
        "In R 3.6.0, RNG defaults changed. Results from rbinom() with the ",
        "same seed will differ between R <= 3.5 and R >= 3.6."
      ),
      reference = "https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html",
      closed       = TRUE,
      closed_reason = paste0(
        "Window deliberately closed at R 3.6.9. All active R users are on ",
        "R >= 4.x and on the same side of the R 3.6.0 RNG change."
      )
    )
  ),

  "stats::rnorm" = list(
    list(
      from_version = "3.5.99",
      to_version   = "3.6.9",
      risk         = "high",
      description  = paste0(
        "In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() ",
        "with the same seed will differ between R <= 3.5 and R >= 3.6."
      ),
      reference = "https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html",
      closed       = TRUE,
      closed_reason = paste0(
        "Window deliberately closed at R 3.6.9. All active R users are on ",
        "R >= 4.x and on the same side of the R 3.6.0 RNG change."
      )
    )
  ),

  "stats::runif" = list(
    list(
      from_version = "3.5.99",
      to_version   = "3.6.9",
      risk         = "high",
      description  = paste0(
        "In R 3.6.0, RNG defaults changed. Stochastic output from runif() ",
        "with the same seed will differ between R <= 3.5 and R >= 3.6. Use ",
        "set.seed() with explicit kind argument for stable results."
      ),
      reference = "https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html",
      closed       = TRUE,
      closed_reason = paste0(
        "Window deliberately closed at R 3.6.9. All active R users are on ",
        "R >= 4.x and on the same side of the R 3.6.0 RNG change."
      )
    )
  ),

  "stats::sample" = list(
    list(
      from_version = "3.5.99",
      to_version   = "3.6.9",
      risk         = "high",
      description  = paste0(
        "In R 3.6.0, the default RNG algorithm for sample() changed ",
        "(sample.kind = 'Rejection' replaced 'Rounding'). Results produced ",
        "with the same seed in R <= 3.5 will differ in R >= 3.6. Use ",
        "set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') ",
        "for explicit reproducibility."
      ),
      reference = "https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html",
      closed       = TRUE,
      closed_reason = paste0(
        "Window deliberately closed at R 3.6.9. All active R users are on ",
        "R >= 4.x and on the same side of the R 3.6.0 RNG change."
      )
    )
  ),

  # ---- stringr -------------------------------------------------------------

  "stringr::str_c" = list(
    list(
      from_version = "1.4.99",
      to_version   = "1.6.9",
      risk         = "high",
      description  = paste0(
        "In stringr 1.5.0, str_c() changed NA handling to match base ",
        "paste(): str_c('a', NA) now returns NA instead of 'aNa'. Code ",
        "that relied on the old behaviour to build strings containing 'NA' ",
        "will silently produce different (NA-propagating) results."
      ),
      reference = "https://stringr.tidyverse.org/news/index.html"
    )
  ),

  # ---- tidyr ---------------------------------------------------------------

  "tidyr::nest" = list(
    list(
      from_version = "0.8.99",
      to_version   = "1.3.9",
      risk         = "high",
      description  = paste0(
        "In tidyr 1.0.0, nest() changed its interface: the by_ argument was ",
        "replaced with a tidyselect interface. Old code using ",
        "nest(data, by_col) will either error or silently nest by the wrong ",
        "columns."
      ),
      reference = "https://tidyr.tidyverse.org/news/index.html"
    )
  ),

  "tidyr::pivot_wider" = list(
    list(
      from_version = "1.1.99",
      to_version   = "1.3.9",
      risk         = "medium",
      description  = paste0(
        "In tidyr 1.2.0, pivot_wider() changed its handling of duplicate ",
        "identifier rows: it now errors by default (values_fn = NULL) instead ",
        "of silently selecting the last value. Analyses with duplicated keys ",
        "will now fail rather than producing quietly incorrect wide tables."
      ),
      reference = "https://tidyr.tidyverse.org/news/index.html"
    )
  ),

  "tidyr::unnest" = list(
    list(
      from_version = "0.8.99",
      to_version   = "1.3.9",
      risk         = "medium",
      description  = paste0(
        "In tidyr 1.0.0, unnest() was rewritten. The old interface (passing ",
        "multiple columns positionally) changed; .drop and .id arguments were ",
        "removed. Code using the old unnest() API may silently change ",
        "structure."
      ),
      reference = "https://tidyr.tidyverse.org/news/index.html"
    )
  )

)

# ---- internal helpers -------------------------------------------------------

#' List all keys in the breaking-changes database
#' @noRd
.list_db_keys <- function() names(.BREAKING_CHANGES_DB)

#' Get breaking-change entries for a pkg::fn key
#' @noRd
.get_breaking_changes <- function(key) .BREAKING_CHANGES_DB[[key]]