% -------------------------------------------------------------------------
% The purpose of this script is to run whole-brain searchlights on each
% subjbect, using customs measures of within subject similarity (i.e.,
% reativation) and transformation. Each of these measures is explained in
% more detail lower down in the script.

% These measures are defined by custom functions that are _NOT_ included in
% the standard cosmo_mvpa distribution, but are stored in the
% scripts/0_custom_functions/matlab directory. You _MUST_ add this
% directory to your matlab path, or else this script will not run.
% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define conditions
conditions = {'aloud', ...
                'silent'...
                };

% Define subjects. possible bads - 008, 015, 018.
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
bads = {'subject-001', 'subject-002', 'subject-008', 'subject-009', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];

% Define paths, to make things easier later on
data_path = fullfile(top_dir, 'MRIanalyses', 'PE', 'subject_level_output');
assets_path = fullfile(top_dir, 'MRIanalyses', 'assets');
out_path = fullfile(data_path, 'PaSTA_output_MNI', '1_searchlight_results');

if ~exist(out_path, 'dir')
    mkdir(out_path)
end

% Define subjects with 0 incorrect responses in any condition
bad_mem_subjs = {'subject-002'}; 

% Remove missing (subject-001 missing from PE) and bad subjects from the
% list of subjects
subjects(strcmp(subjects, 'subject-001')) = [];
subjects(ismember(subjects, bad_mem_subjs)) = [];

% Loop through  subjects
for i_sub=1:numel(subjects)
    subject_id = subjects{i_sub};
    disp(subject_id)
    
    tic
    
    % Load in the lists of correct and incorrect words for this subject
    corr_words_fn = fullfile(assets_path, subject_id,sprintf('%s_PE_corr_words.txt', subject_id));
    corr_words = sort(readlines(corr_words_fn));
    
    incorr_words_fn = fullfile(assets_path, subject_id,sprintf('%s_PE_incorr_words.txt', subject_id));
    incorr_words = sort(readlines(incorr_words_fn));

    % Remove empty lines
    corr_words = cellstr(corr_words(~cellfun(@isempty, corr_words)));
    incorr_words = cellstr(incorr_words(~cellfun(@isempty, incorr_words)));

    % Load in the alltrials data for this subject. We will use it to define
    % the searchlight space, and then split it into its constituent
    % conditions and runs
    ds_fn = fullfile(data_path, '1_stacked_firstlevel_COPEs_MNI', ...
            sprintf('%s_alltrials_stacked_data', subject_id));
    load(ds_fn)

    % Remove useless data and re-name for sanity reasons
    ds_alltrials = cosmo_remove_useless_data(ds_stacked_nofoils); 

    % Use the stacked dataset to define the searchlight space  
    radius = 3;
    ds_nbrhood = cosmo_spherical_neighborhood(ds_alltrials, 'radius', radius, 'progress', false);

    % Now, split the stacked data up into its constituent conditions
    ds_split = cosmo_split(ds_alltrials, {'conditionLab'});

    % The first half of the datasets in ds_split are aloud, the last half are silent
    ds_aloud = ds_split{1};
    ds_silent = ds_split{2};

    % Check that the correct data was assigned to the correct object
    if ~all(strcmp(ds_aloud.sa.conditionLab, 'aloud')) || ~all(strcmp(ds_silent.sa.conditionLab, 'silent'))
        error('WARNING, one or more sample(s) has been allocated to the wrong condition');
    end
    
    % We are going to run searchlights for 2 different measures:
    % - Pattern similarity memory effect size (psim_mem)
    % - Pattern transformation memory effect size (ptran_mem)

    % Below we will define searchlight arguments for each measure

    % Pattern similarity memory effect size (psim_mem). This is defined as
    % the standardised mean difference in same-item correlations across
    % runs between correctly remembered and forgotten items. Note that this
    % measure requires a list of correct words and list of incorrect words
    % as input arguments.
    psim_mem_measure_2runs = @pattern_similarity_mem_effsize_2runs; % used when considering 2 runs (study1-study2 similarity)
    psim_mem_measure_3runs = @pattern_similarity_mem_effsize_3runs; % used when considering 3 runs (studyN-test similarity)
    psim_mem_args = struct();
    psim_mem_args.corr_words = corr_words;
    psim_mem_args.incorr_words = incorr_words;
    psim_mem_args.progress = true;

    % Pattern transformation memory effect size (ptran_mem). Here, we first
    % compute a list of transformation values, defined as the difference in
    % same-item pattern similarity between study1 and study2 versus
    % similarity between study and test. We then compute the standardised
    % mean difference in transformation values between correctly remembered
    % and forgotten words. As with the previous measure, you must supply
    % lists of correct and incorrect words.
    ptran_mem_measure = @pattern_transformation_mem_effsize;
    ptran_mem_args = struct();
    ptran_mem_args.corr_words = corr_words;
    ptran_mem_args.incorr_words = incorr_words;
    ptran_mem_args.progress = true;
 
    % Loop through conditions
    for i_cond=1:numel(conditions)
        condition=conditions{i_cond};
        
        disp(condition)

        % Pull the ds for this condition
        ds_condition = eval(sprintf('ds_%s', condition));
        
        % Re-organize into seperate datasets for each phase
        ds_each_run = cosmo_split(ds_condition, {'chunks'});
        
        ds_study = cosmo_stack({ds_each_run{1}, ds_each_run{2}});
        ds_test = ds_each_run{3};
        
        % Due to the presence of foil words, target values for the test
        % data do not align correctly with those of the study data. So,
        % reset ds_test.sa.targets to match either ds_study data
        ds_test.sa.targets = ds_each_run{1}.sa.targets;
                
        % Check that the same words (and in the same order) are in all
        % datasets
        if ~all(strcmp(ds_each_run{1}.sa.wordLab, ds_test.sa.wordLab)) || ~all(strcmp(ds_each_run{2}.sa.wordLab, ds_test.sa.wordLab))
            error('WARNING, one or more sample has been allocated to the wrong condition');
        end
        
        % Having fixed the .samples field for the test data, re-stack the
        % three (study1, study2, test) datasets. We will supply this new
        % stacked dataset to some of the searchlights below.
        ds_study_test = cosmo_stack({ds_study, ds_test});
        
        % ----------------------------------------------------------------- 
        % Run searchlights with each of our custom functions
        % ----------------------------------------------------------------- 
        
        % -----------------------------------------------------------------
        % psim_mem (study-study). Since we are only concerned with
        % similarity across the two study phases, we will supply ds_study
        % and use the 2x runs measure
        % -----------------------------------------------------------------              
        % Run the searchlight
        study_study_psim_mem = cosmo_searchlight(ds_study, ds_nbrhood, psim_mem_measure_2runs, psim_mem_args);

        % Save output to disk
        cosmo_map2fmri(study_study_psim_mem, fullfile(out_path, ...
            sprintf('%s_%s_study-study_similarity_memory_effsize.nii.gz', subject_id, condition)));
        
        % -----------------------------------------------------------------
        % psim_mem (study-test). Since we are concerned with similarity
        % across study and test, we will supply ds_study_test and use
        % the 3x runs measure (because there are three runs involved:
        % study1, study2, test)
        % -----------------------------------------------------------------       
        % Run the searchlight
        study_test_psim_mem = cosmo_searchlight(ds_study_test, ds_nbrhood, psim_mem_measure_3runs, psim_mem_args);
        
        % Save output to disk
        cosmo_map2fmri(study_test_psim_mem, fullfile(out_path, ...
            sprintf('%s_%s_study-test_similarity_memory_effsize.nii.gz', subject_id, condition)));
        
        % ----------------------------------------------------------------- 
        % ptran_mem (study-test). We will supply ds_study_test
        % -----------------------------------------------------------------           
        % Run the searchlight 
        ptran_mem = cosmo_searchlight(ds_study_test, ds_nbrhood, ptran_mem_measure, ptran_mem_args);

        % Save output to disk
        cosmo_map2fmri(ptran_mem, fullfile(out_path, ...
            sprintf('%s_%s_study-test_transformation_memory_effsize.nii.gz', subject_id, condition))); 


    end % conditions loop   
    
    toc
    
end % subjects loop