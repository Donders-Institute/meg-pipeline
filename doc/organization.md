## Recommended data organization structure

At the DCCN we use the HCP compute cluster and central storage for most analyses. On Central storage you have a home directory, and you have a project directory. In the project directory, we recommend the following organization

  - /project/3010029.01/scripts
  - /project/3010029.01/raw
  - /project/3010029.01/source
  - /project/3010029.01/derived
  - /project/3010029.01/scratch

The scripts directory corresponds to your own clone of this repository, plus additional scripts and functions that you use for your analysis.

The raw directory contains the raw data from the MRI, MEG and EEG labs.

The source directory contains the anonimized BIDS format raw data files that can be shared.

The derived directory contains the result from processing and will mainly contain MATLAB *.mat files.

The scratch directory can be a symbolic link to /home/common/temporary/YourUID.

### Archiving the data

The **raw** directory should be organized consistently with the organization in the **data acquisition collection** on the Donders research data repository. All raw data should be archived immediately after data acquisition.

The **source** directory should be uploaded to the **data sharing collection** together with the relevant scripts and results. The persistent identifier (DOI or Handle) of that collection should be mentioned in your manuscript. 

After completion of the project the derived data and the scripts directory should be archived to the **research documentation collection** on the Donders research data repository.

