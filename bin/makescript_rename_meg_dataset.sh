#!/bin/bash
#
# Use as
#   <scriptname> <directory> <>
#

function help {
SCRIPTNAME=$1
echo
echo This script searches through a directory for MEG datasets and writes
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

LIST=`find ${DIRECTORY} -name \*.ds -not -name hz\* | sort`

echo #------------------------------ script starts here ------------------------------

# the CTF command line utilities are needed
echo module load 32bit/ctf/5.40
echo 'COMMAND="newDs -anon"'
echo 'TARGETDIR="" #specify the path where subject-specific folders should be created'
echo 'PROJECTID="" #project id number to be appended to .ds filename'
echo

maxlength=0
n=0
for DATASET in $LIST ; do
n=`expr $n + 1`
length[n]=${#DATASET} 
if [ ${length[n]} -gt $maxlength ]; then 
  maxlength=${length[n]}
fi
done

n=0
for DATASET in $LIST ; do
n=`expr $n + 1`
subid=`printf "%04d" $n`
sesid=`printf "%02d"  1`
printf 'mkdir -p $TARGETDIR/sub-%s/ses-meg-%s/' $subid $sesid 
printf "\n"
done

n=0
for DATASET in $LIST ; do
n=`expr $n + 1`
subid=`printf "%04d" $n`
sesid=`printf "%02d"  1`
prjid='$PROJECTID'
pad=`expr $maxlength - ${length[n]}`
printf '$COMMAND'" ${DATASET} "
for i in $(seq 1 ${pad}); do printf " " ; done
printf '$TARGETDIR/sub-%s/ses-meg-%s/' $subid $sesid 
printf "s%ss%s_%s.ds" $subid $sesid $prjid
printf "\n"
done

echo #------------------------------ script ends here ------------------------------
