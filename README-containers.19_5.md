## NOTES 

- Tag `2025-08-13` corresponds to StataNow 19 released on 2025-08-13, using Ubuntu 22.04 as base image.
- Tag `2025-08-14` corresponds to StataNow 19 released on 2025-08-13 as well, but using Ubuntu 24.04 as base image.

- Select images have Python installed (with `-python` suffix). For this version, the system Python version is **3.12.3**. If you need Python in other images, the following Dockerfile snippet can be used to add it to any of the images:

```
# Adjust as necessary
FROM sscng/stata18-se:2026-01-13
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
         python3 \
         python3-pip \
    && rm -rf /var/lib/apt/lists/* \
```

Or have a look at [Dockerfile.python](Dockerfile.python) for how we do it for the select images.
