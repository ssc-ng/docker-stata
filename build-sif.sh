#!/bin/bash

VERSION=${VERSION:-18}
[[ -z $1 ]] && TAG=$(date +%F) || TAG=$1
MYHUBID=sscng
MYIMG=stata${VERSION}
SYLABSID=vilhuberlars

echo "======== Build SIF file for Stata $VERSION ========"
sudo singularity build stata${VERSION}.sif \
    docker-daemon://${MYHUBID}/${MYIMG}:${TAG}

[[ $? == 0 ]] || exit 2
[[ -f stata${VERSION}.sif  ]] && sudo chown $(id -u) stata${VERSION}.sif 
echo "======== Sign SIF file for Stata $VERSION ========"
singularity sign stata${VERSION}.sif 

echo "======== Push to Sylabs.io repository (under $MYHUBID ) ======="


echo "Ready to push?"
echo "  singularity push stata${VERSION}.sif  library://$SYLABSID/dataeditors/${MYIMG}:${TAG} "
read answer
case $answer in 
   y|Y)
   singularity remote login SylabsCloud
   singularity remote use SylabsCloud
   singularity push stata${VERSION}.sif \
    library://$SYLABSID/dataeditors/${MYIMG}:${TAG}
    ;;
    *)
    exit 0
    ;;
esac
