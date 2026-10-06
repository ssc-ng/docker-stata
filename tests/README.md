# Tests

Smoke tests for the built `sscng/stata*` images.

## A Stata license is required for most of the tests

`tests/run-tests.sh` runs two kinds of check:

| Check | License needed? |
|---|---|
| Shared libraries resolve (`ldd`); the Stata binary starts without a dynamic-loader error | **No** |
| `test.do` runs (regress, `assert`, `putexcel`), `graph export` produces a PNG + PDF, PyStata `sfi` bridge works | **Yes** |

Without `-l`, the license-dependent checks are reported as `SKIP` and the script
still passes on the library checks alone. The shared-library check is what
catches regressions like [issue #32](https://github.com/AEADataEditor/docker-stata/issues/32)
(`stata-mp: error while loading shared libraries: libtinfo.so.5`).

The license file is mounted read-only at `/usr/local/stata/stata.lic` and is
never copied into an image or committed.

## Usage

```bash
# library checks only
tests/run-tests.sh -i sscng/stata18-mp:2026-06-02

# full run
tests/run-tests.sh -i sscng/stata18-mp:2026-06-02 -l /path/to/stata.lic
```

Test one tag across every variant:

```bash
VERSION=18; TAG=2026-06-02; LIC=/path/to/stata.lic
for v in be se mp be-i se-i mp-i be-x se-x mp-x be-i-python se-i-python mp-i-python; do
    tests/run-tests.sh -i "sscng/stata${VERSION}-${v}:${TAG}" -l "$LIC" || break
done
```

## Files

- `run-tests.sh` — test runner (`-i <image>`, optional `-l <stata.lic>`)
- `test.do` — functional do-file: computation, graphics/font stack, file IO
- `pystata.do` — PyStata `sfi` bridge check (run only on `*-python` images)
