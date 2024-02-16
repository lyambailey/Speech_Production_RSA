% -------------------------------------------------------------------------

% The purpose of this script is to (1) get correlations and BFs between
% exemplar hypothesis models (which contain all stimuli, and therefore are
% identical for all participants), and (2) visualize dissimilarity matrics
% for each hypothesis model, from one participant and conition

% -------------------------------------------------------------------------

clear all;
clc
beep off

% Read top_dir
top_dir = strtrim(fileread('../top_dir_win.txt'));

% Define path to hypothesis models for one participant.
assets_path = fullfile(top_dir, 'MRIanalyses', 'assets');
subject_id='subject-001';

% -------------------------------------------------------------------------
% IMPORTANT: if you want to calculate between-model correlations, set
% condition='alltrials' - this will pull the exemplar models containing all
% stimuli, regardless of condition. Otherwise, choose 'aloud' or 'silent'
% for a representative model actually used by RSA
% -------------------------------------------------------------------------

condition='alltrials';

model_path = fullfile(assets_path, subject_id, 'RSA_models', 'quickread');

% Load in models. The 'get_rsa_model' function returns models in squareform,
% lower triangle, and vector format.

% Visual 
vis_fn = fullfile(model_path, sprintf('quickread_%s_%s_visual.csv', subject_id, condition));
[vis, vis_z, vis_vec] = get_rsa_model(vis_fn);

% Orthographic  
orth_fn = fullfile(model_path, sprintf('quickread_%s_%s_orthographic.csv', subject_id, condition));
[ort, ort_z, ort_vec] = get_rsa_model(orth_fn);

% Phonological 
phon_fn = fullfile(model_path, sprintf('quickread_%s_%s_phonological.csv', subject_id, condition));
[phon, phon_z, phon_vec] = get_rsa_model(phon_fn);

% Semantic 
sem_fn = fullfile(model_path, sprintf('quickread_%s_%s_semantic.csv', subject_id, condition));
[sem, sem_z, sem_vec] = get_rsa_model(sem_fn);

% Articulatory 
art_fn = fullfile(model_path, sprintf('quickread_%s_%s_articulatory.csv', subject_id, condition));
[art, art_z, art_vec] = get_rsa_model(art_fn);

% Define a list of all model vectors
model_vectors = [vis_vec', ort_vec', phon_vec', sem_vec', art_vec'];

%% (1) Compute between-model correlation matrix and Bayes factors
[rhos, p] = corrcoef(model_vectors, 'rows', 'all');

% Display only the upper diagonal for easy reading
%triu(rhos)

% Loop through pairs of model vectors, computing a Bayes factor for each
models = {'vis', 'ort', 'phon', 'sem', 'art'};

% This nested loop will compute Bayes factor for the correlation between
% each pair of models, and print the output to command window. Not as
% elegant as corrcoef but it gets the job done. 
for i=1:numel(models)
    i_model = models{i};
    i_model_vec = eval(sprintf('%s_vec', i_model));
    
    for j=1:numel(models)
        j_model = models{j};
        j_model_vec = eval(sprintf('%s_vec', j_model));
        
        % Skip if i_model and j_model are the same
        if strcmp(j_model, i_model)
            continue
        end
        
        % Compute Bayes factor for the correlation between the two vectors
        bf10 = bf.corr(i_model_vec', j_model_vec');        
        
        % Print output to command window (ignore the number printed at the
        % end of each line, it's just the number of characters)
        format long
        disp(fprintf('r(%s, %s) = %f', i_model, j_model, bf10));
        
    end % j loop
end % i loop
%% (2) Visualize hypothesis models
% I recommend restarting the script and enetering either 'aloud' or
% 'silent', since the visualizations are intended to be representative of
% the models actually used for RSA.

% % Get list of words from one model (doesn't matter which) to use as labels
words = readtable(art_fn);
word_labels = words.Var1;

% To make things easier, define arguments that we will pass to ALL heatmap
% calls

clims = [-3 3];
rot= 45;

heatmap_args = {'CellLabelColor', 'none', ...
    'ColorbarVisible', 'off', ...
    'GridVisible', 'off', ...
    'MissingDataColor', 'w', ...
    'MissingDataLabel', '', ...
    'Colormap', [[1,1,1]; turbo], ... % this ensures that zero values appear white
    'XDisplayLabels', NaN*ones(length(vis_z),1), ...
    'YDisplayLabels', NaN*ones(length(vis_z),1), ...
    'FontName', 'calibri', ...
    'Fontsize', 7, ...
    };

% Create figure using tiledlayout function. Each plot is added successively
% using nexttile(position #). Heatmaps are in odd positions (left column),
% dendrograms in even positions (right column)
f = figure();
t = tiledlayout(5,2, 'TileSpacing', 'tight', 'Padding', 'compact');

% Use a loop to add successive plots
models = {'vis', 'ort', 'phon', 'sem', 'art'};
model_labels = {'\bf Visual', '\bf Orthographic', '\bf Phonological', '\bf Semantic', '\bf Articulatory'};

% Loop through rows of our figure
for i_row = 1:5
    
    % Call the model for this row
    model_str = models{i_row};
    model_sq = eval(model_str);
    model_vec = eval(sprintf('%s_vec', model_str));
    
    % Select the left-hand tile and plot a heatmap (RDM)
    nexttile   
    
    h = heatmap(tril(model_sq), ...
        'YLabel', model_labels{i_row}, ...
        heatmap_args{:}, ...
        'ColorLimits', [min(model_vec)*0.75,max(model_vec)]... % using min(model_vec)*0.75 prevents low nonzero values from appearing white 
        );
    
         
    % Converting to struct allows us to make some aesthetic changes. This
    % will cause a Warning, but we can safely ignore it.
    s = struct(h);
    
    h.XDisplayLabels = word_labels;
    h.YDisplayLabels = word_labels;
    h.ColorbarVisible = 'on';

    % Rotate the X tick labels 
    s.XAxis.TickLabelRotation = rot;

    % Add a colorbar
    cb = s.Colorbar;
    
    cb.Ticks = [min(model_vec)*0.75,max(model_vec)];
    cb.TickLabels = {'Similar','Dissimilar'};
        
    
    % Select the right-hand tile and plot a dendrogram
    nexttile
    d = dendrogram(linkage(model_sq), 'labels', word_labels, 'orientation', 'top');
    set(gca,'fontsize',7, 'fontname', 'calibri')
    set(d, 'Color', [0, 0, 0]);
    xtickangle(45)     
    
end % row loop
