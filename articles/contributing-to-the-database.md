# Contributing to the breaking-changes database

The breaking-changes database is the heart of
[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)’s
`"changelog"` check. It is a curated list of cases where a package
update silently changed a function’s *behaviour* — not its interface —
in a way that can alter analytical results without producing an error.

This vignette explains the database schema, how to find good candidates,
how to write an entry, and how to test it before submitting a pull
request.

------------------------------------------------------------------------

## What belongs in the database

A good database entry documents a case where all of the following are
true:

1.  **A specific function in a specific package** changed its output
    between two versions.
2.  The change is **silent** — it does not throw an error or warning on
    the old calling pattern.
3.  The change can **affect analytical conclusions** — not just cosmetic
    differences like whitespace in printed output.
4.  The change is **documented** — there is a `NEWS.md`, GitHub release,
    or official changelog entry you can link to.

### Examples of things that belong

- `dplyr::summarise()` changed its default `.groups` argument in v1.1.0,
  causing grouped data frames to be returned ungrouped where they
  previously were not.
- `stats::sample()` RNG algorithm changed in R 3.6.0, producing
  different random draws for the same seed.
- `readr::read_csv()` switched its parsing backend in v2.0.0, changing
  column type inference.

### Examples of things that do not belong

- A function that **errors** on the old calling pattern after an upgrade
  (that’s a breaking change that produces a visible failure, not a
  silent one).
- A cosmetic change to printed output (e.g. number of decimal places
  shown by `print.lm()`).
- A change that only affects internal implementation with no observable
  difference in returned values.
- Performance changes with no effect on results.

------------------------------------------------------------------------

## The database schema

The database lives in `R/breaking_changes_db.R` as a named list called
`.BREAKING_CHANGES_DB`. Keys are `"pkg::fn"` strings. Each key maps to a
list of entries — one per distinct breaking change for that function:

``` r

.BREAKING_CHANGES_DB <- list(

  "pkg::function_name" = list(
    list(
      from_version = "x.y.z",   # last version where behaviour was "safe"
      to_version   = "x.y.z",   # last version where breaking change applies
      risk         = "high",     # "high", "medium", or "low"
      description  = "...",      # plain-English explanation
      reference    = "https://..." # URL to the changelog entry
    )
  )

)
```

### The version window

The `from_version` and `to_version` fields define a **half-open
interval**:

    (from_version, to_version]
         ↑               ↑
     exclusive        inclusive

A user’s installed version is flagged if and only if:

    installed > from_version  AND  installed <= to_version

**`from_version`** is the last version where the old behaviour still
applied. Set this to one patch version below the first risky version.
For example, if the breaking change was introduced in `1.1.0`, set
`from_version = "1.0.99"`.

**`to_version`** is where careful judgement is required. The window
should close when the ecosystem has moved on. A breaking change is only
an *active* risk if users might realistically be comparing results
produced by versions on different sides of the change. Once the entire R
community has moved past the breaking version, the flag becomes noise
and erodes trust in the tool.

#### Rules for setting `to_version`

**Rule 1 — Permanent package changes** (e.g. `dplyr 1.1.0` `summarise()`
grouping, `readr 2.0.0` backend switch):

Keep the window open with a version ceiling that covers the current
release series. Any user upgrading from before to after the change is at
risk. Close the window only if a future version explicitly reverts or
compensates for the change.

``` r
# dplyr summarise — permanent change, window stays open
from_version = "1.0.99",
to_version   = "1.1.9"
```

**Rule 2 — Historical base R changes** (e.g. R 3.6.0 RNG defaults, R
4.0.0 [`hclust()`](https://rdrr.io/r/stats/hclust.html) tie-breaking):

Close the window at the patch series where the change occurred — not at
a distant future version. By 2024+, all active R users are on R \>= 4.x
and are on the same side of the R 3.6.0 RNG change. Flagging them
produces a false positive. The risk only applies to teams actively
comparing output between old and new R versions.

``` r
# R 3.6.0 RNG change — close window at 3.6.9, not 4.9.9
from_version = "3.5.99",
to_version   = "3.6.9"    # NOT "4.9.9"

# R 4.0.0 hclust change — close window at 4.0.9
from_version = "3.6.99",
to_version   = "4.0.9"    # NOT "4.9.9"
```

**Rule 3 — When in doubt, prefer a narrower window.**

A missed flag is better than a false positive. False positives cause
users to distrust the tool and ignore genuine warnings. If you are
unsure whether a risk is still active, check when the change was
released and whether anyone using a modern R stack could realistically
encounter it.

#### Quick reference

| Change type | `to_version` strategy |
|----|----|
| Permanent package behaviour change | Version ceiling of current series (e.g. `"1.1.9"`) |
| Historical base R change (pre-2020) | Close at the patch series (e.g. `"3.6.9"`) |
| Recent base R change (post-2022) | Keep open with modest ceiling (e.g. `"4.3.9"`) |
| Fixed in a later version | Set to the last affected version exactly |
| Ongoing / never fixed | Set to current series ceiling, revisit periodically |

### Risk levels

| Level | When to use |
|----|----|
| `"high"` | Output *values* change silently — model coefficients, table cells, random draws, sort order. Any result that goes into a paper could be different. |
| `"medium"` | An argument was renamed or deprecated; the function may warn, error, or produce different output depending on the call pattern. Needs manual review. |
| `"low"` | A minor behavioural note. Output is unlikely to differ in practice, but worth knowing. Covers locale sensitivity, cosmetic differences in edge cases, etc. |

------------------------------------------------------------------------

## Finding candidates

### From NEWS.md files

Most CRAN packages maintain a `NEWS.md`. Look for entries mentioning:

- “breaking change”
- “changed default”
- “deprecated”
- “now returns”
- “behaviour changed”
- “no longer”

The tidyverse packages maintain especially detailed changelogs:

- `dplyr`: <https://dplyr.tidyverse.org/news/index.html>
- `tidyr`: <https://tidyr.tidyverse.org/news/index.html>
- `ggplot2`: <https://ggplot2.tidyverse.org/news/index.html>
- `readr`: <https://readr.tidyverse.org/news/index.html>
- `purrr`: <https://purrr.tidyverse.org/news/index.html>
- `stringr`: <https://stringr.tidyverse.org/news/index.html>
- `lubridate`: <https://lubridate.tidyverse.org/news/index.html>

For base R, the R release notes are authoritative:

- <https://cran.r-project.org/doc/manuals/r-release/NEWS.html>

### From your own experience

If you have encountered a case where upgrading a package changed your
results, that is exactly the kind of entry the database needs. Document
it while the details are fresh.

------------------------------------------------------------------------

## Writing an entry

Here is a complete worked example. Suppose you have discovered that
`broom::augment()` changed the name of the residuals column from
`.resid` to `.std.resid` for some model types between versions 0.7.x and
0.8.0.

**Step 1: Verify it is in the changelog.**

Find the relevant `NEWS.md` entry. Copy the URL.

**Step 2: Determine the version window.**

The change was introduced in 0.8.0. The last safe version is 0.7.x.
Set: - `from_version = "0.7.99"` (one patch below the first risky
version) - `to_version = "1.0.9"` (the last version where this applies,
or a high ceiling if unfixed)

**Step 3: Determine the risk level.**

Code that selects the `.resid` column by name from `augment()` output
will silently return `NA` or error after the upgrade, depending on how
selection is done. Categorise as `"medium"` — the calling pattern may
break, but it depends on the code.

**Step 4: Write the description.**

The description should: - State which version the change was introduced
in - Describe the old behaviour - Describe the new behaviour - Explain
the practical consequence for reproducibility

**Step 5: Add the entry.**

Open `R/breaking_changes_db.R` and add your entry in the appropriate
section:

``` r
"broom::augment" = list(
  list(
    from_version = "0.7.99",
    to_version   = "1.0.9",
    risk         = "medium",
    description  = paste0(
      "In broom 0.8.0, augment() renamed residual columns for several model ",
      "types — '.resid' became '.std.resid' for standardised residuals in ",
      "lm and glm objects. Code that selects '.resid' by name from augment() ",
      "output will silently return NA or error after upgrading."
    ),
    reference = "https://broom.tidymodels.org/news/index.html"
  )
),
```

------------------------------------------------------------------------

## Testing your entry

Before submitting, verify that the entry behaves correctly by simulating
a version match:

``` r

# Temporarily add a test entry to verify the detection logic
# (this is what a test in tests/testthat/ would do)

# 1. Write a script that calls the at-risk function
test_script <- tempfile(fileext = ".R")
writeLines("x <- dplyr::summarise(mtcars, n = dplyr::n())", test_script)

# 2. Audit it — package version will be from installed library
report <- audit_script(test_script, renv = FALSE, verbose = FALSE)

# 3. Confirm the call was detected
report$calls[, c("pkg", "fn", "pkg_version")]
#>     pkg        fn pkg_version
#> 1 dplyr summarise        <NA>
#> 2 dplyr         n        <NA>

# 4. Run the changelog check
risks <- risk_score(report, methods = "changelog")

# 5. If the installed version is in the risk window, it will be flagged
if (nrow(risks) > 0) {
  as.data.frame(risks)[, c("call", "pkg_version", "risk", "check")]
} else {
  cat("Installed version is outside the risk window — entry is correct,\n")
  cat("but not triggered by this version.\n")
}
#> Installed version is outside the risk window — entry is correct,
#> but not triggered by this version.
```

To test with a specific version (simulating a user on an older
installation), you can temporarily override the `pkg_version` in the
calls data frame:

``` r

# Force the version to sit inside the dplyr::summarise risk window
report_forced <- report
report_forced$calls$pkg_version <- as.character(report_forced$calls$pkg_version)
report_forced$calls$pkg_version[report_forced$calls$pkg == "dplyr"] <- "1.1.0"

risks_forced <- risk_score(report_forced, methods = "changelog")
as.data.frame(risks_forced)[, c("call", "pkg_version", "risk")]
#>               call pkg_version risk
#> 1 dplyr::summarise       1.1.0 high
#> 2 dplyr::summarise       1.1.0 high
```

------------------------------------------------------------------------

## Submitting a pull request

1.  Fork the repository on GitHub.
2.  Add your entry to `R/breaking_changes_db.R` in the appropriate
    package section (alphabetical order by package name, then by
    function name).
3.  Add a test in `tests/testthat/test-risk_score.R` that confirms:
    - The entry is flagged when the version is inside the risk window.
    - The entry is **not** flagged when the version is outside the
      window.
4.  Update `NEWS.md` with a bullet under
    `# reproducr (development version)`.
5.  Open a pull request with a short description of the breaking change
    and a link to the official changelog.

### Minimum test for a new entry

``` r

test_that("risk_score() flags mypackage::myfun in the risk window", {
  f <- write_script("x <- mypackage::myfun(42)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  # Simulate a version inside the risk window
  r$calls$pkg_version[r$calls$pkg == "mypackage"] <- "2.1.0"

  rs <- risk_score(r, methods = "changelog")
  expect_true(nrow(rs) > 0L)
  expect_true(any(rs$call == "mypackage::myfun"))
})

test_that("risk_score() does NOT flag mypackage::myfun outside the window", {
  f <- write_script("x <- mypackage::myfun(42)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  # Simulate a version before the risk window
  r$calls$pkg_version[r$calls$pkg == "mypackage"] <- "1.9.0"

  rs <- risk_score(r, methods = "changelog")
  myfun_risks <- rs[rs$call == "mypackage::myfun" & rs$check == "changelog", ]
  expect_equal(nrow(myfun_risks), 0L)
})
```

------------------------------------------------------------------------

## Keeping the database current

As packages release new versions, database entries may become stale —
their `to_version` ceiling falls below the current CRAN release.
[`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
detects this automatically:

``` r

library(reproducr)

# Check all tracked packages against CRAN
report <- check_db_staleness()
print(report)
#>
#> -- reproducr database staleness report --
#>
#>   STALE:     1
#>   OK:        24
#>   UNKNOWN:   0
#>
#> Stale entries:
#>
#>   [STALE] dplyr::summarise
#>           to_version=1.1.9 | current=1.2.0
#>
#> Action: review each entry and update to_version in
#>         R/breaking_changes_db.R.

# Check specific packages only
check_db_staleness(packages = c("dplyr", "tidyr"))

# Offline — use installed versions instead of querying CRAN
check_db_staleness(source = "installed")
```

The `reproducr` repository runs
[`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
automatically every Monday via a GitHub Actions workflow and opens an
issue when stale entries are found. If you notice a stale entry, opening
a PR to update `to_version` is a valuable contribution even without
adding a new entry.

When reviewing a stale entry, ask:

- Has the breaking change been **fixed** in the new version? Lower or
  remove the `to_version`.
- Does the breaking change **still apply**? Extend `to_version` to the
  new release series.
- Has the **ecosystem moved on**? Close the window as described in the
  version window design principles above.
