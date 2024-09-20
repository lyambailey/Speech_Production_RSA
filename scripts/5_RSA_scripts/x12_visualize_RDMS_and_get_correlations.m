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

% Get list of quickread words
quickread_words_fn = fullfile(assets_path, 'quickread_words_alphabetical.csv');
quickread_words = table2cell(readtable(quickread_words_fn, 'ReadVariableNames', false));

% -------------------------------------------------------------------------
% IMPORTANT: if you want to calculate between-model correlations, set
% condition='alltrials' - this will pull the exemplar models containing all
% stimuli, regardless of condition. Otherwise, choose 'aloud' or 'silent'
% for a representative model actually used by RSA (subject-030, silent used
% for Figure in MS)
% -------------------------------------------------------------------------

condition='alltrials';

model_path = fullfile(assets_path, subject_id, 'RSA_models', 'quickread');

% Load in models. The 'get_rsa_model' function returns models in squareform,
% lower triangle, and vector format.

% Visual 
vis_fn = fullfile(model_path, sprintf('quickread_%s_%s_visual.csv', subject_id, condition));
[vis, vis_z, vis_vec] = get_rsa_model(vis_fn);

% Orthographic  
ort_fn = fullfile(model_path, sprintf('quickread_%s_%s_orthographic.csv', subject_id, condition));
[ort, ort_z, ort_vec] = get_rsa_model(ort_fn);

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

% % Also load in models for extraneous properties (these were only computed
% % for subject-001/alltrials)
% 
% Concreteness
conc_fn = fullfile(model_path, sprintf('quickread_%s_%s_conc.csv', subject_id, condition));
[conc, conc_z, conc_vec] = get_rsa_model(conc_fn);

% Grapheme-to-phoneme consistency
g2p_fn = fullfile(model_path, sprintf('quickread_%s_%s_g2p.csv', subject_id, condition));
[g2p, g2p_z, g2p_vec] = get_rsa_model(g2p_fn);

% Imageability
imag_fn = fullfile(model_path, sprintf('quickread_%s_%s_imag.csv', subject_id, condition));
[imag, imag_z, imag_vec] = get_rsa_model(imag_fn);

% Morphological complexity
morph_fn = fullfile(model_path, sprintf('quickread_%s_%s_morph.csv', subject_id, condition));
[morph, morph_z, morph_vec] = get_rsa_model(morph_fn);

% Syntactic category
nounverb_fn = fullfile(model_path, sprintf('quickread_%s_%s_nounverb.csv', subject_id, condition));
[nounverb, nounverb_z, nounverb_vec] = get_rsa_model(nounverb_fn);

% % Word length
% wordlength_fn = fullfile(model_path, sprintf('quickread_%s_%s_wordlength.csv', subject_id, condition));
% [wordlength, wordlength_z, wordlength_vec] = get_rsa_model(wordlength_fn);


%% (1a) Compute between-model correlation matrix and Bayes factors
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

%% (1b) Compute correlations between extraneous properties and hypothesis models
extrans = {'conc', 'g2p', 'imag', 'morph', 'nounverb'};

% Loop through models and extraneous properties. For each combination,
% compute the correlation and Bayes factor.
for i=1:numel(extrans)
    i_extran = extrans{i};
    i_extran_vec = eval(sprintf('%s_vec', i_extran));
        
    for k=1:numel(models)
        k_model = models{k};
                
        % The model for imageability is missing the following words
        % (because ratings are not provided for these words in Scott et
        % al., 2019)
        rm_words = {'account', 'campaign', 'century', 'department', ...
            'journey', 'painting', 'powder', 'turnip'};
        
        % If i_extran == imag, we need to remove those words from the
        % squareform of k_model
        if strcmp(i_extran, 'imag')
            rm_idx = contains(quickread_words, rm_words);
            
            k_model_sq = eval(k_model);
            k_model_sq(:, rm_idx) = [];
            k_model_sq(rm_idx, :) = [];
            
            k_model_vec = squareform(k_model_sq, 'tovector');
            
        else
            k_model_vec = eval(sprintf('%s_vec', k_model));
            
        end % if statement
                    
        % Get correlation and BF
        [bf10,r,p] = bf.corr(i_extran_vec', k_model_vec');
        
        disp(fprintf('r(%s, %s) = %f, BF = %f', i_extran, k_model, r, bf10));
        
    end % k loop
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
rot= 90;

heatmap_args = {'CellLabelColor', 'none', ...
    'ColorbarVisible', 'off', ...
    'GridVisible', 'off', ...
    'MissingDataColor', [1,1,1], ...
    'MissingDataLabel', '', ...
    'Colormap', [1,1,1; turbo], ... % this ensures that the lowest value in the matrix appears white
    'XDisplayLabels', NaN*ones(length(vis_z),1), ...
    'YDisplayLabels', NaN*ones(length(vis_z),1), ...
    'FontName', 'Calibri', ...
    'Fontsize', 7, ...
    };

% Create figure using tiledlayout function. Each plot is added successively
% using nexttile(position #). Heatmaps are in odd positions (left column),
% dendrograms in even positions (right column)
f = figure();
t = tiledlayout(5,5, 'TileSpacing', 'tight', 'Padding', 'compact');

% Use a loop to add successive plots
models = {'vis', 'ort', 'phon', 'sem', 'art'};
model_labels = {'\bf Visual', '\bf Orthographic', '\bf Phonological', '\bf Semantic', '\bf Articulatory'};

% Loop through rows of our figure
for i_row = 1:5
    
    % Call the z-scored model, as well as the model vector, for this row
    model_str = models{i_row};
    model_sq = eval(model_str);
    model_sq_z = eval(sprintf('%s_z', model_str));
    model_vec = eval(sprintf('%s_vec', model_str));
    
    % Identify minimum and maximum values in the z-score model (we'll need
    % this info for the color scale on the heatmap)
    [minz, maxz] = bounds(model_sq_z, 'all');
    
    lims = [minz*1.2, maxz*1.2];
    
    % Take lower triangle to model_sq_z, and then set all zero values (i.e.
    % upper triangle) to minz*1.2 (defined as the first element of 'lims'
    % above). This allows us to plot the heatmap with the upper diagonal as
    % first color in our colormap ([1,1,1]); all values above this (i.e.,
    % everything in the lower triangle) will use the rest of the colormap.
    % Note: this depends on the minimum value being negative (which is to
    % be expected when using z-scored matrices). If positive, use something
    % like minz-(minz*0.1).
    model_sq_z_tril = tril(model_sq_z, -1);
    model_sq_z_tril(model_sq_z_tril==0) = lims(1);
    
    % Select the left-hand tile and plot a heatmap (RDM)
    nexttile([1,2]);    

    h = heatmap(model_sq_z_tril, ...
        'YLabel', model_labels{i_row}, ...
        heatmap_args{:}, ...
        'ColorLimits', lims ...
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
    
    cb.Ticks = lims;
    cb.TickLabels = {'Similar','Dissimilar'};
   
    
    % Select the next (middle) tile and plot a histogram
    nexttile([1,1]);  

    % Plot histogram with histfit, which helpfully fits a curve to the
    % bars. Note that the configuration below (specifically using a
    % 'kernal' fit and setting the 'Xlim' to min/max) produces exactly the
    % same appearance as a histogram with no fit (can be tested by running
    % the line below): 
    % histogram(zscore(model_vec), 10, 'EdgeColor', 'None');
    % The only difference is that histfit fits a curve. 
    
    hist = histfit(zscore(zscore(model_vec)),10, 'kernel');
    
    % Aesthetic changes...
    hist(1).FaceColor = [0.3 0.75 0.93];
    hist(1).FaceAlpha = 0.5;
    hist(1).EdgeColor = 'None';
    hist(2).Color = 'k'; %[0 0.45 0.74];
    hist(2).LineWidth = 1;
    
    % The next line rotates the histogram by 90 degrees, removes X/Y axes,
    % and restricts the scale of the X axis to the min/max of the data
    set(gca, 'xdir', 'reverse', 'view',[90 90], 'Visible', 'off', 'Xlim', lims)
     
    nexttile([1,2]);
    
    d = dendrogram(linkage(model_sq), 'labels', word_labels, 'orientation', 'top');
    set(gca,'fontsize',8, 'fontname', 'Calibri')
    set(d, 'Color', [0, 0, 0]);
    xtickangle(rot)   
    
end % row loop

