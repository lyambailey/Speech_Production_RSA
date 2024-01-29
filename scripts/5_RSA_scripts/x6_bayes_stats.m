% -------------------------------------------------------------------------

% The purpose of this script is to read in stacked searchlight results
% from all subjects, and perform group-level statistical testing (i.e.,
% compute Bayes factors) at every voxel. Statistical testing involves both:
% 1. testing whether searchlight results are different from zero (in each
% condition alone)
% 2. testing whether searchlight results are different between aloud and
% silent reading.

% Note that all of the above is performed independently for each hypothesis
% model.

% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define models and conditions
models = {...
    'articulatory', ...
    'orthographic', ...
    'phonological', ...
    'semantic', ...
    'visual'...
    };

conditions = {'aloud', 'silent'};


% Define path to group-level quickread data
data_path = fullfile(top_dir, 'MRIanalyses', 'quickread', 'group_level_output', 'RSA_output');

% Loop through models
for i_model=1:numel(models)
    model = models{i_model};
    disp(model)

    % Define output folder for this model
    out_path = fullfile(data_path, sprintf('%s_group_searchlight_output', model));

    % Read in stacked searchlights from each condition
    ds_aloud_fn = fullfile(out_path, sprintf('stacked_searchlight_results_aloud_%s', model));
    ds_silent_fn = fullfile(out_path, sprintf('stacked_searchlight_results_silent_%s', model));

    ds_aloud = load(ds_aloud_fn);
    ds_aloud = ds_aloud.stacked_results;

    ds_silent = load(ds_silent_fn);
    ds_silent = ds_silent.stacked_results;

    % First, run paired-samples t-test comparing aloud vs silent, using our
    % predfined do_twosample_bayes function

    % Note that we only need to provide the function with the dataset their
    % raw form - no need to remove useless data (this is done by the
    % function)
    bayes_AvS_map = do_twosample_bayes(ds_aloud, ds_silent);

    % Load group-average searchlight maps for this model, masked with
    % the output from the paired-samples ttest. The masking ensures
    % an equal number of voxels in each map (both the average maps and
    % the bayes map) - this allows the next step to run smoothly.
    ds_aloud_av_fn = fullfile(out_path, sprintf('average_searchlight_map_aloud_%s.nii.gz', model));
    ds_silent_av_fn = fullfile(out_path, sprintf('average_searchlight_map_silent_%s.nii.gz', model));

    ds_aloud_av = cosmo_fmri_dataset(ds_aloud_av_fn, 'mask', bayes_AvS_map);
    ds_silent_av = cosmo_fmri_dataset(ds_silent_av_fn, 'mask', bayes_AvS_map);

    % Decompose the AvS map into aloud-silent and silent-aloud,
    % using the group-average searchlight maps
    bayes_aloud_minus_silent_map = cosmo_slice(bayes_AvS_map, ds_aloud_av.samples > ds_silent_av.samples, 2);
    bayes_silent_minus_aloud_map = cosmo_slice(bayes_AvS_map, ds_aloud_av.samples < ds_silent_av.samples, 2);

    % Save the two maps to disk
    bayes_aloud_minus_silent_map_fn = fullfile(out_path, sprintf('bayes_map_aloud-silent_%s.nii.gz', model));
    cosmo_map2fmri(bayes_aloud_minus_silent_map, bayes_aloud_minus_silent_map_fn);

    bayes_silent_minus_aloud_map_fn = fullfile(out_path, sprintf('bayes_map_silent-aloud_%s.nii.gz', model));
    cosmo_map2fmri(bayes_silent_minus_aloud_map, bayes_silent_minus_aloud_map_fn);

    % Next, run onesample t-test on each condition alone (test correlations against H0 of zero).
    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};
        disp(condition)

        % Grab the dataset for this condition, remove useless data
        ds_thiscond = eval(sprintf('ds_%s', condition));
        bayes_thiscond_map = do_onesample_bayes(ds_thiscond);


        bayes_map_thiscond_fn = fullfile(out_path, sprintf('bayes_map_%s_%s.nii.gz', condition, model));
        cosmo_map2fmri(bayes_thiscond_map, bayes_map_thiscond_fn);

    end % conditions   
end % model
%%
% Function for performing a one-sample Bayes ttest at each voxel for a 
% given dataset (ds)
function bf_df = do_onesample_bayes(ds)

    % Remove uselss data from ds
    ds_useful = cosmo_remove_useless_data(ds);
    
    % Define a new data structure with the same properties as df (but NOT
    % the same samples). We will inset BF values into this new data struct
    % as samples.
    bf_df = struct();
    bf_df.fa = ds_useful.fa;
    bf_df.a = ds_useful.a;
    
    % Determine number of features in df (i.e. columns in df.samples)
    n_features = size(ds_useful.samples, 2); 
    
    % Loop through features, performing onesample ttest at each voxel
    for i_feat=1:n_features
        this_feat = ds_useful.samples(:,i_feat);

        % Get Bayes factor from ttest and insert it at the appropriate feature. 
        % Note we do not need to define h_0, because bf.ttest tests against 0 by default
        b10 = bf.ttest(this_feat, 'tail', 'right');
        bf_df.samples(:,i_feat) = b10;

%         % Update progress bar
%         prog=round((i_feat/n_features)*100);
%         textprogressbar(prog)

    end % features
            
end % end of function

% Function for performing a two-sample Bayes ttest comparing an aloud
% dataset (ds1) to a silent dataset (ds2)
function bf_df = do_twosample_bayes(ds1, ds2)

    % To ensure that the two datasets contains the same number of voxels
    % (and all in the correct place) we will first combine them
    ds_combined = cosmo_stack({ds1, ds2});
    ds_combined_useful = cosmo_remove_useless_data(ds_combined);

    n_features = size(ds_combined_useful.samples, 2);
    
    % Define a new data structure with the same properties as the combined ds. 
    % We will inset BF values into this new data struct as samples.
    bf_df = struct();
    bf_df.fa = ds_combined_useful.fa;
    bf_df.a = ds_combined_useful.a;
    
    % Now split the combined data back into the two conditions
    ds_split = cosmo_split(ds_combined_useful, 'targets');
    ds_aloud = ds_split{1};
    ds_silent = ds_split{2};
 
    
    % Loop through features, performing two-sample ttest at each voxel
    for i_feat=1:n_features
        aloud_vector = ds_aloud.samples(:,i_feat);
        silent_vector = ds_silent.samples(:,i_feat);
        
        % Use Bayes paired ttest to compare the two vectors. Insert the
        % bayes factor into the appropriate position in bf_df
        bf10 = bf.ttest(aloud_vector, silent_vector);
        
        bf_df.samples(:,i_feat) = bf10;

%         % Update progress bar
%         prog=round((i_feat/n_features)*100);
%         textprogressbar(prog)

    end % features
            
end % end of function

