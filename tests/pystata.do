* PyStata smoke test for the sscng/stata*-python Docker images.
*
* REQUIRES a valid Stata license and an image that ships python3.
* Run via tests/run-tests.sh -l <stata.lic>; do not run this file directly.

sysuse auto, clear

python:
import sys
from sfi import Data
print("PYTHON_VERSION=" + sys.version.split()[0])
assert Data.getObsTotal() == 74
print("PYSTATA_OK")
end

di "PYSTATA_DOFILE_OK"
