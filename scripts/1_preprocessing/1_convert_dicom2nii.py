# The purpose of this script is to convert raw DICOM images to
# 4D nifti data files


import shutil, os, glob
import subprocess

# Define top top_dir
top_dir = open('../top_dir_win.txt').read().replace('\n', '')

subjects = ['subject-001', 'subject-002', 'subject-003', 'subject-004', 'subject-005',
            'subject-006', 'subject-007', 'subject-008', 'subject-009', 'subject-010',
            'subject-011', 'subject-012', 'subject-013', 'subject-014', 'subject-015',
            'subject-016', 'subject-017', 'subject-018', 'subject-019', 'subject-020',
            'subject-021', 'subject-022','subject-023', 'subject-024', 'subject-025',
            'subject-026','subject-027', 'subject-028','subject-029', 'subject-030']

for subj in subjects:
    print(subj)


    subj_path = top_dir + subj
    source_path = subj_path + '/DICOM/'
    raw_files = os.listdir(source_path)

    ## Structural image

    # some variation in folder names, so easiest to locate the T1 folder based on partial string match
    struct_partial = 'T1_MPRAGE'
    struct = [i for i in raw_files if struct_partial in i][0]

    # remove any old nifti files from source dir
    for fname in glob.glob(source_path + struct + '/*.nii.gz'):
        os.remove(fname)

    # convert DICOM to nifti
    subprocess.check_call([top_dir + '/MRIanalyses/assets/mricron/dcm2niix',
                          '-x', 'y',
                          '-z', 'i',
                          source_path + struct
                         ])

    # rename to sensible name and move up to subject directory
    orig_file = glob.glob(source_path + struct + '/*Crop*')[0]
    new_file = subj_path + '/' + subj + '_struct.nii.gz'


    os.rename(orig_file, new_file)


    # remove any extra files created during conversion
    for fname in glob.glob(source_path + struct[0] + '/*.nii.gz'):
        os.remove(fname)

    # Functionals
    func_labels = ['Quick_Read_1', 'Quick_Read_2', 'Quick_Read_3', 'Quick_Read_4']


    for func in func_labels:
        fmri_run = [i for i in raw_files if func in i][0]
        print(func)

        # remove any old nifti files from source dir
        for fname in glob.glob(source_path + fmri_run + '/*.nii.gz'):
            os.remove(fname)

        subprocess.check_call([top_dir + '/MRIanalyses/assets/mricron/dcm2niix',
                              '-x', 'y',
                              '-z', 'i',
                              source_path + fmri_run
                             ])

        # rename to sensible name
        orig_file = glob.glob(source_path + fmri_run + '/' + fmri_run + '*.nii.gz')[0]

        new_file = subj_path + '/' + subj + '_' + func.lower() + '.nii.gz'
        os.rename(orig_file, new_file)
