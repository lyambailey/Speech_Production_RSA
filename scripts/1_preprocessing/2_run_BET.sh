#!/bin/bash

# The purpose of this script is to run FSL's automated BET on high-resolution
# struct images.

# Define top_dir
top_dir=$(<../top_dir_win.txt)

subjects=(subject-001 subject-002 subject-003 subject-004 subject-005 subject-006 subject-007
          subject-008 subject-009 subject-010 subject-011 subject-012 subject-013 subject-014
          subject-015 subject-016 subject-017 subject-018 subject-019 subject-020 subject-021
          subject-022 subject-023 subject-024 subject-025 subject-026 subject-027 subject-028
          subject-029 subject-030)


for subj in ${subjects[@]}; do

  echo $subj
    # Set Dirs
    subj_path=${top_dir}${subj}

    # Trial and error testing established that f = 0.2 was appropriate for MOST
    # subjects. However, f value was further adjusted for a few subjects:

    # subject-003 - too conservative. Used f = 0.1
    # subject-005 - too liberal. Used f = 0.3
    # subject-015 - too liberal. Used f = 0.25. Also supplied center of mass (260 226 76)
    # subject-021 - too conservative, however optimal value was f = 0.3 with center of mass supplied (253 292 63)
    # subject-026 - too conservative. Used f = 0.15
    # subject-027 - too liberal. Used f = 0.3

    f_value=0.2
    f_label="${f_value#*.}"

    # Define input and output images
    input_im=${subj_path}/${subj}_struct
    output_im=${input_im}_brain_f0${f_label}


    bet ${input_im} ${output_im}  -f ${f_value} -g 0


done
