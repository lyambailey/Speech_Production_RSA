% -------------------------------------------------------------------------

% The purpose of this script is to arrange all COPEs (in MNI space) from
% the PE experiment into a single dataset (per subject). This produces one
% 'stacked' dataset per subject, containing activity patterns to all
% stimuli along with interpretable labels (subjectID, condition labels,
% etc).

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
bads = {'subject-001', 'subject-002', 'subject-008', 'subject-009', 'subject-015', 'subject-018'};
subjects(ismember(subjects, bads)) = [];
    
% Define experimental phases
phases = {'study', 'test'};

% Define path to COPE files, to make things easier later on
data_path = fullfile(topdir, 'MRIanalyses', 'PE', 'subject_level_output');
assets_path = fullfile(topdir, 'MRIanalyses', 'assets');
behav_path = fullfile(top_dir, 'behavioural_data', 'fmri_runs1'); % note that the fmri_runs1 folder stores data from the PE experiment

% Deine output path
out_path = fullfile(data_path, '1_stacked_firstlevel_COPEs_MNI');

if ~exist(out_path, 'dir')
   mkdir(out_path)
end

% Load MNI template mask
MNI_mask_fn = fullfile(assets_path, 'MNI152_T1_2mm_brain_mask.nii.gz');
MNI_template = cosmo_fmri_dataset(MNI_mask_fn);

% Load cerebellum mask
cerebellum_mask_fn = fullfile(assets_path, 'Harvard_Oxford_ROIs', 'Cerebellum.nii.gz');
cerebellum_mask = cosmo_fmri_dataset(cerebellum_mask_fn);

% Remove cerebellum from MNI mask
MNI_template_masked = cosmo_slice(MNI_template, cerebellum_mask.samples == 0, 2);

% Loop through subjects
for i_sub=1:numel(subjects)
    subject_id = subjects{i_sub};
    
    disp(subject_id)
    tic
    
    % Load in lists of correct and incorrect words for this subject
    words_corr_fn = fullfile(assets_path, subject_id,sprintf('%s_PE_corr_words.txt', subject_id));
    words_corr = sort(readlines(words_corr_fn));
    
    words_incorr_fn = fullfile(assets_path, subject_id,sprintf('%s_PE_incorr_words.txt', subject_id));
    words_incorr = sort(readlines(words_incorr_fn));

    % Loop through phases
    for i_phase=1:numel(phases)
        phase = phases{i_phase};
        
        % Define runs
        if strcmp(phase, 'study')
            runs = {'study_1', 'study_2'};
        elseif strcmp(phase, 'test')
            runs = {'test'};
        end

        % Read in words for in each condition for this subject, in alphabetical
        % order
        words_aloud_fn = fullfile(behav_path, subject_id, 'aloud_words.txt');
        silent_words_fn = fullfile(behav_path, subject_id, 'silent_words.txt');
        foil_words_fn = fullfile(behav_path, subject_id, 'foil_words.txt');

        words_aloud = sort(readlines(words_aloud_fn));
        words_silent = sort(readlines(silent_words_fn));
        words_foil = sort(readlines(foil_words_fn));

        % Remove empty lines
        words_aloud = words_aloud(~cellfun(@isempty, words_aloud));
        words_silent = words_silent(~cellfun(@isempty, words_silent));
        words_foil = words_foil(~cellfun(@isempty, words_foil));

        % Join the word lists, sort alphabetically. Note that foil words
        % are not present in the study phases
        if strcmp(phase, 'study')
            words_all = sort([words_aloud; words_silent]);
        elseif strcmp(phase, 'test')
            words_all = sort([words_aloud; words_silent; words_foil]);
        end

        % Loop through runs
        for i_run=1:numel(runs)
            run = runs{i_run};
            
            % Loop through words, pulling the corresponding COPE file from
            % the each subject's cope2mni folder, and appending necessary
            % info (labels for word/condition, etc). Note that words were
            % input to FEAT in alphabetical order, meaning "word 1" (i.e.
            % i_word=1 below) must be the first word alphabetically
            for i_word=1:numel(words_all)
                word = words_all{i_word};
                
                % Define condition label for this word. Also define
                % conditionVal, which allows us to remove foil trials later
                % (cosmo_slice only accepts numeric values, not strings)
                if any(strcmp(words_aloud, word))
                    condition = 'aloud';
                    conditionVal = 1;
                elseif any(strcmp(words_silent, word))
                    condition = 'silent';
                    conditionVal = 2; 
                elseif any(strcmp(words_foil, word))
                    condition = 'foil';
                    conditionVal = 3;
                end
                
                % Determine whether the word was subsequently remembered or
                % forgotten
                if ismember(word, words_corr)
                    response = 'correct';
                elseif ismember(word, words_incorr)
                    response = 'incorrect';
                end

                % Define COPE number (e.g. cope1)
                thisCOPE = sprintf('cope%s', string(i_word));

                % Define filename 
                ds_word_fn = fullfile(data_path, subject_id, 'firstLevelCOPEs2MNI' ...
                    , sprintf('%s_%s.nii.gz', run, thisCOPE)); 
                
                % Load the data in for this word, apply masking and append
                % interpretable labels.
                ds_word = cosmo_fmri_dataset(ds_word_fn, 'mask', MNI_template_masked, ...
                                            'targets', i_word);
                
                
                % --- WARNING ---
                % Due to the presence of foil words, the target values for
                % words in the test data do not align properly with those
                % of the study data (but note that .sa.wordLab values ARE
                % correct)
                
                % This gets fixed in the searchlight scripts, HOWEVER, be
                % aware that the output from this script contains
                % innaccurate .sa.target values (for the test data only)
                % ---------------
                
                ds_word.sa.conditionLab = {condition};
                ds_word.sa.conditionVal = conditionVal;
                ds_word.sa.wordLab = {word};
                ds_word.sa.subject = {subject_id};               
                ds_word.sa.phase = {phase};
                ds_word.sa.runLab = {run};
                ds_word.sa.response = {response};
                
                if strcmp(phase, 'test')
                    ds_word.sa.chunks = 3;
                else
                    ds_word.sa.chunks = i_run;
                end

                % Now stack each word into a dataset. 
                if i_word==1
                    ds_thisRun_stacked = ds_word;
                elseif i_word~=1
                    ds_thisRun_stacked = cosmo_stack({ds_thisRun_stacked, ds_word});
                end

            end % end words loop 

            % Stack data from all the phases/runs together
            if all(i_phase == 1 & i_run==1)
                ds_stacked = ds_thisRun_stacked;
            else
                ds_stacked = cosmo_stack({ds_stacked, ds_thisRun_stacked});
            end
            

        end % runs loop
    end % end phases loop
    
    % Slice out all trials for foil items
    ds_stacked_nofoils = cosmo_slice(ds_stacked, ds_stacked.sa.conditionVal ~= 3);
    
    % Save the stacked dataset (containing multiple phases & runs) to disk            
    save(fullfile(out_path, sprintf('%s_alltrials_stacked_data', subject_id)), 'ds_stacked_nofoils');
    
    toc
end % end subjects loop