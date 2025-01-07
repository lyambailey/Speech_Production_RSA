#!/bin/bash


# The purpose of this script is to transform searchlight results from native
# subject space to MNI space using ANTs (Advanced Normalization Tools)

# set number of threads
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8

#####################
# Instead of computing transformations one subject at a time, it is more efficient to parallelize
# these computations. This means that we must first write the "instructions" for each transformation
# to a text file - think of these text files like FEAT design.fsf files. To simplify things, I will
# refer to these txt files as ANTS_DESIGN files.
# This will allow us to then compute transformations for multiple subjects in parallel.
#####################

# Define list of subjects
subjects=(subject-001 subject-002 subject-003 subject-004 subject-005 subject-006 subject-007
          subject-008 subject-009 subject-010 subject-011 subject-012 subject-013 subject-014
          subject-015 subject-016 subject-017 subject-018 subject-019 subject-020 subject-021
          subject-022 subject-023 subject-024 subject-025 subject-026 subject-027 subject-028
          subject-029 subject-030)

# Remove bads
delete=(subject-008 subject-009 subject-015 subject-018)


# Remove missing subject from subjects list
subjects=( "${subjects[@]/$delete}" )

# Define important directories
top_dir=$(<../top_dir_linux.txt)

data_dir=/media/lyam/Production_Effect_MVPA/MRIanalyses/quickread/subject_level_output
searchlight_dir=${data_dir}/RSA_output/1_searchlight_results
output_dir=${data_dir}/RSA_output/2_searchlight_results_in_MNI
mkdir -p ${output_dir}

# Define two directories...
# One in which to store the design files ("intructions") for each transform
design_dir=${output_dir}/ANTs_design_files
mkdir -p ${design_dir}

# And one in which to store the actual transformation matrices. These are stored in
# a superordinate folder, because they are useful for different analyses.
mat_dir=${data_dir}/ants_transformation_matrices
mkdir -p ${mat_dir}

# Also create a tempory txt file to which we will redirect output from ANTs commands
# (this stops a lot of junk being printed to terminal when we run the script)
temp_log=${mat_dir}/most_recent_ants_reg_output.txt

# Define paths to MNI template
standard_fn=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain

# Define conditions and models
conditions=(aloud silent)
models=(articulatory orthographic phonological semantic visual)

# Loop through subjects. For each subject, make 3 design files:
# - One aligns highres T1 image with example_func
# - One aligns MNI template to highres T1
# - One combines the *inverse* transforms generated above, and applies
#   them to subjects' native-space searchlight maps
# Note - Github issue explaining why I used this approach: https://github.com/ANTsX/ANTs/issues/1431

echo "Writing design files..."

for subject in ${subjects[@]}; do
  echo ${subject}

  # Define skull-stripped brain
  t1_fn=/media/lyam/Production_Effect_MVPA/MRIdata/${subject}/${subject}_struct_brain

  # Define path to feath folder for run #1
  feat_path=${data_dir}/${subject}/${subject}_quickread_1_LSA.feat

  # Define example_func image (from this subject's first-level feat folder)
  example_func_fn=${feat_path}/reg/example_func

  # Define cope image
  cope_fn=${feat_path}/stats/cope1

  # Add some padding to example func (improves registration performance)
  example_func_padded_fn=${mat_dir}/${subject}_example_func_padded
  ImageMath 3 ${example_func_padded_fn}.nii.gz PadImage ${example_func_fn}.nii.gz 20

  # Define transform design filenames
  highres2example_func_design=${design_dir}/${subject}_highres2example_func.txt
  standard2highres_design=${design_dir}/${subject}_standard2highres.txt


  # Define prefixes that we will use to label transformation matrices
  highres2example_func_prefix=${mat_dir}/${subject}_highres2example_func
  standard2highres_prefix=${mat_dir}/${subject}_standard2highres

  # Write design for rigid + deformation highres -> example_func transform
  echo \
  "antsRegistration \
  -d 3 \
  -t Rigid[ 0.1 ] \
  -f 2x1 -s 1x0vox \
  -m Mattes[ ${example_func_padded_fn}.nii.gz , ${t1_fn}.nii.gz , 1, 32 ] \
  -c [ 50x50, 1e-7, 10 ] \
  -o [ ${highres2example_func_prefix}, ${highres2example_func_prefix}Deformed.nii.gz, ${highres2example_func_prefix}InverseDeformed.nii.gz ] \
  -v 1 \
  -t BSplineSyN[ 0.1, 10, 0, 3 ] \
  -g 0.01x1x0.01 \
  -m Mattes[ ${example_func_padded_fn}.nii.gz , ${t1_fn}.nii.gz , 1, 32 ] \
  -f 1 -s 0vox \
  -c 25 \
  --float 0" \
  > ${highres2example_func_design}

  # # Write design for rigid + SyN MNI -> highres transform
  echo \
  "antsRegistration \
        -v 1 \
        -d 3 \
        -t Affine[ 0.1 ] \
        -m Mattes[ ${t1_fn}.nii.gz, ${standard_fn}.nii.gz , 1, 32 ] \
        -c [ 1000x500x250x0,1e-6,10 ] \
        -o [ ${standard2highres_prefix}, ${standard2highres_prefix}Deformed.nii.gz, ${standard2highres_prefix}InverseDeformed.nii.gz ] \
        -f 12x8x4x2 \
        -s 4x3x2x1vox \
        -t SyN[ 0.1,3,0 ] \
        -m Mattes[ ${t1_fn}.nii.gz, ${standard_fn}.nii.gz , 1, 32] \
        -c [ 50x0,1e-6,10 ] \
        -f 2x1 \
        -s 1x0vox \
        --float 0 " \
        > ${standard2highres_design}

  # Loop through conditions and models
  for condition in ${conditions[@]}; do
    for model in ${models[@]}; do

      # Define design file for this condition/model
      apply_transforms_design=${design_dir}/${subject}_${condition}_${model}_apply_transforms.txt

      # Define searchlight map in native space for this condition/model
      searchlight_fn=${searchlight_dir}/${subject}_${condition}_${model}_searchlight_results

      # Define output filename
      searchlight_in_MNI_fn=${output_dir}/$(basename ${searchlight_fn})_MNI

      # Write design to combine the two (inverse) transforms defined earlier,
      # and apply them to this searchlight map.Note that "-t [transform, 1]" = use inverse
      echo \
      "antsApplyTransforms \
      -d 3 \
      -i ${searchlight_fn}.nii.gz \
      -r ${standard_fn}.nii.gz \
      -t [${standard2highres_prefix}0GenericAffine.mat, 1] \
      -t ${standard2highres_prefix}1InverseWarp.nii.gz \
      -t [${highres2example_func_prefix}0GenericAffine.mat, 1] \
      -o ${searchlight_in_MNI_fn}.nii.gz \
      -v 1 \
      --float 0" \
      > ${apply_transforms_design}

      #
    done # models
  done # conditions
done # subjects

# Add deform command above output line if desired:
# -t ${highres2example_func_prefix}1InverseWarp.nii.gz \

##############################################################
# Now, use GNU parallel to run our design files.
##############################################################

# Detect number of available cores -1 [Note: the -1 prevents crashing if we ever want
# to do other stuff while the parallel analyses are running. To simply use the maximum
# number of available cores, use n_cores=$( nproc )]
n_cores="$(($( nproc )-1))"

# First do highres -> example_func
# echo "Computing highres -> example_func transforms..."
# ls ${design_dir}/*_highres2example_func.txt | parallel --jobs ${n_cores} eval \
#     > ${temp_log} 2>&1 # this line prints output to a temporary txt file instead of terminal

# # Next do standard template -> highres
# echo "Computing standard -> highres transforms..."
# ls ${design_dir}/*_standard2highres.txt | parallel --jobs ${n_cores} eval \
#     > ${temp_log} 2>&1 # this line prints output to a temporary txt file instead of terminal

# Finally, combine the two *inverse* transforms and apply them to the searchlight maps
echo "Applying transforms to searchlight maps..."
ls ${design_dir}/*_apply_transforms.txt | parallel --jobs ${n_cores} eval \
    > ${temp_log} 2>&1 # this line prints output to a temporary txt file instead of terminal
