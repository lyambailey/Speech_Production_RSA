% -------------------------------------------------------------------------

% The purpose of this script is to perform RSA on data from each individual
% subject, using a whole-brain searchlight.

% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define conditions
conditions = {...
    'aloud',...
      'silent'
    };

% Define models
models = {...
    'articulatory', ...
    'orthographic', ...
    'phonological', ...
    'semantic', ...
    'visual'...
    };

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

% subjects 008, 009, 015, 018 should be removed (due to missing data or
% ineligibility)
bads = {'subject-008', 'subject-009', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];


% Define important paths, to make things easier later on
data_path = fullfile(top_dir, 'MRIanalyses', 'quickread', 'subject_level_output');
assets_path = fullfile(top_dir, 'MRIanalyses', 'assets');
out_path = fullfile(data_path, 'RSA_output', '1_searchlight_results');

if ~exist(out_path, 'dir')
    mkdir(out_path)
end

% Define parameters for our searchlight
search_args = struct();
search_args.metric = 'correlation';
search_args.center_data = true;
search_args.post_corr_func = [];

search_measure = @cosmo_target_dsm_corr_measure;

% Create a text file as a record of the parameters we used (apologies,
% the code here is a little clunky).
date_time = string(strrep(char(datetime), ':', '_'));
params_fn = fullfile(out_path, sprintf('searclight_params_%s.txt', date_time));

param_rows = {'metric'; ...
                'center_data'; ...
                'post_corr_func'; ...
                'search_measure' ...
                };
            
param_vals = {search_args.metric; ...
                search_args.center_data; ...
                search_args.post_corr_func; ...
                func2str(search_measure) ...
            };

params = [param_rows, param_vals];

writetable(cell2table(params), params_fn, 'WriteVariableNames',0)


% Loop through  subjects
for i_sub=1:numel(subjects)
    subject_id = subjects{i_sub};
    disp(subject_id)

    % Load in the alltrials data for this subject. We will use it to
    % define the searchlight space, and THEN split it into its
    % constituent conditions
    ds_fn = fullfile(data_path, '1_stacked_firstlevel_COPEs', ...
            sprintf('%s_alltrials_stacked_data', subject_id));
    load(ds_fn)

    % Remove useless data 
    ds_alltrials = cosmo_remove_useless_data(ds_stacked);

    % Use the clean alltrials dataset to define the searchlight space
    radius = 3;
    ds_nbrhood = cosmo_spherical_neighborhood(ds_alltrials, 'radius', radius);

    % Now, split the alltrials data up into its constituent conditions
    ds_aloud = cosmo_slice(ds_alltrials, strcmp(ds_alltrials.sa.conditionLab, 'aloud'), 1);
    ds_silent = cosmo_slice(ds_alltrials, strcmp(ds_alltrials.sa.conditionLab, 'silent'), 1);

    % Loop through conditions, defining RSA models and running the
    % searchlight
    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};

        % Pull the ds for this condition
        ds_condition = eval(sprintf('ds_%s', condition));

        % Average over repeated samples for each word
        ds_condition = cosmo_average_samples(ds_condition, 'split_by', {'targets'});

        % Load in the DSMs (hypothesis models) for this subject and
        % condition, and append each to searchlight_args.glm_dsm. 
        search_args.glm_dsm = {};

        % Loop over our pre-defined list of models, pulling the
        % correspoding DSM and appending it to searchlight_args.glm_dsm.
        % Note that here we use a convenience function (get_model, defined
        % at the end of this script) for formatting the imported csv files.
        % Note that models will be appended in the order in which they are
        % defined by the "models" cell array
        dsms_path = fullfile(assets_path, subject_id, 'RSA_models', 'quickread');

        for i_model=1:numel(models)

            % Define model
            model = models{i_model};

            % Read the appropriate csv from disk using a custom function.
            % Note that this function returns multiple outputs (as it is
            % used in another script) - the untransformed squareform
            % dissimilarity matrix (which we want) is the first, so
            % suppress all other output with ~.
            dsm_fn = fullfile(dsms_path, sprintf('quickread_%s_%s_%s.csv', subject_id, condition, model));
            [dsm, ~]  = get_rsa_model(dsm_fn);

            % Append to search_args.glm_dsm
            search_args.glm_dsm{i_model} = dsm;

        end % models loop           

        % Run the searchlight
        results = cosmo_searchlight(ds_condition, ds_nbrhood, search_measure, search_args);

        % The searchlight results have one row in .samples for each
        % model. Add sensible labels to keep track of which row is
        % which model
        results.sa.models = transpose(models);

        % Now save the results for each model to disk
        results_split = cosmo_split(results,'models');

        for i=1:numel(models)
            model=models{i};

            % Pull the results for this model and its corresponding label
            this_model_results = results_split{i};
            this_model_label = this_model_results.sa.models{1};

            % Save to disk
            this_fn = fullfile(out_path, sprintf('%s_%s_%s_searchlight_results_testing_func.nii.gz', subject_id, condition, this_model_label));

            cosmo_map2fmri(this_model_results, this_fn);

        end % models loop
    end % conditions loop
end % subjects loop
