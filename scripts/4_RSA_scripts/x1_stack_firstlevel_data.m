% -------------------------------------------------------------------------

% The purpose of this script is to arrange all the COPE files from each
% subject into a single dataset. This produces one 'stacked' dataset per
% subject, containing activity patterns to all stimuli along with
% interpretable labels (subjectID, condition labels, etc). 

% -------------------------------------------------------------------------

% Clear workspace and command window
clear all;
clc

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define runs and conditions
runs = {'quickread_1', 'quickread_2', 'quickread_3', 'quickread_4'};
conditions = {'aloud', 'silent'};

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

% Define path to COPE files
data_path = fullfile(top_dir, 'MRIanalyses', 'quickread', 'subject_level_output');
assets_path = fullfile(top_dir, 'MRIanalyses', 'assets');

% Deine output path
ds_write_path = fullfile(data_path, '1_stacked_firstlevel_COPEs');
if ~exist(ds_write_path, 'dir')
       mkdir(ds_write_path)
end

% Loop through subjects
for i_sub=1:numel(subjects)
    subject_id = subjects{i_sub};
    tic

    disp(subject_id)

    % Read in words for in each condition for this subject, in alphabetical
    % order
    words_aloud_fn = fullfile(top_dir, 'behavioural_data', 'fmri_runs2', subject_id, 'aloud_words.txt');
    silent_words_fn = fullfile(top_dir, 'behavioural_data', 'fmri_runs2', subject_id, 'silent_words.txt');

    words_aloud = sort(readlines(words_aloud_fn));
    words_silent = sort(readlines(silent_words_fn));

    % Remove empty lines
    words_aloud = words_aloud(~cellfun(@isempty, words_aloud));
    words_silent = words_silent(~cellfun(@isempty, words_silent));

    % Join the two word lists, sort alphabetically
    words_all = sort([words_aloud; words_silent]);

    % Loop through runs
    for i_run=1:numel(runs)
        run = runs{i_run};
        % Loop through words, pulling the corresponding COPE file from
        % the aligned-to-common space folder, and appending necessary info 
        % (labels for word/condition, etc). Note that words were input to FEAT
        % in alphabetical order, meaning "word 1" (i.e. i_word=1 below) must
        % be the first word alphabetically
        for i_word=1:numel(words_all)
            word = words_all{i_word};

            % Define condition label for this word
            if any(strcmp(words_aloud, word))
                condition = 'aloud';
            elseif any(strcmp(words_silent, word))
                condition = 'silent';
            end

            % Define COPE number (e.g. cope1)
            thisCOPE = sprintf('cope%s', string(i_word));

            % Define filename 
            ds_word_fn = fullfile(data_path, subject_id, 'firstLevelCOPEs2common_native_space_ants' ...
                , sprintf('%s_%s.nii.gz', run, thisCOPE)); 

            % Load the data in for this word and append interpretable labels.
            ds_word = cosmo_fmri_dataset(ds_word_fn, 'targets', i_word);
            ds_word.sa.conditionLab = {condition};
            ds_word.sa.wordLab = {word};
            ds_word.sa.subject = {subject_id};
            ds_word.sa.chunks = i_run;
            ds_word.sa.phase = {run};

            % Now stack each word into a dataset. 
            if i_word==1
                ds_thisRun_stacked = ds_word;
            elseif i_word~=1
                ds_thisRun_stacked = cosmo_stack({ds_thisRun_stacked, ds_word});
            end

        end % end words loop 

        % Stack data from all the runs together
        if i_run==1
            ds_stacked = ds_thisRun_stacked;
        elseif i_run ~=1
            ds_stacked = cosmo_stack({ds_stacked, ds_thisRun_stacked});
        end

    end % runs loop

    % Save the stacked dataset (containing separate runs) to disk
    save(fullfile(ds_write_path, sprintf('%s_alltrials_stacked_data', subject_id)), 'ds_stacked');


    toc
end % end subjects loop

