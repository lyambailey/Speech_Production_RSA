#!/bin/bash

# The purpose of this script is to mask threholded statistical maps for
# aloud-silent and silent-aloud with the thresholded maps from their minuend
# conditions. Note that this is not necessary for between-subjects transformation
# since we did not perform contrasts of that measure


# Define important directories
top_dir=$(<../top_dir_linux.txt)

# Define the directory housing all of our group-level output
data_dir=${top_dir}/MRIanalyses/PE/group_level_output/PaSTA_output_MNI

# Define measures and contrasts
measures=(
        'study-test_similarity_memory_effsize' \
        'study-test_transformation_memory_effsize' \
        )

contrasts=(aloud-silent silent-aloud)

# Loop through measures and contrasts
for measure in ${measures[@]}; do

	# Define group-level directory for this measure
	measure_dir=${data_dir}/${measure}_group_searchlight_output

	for contrast in ${contrasts[@]}; do

    # Identify the minuend condition for this contrast
    if [[ ${contrast} == 'aloud-silent' ]]; then
      minuend='aloud'
    elif [[ ${contrast} == 'silent-aloud' ]]; then
      minuend='silent'
    fi

    # Define path to the stat map for this measure / contrast
    bayes_map_contrast=${measure_dir}/bayes_map_${contrast}_${measure}_thresh

		# Define path to the minuend condition map for this measure
    bayes_map_minuend=${measure_dir}/bayes_map_${minuend}_${measure}_thresh

    # Mask the contrast map with the minuend map
    fslmaths ${bayes_map_contrast} -mas ${bayes_map_minuend} ${bayes_map_contrast}_masked_with_minuend

  done # contrasts
done # measures
