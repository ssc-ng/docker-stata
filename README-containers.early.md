# Docker image basic Stata image

> **DEPRECATED: this image has moved to the `sscng` Docker Hub organization.**
> The `dataeditors` organization is deprecated and will no longer receive updates.
> Please use [`sscng/stata{{ full_version }}`](https://hub.docker.com/r/sscng/stata{{ full_version }}) (same image names and tags, e.g., `sscng/stata{{ full_version }}-mp:<tag>`) instead,
> and update any `FROM dataeditors/...` or `docker pull dataeditors/...` references.
> All images are listed at [https://hub.docker.com/u/sscng](https://hub.docker.com/u/sscng).

For complete information, see [https://github.com/AEADataEditor/docker-stata](https://github.com/AEADataEditor/docker-stata).

## Stata in Docker

This Docker image is meant to serve as a basis for reproducible and automatable work using Stata. 

> NOTE: The image created by these instructions contains binary code that is &copy; Stata. Permission was granted by Stata to Lars Vilhuber to post these images, without the license. A valid license is necessary to use these images. 

## Requirements

You need a Stata license to run the image.
See [https://github.com/AEADataEditor/docker-stata](https://github.com/AEADataEditor/docker-stata) for full instructions.


## Structure

The images are split into **versions**, **flavors**,  **editions** (types), and for versions greater than Stata 18, several **components**.

### Flavors

Stata version 18 and higher are available in the `regular` and the `now` flavors. The latter are denoted as `_5` in the image name, i.e., `stata18_5` for Stata Now 18. 

### Editions (types)

Stata comes in three editions: Basic Edition (`be`), Standard Edition (`se`), and MP-Parallel Edition (`mp`). While the typical Stata for Linux install will contain all three, the images here are split by type, each containing only one of the editions. 

### Versions

- The by-type images are available for Stata 18 and higher. For (monolithic) images for earlier versions of Stata 18 and below, 
see

- <https://hub.docker.com/r/dataeditors/stata18>
- <https://hub.docker.com/r/dataeditors/stata17> (last update: 2024-05-21)
- <https://hub.docker.com/r/dataeditors/stata16> (last update: 2023-06-13)
- <https://hub.docker.com/r/dataeditors/stata15> (last update: 2023-01-27)
- <https://hub.docker.com/r/dataeditors/stata14> (last update: 2021-06-02)
- <https://hub.docker.com/r/dataeditors/stata13> (last update: 2021-06-02)
- <https://hub.docker.com/r/dataeditors/stata12> (last update: 2021-07-30)
- <https://hub.docker.com/r/dataeditors/stata11> (last update: 2022-10-14)



## Accessing the images

You can browse all provided images at [https://hub.docker.com/u/dataeditors](https://hub.docker.com/u/dataeditors).



