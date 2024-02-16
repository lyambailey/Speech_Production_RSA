%% Function to compute (between subjects) test-test correlations minus study-test correlations
function output = compute_between_subjects_transformation(ds, args)   

    % Define output as struct
    output = struct();
    
    % First make sure that ds.samples is not full of zeros (i.e.,
    % functionally useless). If it is, simply enter NaN in output.samples
    % (which would be the result anyway) so the function can move on to the
    % next searchlight immediately
    ds = cosmo_remove_useless_data(ds);
    
    if isempty(ds.samples)
        
        output.samples = NaN;
        return
        
    end
    
    % Made two empty lists to which we will append between-subjects
    % correlations (one value for every 'other subject')
    test_test_rhos = [];
    study_test_rhos = [];
    
    % Split data into study and test, for this_subj and other_subj
    
    % NEW - removed! (replaced with other subj study)
    % This subj study
%     ds_this_subj_study = ds.samples(args.idx_this_subj_study, :);
%     ds_this_subj_study = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'study') & strcmp(ds.sa.subject_class, args.this_subject_class));
    
    % This subj test
    ds_this_subj_test = ds.samples(args.idx_this_subj_test, :);
%     ds_this_subj_test = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'test') & strcmp(ds.sa.subject_class, args.this_subject_class));
    
    % Other subj study (NEW)
    ds_other_subj_study = ds.samples(args.idx_other_subj_study, :);
    
    % Other subj test
    ds_other_subj_test = ds.samples(args.idx_other_subj_test, :);
%     ds_other_subj_test = cosmo_slice(ds, ...
%         strcmp(ds.sa.phase, 'test') & strcmp(ds.sa.subject_class, args.other_subject_class));
    
    % Loop through words
    for i_word=1:numel(args.words)

        % Pull the data for this word from test data for this subject, and
        % the study & test data for other subjects
        
        % This subject test
        this_subject_this_word_test = ds_this_subj_test(i_word,:);
        
        % Other subject study
        other_subject_this_word_study = ds_other_subj_study(i_word,:);

        % Other subject test
        other_subject_this_word_test = ds_other_subj_test(i_word,:);

%         % Ensure that we've selected the correct sample (word) in each of
%         % the above
%         if ~isequal(ds_this_subj_test.sa.wordLab(i_word,:), ...
%                 ds_other_subj_study.sa.wordLab(i_word,:), ...
%                 ds_other_subj_test.sa.wordLab(i_word,:) ...
%                 ) 
%             error('WARNING: samples (words) do not match accross phases being compared');
%         end % error check

        % Get the between-subjects correlation for this word, between study
        % and test, and append it to the (temporary) study-test array
        study_test_rhos(end+1) = cosmo_corr(other_subject_this_word_study', this_subject_this_word_test');

        % Get the between-subjects correlation for this word at test, and
        % append it to the (temporary) test-test array
        test_test_rhos(end+1) = cosmo_corr(other_subject_this_word_test', this_subject_this_word_test');

    end % word loop
    
    % Compute the standardised mean difference (Cohen's D) between
    % test-test correlations and study-study correlations, append to
    % output.samples
    output.samples = (mean(test_test_rhos) - mean(study_test_rhos)) / std([test_test_rhos study_test_rhos]);
    
end % end function

