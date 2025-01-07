# Project description 
This GitHub repository contains code for fMRI analyses reported in [Bailey et al. (2025)][1]. This code is intended to be used in conjunction with data and assets stored in [a companion OSF repository][2]. If you download the relevant files (stored on OSF) and scripts (stored here), and arrange the folders into the directory structure described below, you should be able to run all the analyses as intended.

# Directory structure
This project uses the following directory structure. All folders described below should be downloaded (either from this repo or from OSF) and placed within a single directory.

`scripts`: Contains all scripts for data preprocessing and analysis. More detail is provided in the README within the scripts folder. **This folder is included in this repository.** 

`MRIdata`: Contains preprocessed fMRI data (4D functional images) and brain-extracted T1 images from twelve subjects who consented to their anonymized data being made publicly accessible. **This folder is included in the OSF repository.** 

`MRIanalyses`: Contains all assets required for the analysis scripts stored in `scripts`. This folder also serves as the main output folder for said scripts. Assets are auxiliary files that are necessary for data analysis, but are not derived directly from the MRI data themselves. Examples of assets include fMRI log files, MNI templates, corpora, and the like. Many assets are stored in subject-specific subfolders. Some assets are provided in the OSF repo, but where possible they are generated as part of the analysis pipeline. If you notice that any assets are missing, contact lyam.bailey@dal.ca or aaron.newman@dal.ca. **This folder is included in the OSF repository.**

`behavioural_data`: Contains raw behavioural data acquired during fMRI scanning, from twelve subjects who consented to their anonymized data being made publicly accessible. **This folder is included in the OSF repository.**

[1]: https://direct.mit.edu/imag/article/doi/10.1162/imag_a_00428/125638/Differential-weighting-of-information-during-aloud
[2]: https://osf.io/czb26/?view_only=86a66caf1d71484d8ef0293cfa2371df
