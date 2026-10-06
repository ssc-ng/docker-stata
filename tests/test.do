* Functional smoke test for the sscng/stata* Docker images.
*
* REQUIRES a valid Stata license mounted at /usr/local/stata/stata.lic.
* Run via tests/run-tests.sh -l <stata.lic>; do not run this file directly.

di "STATA_VERSION=" c(stata_version)
di "FLAVOR=" c(flavor)

* --- computation
sysuse auto, clear
assert _N == 74
summarize price mpg
regress price mpg weight foreign
assert e(N) == 74
assert reldif(_b[weight], 3.4647058) < 1e-4

* --- graphics + font stack (exercises libgd / fontconfig)
graph twoway (scatter price mpg) (lfit price mpg), ///
    title("docker-stata smoke test") xtitle("Mileage (mpg)")
graph export "test-graph.png", replace width(600)
graph export "test-graph.pdf", replace
confirm file "test-graph.png"
confirm file "test-graph.pdf"

* --- file IO
putexcel set "test-out.xlsx", replace
putexcel A1 = "ok"
confirm file "test-out.xlsx"

di "DOFILE_OK"
