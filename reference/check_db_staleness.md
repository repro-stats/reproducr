# Check whether breaking-changes database entries are stale

Compares the `to_version` ceiling and `from_version` floor of each entry
in the breaking-changes database against the current version of that
package on CRAN. Two types of staleness are detected:

- **`stale_ceiling`** – the package has released a new version above the
  `to_version` ceiling. The window may need extending.

- **`stale_floor`** – the current CRAN version is so far ahead of
  `from_version` that the window captures users who are already well
  past the breaking-change transition. The entry may need closing or the
  `from_version` floor raising.

This function is primarily intended for use by `reproducr` maintainers
and contributors. It is also run as a scheduled GitHub Actions workflow
on the `reproducr` repository to automatically open issues when
staleness is detected.

## Usage

``` r
check_db_staleness(
  packages = NULL,
  verbose = TRUE,
  source = "cran",
  from_version_major_threshold = 1L
)

# S3 method for class 'staleness_report'
print(x, details = TRUE, ...)
```

## Arguments

- packages:

  `character` or `NULL`. Package names to check. If `NULL` (the
  default), all packages tracked in the breaking-changes database are
  checked.

- verbose:

  `logical(1)`. Print progress messages. Default `TRUE`.

- source:

  `character(1)`. Where to resolve current package versions. One of:

  `"cran"`

  :   Query the CRAN package database via
      [`utils::available.packages()`](https://rdrr.io/r/utils/available.packages.html).
      Requires an internet connection.

  `"installed"`

  :   Use locally installed versions via
      [`utils::packageDescription()`](https://rdrr.io/r/utils/packageDescription.html).
      Fast and offline, but only reflects what is installed on the
      current machine.

  Default `"cran"`.

- from_version_major_threshold:

  `integer(1)` or `Inf`. Number of full major versions the current CRAN
  release must be *ahead* of `from_version` before the entry is flagged
  as having a stale floor. Set to `Inf` to disable this check. Default
  `1L`.

- x:

  A `staleness_report` object.

- details:

  `logical(1)`. When `TRUE` (the default), renders the full per-entry
  breakdown for stale entries. Set to `FALSE` to print only the summary
  counts.

- ...:

  Additional arguments (currently unused).

## Value

A `data.frame` of class `c("staleness_report", "data.frame")` with one
row per database entry. Columns:

- `key`:

  The `pkg::fn` key.

- `pkg`:

  Package name.

- `fn`:

  Function name.

- `from_version`:

  The floor version currently in the database.

- `to_version`:

  The ceiling version currently in the database.

- `current_version`:

  The current version on CRAN or installed.

- `status`:

  One of `"ok"`, `"stale_ceiling"`, `"stale_floor"`, or `"unknown"`.

- `gap`:

  Description of the version gap. `NA` when status is `"ok"` or
  `"unknown"`.

Rows are ordered: stale_ceiling first, stale_floor second, then ok, then
unknown.

## See also

[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
which uses the database at runtime;
[`vignette("contributing-to-the-database")`](https://repro-stats.github.io/reproducr/articles/contributing-to-the-database.md)
for the database schema and version window design principles.

## Examples

``` r
# \donttest{
# Check all tracked packages against CRAN
report <- check_db_staleness()
#> reproducr: checking 13 package(s) against cran...
#> reproducr: 3 stale ceiling, 10 stale floor, 9 ok, 0 unknown
#> 
#> Stale ceiling entries (to_version below current release):
#>   MatchIt::match.data  [to_version 4.4.9 -> current 4.7.2]
#>   dplyr::group_by  [to_version 1.1.9 -> current 1.2.1]
#>   ggplot2::geom_sf  [to_version 3.4.9 -> current 4.0.3]
#> 
#> Stale floor entries (from_version too old -- window too wide):
#>   dplyr::filter  [from_version 0.8.99 << current 1.2.1 (>= 1 major version(s) behind)]
#>   ggplot2::geom_histogram  [from_version 3.5.99 << current 4.0.3 (>= 1 major version(s) behind)]
#>   ggplot2::scale_colour_continuous  [from_version 3.5.99 << current 4.0.3 (>= 1 major version(s) behind)]
#>   purrr::map_df  [from_version 0.3.99 << current 1.2.2 (>= 1 major version(s) behind)]
#>   readr::read_csv  [from_version 1.4.99 << current 2.2.0 (>= 1 major version(s) behind)]
#>   readr::read_tsv  [from_version 1.4.99 << current 2.2.0 (>= 1 major version(s) behind)]
#>   survival::survfit  [from_version 2.99.99 << current 3.8-6 (>= 1 major version(s) behind)]
#>   tidyr::nest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::pivot_wider  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::unnest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
print(report)
#> 
#> -- reproducr database staleness report --
#> 
#>   STALE CEILING:         3
#>   STALE FLOOR:           10
#>   OK:                    9
#>   UNKNOWN:               0
#> 
#> Stale ceiling entries (to_version below current release):
#> 
#>   [STALE CEILING] MatchIt::match.data
#>     to_version=4.4.9 | current=4.7.2
#>     Action: extend to_version or close entry.
#> 
#>   [STALE CEILING] dplyr::group_by
#>     to_version=1.1.9 | current=1.2.1
#>     Action: extend to_version or close entry.
#> 
#>   [STALE CEILING] ggplot2::geom_sf
#>     to_version=3.4.9 | current=4.0.3
#>     Action: extend to_version or close entry.
#> 
#> Stale floor entries (from_version too old -- window too wide):
#> 
#>   [STALE FLOOR] dplyr::filter
#>     from_version=0.8.99 | current=1.2.1
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] ggplot2::geom_histogram
#>     from_version=3.5.99 | current=4.0.3
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] ggplot2::scale_colour_continuous
#>     from_version=3.5.99 | current=4.0.3
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] purrr::map_df
#>     from_version=0.3.99 | current=1.2.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] readr::read_csv
#>     from_version=1.4.99 | current=2.2.0
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] readr::read_tsv
#>     from_version=1.4.99 | current=2.2.0
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] survival::survfit
#>     from_version=2.99.99 | current=3.8-6
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::nest
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::pivot_wider
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::unnest
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 

# Compact counts-only view
print(report, details = FALSE)
#> 
#> -- reproducr database staleness report --
#> 
#>   STALE CEILING:         3
#>   STALE FLOOR:           10
#>   OK:                    9
#>   UNKNOWN:               0
#> 

# Check specific packages only
check_db_staleness(packages = c("dplyr", "tidyr"))
#> reproducr: checking 2 package(s) against cran...
#> reproducr: 1 stale ceiling, 4 stale floor, 0 ok, 0 unknown
#> 
#> Stale ceiling entries (to_version below current release):
#>   dplyr::group_by  [to_version 1.1.9 -> current 1.2.1]
#> 
#> Stale floor entries (from_version too old -- window too wide):
#>   dplyr::filter  [from_version 0.8.99 << current 1.2.1 (>= 1 major version(s) behind)]
#>   tidyr::nest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::pivot_wider  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::unnest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]

# Offline check using installed versions
check_db_staleness(source = "installed")
#> reproducr: checking 13 package(s) against installed...
#> reproducr: 0 stale ceiling, 2 stale floor, 1 ok, 19 unknown
#> 
#> Stale floor entries (from_version too old -- window too wide):
#>   purrr::map_df  [from_version 0.3.99 << current 1.2.2 (>= 1 major version(s) behind)]
#>   survival::survfit  [from_version 2.99.99 << current 3.8.6 (>= 1 major version(s) behind)]

# Filter to stale entries only
report <- check_db_staleness()
#> reproducr: checking 13 package(s) against cran...
#> reproducr: 3 stale ceiling, 10 stale floor, 9 ok, 0 unknown
#> 
#> Stale ceiling entries (to_version below current release):
#>   MatchIt::match.data  [to_version 4.4.9 -> current 4.7.2]
#>   dplyr::group_by  [to_version 1.1.9 -> current 1.2.1]
#>   ggplot2::geom_sf  [to_version 3.4.9 -> current 4.0.3]
#> 
#> Stale floor entries (from_version too old -- window too wide):
#>   dplyr::filter  [from_version 0.8.99 << current 1.2.1 (>= 1 major version(s) behind)]
#>   ggplot2::geom_histogram  [from_version 3.5.99 << current 4.0.3 (>= 1 major version(s) behind)]
#>   ggplot2::scale_colour_continuous  [from_version 3.5.99 << current 4.0.3 (>= 1 major version(s) behind)]
#>   purrr::map_df  [from_version 0.3.99 << current 1.2.2 (>= 1 major version(s) behind)]
#>   readr::read_csv  [from_version 1.4.99 << current 2.2.0 (>= 1 major version(s) behind)]
#>   readr::read_tsv  [from_version 1.4.99 << current 2.2.0 (>= 1 major version(s) behind)]
#>   survival::survfit  [from_version 2.99.99 << current 3.8-6 (>= 1 major version(s) behind)]
#>   tidyr::nest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::pivot_wider  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
#>   tidyr::unnest  [from_version 0.8.99 << current 1.3.2 (>= 1 major version(s) behind)]
report[report$status != "ok", ]
#> 
#> -- reproducr database staleness report --
#> 
#>   STALE CEILING:         3
#>   STALE FLOOR:           10
#>   OK:                    0
#>   UNKNOWN:               0
#> 
#> Stale ceiling entries (to_version below current release):
#> 
#>   [STALE CEILING] MatchIt::match.data
#>     to_version=4.4.9 | current=4.7.2
#>     Action: extend to_version or close entry.
#> 
#>   [STALE CEILING] dplyr::group_by
#>     to_version=1.1.9 | current=1.2.1
#>     Action: extend to_version or close entry.
#> 
#>   [STALE CEILING] ggplot2::geom_sf
#>     to_version=3.4.9 | current=4.0.3
#>     Action: extend to_version or close entry.
#> 
#> Stale floor entries (from_version too old -- window too wide):
#> 
#>   [STALE FLOOR] dplyr::filter
#>     from_version=0.8.99 | current=1.2.1
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] ggplot2::geom_histogram
#>     from_version=3.5.99 | current=4.0.3
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] ggplot2::scale_colour_continuous
#>     from_version=3.5.99 | current=4.0.3
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] purrr::map_df
#>     from_version=0.3.99 | current=1.2.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] readr::read_csv
#>     from_version=1.4.99 | current=2.2.0
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] readr::read_tsv
#>     from_version=1.4.99 | current=2.2.0
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] survival::survfit
#>     from_version=2.99.99 | current=3.8-6
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::nest
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::pivot_wider
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 
#>   [STALE FLOOR] tidyr::unnest
#>     from_version=0.8.99 | current=1.3.2
#>     Action: raise from_version or close entry.
#> 
# }
```
