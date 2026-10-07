#!/bin/bash

# this script captures an existing Stata install, updated as necessary

# set locations


if [[ -z $1 || "$1" == "-h" ]]
then
cat << EOF

$0 -v[ersion]  -c[apture]

where 
  - Version: of Stata (17, 18, 18_5, ...) (can be omitted if set in _version.sh)
  - Capture: date of the capture (can be omitted if not overriding)
  - h: this helpfile

Note that Stata Now version numbers should be coded as '18_5', but will look in a directory called 'statanow18'.

EOF
exit 2
fi

source ./_version.sh
while getopts v:c: flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        c) CAPTURE=${OPTARG};;
    esac
done

[[ -z $CAPTURE ]] && CAPTURE=$(date +%F) 

cat << EOF

  VERSION: $VERSION
  CAPTURE: $CAPTURE

Ready? 

EOF
read

TARLOC=bin-exclude
TARBASE=$(pwd)/bin-exclude/stata-installed-$VERSION
TARFILE=${TARBASE}.tgz
VTARFILE=${TARBASE}-${CAPTURE}
TMP=/mnt/local/fast_home/$USER/tmp
BUILD=$TMP/stata-build
# Is this StataNow or regular?
if [[ "$VERSION" == ${VERSION##*_} ]]
then
    # regular Stata
    printf "%20s " "Stata version $VERSION"
    INSTALLED=usr/local/stata${VERSION}
else
    # StataNow
    printf "%20s " "StataNow version $VERSION"
    INSTALLED=usr/local/statanow${VERSION%%_*}
fi
# untar

printf "%20s " "Prepare build."
[[ -d $BUILD ]] && \rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
# disable the re-use of tarfiles, but leave it here 
if [[ -f xxxxx$TARFILE ]]
then
	tar xzf $TARFILE && echo "Tar file unpacked." || exit 2
	\rm -rf $BUILD/$INSTALLED/utilities/.old
	# Not functional
  # [[ "$VERSION" == "17" || "$VERSION" == "18" || "$VERSION" == "18_5" ]] && \rm -rf $BUILD/$INSTALLED/utilities/java/linux-x64
	printf "%20s " ""
	echo "Ready for sync."
else
	echo "No previous version found"
	mkdir -p $BUILD/$INSTALLED
	echo "Ready for sync."
fi
echo "  $BUILD"



# sync

printf "%20s " "Syncing."
rsync -au --exclude='.old' /$INSTALLED/ $BUILD/$INSTALLED/ && echo "Done." || exit 2

# remove license

printf "%20s " "Remove license:"
#LICFILE=$BUILD/$INSTALLED/stata.lic
find $BUILD/$INSTALLED -name stata.lic\* -exec rm {} \;
echo "Done."

# Pack it back up

printf "%20s \n" "Rebuild tarfile:"
cd $BUILD
printf "%20s - " "Docs"
tar czf ${VTARFILE}-docs.tgz $INSTALLED/docs \
	&& \rm -rf $INSTALLED/docs || exit 2
echo "Done"
printf "%20s - " "Help files"
tar czf ${VTARFILE}-help.tgz $(find $INSTALLED -name \*hlp) \
	&& find $INSTALLED -name \*hlp -exec rm {} \; || exit 2
echo "Done"
for arg in mp se be
do
   printf "%20s - " "Stata $arg" 
   case $arg in 
	   be)
		   type=
		   ;;
	   *)
		   type=-$arg
		   ;;
   esac
   tar czf ${VTARFILE}-${arg}.tgz $INSTALLED/libstata${type}.* $INSTALLED/stata${type} 
   echo "Done"
   printf "%20s - " "Stata X $arg"
   tar czf ${VTARFILE}-x${arg}.tgz $INSTALLED/xstata${type} $INSTALLED/libstata${type}.*  $INSTALLED/stata_pdf 
   echo "Done"
done

printf "%20s - " "Deleting excess files" 
\rm -rf $INSTALLED/libstata${arg}* $INSTALLED/stata-*  || exit 2
\rm -rf $INSTALLED/libstata* $INSTALLED/stata || exit 2
\rm -rf $INSTALLED/x* $INSTALLED/stata_pdf|| exit 2
echo "Done"

printf "%20s - " "Stata base - whats left"
tar czf ${VTARFILE}-base.tgz $INSTALLED && echo "Done."

echo "All done."



