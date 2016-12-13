import os
import sys
import re

sys.path.insert(0, "/Users/roboos/meg-pipeline/lib/pydicom")
import pydicom as dicom

rootlist = []
filelist = []
print('scanning directory structure...')
for root, dirs, files in os.walk('/Volumes/128GB/data/subjectRO/'):
    for file in files:
        if re.match('.*IMA$', file) or re.match('.*\.ima$', file) or re.match('.*\.DCM$', file) or re.match('.*\.dcm$', file):
            rootlist.append(root)
            filelist.append(file)

patientlist = []
print('getting DICOM headers...')
for root, file in zip(rootlist, filelist):
    ds = dicom.read_file(os.path.join(root, file))
    patientlist.append(ds.PatientName)

print(patientlist)

identifierlist = []
for root, file, patient in zip(rootlist, filelist, patientlist):
    # add a tuble with the directory and the patient ID, exclude the file name
    identifierlist.append((root, patient))
