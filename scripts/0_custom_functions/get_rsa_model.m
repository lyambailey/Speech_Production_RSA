% Quick function that reads in a computational model and gets it into
% correct format(s) for running rsa, getting inter-model correlations and 
% generating figures
function [comp_model, comp_model_z, comp_model_vec] = get_rsa_model(filename)
    % Read in table .csv
    T = readtable(filename);
    
    % Remove first column (word labels) and convert to a matrix
    T_new = removevars(T,{'Var1'});
    comp_model = T_new{:,:};
    
    % Make a vector form containing only off-diagonals 
    comp_model_vec = squareform(comp_model, 'tovector');
    
    % In order to return a z-scored model, we will zscore the vector, and
    % then re-arrange it into squareform
    comp_model_vec_zscore = zscore(comp_model_vec);
    
    comp_model_z = squareform(comp_model_vec_zscore, 'tomatrix');
    
    % Set diagonal to NaN (desirable for plotting heatmaps)
    comp_model_z(eye(size(comp_model_z))==1) = nan;
    
    
end