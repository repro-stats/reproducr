# CRAN submission comments

## Version 0.1.0 — initial submission

### Test environments

* Local: Ubuntu 24.04, R 4.3.3
* GitHub Actions: ubuntu-latest (R release, devel, oldrel-1)
* GitHub Actions: macos-latest (R release)
* GitHub Actions: windows-latest (R release)

### R CMD check results

0 errors | 0 warnings | 0 notes

### Reverse dependencies

None — this is the first submission.

### Notes for CRAN reviewers

* The package intentionally uses only base R packages as hard dependencies
  (`utils`, `tools`, `stats`) to keep the install footprint minimal.
  `digest` (for SHA-256 hashing) is a soft dependency listed in `Suggests`;
  a fallback implementation is provided.

* The breaking-changes database (`R/breaking_changes_db.R`) is a static
  data structure embedded in the package source. It does not fetch data
  from the internet at runtime.

* All `\dontrun{}` examples are wrapped because they write to the filesystem.
  Examples that do not write files are fully runnable.
