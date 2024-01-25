#!/bin/bash

# Script to transform functional data from seperate runs to a common native functional space

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define list of subjects
subjects=(subject-001 subject-002 subject-003 subject-004 subject-005 subject-006 subject-007
          subject-008 subject-010 subject-011 subject-012 subject-013 subject-014 subject-015
          subject-016 subject-017 subject-018 subject-019 subject-020 subject-021 subject-022
          subject-023 subject-024 subject-025 subject-026 subject-027 subject-028 subject-029
          subject-030)

# Define important directories
data_dir=${top_dir}/MRIanalyses/quickread/subject_level_output/
assets_dir=${top_dir}/MRIanalyses/assets


# We are going to end up with a folder containg all COPEs in a common native space.
# We'll transform COPEs from runs 2, 3 & 4 to run1, and simply move COPEs from run1 (because
# they're already in that space)
runs=(quickread_1 quickread_2 quickread_3 quickread_4)

for subject in ${subjects[@]}; do

  echo ${subject}

  # Define output directory for this subject
  output_dir=${data_dir}/${subject}/firstLevelCOPEs2common_native_space_ants
  mkdir -p ${output_dir}

  # Define a temporary text file to redirect real-time ants output (this will
  # prevent it from printing to Terminal)
  temp_log=${output_dir}/most_recent_ants_reg_output.txt

  # Define the example func image from run 1. We will transform data from all other runs to this image.
  run1_example_func_fn=${data_dir}/${subject}/${subject}_quickread_1_LSA.feat/reg/example_func.nii.gz


  # Also define the cope image from run one and use it to create a mask
  run1_cope1_fn=${data_dir}/${subject}/${subject}_quickread_1_LSA.feat/stats/cope1.nii.gz
  run1_cope1_mask_fn=${output_dir}/${subject}_run1_cope1_mask.nii.gz

  fslmaths ${run1_cope1_fn} -abs -bin ${run1_cope1_mask_fn}


  # Loop through runs
  for run in ${runs[@]}; do

    # Define feat folder and example_func image for this run
    feat_dir=${data_dir}/${subject}/${subject}_${run}_LSA.feat
    runN_example_func_fn=${feat_dir}/reg/example_func.nii.gz
    runN_cope_fn=${feat_dir}/stats/cope1.nii.gz

    # Compute transformation matrix to align example_func from runN with that of run1.
    # Later we will apply this matrix to all COPE images from this run.


    # Define filename for the transformation matrix we are about to create
    runNfunc_to_run1func_mat=${output_dir}/runNfunc_to_run1func_

    # Compute transformation
    antsRegistrationSyNQuick.sh                                   \
                              -d 3                                \
                              -t r                                \
                              -f ${run1_example_func_fn}        \
                              -m ${runN_example_func_fn}        \
                              -o ${runNfunc_to_run1func_mat}  \
                              > ${temp_log} 2>&1 # this line prints output to a temporary txt file instead of terminal


    # Define list of COPEs for this run
    copes=$(ls ${feat_dir}/stats/cope*)

    # Loop through COPEs, either moving each straight to the output directory
    # (run #1), or transforming to a different native space (runs 2, 3 and 4)
    for cope_fn in ${copes}; do

      # Define input and output filenames
      cope_label=$(basename ${cope_fn})
      cope_output_fn=${output_dir}/${run}_${cope_label}

      # Use the matrix we generated to transofrm the cope image from runN space to run1 space
      antsApplyTransforms -d 3                                                    \
                            -i ${cope_fn}                                         \
                            -r ${run1_example_func_fn}                                 \
                            -o ${cope_output_fn}.nii.gz                           \
                            -t ${runNfunc_to_run1func_mat}0GenericAffine.mat  \

      ## NEW - mask the aligned image with cope1 from the first run
      fslmaths ${cope_output_fn} -mas ${run1_cope1_mask_fn} ${cope_output_fn}


    done # copes
  done # runs

  # Tidy up by removing the extra files we created
  find ${output_dir}/. -name 'runNfunc_to_run1func*' -exec rm {} \;

done # subjects
