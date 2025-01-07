#!/bin/bash

# This script runs first-level FEAT design files (created by a previous script)
# in parallel, for maximum efficiency

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define assets path
assets_path=${top_dir}/MRIanalyses/assets

# Define subjects
subjects=(subject-001 subject-002 subject-003 subject-004 subject-005 subject-006 subject-007
          subject-008 subject-009 subject-010 subject-011 subject-012 subject-013 subject-014
          subject-015 subject-016 subject-017 subject-018 subject-019 subject-020 subject-021
          subject-022 subject-023 subject-024 subject-025 subject-026 subject-027 subject-028
          subject-029 subject-030)


# Loop through subjects, copying the necessary .fsf files to a temporary folder.
# (it's easier to feed files to the parallel function if they're all in the same dircteory)
temp_dir=./temp_fsf_dir
mkdir -p ${temp_dir}

for subject in ${subjects[@]}; do

  subject_dir=${assets_path}/${subject}

  # Pro tip: using cp prefix_{1..n}_suffix copies n files at once! Much more
  # efficient than a loop or one line per file!
  cp ${subject_dir}/${subject}_quickread_{1..4}_firstlevel_design.fsf ${temp_dir}

done

# Detect number of available cores -1 [Note: the -1 prevents crashing if we ever want
# to do other stuff while the feat analyses are running. To simply use the maximum
# number of available cores, use n_cores=$( nproc )]
n_cores="$(($( nproc )-1))"

# Grab fsf files in the temporary directory and feed them to FEAT using the
# parallel function. Number of parallel jobs (--jobs argument) is determinned
# by the number of available cores-1
ls ${temp_dir}/*.fsf | parallel --jobs ${n_cores} feat

# Remove temporary directory
rm -r ${temp_dir}
