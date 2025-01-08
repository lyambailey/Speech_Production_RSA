% Function for performing a two-sample Bayes ttest comparing an aloud
% dataset (ds1) to a silent dataset (ds2)
function bf_df = compute_wholebrain_bfs_twosample(ds1, ds2)

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