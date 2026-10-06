## NOTES 

- **Broken tags `2026-04-14` and `2026-06-02`:** these tags were mistakenly built on an Ubuntu 24.04 base, which lacks the `libtinfo5` / `libncurses5` libraries that the Stata 18 binaries require. Any attempt to run Stata from these tags fails immediately with:

  ```
  stata-mp: error while loading shared libraries: libtinfo.so.5: cannot open shared object file: No such file or directory
  ```

  (likewise `stata` and `stata-se` in the `-be` / `-se` variants). The `2026-04-14` and `2026-06-02` tags (all variants) have since been **rebuilt correctly on Ubuntu 22.04 and re-pushed**. The original broken images are preserved for the record as `2026-04-14-24.04` and `2026-06-02-24.04`. If you pinned one of these tags before this fix, re-pull it. See [issue #32](https://github.com/AEADataEditor/docker-stata/issues/32).

- When combining these Stata images with R images, note that R 4.5.0 is the first version using Ubuntu 24.04 as base image. That OS does not have the relevant system libraries (`libtinfo5` in particular) to support running Stata 18. You may need a newer version of Stata, or stick with R 4.4.2 or earlier. (based on our testing).

- Select images have Python installed (with `-python` suffix). For this version, the system Python version is **3.10.12**. If you need Python in other images, the following Dockerfile snippet can be used to add it to any of the images:

```
# Adjust as necessary
FROM sscng/stata18-se-i:2026-01-13
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
         python3 \
         python3-pip \
    && rm -rf /var/lib/apt/lists/* \
```

