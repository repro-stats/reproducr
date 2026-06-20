# Check whether breaking-changes database entries are stale

Compares the `to_version` ceiling of each entry in the breaking-changes
database against the current version of that package on CRAN. Entries
whose `to_version` is below the current CRAN version may need their
ceiling updated to reflect new releases.

This function is primarily intended for use by `reproducr` maintainers
and contributors. It is also run as a scheduled GitHub Actions workflow
on the `reproducr` repository to automatically open issues when
staleness is detected.

## Usage

``` r
check_db_staleness(packages = NULL, verbose = TRUE, source = "cran")
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
      [`utils::installed.packages()`](https://rdrr.io/r/utils/installed.packages.html).
      Fast and offline, but only reflects what is installed on the
      current machine.

  Default `"cran"`.

## Value

A `data.frame` of class `c("staleness_report", "data.frame")` with one
row per database entry. Columns:

- `key`:

  The `pkg::fn` key.

- `pkg`:

  Package name.

- `fn`:

  Function name.

- `to_version`:

  The ceiling version currently in the database.

- `current_version`:

  The current version on CRAN or installed.

- `status`:

  One of `"ok"`, `"stale"`, or `"unknown"`.

- `gap`:

  The version difference as a string, e.g. `"1.1.9 -> 1.3.0"`. `NA` when
  status is `"unknown"`.

Rows are ordered: stale first, then ok, then unknown. Printed invisibly
when all entries are current.

## Staleness vs requiring an update

A stale entry does not automatically mean the database is wrong. It
means the package has released a new version since the ceiling was set.
A human must determine whether:

1.  The breaking change still applies in the new version (extend
    ceiling).

2.  The new version fixed or reverted the change (lower or remove
    ceiling).

3.  The entry should be closed because the ecosystem has moved on.

See the contributing vignette for guidance on setting `to_version`.

## See also

[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
which uses the database at runtime;
[`vignette("contributing-to-the-database")`](https://repro-stats.github.io/reproducr/articles/contributing-to-the-database.md)
for the database schema and version window design principles.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check all tracked packages against CRAN
report <- check_db_staleness()
print(report)

# Check specific packages only
check_db_staleness(packages = c("dplyr", "tidyr"))

# Offline check using installed versions
check_db_staleness(source = "installed")

# Filter to stale entries only
report <- check_db_staleness()
report[report$status == "stale", ]
} # }
```
