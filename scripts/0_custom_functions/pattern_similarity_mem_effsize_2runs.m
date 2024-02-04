function output = pattern_similarity_mem_effsize_2runs(ds, args)

% Function to return an effect size for the difference in similarity
% across two runs (e.g., study-study) between correct and incorrect items. 

    % Define output as an empty struct, but with the same .fa and .a as the
    % input ds
    output = struct();
    %output.fa = ds.fa;
    %output.a = ds.a;

    % Make an empty array to house same-item similarity values for each
    % response type
    sim_vals_correct = [];
    sim_vals_incorrect = [];

    % Slice ds into correct and incorrect words. (Matlab will complain that
    % these new datasets aren't used, but in reality they are called by
    % eval in the i_response loop)
    ds_correct = cosmo_slice(ds, ismember(ds.sa.wordLab, args.corr_words));
    ds_incorrect = cosmo_slice(ds, ismember(ds.sa.wordLab, args.incorr_words));

    % Compute pairwise correlations between the two runs, seperately for
    % the two response types.  
    responses = {'correct', 'incorrect'};

    % Loop through the two response types, seperating the data for each response
    % into constituent runs and computing same-item similarity values for each sample 
    for i_response=1:numel(responses)
        response = responses{i_response};

        % Call the ds for this response type
        ds_this_resp = eval(sprintf('ds_%s', response));

        % Split the ds into its two constituent runs
        ds_runs = cosmo_split(ds_this_resp, 'chunks');

        ds_run1 = ds_runs{1};
        ds_run2 = ds_runs{2};

        % Loop through rows in run1. On each loop, we will pull the samples 
        % for the corresponding item (i.e. target) in each run, and correlate 
        % the two samples
        for i_row=1:size(ds_run1.samples, 1)
            
            % We are going to call corresponding rows of ds_run1 and 
            % ds_run2 using i_row as the row index. First, verify that these
            % rows actually correspond to the same item
            if ~strcmp(ds_run1.sa.wordLab(i_row), ds_run2.sa.wordLab(i_row))
                error(sprintf('WARNING! Row %s in ds.samples does not correspond to the same item across runs!', int2str(i_row)));
            end
            
            % Pull the pattern vector from each run and normalize
            vec1 = ds_run1.samples(i_row,:);
            vec2 = ds_run2.samples(i_row,:);

            % Compute similarity as the correlation between the two vectors 
            sim_val = cosmo_corr(vec1', vec2'); 
            
% ------------------------------------------------------------------------
            % In principle, the following method is more robust (resistant
            % to rows in .samples being scrambled, though I'm not sure why
            % that would happen), but it takes >10x longer!
            
%             % Identify the target value for this row
%             this_target = ds_run1.sa.targets(i_row);
% 
%             % Isolate the data for this target in each run
%             dat_run1 = cosmo_slice(ds_run1, ds_run1.sa.targets == this_target);
%             dat_run2 = cosmo_slice(ds_run2, ds_run1.sa.targets == this_target);
% 
%             % Correlate the pattern vectors from the two runs to get a similarity value
%             sim_val = cosmo_corr(dat_run1.samples', dat_run2.samples');
% ------------------------------------------------------------------------

            % Append the computed similarity to either the correct_vals or
            % incorrect_vals 
            if strcmp(response, 'correct')
                sim_vals_correct(end+1) = sim_val;
            elseif strcmp(response, 'incorrect')
                sim_vals_incorrect(end+1) = sim_val;
            end % if-else

        end % run1 rows   
    end % responses

    % We now have an array of similarity values for each response type.
    % Compute the standardised mean difference (Cohen's D) between the two
    % response types, and insert into output.samples
    D = (mean(sim_vals_correct) - mean(sim_vals_incorrect)) / std([sim_vals_correct sim_vals_incorrect]);

    output.samples = D;

end % end function
