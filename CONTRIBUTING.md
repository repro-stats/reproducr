# Contributing to reproducr

Thank you for your interest in contributing to `reproducr`. There are two main
ways to contribute:

1. **Contributing to the package** — bug fixes, new features, tests, documentation
2. **Contributing breaking-change entries** — the most impactful contribution for
   most users. See [reproducr-db](https://github.com/repro-stats/reproducr-db)

---

## Contributing to the package

### Before you start

- Check the [issue tracker](https://github.com/repro-stats/reproducr/issues)
  to see if the bug or feature has already been reported
- For significant changes, open an issue first to discuss the approach before
  writing code
- Small bug fixes and documentation improvements can go straight to a PR

### Development setup

```r
# Clone the repo
# git clone https://github.com/repro-stats/reproducr.git

# Install development dependencies
install.packages("devtools")
devtools::install_deps(dependencies = TRUE)

# Load the package
devtools::load_all()

# Run tests
devtools::test()

# Check the package
devtools::check()
```

### Code style

- Follow the existing code style — base R, no tidyverse imports in the package
  itself
- All exported functions must have roxygen2 documentation
- All new functionality must have tests in `tests/testthat/`
- Use `--` for em dashes in comments and documentation (no non-ASCII characters)
- Internal helpers should be prefixed with `.` and documented with `#' @noRd`

### Pull request checklist

Before opening a PR, confirm:

- [ ] `devtools::check()` returns 0 errors, 0 warnings
- [ ] New functions have roxygen2 documentation
- [ ] New functionality has tests
- [ ] `spelling::spell_check_package()` returns no errors
- [ ] `NEWS.md` has an entry under the dev version heading

### Adding a new risk check

`risk_score()` supports three check methods: `"changelog"`, `"seed_check"`,
`"locale_check"`. To add a new check method:

1. Add the check logic as a new internal function `.check_<name>(calls, ...)`
   in `R/risk_score.R`
2. Register it in the `methods` argument of `risk_score()`
3. Add tests in `tests/testthat/test-risk_score.R`
4. Document it in the `@param methods` section of `risk_score()`

---

## Contributing breaking-change entries

The breaking-changes database that powers `risk_score()` is maintained in a
separate repository:

**[repro-stats/reproducr-db](https://github.com/repro-stats/reproducr-db)**

This is the most impactful contribution for most users. If you have hit a
silent breaking change in a CRAN package — one that changed function behaviour
without an error or warning — please contribute an entry.

See the [reproducr-db contributing guide](https://github.com/repro-stats/reproducr-db/blob/main/CONTRIBUTING.md)
for the entry format and submission process.

---

## Reporting bugs

Please include:

- A minimal reproducible example
- Your R version (`R.version.string`)
- Your platform (`Sys.info()[["sysname"]]`)
- Whether you are using `renv` and if so your `renv.lock` R and package versions
- The full error message or unexpected output

Open a bug report at:
**https://github.com/repro-stats/reproducr/issues/new**

---

## Code of conduct

Please be respectful and constructive in all interactions. This project follows
the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.