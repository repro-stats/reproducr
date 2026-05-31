# reproducr audit report

- **Generated:** 2026-05-31 13:04
- **R version:** 4.6.0
- **Platform:** Linux 6.17.0-1015-azure
- **Files scanned:** 21
- **Packages found:** 22
- **Qualified calls:** 221
- **Versions from:** installed library

## Verdict

> AT RISK: 38 high-severity risk(s) detected.

## Risks

### [HIGH] `stats::sample`
- **File:** breaking_changes_db.R, line 360
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::runif`
- **File:** breaking_changes_db.R, line 377
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from runif() with the same seed will differ between R <= 3.5 and R >= 3.6. Use set.seed() with explicit kind argument for stable results.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** breaking_changes_db.R, line 391
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rbinom`
- **File:** breaking_changes_db.R, line 404
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Results from rbinom() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::hclust`
- **File:** breaking_changes_db.R, line 417
- **Check:** changelog
- **Details:** In R 4.0.0, hclust() changed its tie-breaking rule for equal distances. Dendrograms for datasets with tied distance values will differ between R 3.x and R 4.x.
- **Reference:** <https://cran.r-project.org/doc/manuals/r-release/NEWS.html>

### [HIGH] `stats::sample`
- **File:** risk_score.R, line 118
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::runif`
- **File:** risk_score.R, line 118
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from runif() with the same seed will differ between R <= 3.5 and R >= 3.6. Use set.seed() with explicit kind argument for stable results.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** risk_score.R, line 118
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rbinom`
- **File:** risk_score.R, line 119
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Results from rbinom() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-audit_script.R, line 26
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-audit_script.R, line 104
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-audit_script.R, line 177
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-repro_badge.R, line 42
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 34
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 72
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 73
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::sample`
- **File:** test-risk_score.R, line 83
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::sample`
- **File:** test-risk_score.R, line 84
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 94
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 104
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 115
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rbinom`
- **File:** test-risk_score.R, line 116
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Results from rbinom() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::runif`
- **File:** test-risk_score.R, line 117
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from runif() with the same seed will differ between R <= 3.5 and R >= 3.6. Use set.seed() with explicit kind argument for stable results.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 161
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 175
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 188
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** test-risk_score.R, line 211
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::sample`
- **File:** audit-and-risk.Rmd, line 186
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::runif`
- **File:** audit-and-risk.Rmd, line 186
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from runif() with the same seed will differ between R <= 3.5 and R >= 3.6. Use set.seed() with explicit kind argument for stable results.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** audit-and-risk.Rmd, line 186
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rbinom`
- **File:** audit-and-risk.Rmd, line 186
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Results from rbinom() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** audit-and-risk.Rmd, line 197
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rbinom`
- **File:** audit-and-risk.Rmd, line 201
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Results from rbinom() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::runif`
- **File:** audit-and-risk.Rmd, line 205
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from runif() with the same seed will differ between R <= 3.5 and R >= 3.6. Use set.seed() with explicit kind argument for stable results.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** audit-and-risk.Rmd, line 255
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::sample`
- **File:** contributing-to-the-database.Rmd, line 46
- **Check:** changelog
- **Details:** In R 3.6.0, the default RNG algorithm for sample() changed (sample.kind = 'Rejection' replaced 'Rounding'). Results produced with the same seed in R <= 3.5 will differ in R >= 3.6. Use set.seed(seed, kind = 'Mersenne-Twister', sample.kind = 'Rejection') for explicit reproducibility, or withCallingHandlers() to suppress the change warning.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** getting-started.Rmd, line 50
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [HIGH] `stats::rnorm`
- **File:** reports-and-badges.Rmd, line 23
- **Check:** changelog
- **Details:** In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html>

### [MEDIUM] `stats::sample`
- **File:** breaking_changes_db.R, line 360
- **Check:** seed_check
- **Details:** sample() is stochastic but no set.seed() was found in the 50 lines above this call (line 360). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::sample`
- **File:** risk_score.R, line 118
- **Check:** seed_check
- **Details:** sample() is stochastic but no set.seed() was found in the 50 lines above this call (line 118). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::runif`
- **File:** risk_score.R, line 118
- **Check:** seed_check
- **Details:** runif() is stochastic but no set.seed() was found in the 50 lines above this call (line 118). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** risk_score.R, line 118
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 118). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rbinom`
- **File:** risk_score.R, line 119
- **Check:** seed_check
- **Details:** rbinom() is stochastic but no set.seed() was found in the 50 lines above this call (line 119). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rpois`
- **File:** risk_score.R, line 119
- **Check:** seed_check
- **Details:** rpois() is stochastic but no set.seed() was found in the 50 lines above this call (line 119). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rexp`
- **File:** risk_score.R, line 119
- **Check:** seed_check
- **Details:** rexp() is stochastic but no set.seed() was found in the 50 lines above this call (line 119). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rgamma`
- **File:** risk_score.R, line 120
- **Check:** seed_check
- **Details:** rgamma() is stochastic but no set.seed() was found in the 50 lines above this call (line 120). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rbeta`
- **File:** risk_score.R, line 120
- **Check:** seed_check
- **Details:** rbeta() is stochastic but no set.seed() was found in the 50 lines above this call (line 120). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rcauchy`
- **File:** risk_score.R, line 120
- **Check:** seed_check
- **Details:** rcauchy() is stochastic but no set.seed() was found in the 50 lines above this call (line 120). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rchisq`
- **File:** risk_score.R, line 121
- **Check:** seed_check
- **Details:** rchisq() is stochastic but no set.seed() was found in the 50 lines above this call (line 121). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rf`
- **File:** risk_score.R, line 121
- **Check:** seed_check
- **Details:** rf() is stochastic but no set.seed() was found in the 50 lines above this call (line 121). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rt`
- **File:** risk_score.R, line 121
- **Check:** seed_check
- **Details:** rt() is stochastic but no set.seed() was found in the 50 lines above this call (line 121). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rgeom`
- **File:** risk_score.R, line 122
- **Check:** seed_check
- **Details:** rgeom() is stochastic but no set.seed() was found in the 50 lines above this call (line 122). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rhyper`
- **File:** risk_score.R, line 122
- **Check:** seed_check
- **Details:** rhyper() is stochastic but no set.seed() was found in the 50 lines above this call (line 122). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnbinom`
- **File:** risk_score.R, line 122
- **Check:** seed_check
- **Details:** rnbinom() is stochastic but no set.seed() was found in the 50 lines above this call (line 122). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rweibull`
- **File:** risk_score.R, line 123
- **Check:** seed_check
- **Details:** rweibull() is stochastic but no set.seed() was found in the 50 lines above this call (line 123). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `base::sample`
- **File:** risk_score.R, line 123
- **Check:** seed_check
- **Details:** sample() is stochastic but no set.seed() was found in the 50 lines above this call (line 123). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `base::sample.int`
- **File:** risk_score.R, line 123
- **Check:** seed_check
- **Details:** sample.int() is stochastic but no set.seed() was found in the 50 lines above this call (line 123). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-audit_script.R, line 26
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 26). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-audit_script.R, line 104
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 104). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-audit_script.R, line 177
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 177). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-repro_badge.R, line 42
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 42). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-risk_score.R, line 34
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 34). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-risk_score.R, line 161
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 161). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-risk_score.R, line 175
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 175). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-risk_score.R, line 188
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 188). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::rnorm`
- **File:** test-risk_score.R, line 211
- **Check:** seed_check
- **Details:** rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 211). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [MEDIUM] `stats::sample`
- **File:** contributing-to-the-database.Rmd, line 46
- **Check:** seed_check
- **Details:** sample() is stochastic but no set.seed() was found in the 50 lines above this call (line 46). Output will differ across runs without a fixed seed.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html>

### [LOW] `base::sort`
- **File:** risk_score.R, line 179
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::order`
- **File:** risk_score.R, line 179
- **Check:** locale_check
- **Details:** order() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::format`
- **File:** risk_score.R, line 179
- **Check:** locale_check
- **Details:** format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::toupper`
- **File:** risk_score.R, line 180
- **Check:** locale_check
- **Details:** toupper() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::tolower`
- **File:** risk_score.R, line 180
- **Check:** locale_check
- **Details:** tolower() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::strftime`
- **File:** risk_score.R, line 180
- **Check:** locale_check
- **Details:** strftime() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::as.Date`
- **File:** risk_score.R, line 181
- **Check:** locale_check
- **Details:** as.Date() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sprintf`
- **File:** risk_score.R, line 181
- **Check:** locale_check
- **Details:** sprintf() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 33
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 128
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 129
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::format`
- **File:** test-risk_score.R, line 138
- **Check:** locale_check
- **Details:** format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::format`
- **File:** test-risk_score.R, line 139
- **Check:** locale_check
- **Details:** format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 148
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 160
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 174
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 188
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** test-risk_score.R, line 211
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** audit-and-risk.Rmd, line 222
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::order`
- **File:** audit-and-risk.Rmd, line 222
- **Check:** locale_check
- **Details:** order() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::format`
- **File:** audit-and-risk.Rmd, line 222
- **Check:** locale_check
- **Details:** format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::toupper`
- **File:** audit-and-risk.Rmd, line 223
- **Check:** locale_check
- **Details:** toupper() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::tolower`
- **File:** audit-and-risk.Rmd, line 223
- **Check:** locale_check
- **Details:** tolower() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::strftime`
- **File:** audit-and-risk.Rmd, line 223
- **Check:** locale_check
- **Details:** strftime() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::as.Date`
- **File:** audit-and-risk.Rmd, line 224
- **Check:** locale_check
- **Details:** as.Date() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sprintf`
- **File:** audit-and-risk.Rmd, line 224
- **Check:** locale_check
- **Details:** sprintf() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** audit-and-risk.Rmd, line 230
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::format`
- **File:** audit-and-risk.Rmd, line 231
- **Check:** locale_check
- **Details:** format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::strftime`
- **File:** audit-and-risk.Rmd, line 232
- **Check:** locale_check
- **Details:** strftime() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** audit-and-risk.Rmd, line 256
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** getting-started.Rmd, line 51
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

### [LOW] `base::sort`
- **File:** reports-and-badges.Rmd, line 24
- **Check:** locale_check
- **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
- **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>

