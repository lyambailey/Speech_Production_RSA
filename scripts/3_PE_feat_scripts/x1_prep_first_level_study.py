# The purpose of this script is to prepare FEAT design files for running
# LSA on data from the Study Phase of the 'PE' experiment. These files are
# exceuted by a different script in this folder.

# Import dependencies
import shutil
import sys
import os
from os.path import join as join


# Define topDir
with open('../top_dir_linux.txt', 'r') as t:
    topDir = '/' + t.readline().rstrip()

# Define important dirs
assetsPath = join(topDir, 'MRIanalyses', 'assets')
behavPath = join(topDir, 'behavioural_data')
origTemplateFn = join(assetsPath, 'FSL_templates', 'PE_study_template_firstLevel.fsf')

# Define subjects and runs
subjects = ['subject-002', 'subject-003','subject-004','subject-005','subject-006',
            'subject-007','subject-008','subject-009','subject-010','subject-011',
            'subject-012','subject-013','subject-014', 'subject-015', 'subject-016',
            'subject-017', 'subject-018', 'subject-019', 'subject-020', 'subject-021',
            'subject-022', 'subject-023', 'subject-024', 'subject-025', 'subject-026',
            'subject-027', 'subject-028', 'subject-029', 'subject-030']

runs = ['study_1', 'study_2']

# Loop through subjects and runs. On each loop, make a copy of the original design template, move it to the appropriate
# folder in assets, and fill in the details for this subject/run
for subject in subjects:

    print(subject)

    # Define subject dirs:

    # Input (for reading in word lists)
    subjectInDir = join(behavPath, 'fmri_runs1', subject)

    # Output (where we will write the new design file)
    subjectOutDir = join(assetsPath, subject)

    # Log file path
    logPath = join(assetsPath, subject, subject + '_log_files/')

    # Also define filenames for word lists
    aloud_fn = join(subjectInDir, 'aloud_words.txt')
    silent_fn = join(subjectInDir, 'silent_words.txt')

    # Read in aloud and silent word lists (in alphabetical order) and join together
    with open(aloud_fn) as a:
        aloud_words = sorted(a.read().split("\n"))
        aloud_words = list(filter(None, aloud_words))   # Removes empty list entry

    with open(silent_fn) as s:
        silent_words = sorted(s.read().split("\n"))
        silent_words = list(filter(None, silent_words))   # Removes empty list entry

    words = sorted(aloud_words + silent_words)

    for run in runs:

        # Define output path/filename for the design file we will create for this subject/run
        outputDesignFn = subjectOutDir + '/' + subject + '_PE_' + run + '_firstLevel_design.fsf'

        # Copy the template design file to the appropraite subject folder
        shutil.copy(origTemplateFn, outputDesignFn)

        # Open up the design file and make changes
        with open(outputDesignFn, 'r') as file:
            filedata = file.read()

        # Replace placeholders for subject# and run#
        filedata = filedata.replace('subjectLabel', subject)
        filedata = filedata.replace('runLabel', run)


        # Loop through words, replacing placeholders for EV labels (w1_, w2_, ...)
        # and log-file paths (w1fn, w2fn, ...)
        for idx, word in enumerate(words):

            # Check which condition this word belongs to
            if word in aloud_words:
                condition='aloud'
            elif word in silent_words:
                condition='silent'

            # idx should start at 1
            idx = str(idx+1)

            # Define placeholder string for EV label
            EV_pl = 'w' + idx + '_'

            # Define placeholder and real strings for log file

            # Note that the log files use a slightly different format for defining study number, so correct that:
            new_runLabel = run.replace('_', '')

            log_pl = 'w' + idx + 'fn'
            log_real = logPath + subject + '_PE_' + new_runLabel + '_' + condition + '_' + word + '.txt'

            # Replace placeholder strings with real strings
            filedata = filedata.replace(EV_pl, word)
            filedata = filedata.replace(log_pl, log_real)

            # Write the changes to file
            with open(outputDesignFn, 'w') as file:
                file.write(filedata)
