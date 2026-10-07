#!/bin/bash

if [[ -z $1 || "$1" == "-h" ]]
then
cat << EOF

$0 -v[ersion] -t[ag] -e[arly]

where 
  - Version: of Stata (17, 18, ...) (can be omitted if set in _version.sh)
  - Tag: tag to give Docker image (typically date)
  - Early: use template README for early version of Stata 
  - h: this helpfile
EOF
exit 2
fi

source ./_version.sh
while getopts v:t:c:r: flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        t) TAG=${OPTARG};;
        e) EARLY=1;;
    esac
done
VERSION=${VERSION:-18}
[[ -z $TAG ]] && TAG=$(date +%F) 
SHORTDESC="$(cat "$(dirname "$0")/SHORTDESC")"
TEMPLATE="README-containers.template.md"
[[ -n $EARLY ]] && TEMPLATE="README-containers.early.md"
EXTRAMD="README-containers.$VERSION.md"
OUTPUTMD="README-containers.md"

MYHUBID=sscng
MYIMG=stata${VERSION}

# Generate README-containers.md from template
if [[ -f "$TEMPLATE" ]]; then
    # Extract base version (e.g., "19" from "19_5")
    BASE_VERSION=$(echo "$VERSION" | cut -d'_' -f1)
    
    # Replace template placeholders
    sed -e "s/{{ base_version }}/$BASE_VERSION/g" \
        -e "s/{{ full_version }}/$VERSION/g" \
        "$TEMPLATE" > "$OUTPUTMD"
    
    if [[ -f "$EXTRAMD" ]]; then
        echo "" >> "$OUTPUTMD"
        cat "$EXTRAMD" >> "$OUTPUTMD"
    fi
fi

# build all the images
# Base: 

list=$(docker images --format '{{.Repository}}' --filter "reference=*/${MYIMG}-*:${TAG}")

if [[ -z $list ]]; then
    echo "No images found for tag $TAG with prefix ${MYIMG}-"
    exit 1
fi
echo "Ready to push? (y/N)"
echo "  docker push  $MYHUBID/${MYIMG}:$TAG"
echo " (will iterate across all images)"
docker images --format '{{.Repository}}:{{.Tag}}' --filter "reference=*/${MYIMG}-*:${TAG}"
read answer
case $answer in 
   y|Y)
   # iterate over all images in $list
   for arg in $list
   do
	  docker push ${arg}:$TAG
	  # also push the README - requires installation of docker-pushrm https://github.com/christian-korneck/docker-pushrm
	  docker pushrm ${arg} --short "$SHORTDESC" 
   done
   ;;
   *)
   exit 0
   ;;
esac


