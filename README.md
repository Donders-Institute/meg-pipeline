# M/EEG data analysis pipelines

This repository contains the DCCN template EEG and MEG data analysis pipelines.

## Recommended directory structure
  * /project/3010029.01/scripts
  * /project/3010029.01/raw/MEG
  * /project/3010029.01/raw/MRI
  * /project/3010029.01/processed
  * /project/3010029.01/scratch

The project/scripts directory corresponds to your own clone of this repository.

The project/raw/MEG and project/raw/MRI directory should be organized as they are on the Donders RDM archive server.

The project/processed directory contains the files that result from processing and will mainly contain MATLAB *.mat files.

The project/scratch directory can be a symbolic link to /home/common/temporary/YourUID.
