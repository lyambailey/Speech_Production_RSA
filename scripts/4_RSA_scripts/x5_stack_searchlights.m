% -------------------------------------------------------------------------

% The purpose of this script is to arrange all the (transformed-to-MNI)
% searchight results into a single dataset. This produces a single
% 'stacked' dataset per condition and hypothesis model.


% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define conditions and models
conditions = {...
    'aloud',...
    'silent'};

models = {...
    'articulatory', ...
    'orthographic', ...
    'phonological', ...
    'semantic', ...
    'visual'...
    };

% Define list of subjects
subjects = {...
            'subject-001', ...
            'subject-002', ...
            'subject-003', ...
            'subject-004', ...
            'subject-005', ...
            'subject-006', ...
            'subject-007', ... 
            'subject-008', ...  
            'subject-009', ...
            'subject-010', ...
            'subject-011', ...
            'subject-012', ...
            'subject-013', ...
            'subject-014', ... 
            'subject-015' ...
            'subject-016', ...
            'subject-017', ... 
            'subject-018', ...
            'subject-019', ...
            'subject-020', ...
            'subject-021', ...
            'subject-022', ...
            'subject-023', ...
            'subject-024', ...
            'subject-025', ...
            'subject-026', ... 
            'subject-027', ...
            'subject-028', ...
            'subject-029', ...
            'subject-030' ...
        };

% subjects 008, 009, 015, 018 should be removed (due to missing data or
% ineligibility)
bads = {'subject-008', 'subject-009', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];

% Define MNI template mask
assets_path = fullfile(top_dir, 'MRIanalyses', 'assets');
MNI_mask_fn = fullfile(assets_path, 'MNI152_T1_2mm_brain_mask.nii.gz');
MNI_mask = cosmo_fmri_dataset(MNI_mask_fn);

% Define cerebellum mask (we want to remove the cerebellum from all maps
% prior to statistical analysis)
cerebellum_mask_fn = fullfile(assets_path, 'Harvard_Oxford_ROIs', 'Cerebellum.nii.gz');
cerebellum_mask = cosmo_fmri_dataset(cerebellum_mask_fn);

% Remove cerebellum from MNI mask
MNI_mask_no_cereb = cosmo_slice(MNI_mask, cerebellum_mask.samples == 0, 2);

% Define paths, to make things easier later on
data_path = fullfile(top_dir, 'MRIanalyses', 'quickread', 'subject_level_output', 'RSA_output');
out_path = fullfile(top_dir, 'MRIanalyses', 'quickread', 'group_level_output', 'RSA_output');

% Loop through models, conditions, and subjects
for i_model=1:numel(models)
    model = models{i_model};

    disp(model);

    % Define output folder for this model
    this_model_out_path = fullfile(out_path, sprintf('%s_group_searchlight_output', model));

    if ~exist(this_model_out_path, 'dir')
        mkdir(this_model_out_path)
    end

    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};

        disp(condition)

        for i_sub=1:numel(subjects)
            subject_id = subjects{i_sub};

            %disp(subject_id)

            % Load in searchlight results for this subject and condition and
            % apply MNI mask (with cerebellum removed)
            ds_fn = fullfile(data_path, '2_searchlight_results_in_MNI', ...
                sprintf('%s_%s_%s_searchlight_results_MNI.nii.gz', subject_id, condition, model));

            ds = cosmo_fmri_dataset(ds_fn, 'mask', MNI_mask_no_cereb);

            % Assign targets (proxy for condition later on)
            ds.sa.targets = i_cond;

            % Assign chunks (proxy for subject_id later on)
            ds.sa.chunks = i_sub;

            % Add results to stacked dataset
           if i_sub == 1
               stacked_results = ds;
           else
               stacked_results = cosmo_stack({stacked_results, ds});
           end

        end % subjects loop

        % Save the stacked dataset to disk
        stacked_ds_fn = fullfile(this_model_out_path, ... 
            sprintf('stacked_searchlight_results_%s_%s', condition, model));

        save(fullfile(stacked_ds_fn), 'stacked_results');

    end % conditions loop
end % model
