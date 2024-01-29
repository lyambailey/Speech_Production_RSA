#!/bin/bash

# The purpose of this script is to take the RSA searchlight results from individual
# subjects and combine them into a single average searchlight map (one map per
# condition/model)

# Define top_dir
top_dir=$(<../top_dir_linux.txt)

# Define directories
data_dir=${top_dir}/MRIanalyses/quickread
searchlight_dir=${data_dir}/subject_level_output/RSA_output/2_searchlight_results_in_MNI

# Define models and conditions
models=(articulatory orthographic phonological semantic visual)

conditions=(aloud silent)

# Out of an over-abundance of caution, we're going to compute average maps in a
# temporary folder in the group_level_output/RSA_output folder. This ensures
# that no unwanted files get mixed into the average for any model. This is probably
# not necessary, but it does not hurt...
temp_output_dir=${data_dir}/group_level_output/RSA_output/average_searchlight_results_temp
mkdir -p ${temp_output_dir}

# Loop through models and conditions. On each loop, combine all subjects'
# searchlight maps into a single group average
for model in ${models[@]}; do

	# Create a directory to house group-level output for each model (we will
	# ultimately move our average searchlight files to this directory)
	model_output_dir=${data_dir}/group_level_output/RSA_output/${model}_group_searchlight_output/
	mkdir -p ${model_output_dir}

	for condition in ${conditions[@]}; do

		# Get the searchlight maps for this model/condition
		pattern="*${condition}_${model}_*.nii.gz"
		readarray -t searchlight_fns < <(find ${searchlight_dir} -name ${pattern})

		# Copy to temporary output dir
		cp ${searchlight_fns[@]} ${temp_output_dir}/

		# Get list of files in new directory
		readarray -t new_searchlight_fns < <(find ${temp_output_dir} -name ${pattern})

		# Average files together. Ordinarily we'd do this by adding a bunch of files
		# together with fslmaths file1 -add file2 -add file3 etc and then diving by
		# the number of files. However, manually writing -add ... for each file is tedious
		# and prone to error. Therefore, we're going to define a text string "fslmaths ..."
		# and then use a loop to append each -add statement

		# Start the string off with the first file in our array of filenames
		add_command="fslmaths ${new_searchlight_fns[0]} "

		# Now use a loop to append an -add flag along with the next filename
		for i in ${new_searchlight_fns[@]:1}; do   # note that [@]:1 indexes all elements except for the first. Otherwise use [@]:first:last
			add_command+="-add ${i} "
		done

		# Define output filename, append to the command and run it
		average_fn=${temp_output_dir}/average_searchlight_map_${condition}_${model}
		add_command+=" $average_fn"

		eval $add_command

		# # Now divide the resultant image by the number of input files
		n_searchlights=${#new_searchlight_fns[@]}
		fslmaths ${average_fn} -div ${n_searchlights} ${average_fn}

		# Remove the individual searchlight files
		rm ${temp_output_dir}/subject-*

		# Finally, move the newly-created average searchlight file to the appropraite
		# [model]_group_searchlight_output folder
		mv ${average_fn}.nii.gz ${model_output_dir}/


	done # conditions
done # models

# # Delete the temporary directory
rm -rf ${temp_output_dir}
