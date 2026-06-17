# List all certifications stored in a certification file

A convenience function to inspect what certification tags are stored and
their key metadata, without needing to read the raw `.rds` file.

## Usage

``` r
list_certs(file = ".reproducr")
```

## Arguments

- file:

  `character(1)`. Base path of the certification store. Default
  `".reproducr"`.

## Value

A `data.frame` with columns `tag`, `timestamp`, `r_version`, `os`,
`n_outputs`, `script` – one row per certification. Returns an empty data
frame if no certifications exist.

## Examples

``` r
cert_file <- tempfile()
model <- lm(mpg ~ wt, data = mtcars)

certify(list(coefs = coef(model)), tag = "v1", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-17] under tag 'v1'
certify(list(coefs = coef(model)), tag = "v2", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-17] under tag 'v2'

list_certs(file = cert_file)
#>   tag                timestamp r_version                      os n_outputs
#> 1  v1 2026-06-17T13:02:05+0000     4.6.0 Linux 6.17.0-1018-azure         1
#> 2  v2 2026-06-17T13:02:05+0000     4.6.0 Linux 6.17.0-1018-azure         1
#>   script
#> 1   <NA>
#> 2   <NA>
```
