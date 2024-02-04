function output = pattern_similarity_mem_effsize_3runs(ds, args)

% Function to return an effect size for the difference in similarity across
% 3 runs (study1-test & study2-test) between correct and incorrect items.

    % Define output as an empty struct
    output = struct();
    
    % Define possible responses
    responses = {'correct','incorrect'};
    
    % Define empty arrays to contain similarity values for correct and
    % incorrect items
    sim_vals_correct = [];
    sim_vals_incorrect = [];
    
    % Slice ds into correct and incorrect words
    ds_correct = cosmo_slice(ds, ismember(ds.sa.wordLab, args.corr_words));
    ds_incorrect = cosmo_slice(ds, ismember(ds.sa.wordLab, args.incorr_words));
    
    % Loop through the two response types
    for i_response=1:numel(responses)
       response = responses{i_response};
        
       % Call the ds for this response type
       ds_this_resp = eval(sprintf('ds_%s', response));
        
        % Split into constituent runs
       ds_split = cosmo_split(ds_this_resp, 'chunks');

       ds_study1 = ds_split{1};
       ds_study2 = ds_split{2};
       ds_test = ds_split{3};

       % Loop through rows, getting same-item correlations across pairs of
       % runs
       for i_row=1:numel(unique(ds_this_resp.sa.targets))

           % First, verify that these rows actually correspond to the same item
            if ~ismember(ds_study1.sa.wordLab(i_row), ds_study2.sa.wordLab(i_row)) ...
                    && ~ismember(ds_study1.sa.wordLab(i_row), ds_test.sa.wordLab(i_row))

                error(sprintf('WARNING! Row %s in ds.samples does not correspond to the same item across runs!', int2str(i_row)));
            end

           % Pull the vector for this row/item
           study1_vec = ds_study1.samples(i_row, :);
           study2_vec = ds_study2.samples(i_row, :);
           test_vec = ds_test.samples(i_row, :);

           % Compute correlations across pairs of runs
           study1_test_rho = cosmo_corr(study1_vec', test_vec');
           study2_test_rho = cosmo_corr(study2_vec', test_vec');

           % Append the correlations to sim_vals_<response type>
           switch(response)
               case 'correct'
                   sim_vals_correct(end+1) = study1_test_rho;
                   sim_vals_correct(end+1) = study2_test_rho;
               case 'incorrect'
                   sim_vals_incorrect(end+1) = study1_test_rho;
                   sim_vals_incorrect(end+1) = study2_test_rho;
           end % switch response                    

       end % rows

    end % responses
    
    % We now have an array of similarity values for EACH response type.
    % These two arrays likely have different lengths, but that is okay so
    % long as each array has a length >= 1
    
    % Now compute the standardised mean difference (Cohen's D) between the
    % two response types. 
    D = (mean(sim_vals_correct) - mean(sim_vals_incorrect)) / std([sim_vals_correct sim_vals_incorrect]);
    
    % Append D to output.samples
    output.samples = D;


end % function
