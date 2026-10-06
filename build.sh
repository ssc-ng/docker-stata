#!/bin/bash

if [[ -z $1 || "$1" == "-h" ]]
then
cat << EOF

$0 -v[ersion] -t[ag] -c[apture]

where 
  - Version: of Stata (17, 18, 18_5, ...) (can be omitted if set in _version.sh)
  - Tag: tag to give Docker image (typically date)
  - Capture: of the capture
  - h: this helpfile
EOF
exit 2
fi

source ./_version.sh
while getopts v:t:c: flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        t) TAG=${OPTARG};;
        c) CAPTURE=${OPTARG};;
    esac
done
[[ -z $TAG ]] && TAG=$(date +%F) 
[[ -z $CAPTURE ]] && $0 -h

cat << EOF

  VERSION: $VERSION
  TAG    : $TAG
  CAPTURE: $CAPTURE

Ready? 

EOF
read

MYHUBID=sscng
MYIMG=stata${VERSION}

# define STATA_VERSION

if [[ "${VERSION}" == "${VERSION%%_*}" ]]
then
	STATA_VERSION=${VERSION}
else
	STATA_VERSION=now${VERSION%%_*}
fi

# Guard: Stata <= 18.5 binaries are linked against the ncurses5 ABI
# (libtinfo.so.5 / libncurses.so.5). Ubuntu dropped libncurses5/libtinfo5 after
# 22.04, so a Stata <= 18.5 image built on a newer base fails at runtime with:
#   stata-mp: error while loading shared libraries: libtinfo.so.5: cannot open ...
# Stata 18 / 18.5 must be built from the `stata18` / `stata18_5` branch, whose
# Dockerfile.base is pinned to ubuntu:22.04. See issue #32.
STATA_MAJOR=${VERSION%%_*}
BASE_UBUNTU=$(grep -oE 'ubuntu:[0-9]+\.[0-9]+' Dockerfile.base | head -1 | cut -d: -f2)
if [[ "$STATA_MAJOR" =~ ^[0-9]+$ ]] && (( STATA_MAJOR <= 18 )) \
   && [[ -n "$BASE_UBUNTU" ]] && (( ${BASE_UBUNTU//./} > 2204 )); then
	cat >&2 <<EOF

ERROR: Refusing to build Stata ${VERSION}.

  Dockerfile.base is based on Ubuntu ${BASE_UBUNTU}, but Stata <= 18.5 binaries
  are linked against the ncurses5 ABI (libtinfo.so.5 / libncurses.so.5), which
  is not available after Ubuntu 22.04. Images built this way fail at runtime with:
    stata-mp: error while loading shared libraries: libtinfo.so.5

  Build Stata 18 / 18.5 from the matching branch instead:
    git switch stata18      # or: git switch stata18_5

EOF
	exit 1
fi

# build all the images
# Base: 

image=base
DOCKER_BUILDKIT=1 docker build \
	-f Dockerfile.base \
	--build-arg STATA_VERSION=${STATA_VERSION}  \
	--build-arg CAPTURE_VERSION=$VERSION \
	--build-arg CAPTURE=$CAPTURE  \
	. \
        -t $MYHUBID/${MYIMG}-base:$TAG


# now build the functional command line versions

for arg in be se mp
do
	case $arg in 
		be)
			cmd=stata
			;;
	        *)
			cmd=stata-$arg
			;;
	esac
	sed "s+stata-mp+${cmd}+" Dockerfile.type > Dockerfile.$arg
	sed "s+stata-mp+x${cmd}+" Dockerfile.type > Dockerfile.x$arg

	# Build the command line versions
	DOCKER_BUILDKIT=1 docker build \
		-f Dockerfile.${arg} \
	        --build-arg STATA_VERSION=${STATA_VERSION}  \
	        --build-arg CAPTURE_VERSION=$VERSION \
	       	--build-arg TAG=${TAG} \
	      	--build-arg CAPTURE=${CAPTURE} \
	       	--build-arg TYPE=$arg \
		. \
                -t $MYHUBID/${MYIMG}-${arg}:$TAG
    
	# Build the interactive command line versions
	DOCKER_BUILDKIT=1 docker build \
		-f Dockerfile.${arg} \
	        --build-arg STATA_VERSION=${STATA_VERSION}  \
	        --build-arg CAPTURE_VERSION=$VERSION \
	       	--build-arg TAG=${TAG} \
	      	--build-arg CAPTURE=${CAPTURE} \
	       	--build-arg TYPE=help \
		--build-arg BASIS=$arg \
		. \
                -t $MYHUBID/${MYIMG}-${arg}-i:$TAG
	# build the X versions - note: still no X libraries
	DOCKER_BUILDKIT=1 docker build \
		-f Dockerfile.x${arg} \
	        --build-arg STATA_VERSION=${STATA_VERSION}  \
	        --build-arg CAPTURE_VERSION=$VERSION \
	       	--build-arg TAG=${TAG} \
	      	--build-arg CAPTURE=${CAPTURE} \
	       	--build-arg TYPE=x$arg \
		--build-arg BASIS=${arg}-i \
		. \
                -t $MYHUBID/${MYIMG}-${arg}-x:$TAG

	# Build Python-enabled versions based on the -i images
	sed "s+stata-mp+${cmd}+" Dockerfile.python > Dockerfile.${arg}-python
	DOCKER_BUILDKIT=1 docker build \
		-f Dockerfile.${arg}-python \
	        --build-arg STATA_VERSION=${STATA_VERSION}  \
	        --build-arg CAPTURE_VERSION=$VERSION \
	       	--build-arg TAG=${TAG} \
	      	--build-arg TYPE=$arg \
		. \
                -t $MYHUBID/${MYIMG}-${arg}-i-python:$TAG


done

exit 0
echo "Ready to push?"
echo "  docker push  $MYHUBID/${MYIMG}:$TAG"
echo " (will iterate across all images)"
read answer
case $answer in 
   y|Y)
   for arg $(docker images | grep $TAG | grep ${MYIMG}- | awk ' { print $1 } '))
   do
	  docker push ${arg}:$TAG
	  # also push the README - requires installation of docker-pushrm https://github.com/christian-korneck/docker-pushrm
	  docker pushrm ${arg}
   done
   ;;
   *)
   exit 0
   ;;
esac


