# coding: utf-8

# The purpose of this script is to read in the raw cluster tables generated in
# the previous script and re-format them into interpretable results tables.

# Import dependencies
import pandas as pd
import numpy as np
import os

# Define important directories
top_dir = open('../top_dir_linux.txt').read().replace('\n', '')
data_dir = os.path.join(top_dir, 'MRIanalyses', 'PE','group_level_output', 'PaSTA_output_MNI', '1_tables_and_figures')

out_path = os.path.join(data_dir, 'cluster_tables_parsed')
os.makedirs(out_path, exist_ok=True)

# Define measures and contrasts
measures = ['study-test_similarity_memory_effsize', 'study-test_transformation_memory_effsize']

contrasts = ['aloud-silent', 'silent-aloud']

# # Loop through measures and contrasts. On each loop, pull the raw cluster table
# # and re-format it.
for measure in measures:
    for contrast in contrasts:

        # Define path to raw cluster table
        infile = os.path.join(data_dir, 'cluster_tables', 'cluster_table_%s_%s.csv' %(contrast, measure))

        # Read in file
        df = pd.read_csv(infile, header=0)

        # If df is empty, skip
        if df.empty:
            continue

        # Re-number cluster N column, by ascending Mean BF, Cluster extent, and xyz
        df['Mean BF'] = df['Mean BF'].astype(float)
        df['Cluster N'] = df['Mean BF'].rank(method='dense', ascending=False).astype(int)

        # Convert Anatomical labels column to list
        df['Anatomical labels'] = df['Anatomical labels'].str.split('+')

        # Split the contents of the Anatomical labels column into separate rows
        df = df.explode('Anatomical labels')

        # Split (voxels) from anatomical label into separate column
        df[['Anatomical labels', 'voxels']] = df['Anatomical labels'].str.split('(', expand=True)

        # Delete whitespace in label columns (allows us to match labels across columns below)
        df['Anatomical labels'] = df['Anatomical labels'].str.strip()
        df['COG label'] = df['COG label'].str.strip()

        # Bug: COG label will not match an anatomical label in some instances. This seems to be a
        # result of SLIGHTLY different naming conventions between atlasquery (where the COG label
        # comes from) and the anatomical volumes in the assets folder (where the anatomical labels
        # come from). For example, atlasquery uses "Temporal_Fusiform_Cortexanterior_division",
        # while the anatomical volumes use "Temporal_Fusiform_Cortex_anterior". To fix this, we need
        # to change the affected COG labels to match the anatomical labels.
        df['COG label'] = df['COG label'].str.replace("Cortexanterior_division", "Cortex_anterior")
        df['COG label'] = df['COG label'].str.replace("Cortexposterior_division", "Cortex_posterior")
        df['COG label'] = df['COG label'].str.replace("Cortexinferior_division", "Cortex_inferior")
        df['COG label'] = df['COG label'].str.replace("Cortexsuperior_division", "Cortex_superior")
        df['COG label'] = df['COG label'].str.replace("Gyruspars_opercularis", "Gyrus_pars_opercularis")
        df['COG label'] = df['COG label'].str.replace("Gyruspars_triangularis", "Gyrus_pars_triangularis")

        # Note that we must use regex=False for strings containing parentheses)
        df['COG label'] = df['COG label'].str.replace(
            'Juxtapositional_Lobule_Cortex_(formerly_Supplementary_Motor_Cortex)', 'Supplementary_Motor_Area',
            regex=False)

        # If COG label does not match anatomical label, replace it with NaN
        # (not sure why, but we first have to reset index)
        df = df.reset_index(drop=True)
        df.loc[df['COG label'] != df['Anatomical labels'], 'COG label'] = np.nan

        # Replace underscores with spaces in anatomical labels
        df['Anatomical labels'] = df['Anatomical labels'].str.replace('_', ' ')

        # Change hemi suffix to single-letter prefix
        df.loc[df['Anatomical labels'].str.contains('LH'), 'Anatomical labels'] = 'L ' + df['Anatomical labels']
        df.loc[df['Anatomical labels'].str.contains('RH'), 'Anatomical labels'] = 'R ' + df['Anatomical labels']
        df['Anatomical labels'] = df['Anatomical labels'].str.replace(' LH','')
        df['Anatomical labels'] = df['Anatomical labels'].str.replace(' RH','')

        # (re-)Append Anatomical labels with N voxels, delete voxels column
        df['Anatomical labels'] = df['Anatomical labels'] + ' (' + df['voxels']
        df = df.drop(columns=['voxels'])

        # Now, boldface the anatomical label if COG label is not nan
        df.loc[df['COG label'].notnull(), 'Anatomical labels'] = '** ' + df['Anatomical labels'] + ' **'

        # Drop COG label column
        df = df.drop(columns=['COG label'])

        # Sort by Cluster N, then Anatomical label
        df = df.sort_values(['Cluster N', 'Anatomical labels'])

        # Round x, y, z values (0 decimal places)
        df['x'] = df['x'].round(0)
        df['y'] = df['y'].round(0)
        df['z'] = df['z'].round(0)

        # Round mean BF and SD (2 decimal places)
        df['Mean BF'] = df['Mean BF'].round(2)

        # Remove duplicates of Cluster N, Cluster extent (mm^3), Mean/Max BF, xyz, but otherwsise preserve rows
        cols = ['Cluster N', 'Cluster extent (mm^3)', 'Mean BF', 'Max BF', 'x', 'y', 'z']
        df.loc[df.duplicated(subset=cols), cols] = np.nan

        # Re-order columns, Cluster N, Cluster extent (mm^3), Mean/Max BF, xyz, Anatomical labels
        df = df[['Cluster N', 'Cluster extent (mm^3)', 'Mean BF',
                'Max BF', 'x', 'y', 'z', 'Anatomical labels']]

        # Write out to CSV file
        outfile = os.path.join(out_path + '/cluster_table_parsed_%s_%s.csv' %(measure,contrast) )
        df.to_csv(outfile, sep=',', header=True, index=False)
