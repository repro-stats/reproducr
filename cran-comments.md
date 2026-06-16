This is a resubmission addressing reviewer feedback:

- Added reference URL to the Description field of DESCRIPTION
- Replaced \dontrun{} with \donttest{} in check_db_staleness examples
- Replaced cat()/print() with message() in non-S3-print functions
  (audit_script.R, certify.R, check_db_staleness.R, repro_badge.R,
  repro_report.R, risk_score.R)
- Replaced installed.packages() with packageVersion() in
  check_db_staleness.R and utils.R

Note on versioning: the version has been incremented from 0.1.5
(current CRAN release) to 0.2.0, as new functionality was added during the review period:
- major_version_grace and from_version_major_threshold parameters
  added to risk_score() and check_db_staleness() respectively,
  suppressing false-positive flags for users already past a
  breaking-change transition window.
