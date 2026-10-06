#!/bin/bash

if [[ -z $1 ]] 
then
	echo "provide date of snapshot"
	exit 2
fi

VERSION=${VERSION:-18_5}
TYPE=${TYPE:-se}
TAG=${1:-2023-08-30}
shift
MYHUBID=sscng
MYIMG=stata${VERSION}-$TYPE
[[ -z $STATALIC ]] && STATALIC=$(find . -name stata.lic.$VERSION | tail -1)
[[ -z $STATALIC ]] && STATALIC=$(find $HOME/Dropbox/ -name stata.lic.$VERSION | tail -1)
docker run -it --rm \
  -v ${STATALIC}:/usr/local/stata/stata.lic \
  -v $(pwd):/project \
  $MYHUBID/${MYIMG}:${TAG} "$@"

