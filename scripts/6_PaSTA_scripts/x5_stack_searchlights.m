% -------------------------------------------------------------------------
% The purpose of this script is to arrange all the PaSTA searchight results
% into a single dataset. This produces a single 'stacked' dataset per
% condition and measure.

% I know this seems a _little_ redundant (why not simply read in each
% subject's data individually in the next script?). The reason is that
% loading data from every subject takes time, so I created this script to
% help with debugging further down the pipeline (it's easier to debug
% something when you dont have to wait 20 minutes for the script to read in
% data before it hits an error!).
% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define subjects
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
% Subjects 001, 002, 008, 015, and 018 should not be included, due to
% missing data or ineligibility
bads = {'subject-001', 'subject-002', 'subject-008', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];


% Define conditions and measures
conditions = {...
    'aloud',...
    'silent'...
    };

measures = {...
        'study-test_similarity_memory_effsize', ...
        'study-test_transformation_memory_effsize', ...
        'study-test_between_subjects_transformation_effsize' ...
    };

% Define input and output paths
data_path = fullfile(top_dir, 'MRIanalyses', 'PE', 'subject_level_output', 'PaSTA_output_MNI');
out_path = fullfile(top_dir, 'MRIanalyses', 'PE', 'group_level_output', 'PaSTA_output_MNI');


% Loop through measures, conditions, and subjects
for i_measure=1:numel(measures)
    measure = measures{i_measure};

    disp(measure);

    % Define output folder for this measure
    this_measure_out_path = fullfile(out_path, sprintf('%s_group_searchlight_output', measure));

    if ~exist(this_measure_out_path, 'dir')
        mkdir(this_measure_out_path)
    end

    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};
        
        % Define stacked_results as an empty struct. We will append data
        % from each subject on each iteration of the loop below
        stacked_results = struct();

        disp(condition)

        for i_sub=1:numel(subjects)
            subject_id = subjects{i_sub};
            
            disp(subject_id)

            % subject-002 not included in sub-mem-eff analyses
            if contains(measure, 'memory_effsize') && strcmp(subject_id, 'subject-002')
                continue;
            end


            % Load in searchlight results for this subject and condition
            % and apply MNI mask (with cerebellum already removed)
            ds_fn = fullfile(data_path, '1_searchlight_results', ...
                sprintf('%s_%s_%s.nii.gz', subject_id, condition, measure));

            ds = cosmo_fmri_dataset(ds_fn);
            

            % Assign targets (proxy for condition later on)
            ds.sa.targets = i_cond;

            % Assign chunks (proxy for subject_id later on)
            ds.sa.chunks = i_sub;

            % Add results to stacked dataset
           if ~isfield(stacked_results, 'samples')
               stacked_results = ds;
           else
               stacked_results = cosmo_stack({stacked_results, ds});
           end

        end % subjects loop
        
        % Remove useless data
        stacked_results = cosmo_remove_useless_data(stacked_results);

        % Save the stacked dataset to disk
        stacked_ds_fn = fullfile(this_measure_out_path, ... 
            sprintf('stacked_searchlight_results_%s_%s', condition, measure));

        save(fullfile(stacked_ds_fn), 'stacked_results');

    end % conditions loop
end % measures loop
