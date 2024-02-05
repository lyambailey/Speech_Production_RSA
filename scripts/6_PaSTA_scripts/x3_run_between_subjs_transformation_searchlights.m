% -------------------------------------------------------------------------
% The purpose of this script is to run whole-brain searchlights on each
% subjbect, using our custom measure of between-subjects transformation.
% This measures is defined by a custom function that is _NOT_ included in
% the standard cosmo_mvpa distribution, but is stored in the
% scripts/0_custom_functions/matlab directory. You _MUST_ add this
% directory to your matlab path, or else this script will not run.

% WARNING: this script is very computationally demanding. For that reason,
% it is divided into three sections. The first section simply defines our
% list of subjects, directories, etc.  The second section arranges all
% subjects' stacked data into a single dataframe. The third section
% actually does the work of computing between-subjects transformation
% indices. I recommend running these sections one at a time (in my
% experience, this helps prevent MATLAB crashing).
% -------------------------------------------------------------------------

%% Section 1: Define parameters

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
bads = {'subject-001', 'subject-002', 'subject-008', 'subject-009', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];

% Define path to stacked data
data_path = fullfile(top_dir, 'MRIanalyses', 'PE', 'subject_level_output');

% Define output path
out_path = fullfile(data_path, 'PaSTA_output_MNI', '1_searchlight_results');

if ~exist(out_path, 'dir')
   mkdir(out_path)
end

%% Section 2: Create a single dataframe containing data for all subjects.
 
% Lopo through subjects. On each loop, load in the stacked data for that
% subject, tidy it up (removing incorrect trials & averaging study runs
% together), and append it to the dataframe for the whole group.
for i_subj=1:numel(subjects)
    subject_id = subjects{i_subj};
    
    disp(subject_id)
    
    % Load alltrials data for this subject
    load(fullfile(data_path, '1_stacked_firstlevel_COPEs_MNI', ...
                        sprintf('%s_alltrials_stacked_data.mat', subject_id)));
    
    % Rename for ease of use
    ds_this_subject = ds_stacked_nofoils;
        
    % Re-set the target values (values for test data were disrupted due to
    % the presence of foils). The easiest way to do that is subset one of
    % the study phases, and then duplicate the .sa.target array (since all
    % words should be in the same order in each run)
    
    % Subset study1 data
    ds_this_subject_study_1 = cosmo_slice(ds_this_subject, ...
        strcmp(ds_this_subject.sa.runLab, 'study_1'));
    
    % Pull target array
    targets = ds_this_subject_study_1.sa.targets;
    
    % Re-set targets in the main dataset
    ds_this_subject.sa.targets = repmat(targets,3,1);
    
    % Remove redundant fields to help a little with memory load
    ds_this_subject.sa = rmfield(ds_this_subject.sa, {'conditionVal', 'runLab'});
    
    % Also remove incorrect words (muted for debugging purposes)
    ds_this_subject = cosmo_slice(ds_this_subject, strcmp(ds_this_subject.sa.response, 'correct'));
       
    % Average over phase, preserving subject_id and word. This has the
    % effect of averaging the 2 study phases together, which greatly reduces
    % computational load later on). 
    ds_this_subject = cosmo_average_samples(ds_this_subject, 'split_by', {'subject', 'phase', 'wordLab'});
    
    % Stack into a dataframe containing data for all subjects
    if i_subj == 1
        ds_group = ds_this_subject;
    else
        ds_group = cosmo_stack({ds_group, ds_this_subject});
    end 
    
end % subjects loop

%% Section 3: compute between-subjects transformation
% We are going to loop through subjects; for each, we'll iteratively
% compare that subject's activation pattern for each word to the
% corresponding pattern from each _other_ subject. We'll do this seperately
% for study and test. This will produce an r value for each word at study
% and test. Next, we will subtract each study r value its corresponding
% test r value. We will repeat this whole procedure for each condition
% separately


% ^ Lyam, this is gibberish. Rewrite it, please
% ----------------------------------------------------------------------

% Remove useless data from ds_group (i.e., constant columns in .samples)
ds_group = cosmo_remove_useless_data(ds_group);

% Define searchlight parameters
searchlight_measure = @compute_between_subjects_tarnsformation_iter;
searchlight_args = struct();
searchlight_args.progress = false;

% Set up searchlight neighbourhood
radius = 3;
ds_nbrhood = cosmo_spherical_neighborhood(ds_group, 'radius', radius);

% Loop through conditions
conditions = {'aloud', 'silent'};

for i_cond=1:numel(conditions)
    
    condition = conditions{i_cond};
    
    % Subset data for this condition
    ds_group_this_condition = cosmo_slice(ds_group, strcmp(ds_group.sa.conditionLab, condition));
    
    % Loop through subjects
    for i_subj=1:numel(subjects)
        
        % Set a timer for each subject
        tic
        
        subject_id = subjects{i_subj};
        disp(subject_id)
        
        % Subset the data for this participant and all other participants
        ds_this_subject = cosmo_slice(ds_group_this_condition, strcmp(ds_group_this_condition.sa.subject, subject_id));
        ds_other_subjects = cosmo_slice(ds_group_this_condition, ~strcmp(ds_group_this_condition.sa.subject, subject_id));
        
        % Get the list of words in this condition for this participant
        words = unique(ds_this_subject.sa.wordLab);
        
%         % Remove samples in 'ds_other_subjects' that do not correspond to
%         % items listed in 'words'
%         ds_other_subjects = cosmo_slice(ds_other_subjects, ismember(ds_other_subjects.sa.wordLab, words));
        
        % Remove study data in ds_other_subjects
        ds_other_subjects = cosmo_slice(ds_other_subjects, strcmp(ds_other_subjects.sa.phase, 'test'));
             
        % Stack the two datasets. Before doing this, however, we must add
        % .sa.subject_class to each - this will allow our custom function
        % to pull apart data from this_subject and other_subjects
        ds_this_subject.sa.subject_class = repmat({'this_subject'}, size(ds_this_subject.samples, 1), 1);
        ds_other_subjects.sa.subject_class = repmat({'other_subject'}, size(ds_other_subjects.samples, 1), 1);
        
        ds_other_subjects_split = cosmo_split(ds_other_subjects, {'subject'});
        
        % Loop through other subjects
        for i_other_subj=1:numel(ds_other_subjects_split)
         
            % Pull the dataset for this other subject (other_subj)
            ds_other_subj = ds_other_subjects_split{i_other_subj};

            % Determine which words are common to this_subj and other_subj
            words = intersect(ds_this_subject.sa.wordLab, ds_other_subj.sa.wordLab);

            % Subset samples for shared words (append 'test' to the subsetted
            % ds for other_subj - this will make this less confusing later)
            ds_this_subj_subset = cosmo_slice(ds_this_subject, ismember(ds_this_subject.sa.wordLab, words));
            ds_other_subj_subset = cosmo_slice(ds_other_subj, ismember(ds_other_subj.sa.wordLab, words));
            
            % Stack data for this subj and i_other_subj
            ds_between = cosmo_stack({ds_this_subj_subset, ds_other_subj_subset});
            
            % Define indexes to distinguish subjects and phases within the
            % searchlight
            idx_this_subj_study = strcmp(ds_between.sa.phase, 'study') & strcmp(ds_between.sa.subject_class, 'this_subject');
            idx_this_subj_test = strcmp(ds_between.sa.phase, 'test') & strcmp(ds_between.sa.subject_class, 'this_subject');
            idx_other_subj_test = strcmp(ds_between.sa.phase, 'test') & strcmp(ds_between.sa.subject_class, 'other_subject');
            
            % Use custom function to compute between-subject transformation.
            % Must supply args.this_subject_class and args.other_subject_class

            % Supply args to distinguish between this-subject data and
            % other-subjects data
            searchlight_args.idx_this_subj_study = idx_this_subj_study;
            searchlight_args.idx_this_subj_test = idx_this_subj_test;
            searchlight_args.idx_other_subj_test = idx_other_subj_test;
            
            searchlight_args.words = words;

            % Run the searchlight
            study_test_ptran_between_subjects = cosmo_searchlight(ds_between, ...
                        ds_nbrhood, searchlight_measure, searchlight_args);
                    
            % Assign dummy targets & chunks to searchlight output (allows
            % cosmo_average_samples to work)
            study_test_ptran_between_subjects.sa.targets = 1;
            study_test_ptran_between_subjects.sa.chunks = 2;

            % Stack searchlight results for consecutive other_subj's
            switch(i_other_subj)
                case 1
                    stacked_searchlight_results = study_test_ptran_between_subjects;
                otherwise
                    stacked_searchlight_results = cosmo_stack({stacked_searchlight_results, study_test_ptran_between_subjects});
            end % switch case
            
        end % i_other_subj
          
        % Average the stacked results together and save to disk
        average_searchlight_results = cosmo_average_samples(stacked_searchlight_results);

        
        % Save to disk 
        cosmo_map2fmri(average_searchlight_results, ...
            fullfile(out_path, sprintf('%s_%s_study-test_between_subjects_transformation_effsize.nii.gz', subject_id, condition)));
        toc
    end % subjects
end % conditions 


%% Function to compute (between subjects) test-test correlations minus study-test correlations
function output = compute_between_subjects_tarnsformation_iter(ds, args)

    % Define output as struct
    output = struct();
    
    % Made two empty lists to which we will append between-subjects
    % correlations (one value for every 'other subject')
    test_test_rhos = [];
    study_test_rhos = [];
    
    % Split data into study and test, for this_subj and other_subj
    
    % This subj study
    ds_this_subj_study = ds.samples(args.idx_this_subj_study, :);
%     ds_this_subj_study = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'study') & strcmp(ds.sa.subject_class, args.this_subject_class));
    
    % This subj test
    ds_this_subj_test = ds.samples(args.idx_this_subj_test, :);
%     ds_this_subj_test = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'test') & strcmp(ds.sa.subject_class, args.this_subject_class));
    
    % Other subj test
    ds_other_subj_test = ds.samples(args.idx_other_subj_test, :);
%     ds_other_subj_test = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'test') & strcmp(ds.sa.subject_class, args.other_subject_class));
    
    % Loop through words
    for i_word=1:numel(args.words)

        % Pull the data for this word from the study and test data for this
        % subject, and the test data for other subjects

        % This subject study
        this_subject_this_word_study = ds_this_subj_study(i_word,:);

        % This subject test
        this_subject_this_word_test = ds_this_subj_test(i_word,:);

        % Other subject test
        other_subject_this_word_test = ds_other_subj_test(i_word,:);

        % Ensure that we've selected the correct sample (word) in each of
        % the above
%         if ~isequal(ds_this_subj_study.sa.wordLab(i_word,:), ...
%                 ds_this_subj_test.sa.wordLab(i_word,:), ...
%                 ds_other_subj_test.sa.wordLab(i_word,:) ...
%                 ) 
%             error('WARNING: samples (words) do not match accross phases being compared');
%         end % error check

        % Get the between-subjects correlation for this word, between study
        % and test, and append it to the (temporary) study-test array
        study_test_rhos(end+1) = cosmo_corr(this_subject_this_word_study', other_subject_this_word_test');

        % Get the between-subjects correlation for this word at test, and
        % append it to the (temporary) test-test array
        test_test_rhos(end+1) = cosmo_corr(this_subject_this_word_test', other_subject_this_word_test');

    end % word loop
    
    % Compute the standardised mean difference (Cohen's D) between
    % test-test correlations and study-study correlations, append to
    % output.samples
    output.samples = (mean(test_test_rhos) - mean(study_test_rhos)) / std([test_test_rhos study_test_rhos]);
    
end % end function

