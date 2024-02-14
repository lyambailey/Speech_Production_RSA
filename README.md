# Project description
This GitHub repository contains code used for an fMRI study of the production effect, conducted at Dalhousie University between November 2021 and March 2022. This code is indended to be used in conjunction with data and assets from the same study, stored here [provide OSF link]. If you download all the data (stored on OSF) and all the scripts (stored here), and arrange the folders into the directory structure described below, you should be able to run all the analyses as intended.

This study involved two experiments, which were dubbed _PE_ and _quickread_ respectively. PE is short for "production effect"; this experiment was a modified version of the paradigm from [Bailey et al. (2021)][1], specifically intended for multivariate analysis. The quickread experiment was a shortened version of the study phase from the PE experiment with more rapid trial presentation. These two experiments are related; however, data from each has been analyzed and written up independently. 

# Directory structure
This project uses the following directory structure. All folders described below should be downloaded (either from this repo or from OSF) and placed within a single directory.

**scripts**: [This folder is included in this repository] Contains all scripts for data preprocessing and analysis. More detail is provided in the README within the scripts folder. 

**MRIdata**: [This folder is included in the OSF repository] Contains preprocessed fMRI data (4D functional images from each experiment) and brain-extracted T1 images from each subject. Note that data from 12 subjects are available in this repo.

**MRIanalyses:** [This folder is included in the OSF repository] Contains all assets required for the analysis scripts stored in *scripts*. This folder also serves as the main output folder for said scripts. Assets are auxiliary files that are necessary for data analysis, but are not derived directly from the MRI data themselves. Examples of assets include fMRI log files, MNI templates, corpora, and the like. Assets are stored in subject-specific subfolders, which in turn contain assets required for both the PE and quickread pipelines. Some assets are provided in the OSF repo, but where possible they are generated as part of the analysis pipeline. If you notice that any assets are missing, contact lyam.bailey@dal.ca or aaron.newman@dal.ca

**behavioural_data:**  [This folder is included in the OSF repository] Contains raw behavioural data from each subject acquired during fMRI scanning. Note that the subfolders 'fMRI_runs1' and 'fMRI_runs2' pertain to the PE and quickread experiments respectively. 

[1]: https://doi.org/10.1016/j.bandc.2021.105757
