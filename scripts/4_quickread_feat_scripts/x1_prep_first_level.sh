#!/bin/bash

# The purpose of this script is to prepare FEAT design files for running
# LSA on data from the 'quickread' experiment. These files are executed
# by a different script in this folder.

# Define top_dir
top_dir=$(<../top_dir_linux.txt)/MRIanalyses

subjects=(subject-001 subject-002 subject-003 subject-004 subject-005 subject-006 subject-007
          subject-008 subject-010 subject-011 subject-012 subject-013 subject-014 subject-015
          subject-016 subject-017 subject-018 subject-019 subject-020 subject-021 subject-022
          subject-023 subject-024 subject-025 subject-026 subject-027 subject-028 subject-029
          subject-030)

runs=(1 2 3 4)

# define template file
template=${top_dir}/assets/FSL_templates/quickread_template_firstLevel.fsf

# Define word list
allWords=(account answer author beauty campaign century department education envelope forest
          garden handle industry journey kingdom language machine message ocean painting pebble
          powder record sailor speech summer ticket turnip valley wheat)

for subj in ${subjects[@]}; do

  for run in ${runs[@]}; do

    echo ${subj}

      # Set Dirs
      template_out_path=${top_dir}/assets/${subj}
      log_file_path=${top_dir}/assets/${subj}/${subj}_log_files

      # Copy template for this subject and run
      subj_run_template=${template_out_path}/${subj}_quickread_${run}_firstlevel_design.fsf
      cp $template ${subj_run_template}

      # Change all instances of subject #
      sed -i 's/subject-number/'${subj}'/g' ${subj_run_template}  # without the 'g', it only replaces the first instance in each line (I think)

      # Insert run number
      sed -i 's/runNumber/'${run}'/' ${subj_run_template}

      # Now we need to insert the appropriate log files for every EV.

      # Read in words in each condition
      aloud_words_path=../../behavioural_data/fmri_runs2/${subj}/aloud_words.txt
      silent_words_path=../../behavioural_data/fmri_runs2/${subj}/silent_words.txt

      readarray aloud_words < ${aloud_words_path}
      readarray silent_words < ${silent_words_path}

      # Loop through words
      for word in ${allWords[@]}; do

        # Test which condition this word is in, and assign the appropraite condition label
        if [[ " ${aloud_words[*]} " =~ "${word}" ]]; then
          condition=aloud

        elif [[ " ${silent_words[*]} " =~ "${word}" ]]; then
          condition=silent
        fi

        # Replace the (incorrect) file name in the template: subject-run-word.txt
        # ... with the correct format: subject-run-condition-word.txt
        old_format="${subj}"_quickread"${run}"_"${word}".txt
        new_format="${subj}"_quickread"${run}"_"${condition}"_"${word}".txt

        sed -i 's/'${old_format}'/'${new_format}'/' ${subj_run_template}

      done # words
    done # runs
  done # subjects
