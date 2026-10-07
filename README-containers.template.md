# Docker image basic Stata image

For complete information, see [https://github.com/ssc-ng/docker-stata](https://github.com/ssc-ng/docker-stata).

## Stata in Docker

This Docker image is meant to serve as a basis for reproducible and automatable work using Stata. 

> NOTE: The image created by these instructions contains binary code that is &copy; Stata. Permission was granted by Stata to Lars Vilhuber to post these images, without the license. A valid license is necessary to use these images. 

## Requirements

You need a Stata license to run the image.
See [https://github.com/ssc-ng/docker-stata](https://github.com/ssc-ng/docker-stata) for full instructions.


## Structure

The images are split into **versions**, **flavors**,  **editions** (types), and several **components**.

### Flavors

Stata version 18 and higher are available in the `regular` and the `now` flavors. The latter are denoted as `_5` in the image name, i.e., `stata18_5` for Stata Now 18. 

### Editions (types)

Stata comes in three editions: Basic Edition (`be`), Standard Edition (`se`), and MP-Parallel Edition (`mp`). While the typical Stata for Linux install will contain all three, the images here are split by type, each containing only one of the editions. 

### Versions

- The by-type images are available for Stata 18 and higher. For (monolithic) images for earlier versions of Stata 18 and below, 
see

- <https://hub.docker.com/r/sscng/stata18>
- <https://hub.docker.com/r/sscng/stata17>
- <https://hub.docker.com/r/sscng/stata16>
- <https://hub.docker.com/r/sscng/stata15>
- <https://hub.docker.com/r/sscng/stata14>
- <https://hub.docker.com/r/sscng/stata13>
- <https://hub.docker.com/r/sscng/stata12>

### Components

For compactness, the various versions, editions, and flavors are provided in several components:

The naming goes as `stata` 

- followed by the version number (e.g., `{{ base_version }}`)
- followed by the release number separated by `_` if not zero (e.g., `{{ base_version }}.0` = `{{ base_version }}`, but `{{ base_version }}.5` becomes `{{ base_version }}_5`), 
- followed by the edition (`be`, `se`, `mp`), 
- followed by the optional `-i` for interactive, or the optional `-x` for GUI.
- for some images, followed by the optional `-python` for Python support.

#### Base image

The base image serves all other images, but is not useful on its own - it does not contain any of the various Stata binaries. 

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sscng/stata{{ full_version }}-base  test  90364eb9a9d9  9 minutes ago   795MB
```


#### Minimal command line images

These images have only the relevant command line binaries. They are fully functional, but contain no documentation or help files, and are meant to be used for automation. A license appropriate for each version is necessary: Basic Edition (`be`), Standard Edition (`se`), and MP-Parallel Edition (`mp`). 

> NOTE: these images were built with the 32-core edition. They have not been tested with lower-core-count licenses. Please provide feedback if they do not work.


```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sscng/stata{{ full_version }}-mp    test  4c1580c00abd  9 minutes ago   1.18GB
sscng/stata{{ full_version }}-se    test  662e2d09026e  9 minutes ago   1.12GB
sscng/stata{{ full_version }}-be    test  5f87e594ddbf  9 minutes ago   1.12GB
```

#### Command line images for interactive development

These images have help files, and are suitable for interactive development, for instance by inclusion in JupyterLab or in on-demand cloud instances.  They use the non-`i` versions (above) as the basis, and simply add a layer with the help files.


```
REPOSITORY                  TAG   IMAGE ID      CREATED         SIZE
sscng/stata{{ full_version }}-mp-i  test  642e4a006672  9 minutes ago   1.41GB
sscng/stata{{ full_version }}-se-i  test  76786bda8680  9 minutes ago   1.32GB
sscng/stata{{ full_version }}-be-i  test  f5600d1fe84d  9 minutes ago   1.32GB
```


#### Same as above, with Python installed

For select interactive images, a version is installed with Python support. These images have the `-python` suffix. They are substantially larger than the non-Python versions. Please let us know if you run into issues.

```
REPOSITORY                          TAG   IMAGE ID      CREATED         SIZE
sscng/stata{{ full_version }}-mp-i-python  2026-02-18  555452384561   3 weeks ago      2.04GB
sscng/stata{{ full_version }}-se-i-python  2026-02-18  17745f15fdf1   3 weeks ago      1.95GB
sscng/stata{{ full_version }}-be-i-python  2026-02-18  db2b73f72f1b   3 weeks ago      1.95GB
```

#### Interactive with GUI

The GUI (`X`) variants start with the `-i` variant, and add the `x` binaries. They are complete, but the container is **NOT COMPLETE** and will not work without additional installation of X11 libraries. If you do not know what I'm talking about do not use them **AT ALL**. If you do, then use these images in the `FROM` statement of a Dockerfile or Singularity image, then add all the necessary libraries.


```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sscng/stata{{ full_version }}-mp-x  test  2fbc841cba25  9 minutes ago   1.92GB
sscng/stata{{ full_version }}-se-x  test  dedf75051503  9 minutes ago   1.76GB
sscng/stata{{ full_version }}-be-x  test  07b1b687e984  9 minutes ago   1.76GB
```

## Special features

Containers have minimal additional Linux commands. If any are necessary, you will need to build your own image:

| Command | Available since |
|---------|-----------------|
|git | |
|nano | |
|unzip | |
|sudo | 2026-01-13 |

## Accessing the images

You can browse all provided images at [https://hub.docker.com/u/sscng](https://hub.docker.com/u/sscng).



