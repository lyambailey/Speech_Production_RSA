#!/bin/bash

# The purpose of this script is to mask threholded statistical maps for
# aloud-silent and silent-aloud with the thresholded maps from their minuend
# conditions

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define models and conditions (for simplicity, we'll treat aloud vs. silent as a condition)
models=(articulatory orthographic phonological semantic visual)
contrasts=(aloud-silent silent-aloud)

# Define folder containing all group-level output
data_dir=${top_dir}/MRIanalyses/quickread/group_level_output/RSA_output

# Loop through models and conditions.
for model in ${models[@]}; do

	# Define directory for this model
	model_dir=${data_dir}/${model}_group_searchlight_output

	# Now loop through contrasts. For each contrast, mask the stat map for that
	# contrast with the map from the corresponding minuend condition
	for contrast in ${contrasts[@]}; do

		# Define Bayes map for this contrast, as well as the onesample map for corresponding minuend condition
		bayes_map_contrast=${model_dir}/bayes_map_${contrast}_${model}_thresh

		if [[ ${contrast} == "aloud-silent" ]]; then
			minuend='aloud'
		elif [[ ${contrast} == "silent-aloud" ]]; then
			minuend='silent'
		fi

		bayes_map_minuend=${model_dir}/bayes_map_${minuend}_${model}_thresh.nii.gz

		# Mask the contrast with the minuend map
		fslmaths ${bayes_map_contrast} -mas ${bayes_map_minuend} ${bayes_map_contrast}_masked_with_minuend


	done # contrasts
done # models
