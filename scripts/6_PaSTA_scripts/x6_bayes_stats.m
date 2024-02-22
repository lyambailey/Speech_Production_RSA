% -------------------------------------------------------------------------

% The purpose of this script is to read in stacked searchlight results
% from all subjects, and perform group-level statistical testing (i.e.,
% compute Bayes factors) at every voxel. Statistical testing involves both:
% 1. testing whether searchlight results are different from zero (in each
% condition alone)
% 2. testing whether searchlight results are different between aloud and
% silent reading.

% Note that all of the above is performed independently for each measure of
% reactivation (within-subjects) and transformation (within & between)

% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc


% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define conditions and measures    
conditions = {...
    'aloud', ...
    'silent', ...
    };

measures = {...
        'study-test_similarity_memory_effsize', ...
        'study-test_transformation_memory_effsize', ...
        'study-test_between_subjects_transformation_effsize' ...
    };

% Define paths to stacked searchlight and behavioural data
data_path = fullfile(top_dir, 'MRIanalyses', 'PE', 'group_level_output', 'PaSTA_output_MNI');

% Loop through measures
for i_measure=1:numel(measures)
    measure = measures{i_measure};
    disp(measure)

    % Define output folder for this measure
    this_measure_out_path = fullfile(data_path, sprintf('%s_group_searchlight_output', measure));
    

    % Read in stacked searchlights from each condition (including
    % alltrials)
    ds_aloud_fn = fullfile(this_measure_out_path, sprintf('stacked_searchlight_results_aloud_%s', measure));
    ds_silent_fn = fullfile(this_measure_out_path, sprintf('stacked_searchlight_results_silent_%s', measure));

    ds_aloud = load(ds_aloud_fn);
    ds_aloud = ds_aloud.stacked_results;

    ds_silent = load(ds_silent_fn);
    ds_silent = ds_silent.stacked_results;
    
    % First, run a two-sampled t-test comparing aloud vs silent, using our
    % predfined do_twosample_bayes function

    % Note that we only need to provide the function with the datasets in their
    % raw forms - no need to remove useless data (this is done by the
    % function)
    
    % Skip the AvS test for the between-subjects measure 
    if ~strcmp(measure, 'study-test_between_subjects_transformation_effsize')
        bayes_map_AvS = compute_wholebrain_bfs_twosample(ds_aloud, ds_silent);

        % Load group-average searchlight maps for this contrast, masked with
        % the output from the paired-samples ttest. The masking ensures
        % an equal number of voxels in each map (both the average maps and
        % the bayes map) - this allows the next step to run smoothly.
        ds_aloud_av_fn = fullfile(this_measure_out_path, sprintf('average_searchlight_map_aloud_%s.nii.gz', measure));
        ds_silent_av_fn = fullfile(this_measure_out_path, sprintf('average_searchlight_map_silent_%s.nii.gz', measure));

        ds_aloud_av = cosmo_fmri_dataset(ds_aloud_av_fn, 'mask', bayes_map_AvS);
        ds_silent_av = cosmo_fmri_dataset(ds_silent_av_fn, 'mask', bayes_map_AvS);

        % Decompose the AvS map into aloud-silent and silent-aloud,
        % using the group-average searchlight maps
        bayes_aloud_minus_silent_map = cosmo_slice(bayes_map_AvS, ds_aloud_av.samples > ds_silent_av.samples, 2);
        bayes_silent_minus_aloud_map = cosmo_slice(bayes_map_AvS, ds_aloud_av.samples < ds_silent_av.samples, 2);

        % Save the two maps to disk
        bayes_aloud_minus_silent_map_fn = fullfile(this_measure_out_path, sprintf('bayes_map_aloud-silent_%s.nii.gz', measure));
        cosmo_map2fmri(bayes_aloud_minus_silent_map, bayes_aloud_minus_silent_map_fn);

        bayes_silent_minus_aloud_map_fn = fullfile(this_measure_out_path, sprintf('bayes_map_silent-aloud_%s.nii.gz', measure));
        cosmo_map2fmri(bayes_silent_minus_aloud_map, bayes_silent_minus_aloud_map_fn);
    
    end % check that measure is not between-subjects 


    % Next, run onesample t-test on each condition alone (test correlations against zero).
    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};
        disp(condition)

        % Grab the dataset for this condition, run onesample bayes test
        ds_thiscond = eval(sprintf('ds_%s', condition));
        bayes_map_thiscond = compute_wholebrain_bfs_onesample(ds_thiscond);

        % Save to disk
        bayes_map_thiscond_fn = fullfile(this_measure_out_path, sprintf('bayes_map_%s_%s.nii.gz', condition, measure));
        cosmo_map2fmri(bayes_map_thiscond, bayes_map_thiscond_fn);
    end % conditions

end % contrasts
%%
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
        
        % Use Bayes ttest to compare the two vectors. Insert the
        % bayes factor into the appropriate position in bf_df
        bf10 = bf.ttest(aloud_vector, silent_vector);
        bf_df.samples(:,i_feat) = bf10;



    end % features
            
end % end of function

% Function for performing one-sampled Bayes ttest
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


    end % features
            
end % end of function


% Function for performing Bayes correlation at each voxel against
% a vector of behavioural data (behav_vec), for a given dataset (ds)

% Note - this returns a bayes factor map (bf_df) AND a correlation map (r_df)
function [bf_df, r_df] = do_correlation_bayes(ds, behav_vec)

    % Remove uselss data from ds
    ds_useful = cosmo_remove_useless_data(ds);

    % Define two new data structures with the same properties as df (but NOT
    % the same samples). One will hold BF values, the other will hold
    % correlation (r) values. We will insert BF and r values into each
    % respective struct as samples
    bf_df = struct();
    bf_df.fa = ds_useful.fa;
    bf_df.a = ds_useful.a;
    
    r_df = struct();
    r_df.fa = ds_useful.fa;
    r_df.a = ds_useful.a;
    
    % Determine number of features in df (i.e. columns in df.samples)
    n_features = size(ds_useful.samples, 2); 
    
    % Loop through features, performing onesample ttest at each voxel
    for i_feat=1:n_features
        this_feat = ds_useful.samples(:,i_feat);

        % Get Bayes factor from the correlation and insert it at the appropriate feature in bf_df. 
        % Do the same for r values (r_df)
        [bf10, r] = bf.corr(this_feat, behav_vec);
        bf_df.samples(:,i_feat) = bf10;
        r_df.samples(:,i_feat) = r;


    end % features
            
end % end of function
