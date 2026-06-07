## R CMD check results
0 errors | 0 warnings | 1 note

* checking for future file timestamps: unable to verify current time
  Known infrastructure issue, unrelated to the package.

## Test environments
* macOS 26.5, R 4.4.2 (local)
* Windows (R-devel, win-builder): 0 errors, 0 warnings, 1 note

## Downstream dependencies
None.

## Resubmission notes
This is a resubmission of v0.1.3 (previously submitted 2026-06-07).
Changes since v0.1.3:

* Fixed invalid relative URI in README.md -- CODE_OF_CONDUCT.md link now use absolute GitHub URLs. Resolves CRAN
  pre-check NOTE: "Found the following (possibly) invalid file URI".