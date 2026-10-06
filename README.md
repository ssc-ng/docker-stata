# Docker image basic Stata image

The primary source for this README is at [https://github.com/AEADataEditor/docker-stata](https://github.com/AEADataEditor/docker-stata).

## Purpose

This Docker image is meant to isolate and stabilize that environment, and should be portable across
multiple operating system, as long as [Docker](https://docker.com) is available.

> To learn more about the use of containers for research reproducibility, see [Carpentries' docker-introduction](https://carpentries-incubator.github.io/docker-introduction/index.html). For commercial services running containers, see [codeocean.com](https://codeocean.com),  or any of the cloud service providers. For an academic project using containers, see [Whole Tale](https://wholetale.org/).

> NOTE: The image created by these instructions contains binary code that is &copy; Stata. Permission was granted by Stata to Lars Vilhuber to post these images, without the license. A valid license is necessary to build and use these images. 

> NOTE: The X (GUI) versions of Stata in these images are complete, but the container is NOT COMPLETE and will not work without additional installation of X11 libraries. If you do not know what I'm talking about do not use them AT ALL. If you do, then use these images in the `FROM` statement of a Dockerfile, then add all the necessary libraries.
 
## Requirements

You need a Stata license to run the image.

### Where should you put the Stata license

In the documentation below, we will use a (bash) environment variable to abstract from the actual location of the Stata license. This has been tested on MacOS and Linux, and it *should* work using Git Bash on Windows. Comments welcome.

## Dockerfile

The [Dockerfile](Dockerfile) contains the build instructions. A few things of note:


## Build

### Set up a few things

Set the `TAG`, `MYHUBID` and `MYIMG` accordingly, if intending to rebuild. `VERSION` should be the Stata version.

```
VERSION=18
TAG=$(date +%F)
MYHUBID=sscng
MYIMG=stata${VERSION}
```


### Build the image

Basic image building is easy:

```
DOCKER_BUILDKIT=1 docker build \
        -f Dockerfile.base \
        --build-arg VERSION=$VERSION  \
        --build-arg CAPTURE=$CAPTURE  \
        . \
        -t $MYHUBID/${MYIMG}-base:$TAG
```

However, since 2023-10, I have restructured the images to be leaner, but this means that multiple images must be built. 

- First build the `base` image above. This will contain all files from a Stata install EXCEPT the actual Stata binaries, and the EXCEPT the help and documentation files.
- The focal images are the `be`, `se`, and `mp` images. They contain the necessary Stata binaries to run command-line Stata. No help files, GUI binaries, or documentation is included.
- If you wish to use the image for interactive development, help files are useful. The `-i` suffix indicates that these are images for interactive development (e.g., `stata18-mp-i`.
- If you wish to run the GUI version of Stata, you will want to use the `-x` images as a basis. NOTE THAT I DO NOT USE THESE, AND THEY ARE NOT FUNCTIONAL because they are missing many X11 libraries. You will need to base your image on these.
 
To build all these images from captures of a workstation install, a convenience script `build.sh` is provided. It is invoked with

```
./build.sh -v[ersion] -t[ag] -c[apture]

where 
  - Version: of Stata (17, 18, ...)
  - Tag: tag to give Docker image (typically date)
  - Capture: of the capture
  - h: this helpfile
```

e.g.

```
./build.sh -v 18 -t test -c 2023-10-14
```

This will generate a lot of output, and may take a while:

```
[+] Building 4.7s (17/17) FINISHED                                              
 => [internal] load build definition from Dockerfile                       0.0s
 => => transferring dockerfile: 37B                                        0.0s
...
 => exporting to image                                                     0.0s
 => => exporting layers                                                    0.0s
 => => writing image sha256:2dc159dee0413040c99b02f885eb7a6559b647cd6e86a  0.0s
 => => naming to docker.io/sscng/stata18:2023-10-09                  0.0s
```

Once done, you should have multiple images:


```
docker images 
```

output:

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sscng/stata18-mp-x  test  2fbc841cba25  9 minutes ago   1.92GB
sscng/stata18-mp-i  test  642e4a006672  9 minutes ago   1.41GB
sscng/stata18-mp    test  4c1580c00abd  9 minutes ago   1.18GB
sscng/stata18-se-x  test  dedf75051503  9 minutes ago   1.76GB
sscng/stata18-se-i  test  76786bda8680  9 minutes ago   1.32GB
sscng/stata18-se    test  662e2d09026e  9 minutes ago   1.12GB
sscng/stata18-be-x  test  07b1b687e984  9 minutes ago   1.76GB
sscng/stata18-be-i  test  f5600d1fe84d  9 minutes ago   1.32GB
sscng/stata18-be    test  5f87e594ddbf  9 minutes ago   1.12GB
sscng/stata18-base  test  90364eb9a9d9  9 minutes ago   795MB
```

## Test the image

`tests/run-tests.sh -i <image>` smoke-tests a built image. The shared-library
checks need no license; the checks that run Stata code (do-file, graph export,
PyStata) require a license file passed with `-l <stata.lic>`. See
[`tests/README.md`](tests/README.md).

```
tests/run-tests.sh -i sscng/stata18-mp:2026-06-02 -l /path/to/stata.lic
```

## Publish the image 

The resulting docker image(s) can be uploaded to [Docker Hub](https://hub.docker.com/), if desired, or any other of the container registries. 


```
docker push $MYHUBID/${MYIMG}:$TAG
```

You can browse the provided images at [https://hub.docker.com/u/sscng](https://hub.docker.com/u/sscng):

![Screenshot of repository for dataeditors](assets/docker-hub-dataeditors.png)


## Using the image

### Directory structure

In the following, we are going to assume that your project has the following directory structure, and simplify the directory mounts:

```
project/
   data/
   code/
      01_preparedata.do
      02_runanalysis.do
   results/
   main.do
   setup.do
```

`setup.do` installs all required Stata ado packages via the necessary commands (`ssc install`, `net install pkg, from(url)`). `main.do` is the main controller script, which here resides in the root directory of the project. Other options are possible. We will run all commands with the working directory set to `/path/to/project`. When NOT using Docker, you can achieve the same goal by double-clicking `main.do`, which will automatically set the working directory to where `main.do` resides.

### Using pre-built images

Using a pre-built image on [Docker Hub](https://hub.docker.com/u/sscng) to run a program. 

> NOTE: because Stata is proprietary software, we need to mount a license file. 

> NOTE: We are using a working directory of "/project" here - check the [Dockerfile](Dockerfile) for the precise location.


For all the subsequent `docker run` commands, we will use similar environment variables:

```
VERSION=18
TAG=2023-10-14
MYHUBID=sscng
MYIMG=stata${VERSION}
TYPE=mp
STATALIC="$(pwd)/stata.lic.${VERSION}"
```

or

```
VERSION=17
TAG=2023-03-08
MYHUBID=sscng
MYIMG=stata${VERSION}
TYPE=mp
STATALIC="$(find $HOME/Dropbox/ -name stata.lic.$VERSION | tail -1)"
```

where again, the various forms of `STATALIC` are meant to capture the location of the `stata.lic` file (in my case, it is called `stata.lic.18`, but in your case, it might be simply `stata.lic`). 

### To enter interactive stata

```
docker run -it --rm \
  -v "${STATALIC}":/usr/local/stata/stata.lic \
  -v "$(pwd):/project \
  $MYHUBID/${MYIMG}-${TYPE}-i:${TAG}
```

where I am using the `mp-i` image because my license covers MP and I would like to have the help files. 


### Aside: Using other container management software

The above builds and runs the container using Docker. While there is a free Community Edition of Docker, others may prefer to use one of the other container management software, such as [Podman](https://podman.io/) or [Singularity](https://sylabs.io/guides/latest/user-guide/). For instance, in Singularity, the following works:

```
singularity run  \
  -B ${STATALIC}:/usr/local/stata/stata.lic \
  -B $(pwd):/project \
  -H $(pwd) \
  docker://$MYHUBID/${MYIMG}-${TYPE}-i:${TAG}
```

We have also converted the Docker image to a Singularity Image File (SIF), 

```
sudo singularity build stata${VERSION}.sif docker-daemon://${MYHUBID}/${MYIMG}:${TAG}
```

and uploaded the resultant SIF file to the Sylabs.io servers ([library/vilhuberlars/sscng/stata17](https://cloud.sylabs.io/library/vilhuberlars/sscng/stata17)), so it can be used directly in a way similar to DockerHub:

```
SYLABSID=vilhuberlars
singularity run  \
  -B ${STATALIC}:/usr/local/stata/stata.lic \
  -B $(pwd):/project \
  -H $(pwd) \
  library://$SYLABSID/$MYHUBID/${MYIMG}-${TYPE}-i:${TAG}
```

without the need to first convert it.


### Running a program

The docker image has a `ENTRYPOINT` defined, which means it will act as if you were running Stata:

```bash
cd /path/to/project
docker run -it --rm \
  -v ${STATALIC}/stata.lic.${VERSION}:/usr/local/stata/stata.lic \
  -v $(pwd):/project \
  -w /project \
  $MYHUBID/${MYIMG}-${TYPE}:${TAG} -b program.do
```

I am using here the `mp` image, because I do not need the help files. In the context of some automated running, or just project isolation, this image is a bit smaller. 

Your program, of course, should reference the `/data` and `/results` directories, ideally in a location-agnostic manner:

```
// we start in the rootdir
// Note: we could double-check that we are in the right directory:
// confirm file "main.do"
global rootdir : pwd
global data "${rootdir}data"
global results "${rootdir}results"
// all subsequent use references the globals
use "${data}/mydata.dta"
graph export "${results}/figure1.png"
```


### Using the container to build a project-specific docker image

- Adjust the `setup.do` file - list all packages you want installed permanently. 
- Remember to have the `stata.lic.17` file available
- Start your Dockerfile with (adjust the tag)

```
# syntax=docker/dockerfile:1.2
FROM sscng/stata18:2024-02-14
# this runs your setup code 
COPY code/setup.do setup.do
RUN --mount=type=secret,id=statalic,dst=/usr/local/stata/stata.lic /usr/local/stata/stata-mp do /setup.do

USER statauser:stata
VOLUME /project
WORKDIR /project
# run the master file
ENTRYPOINT ["stata-mp","/code/master.do"]
```

build, and then run this Docker image with

```
docker run \
  -v ${STATALIC}/stata.lic.${VERSION}:/usr/local/stata/stata.lic \
  -v $(pwd):/project \
  larsvilhuber/greatpaper:2021-06-08 -b main.do
```
and the results of running the code (in `code`) on the data (in `data`) will show up in the `results` folder which is local to your workstation, with no need to install any additional Stata packages.
