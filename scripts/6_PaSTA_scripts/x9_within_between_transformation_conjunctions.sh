#!/bin/bash

# The purpose of this script is to mask statistical maps from within-subject
# transformation analyses (contrasts between conditions) with that of
# between-subjects transformation analyses (each respective minuend condition)


# Define important directories
top_dir=$(<../top_dir_linux.txt)

# Define the directory housing all of our group-level output
data_dir=${top_dir}/MRIanalyses/PE/group_level_output/PaSTA_output_MNI

# Define contrasts
contrasts=(aloud-silent silent-aloud)

# Define directories for the within- and between-subjects transformation measures
within_dir=${data_dir}/study-test_transformation_memory_effsize_group_searchlight_output
between_dir=${data_dir}/study-test_between_subjects_transformation_effsize_group_searchlight_output

# Loop through contrasts
for contrast in ${contrasts[@]}; do

  # Select minuend condition for the current contrast
  if [[ ${contrast} == 'aloud-silent' || ${contrast} == 'aloud' ]]; then
    minuend='aloud'
  elif [[ ${contrast} == 'silent-aloud' || ${contrast} == 'silent' ]]; then
    minuend='silent'
  fi

  # Define filename stem for the within-subjects contrast map
  transform_map_within=${within_dir}/bayes_map_${contrast}_study-test_transformation_memory_effsize_thresh_masked_with_minuend

  # And the between-subjects minuend map
  transform_map_between=${between_dir}/bayes_map_${minuend}_study-test_between_subjects_transformation_effsize_thresh

  # Define output filename.
  output_fn=${transform_map_within}_cnjxn_with_between

  # Mask the within-subjects map with the between-subjects map
  fslmaths ${transform_map_within} -mas ${transform_map_between} ${output_fn}

done # contrasts
