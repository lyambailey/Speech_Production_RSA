#!/bin/bash

# The purpose of this script is to threshold group-level statistical maps for
# each model. This step really should have been implemented in the previous
# script, however trying to threshold the maps in MATLAB has weird effects when
# values are extremely close to zero (I suspect due to rounding). Thresholding 
# using fslmaths seems to work more reliably. 

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define the directory housing all of our group-level output
data_dir=${top_dir}/MRIanalyses/quickread/group_level_output/RSA_output

# Define models and conditions (for simplicity, we'll treat aloud/silent contrasts as conditions)
models=(articulatory orthographic phonological semantic visual)
conditions=(aloud silent aloud-silent silent-aloud)

# Loop through models and conditions. In each case, pull the Bayes stat map,
# threshold it, and save it as a new file
for model in ${models[@]}; do
	model_dir=${data_dir}/${model}_group_searchlight_output
	
	for condition in ${conditions[@]}; do

		# Define original filename for the Bayes map for this model and condition
		bayes_map=${model_dir}/bayes_map_${condition}_${model}

		# Threshold the bayes map
		bayes_map_thresh=${bayes_map}_thresh

		# Define threhold here
		# Using top 5%:
		# threshold=95
		# fslmaths ${bayes_map} -thr 1 -thrP ${threshold} ${bayes_map_thresh}

		# Or using hard threshold of BF >= 3
		threshold=3
		fslmaths ${bayes_map} -thr ${threshold} ${bayes_map_thresh}

	done # conditions
done # models
