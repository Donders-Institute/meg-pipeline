#!/bin/bash
#
# Use as
#   <scriptname> <directory>
#

# see http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/DICOM.html

function help {
SCRIPTNAME=$1
echo
echo This script searches through a directory for DICOM files and writes
echo them to the output screen in such a way that you can easily make a script
echo to rename all your datasets.
echo
echo You should edit the output, save it to a script and execute that script.
echo
echo Use as
echo   $SCRIPTNAME '<directory>'
echo
}

DIRECTORY=$1

if [ ! -d "$DIRECTORY" ]; then 
  help $0
fi

LIST=`find ${DIRECTORY} -type f -name \*.IMA -or -name *.ima -or -name *.DCM -or -name *.dcm`
echo $LIST

module load freesurfer
SeriesDescription=`mri_probedicom --i ${DICOMFILE} --t 0008 103E`



echo ###################
# dicom-rename --o $BASEDIR/$BASENAME ${DICOMFILE}
