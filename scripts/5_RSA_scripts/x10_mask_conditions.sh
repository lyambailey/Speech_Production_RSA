#!/bin/bash

# The purpose of this script is to mask threholded statistical maps for
# aloud and silent condiions with eachother, so we can see any overlap 
# between the 2 conditions

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define models and conditions (for simplicity, we'll treat aloud vs. silent as a condition)
models=(articulatory orthographic phonological semantic visual)

# Define folder containing all group-level output
data_dir=${top_dir}/MRIanalyses/quickread/group_level_output/RSA_output

# Loop through models and conditions.
for model in ${models[@]}; do

	# Define directory for this model
	model_dir=${data_dir}/${model}_group_searchlight_output

		# Define Bayes map for the aloud and silent conditions
		bayes_map_aloud=${model_dir}/bayes_map_aloud_${model}_thresh_no_small_clusters.nii.gz
		bayes_map_silent=${model_dir}/bayes_map_silent_${model}_thresh_no_small_clusters.nii.gz

		if [ ! -f ${bayes_map_aloud} ]; then
			echo "file not found"
		fi

		# Mask the aloud map with the silent and binarize the output 
		bayes_map_conjunction=${model_dir}/bayes_map_aloud_silent_conjunction_${model}_thresh_no_small_clusters.nii.gz
		fslmaths ${bayes_map_aloud} -mas ${bayes_map_silent} -bin ${bayes_map_conjunction}

		# Finally, check if the conjunction map is empty. If so, delete it.
		n_voxels=$(fslstats ${bayes_map_conjunction} -V)

		echo $n_voxels

		if [ "${n_voxels:0:1}" == 0 ]; then
			echo "removing file"
			rm ${bayes_map_conjunction}
		
		fi


done # models
