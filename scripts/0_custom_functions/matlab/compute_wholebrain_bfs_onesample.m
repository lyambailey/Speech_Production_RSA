% Function for performing a one-sample Bayes ttest at each voxel for a 
% given dataset (ds)
function bf_df = compute_wholebrain_bfs_onesample(ds)

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