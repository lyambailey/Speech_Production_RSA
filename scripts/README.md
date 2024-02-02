### Information about the contents of this folder
This folder contains all the code used for this project. Scripts are grouped into subfolders corresponding to specific stages/components of the analysis pipeline, and subfolders are numbered in the order in which they should be executed (e.g., you must perform preprocessing and asset creation before you can perform FEAT). Preprocessing and asset creation for both experiments are handled by scripts in "1_prepocessing" and "2_make_assets" respectively; "0_custom_functions" contains custom python and matlab functions called by other scripts in the pipeline. All other folders provide code for a specific experiment.

Within each subfolder, scripts are numbered in the order in which they should be executed. Running scripts in the wrong order will likely cause problems.

**IMPORTANT**: The root directory adopted by all of these scripts is the superordinate project directory (i.e., one level above this folder, containing MRIdata, MRIanalyses, etc.). The root directory is always read out of top_dir_win.txt or top_dir_linux, both of which are stored in this folder. This means that, if you wish to download and run our code, you simply need to modify the top_dir file for your OS. As an aside: this pipeline was developed across tw computers running Windows and Linux respectively, hence the existence of two top_dir files.

### Dependencies (i.e., stuff you should install in order to run this code)
Version #'s indicate the versions with which this code was developed. The code might not run as intended on more recent versions.

- FSL 6.0
- Advanced Normalization Tools (http://stnava.github.io/ANTs/)
- MATLAB R2020b (dependencies not included in the base installation are listed below):
  - CoSMoMVPA (https://cosmomvpa.org/download.html)
  - bayesFactor (https://github.com/klabhub/bayesFactor)
    
- Python / Anaconda 3 (dependencies not included in the base installation are listed below):
  - corpustools v1.4.0 (https://phonologicalcorpustools.github.io/CorpusTools/)
  - gensim v4.0.1 (https://pypi.org/project/gensim/)
  - imageio v2.9.0 (https://pypi.org/project/imageio/)
  - numpy v2.21.5 (https://numpy.org/)
  - pandas 1.1.3 (https://pandas.pydata.org/)
  - pattern 3.6 (https://github.com/clips/pattern)
  - pillow 8.0.1 (https://pypi.org/project/pillow/)
  - scipy 1.5.2 (https://scipy.org/)
  - wordkit 4.3.3 (https://github.com/clips/wordkit)
    
- shell
  - GNUparallel (https://www.gnu.org/software/parallel/)
 
- Surf Ice (https://www.nitrc.org/projects/surfice/)
- MRIcroGL (https://www.nitrc.org/projects/mricrogl)
