#!/bin/bash

if [[ -z $1 || "$1" == "-h" ]]
then
cat << EOF

$0 -v[ersion] -t[ag] [-e] [-h]

where 
    - Version: of Stata (17, 18, ...) (required)
    - Tag: tag to pull (required)
    - -e: use template README for early version of Stata 
    - -h: this helpfile

This script pulls down a Stata version with specified tag, tags it as "latest", 
pushes that tag, and updates the README using the early.md template.
EOF
exit 2
fi

source ./_version.sh
EARLY=0
while getopts v:t:eh flag
do
        case "${flag}" in
                v) VERSION=${OPTARG};;
                t) TAG=${OPTARG};;
                e) EARLY=1;;
                h) 
                        # Show help and exit
                        exec "$0" -h
                        ;;
        esac
done


# Check required parameters
if [[ -z $VERSION ]]; then
    echo "Error: Version (-v) is required"
    exit 1
fi

if [[ -z $TAG ]]; then
    echo "Error: Tag (-t) is required"
    exit 1
fi

SHORTDESC="Docker image for Stata, to be used in automation and reproducibility."
TEMPLATE="README-containers.template.md"
[[ -n $EARLY ]] && TEMPLATE="README-containers.early.md"
EXTRAMD="README-containers.$VERSION.md"
OUTPUTMD="README-containers.md"

MYHUBID=sscng
MYIMG=stata${VERSION}

echo "Pulling images with tag $TAG for Stata $VERSION..."

# Find all available image variants for this version
available_images=$(docker search ${MYHUBID}/${MYIMG} --limit 100 2>/dev/null | grep "${MYHUBID}/${MYIMG}" | awk '{print $1}' | grep -E "${MYIMG}-(be|se|mp)" || echo "${MYHUBID}/${MYIMG}")

if [[ -z "$available_images" ]]; then
    # Fallback to basic image name
    available_images="${MYHUBID}/${MYIMG}"
fi

echo "Found images to pull:"
for img in $available_images; do
    echo "  $img:$TAG"
done

echo ""
echo "Ready to pull and retag? (y/N)"
read answer
case $answer in 
   y|Y)
   # Pull, retag as latest, and push for each image
   for img in $available_images
   do
       echo "Processing $img..."
       
       # Pull the specified tag
       docker pull ${img}:$TAG
       if [[ $? -ne 0 ]]; then
           echo "Failed to pull ${img}:$TAG, skipping..."
           continue
       fi
       
       # Tag as latest
       docker tag ${img}:$TAG ${img}:latest
       
       # Push the latest tag
       docker push ${img}:latest
       
       # Update README on Docker Hub
       docker pushrm ${img} --short "$SHORTDESC" 
   done
   
   # Generate README-containers.md from template
   if [[ -f "$TEMPLATE" ]]; then
       echo "Updating README using $TEMPLATE..."
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
       
       echo "README updated: $OUTPUTMD"
   else
       echo "Warning: Template $TEMPLATE not found"
   fi
   
   echo "Pull and retag operation completed!"
   ;;
   *)
   exit 0
   ;;
esac