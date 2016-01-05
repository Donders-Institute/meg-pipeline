# M/EEG data analysis pipelines

This repository contains the DCCN template EEG and MEG data analysis pipelines.

## Disclaimer

The analysis pipelines and settings for the algorithms represented in this repository are merely a *template* for how you **could do** your analysis at the DCCN, not how you **should do** your analysis.

You should train yourself about the different options that you have for data processing and you should understand that the **optimal data processing pipeline** is always dependent on the research question,  the experimental design and on the features of the data that you have acquired.

You should always consult and inform your supervisor or principal investigator on the decisions that you make in data processing.

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

## Pipeline sequence

The processing pipelines of EEG and MEG data share many aspects, that is why we largely use the same analysis scripts. Where needed, e.g. for coregistration of MEG and re-referencing of EEG, there are separate scripts that need to be executed at the right moment in the pipeline.
