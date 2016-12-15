#!/usr/bin/env python

import os
import sys
import re
import getopt

if hasattr(sys, 'frozen'):
    basis = sys.executable
elif sys.argv[0]!='':
    basis = sys.argv[0]
else:
    basis = './'
installed_folder = os.path.split(basis)[0]

# bin contains this file, lib contains shared modules
sys.path.insert(0,os.path.join(installed_folder,'../lib'))
import pydicom as dicom

def help(name):
    print "This script searches through a directory for DICOM files and writes"
    print "them to the output screen in such a way that you can easily make a script"
    print "to reorganize them to a BIDS structure."
    print ""
    print "You should save the output to a script, edit the script and then execute it."
    print "Use as"
    print '  %s -c <command> -o <outputdir> [inputdir]' % name
    print ""
    
# set the defaults
command = "cp"
outputdir = "FIXME"

try:
    opts, args = getopt.getopt(sys.argv[1:],"hc:o:",["command=","outputdir="])
except getopt.GetoptError:
    help(sys.argv[0])
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        help(sys.argv[0])
        sys.exit()
    elif opt in ("-c", "--command"):
        command = arg
    elif opt in ("-o", "--outputdir"):
        outputdir = arg
            
inputdirs = args
if len(inputdirs)<1:
    help(sys.argv[0])
    sys.exit(2)

rootlist = []
filelist = []
for dir in inputdirs:
    print '# scanning directory structure starting at %s' % dir
    for root, dirs, files in os.walk(dir):
        for file in files:
            if re.match('.*IMA$', file) or re.match('.*\.ima$', file) or re.match('.*\.DCM$', file) or re.match('.*\.dcm$', file):
                rootlist.append(root)
                filelist.append(file)

print '# found %d dicom files in %d directories' % (len(filelist), len(set(rootlist)))

patientlist = []
protocollist = []
print('# getting dicom headers, this may take a while...')
for root, file in zip(rootlist, filelist):
    ds = dicom.read_file(os.path.join(root, file))
    patientlist.append(ds.PatientName)
    protocollist.append(ds.ProtocolName)

identifierlist = []
for root, file, patient in zip(rootlist, filelist, patientlist):
    # add a tuble with the directory and the patient ID, exclude the file name
    identifier = (root, patient)
    identifierlist.append(identifier)

uniquepatient = sorted(list(set(patientlist)))
uniqueprotocol = sorted(list(set(protocollist)))
uniqueidentifier = sorted(list(set(identifierlist)))

print '# found %d patient IDs' % len(uniquepatient)
print '# found %d protocols' % len(uniqueprotocol)
print '# constructed %d different identifiers from patient IDs and directories' % len(uniqueidentifier)

sub=1
ses=1
subdir = []
sesdir = []
subvar = []
sesvar = []
for identifier in uniqueidentifier:
    subdir.append("sub-%04d" % sub)
    subvar.append("SUB%04d" % sub)
    sesdir.append("ses-mri-%03d" % ses)
    sesvar.append("SES%04d" % sub)
    sub += 1
    
index=1
protdir = []
protvar = []
for protocol in uniqueprotocol:
    protdir.append(protocol) # fixme, check that the name is valid for a directory
    protvar.append("PROT%03d" % index)
    index+=1
    
print""
print "# please verify the following general variables"
print "OUTPUTDIR=%s" % outputdir
print "COMMAND=%s" % command

print""
print "# please verify the following subject and session identifier variables"
for subv,subd,sesv,sesd,identifier in zip(subvar,subdir,sesvar,sesdir,uniqueidentifier):
    print "%s=%s ; %s=%s  # %s" % (subv,subd,sesv,sesd,identifier)

print""
print "# please verify the following protocol variables"
for protv,protd in zip(protvar,protdir):
    print "%s=%s" % (protv,protd)

print ""    
print "###### the script should not need any changes below this line ######"

print ""    
print "# create the target directory structure"
for subv,sesv in zip(subvar,sesvar):
    for protv in protvar:
        print "mkdir -p %s" % os.path.join("$OUTPUTDIR", "$"+subv, "$"+sesv, "$"+protv)

print ""    
print "# copy all the files"

previous=None
for root,file,identifier,protocol in zip(rootlist, filelist, identifierlist, protocollist):
    index_id = uniqueidentifier.index(identifier)
    index_pr = uniqueprotocol.index(protocol)
    if previous!=(index_id,index_pr):
        # place a blank line between blocks of dicom files with the same identifier and protocol
        # this facilitates visual parsing of the bash script
        if previous!=None:
            # no empty line at the start
            print ''
        previous=(index_id,index_pr)
    fullfile1 = os.path.join(root, file)
    fullfile2 = os.path.join("$OUTPUTDIR", '$'+subvar[index_id], '$'+sesvar[index_id], '$'+protvar[index_pr], file)
    print "$COMMAND %s %s" % (fullfile1, fullfile2)
    
print ""    
print "# remove empty directories"
print "find $OUTPUTDIR -type d -empty -delete"

      