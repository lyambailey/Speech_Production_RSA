############################################################
# Import base packages
############################################################

# Import base packages
import pandas as pd
import itertools
import os.path
import numpy as np
from scipy.spatial.distance import pdist, squareform
from scipy import spatial

############################################################
# Define important directories
############################################################
top_dir =  open('../top_dir_win.txt').read().replace('\n', '') # If running Windows
# top_dir =  open('../../top_dir_unix.txt').read().replace('\n', '') # If running Unix

assets_dir = os.path.join(top_dir, 'MRIanalyses', 'assets')

############################################################
# Import dependencies for specific functions
############################################################

# Dependencies for articulatory measure (corpustools)
from corpustools import corpus, symbolsim, contextmanagers
from corpustools.symbolsim.string_similarity import string_similarity
from corpustools.corpus import *
from corpustools.corpus.io import *
from corpustools.contextmanagers import *

# Dependencies for orthographic measure (wordkit)
import wordkit
from wordkit.features import OpenNGramTransformer, LinearTransformer, fourteen, CVTransformer, PhonemeFeatureExtractor
#import eng_to_ipa as ipa

# Dependencies for semantic measure (gensim and pattern)
import gensim ## we can ignore the warning about Levenshtein distance - it doesn't matter to us
from gensim import downloader as api
from pattern.en import lemma, lexeme  # .en gives us the English version

# Dependencies for visual measure (Pillow / PIL)
import PIL
from PIL import Image, ImageDraw, ImageFont
from imageio import imread

############################################################
# Import assets for specific functions
############################################################

# IPHOD corpus, for articulatory measure
corpus_path = os.path.join(assets_dir, 'corpora_and_models', 'iphod_corpus')
mycorpus=load_binary(corpus_path)
mycontext=BaseCorpusContext(mycorpus, sequence_type='transcription', type_or_token='type')

# Grapheme-to-phoneme consistency values (Obtained from Chee et al., 2020) for phonological measure
g_to_p_values_fname = os.path.join(assets_dir, 'grapheme_to_phoneme_consistency_norms', 'quickread_words_alphabetical_consistency.csv')
gpvs = pd.read_csv(g_to_p_values_fname, sep=',', usecols = ['WORD', 'O', 'N', 'C'])  # The remaining columns are combinations of O,N,C and not really useful to us

# Pre-made word2vec model, for semantic measure
sem_model_fname = os.path.join(assets_dir, 'corpora_and_models', 'SEMmodel_glove-wiki-gigaword-300.model')
sem_model = gensim.models.keyedvectors.KeyedVectors.load(sem_model_fname)


############################################################
# Define custom functions for constructing hypothesis matrices
############################################################

# Articulatory (feature-weighted phonological edit distance)
def make_articulatory_matrix(word_list):

    # Ensure word list is sorted alphabetically
    word_list_sorted = sorted(word_list)

    # Arrange list of words into all possible pairs
    pairs = list(itertools.permutations(word_list_sorted, 2))

    # Define an empty matrix, containing a row/column for ever word
    matrix=pd.DataFrame(index=word_list_sorted, columns=word_list_sorted)

    for pair in pairs:

        # Each pair is a tuple, so let's convert to list
        pair_list = list(pair)

        # Some words are Capitalised in the corpus, so this code Capitalises any such words:
        for n, i in enumerate(pair_list):
            if i not in mycorpus:
                pair_list[n] = pair_list[n].title()

        w1 = mycorpus.find(pair_list[0])
        w2 = mycorpus.find(pair_list[1])

        # Get similarity for this pair
        x = string_similarity(corpus_context=mycontext
                              , query=(w1,w2)
                              , algorithm='phono_edit_distance')

        # The object "x" is technically a list of tuples, BUT there is only one tuple. The tuple contains:
        # (1) string1, (2) string2, (3) the phonological edit distance betwen string1 and string2
        # Therefore we can extract the edit distance using x[0][2]. The first [0] selects the "first" tuple,
        # the [2] selects the third item in the tuple. God damn Python.
        distance=x[0][2]


        # New version: divide by the length of the longest word in the pair (a-la Schepens et al, 2012)
        # https://www.cambridge.org/core/services/aop-cambridge-core/content/view/9B0B8913C6A5F39984B11A4063F55FDB/S1366728910000623a.pdf/distributions-of-cognates-in-europe-as-based-on-levenshtein-distance.pdf

        # Get max word length
        max_len = max(len(pair_list[0]), len(pair_list[1]))

        # Divide distance by max word length
        distance = distance/max_len

        # Insert the distance value into the corresponding row/column
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[1]]=distance

        # Finally, enter zeros along the diagonal
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[0]]=0

    return matrix

# Orthographic (correlation distance of open bigram vectors)
def make_orthographic_matrix(word_list):

    for i in word_list:

        # Transform to features based on open bigrams. We'll use a constrained bigram approach
        # but see options here: https://github.com/clips/wordkit/tree/master/wordkit/features/orthography
        o = OpenNGramTransformer(2)
        features = o.fit_transform(word_list)


        # Arrange features into a DSM (correlation distance)
        matrix = squareform(pdist(features, 'correlation'))

        # Plug into a pandas df
        df = pd.DataFrame(data=matrix, index=word_list, columns=word_list)


    return df

# Phonological (euclidean distance of G2P consistency vectors)
def make_phonological_matrix(word_list):

    # Ensure word list is sorted alphabetically
    word_list_sorted = sorted(word_list)

    # Arrange list of words into all possible pairs
    pairs = list(itertools.permutations(word_list_sorted, 2))

    # Define an empty matrix, containing a row/column for ever word
    matrix=pd.DataFrame(index=word_list_sorted, columns=word_list_sorted)

    for pair in pairs:

        # Define each word in the pair
        w1 = pair[0]
        w2 = pair[1]

        # Get vector for each word
        w1_vec = gpvs.loc[gpvs['WORD'].isin([w1])].iloc[0][1:]
        w2_vec = gpvs.loc[gpvs['WORD'].isin([w2])].iloc[0][1:]

        # Treat values for O,N,C as a vector and compute euclidean distance
        distance = spatial.distance.euclidean(w1_vec, w2_vec)

        # Insert the distance value into the corresponding row/column
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[1]]=distance

        # Finally, enter zeros along the diagonal
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[0]]=0

    return matrix

# Semantic distance (cosine distance of word2vec vectors)
def make_semantic_matrix(word_list):

    # Ensure word list is sorted alphabetically
    word_list_sorted = sorted(word_list)

    # Arrange list of words into all possible pairs
    pairs = list(itertools.permutations(word_list_sorted, 2))

    # Define an empty matrix, containing a row/column for ever word
    matrix=pd.DataFrame(index=word_list_sorted, columns=word_list_sorted)

    # Loop through word pairs, getting a distance value for each pair, and insert it into our matrix
    for pair in pairs:

        # Assign each word to an object and compute distance
        w1 = pair[0]
        w2 = pair[1]
        x = sem_model.similarity(w1, w2)

        # model.similarity spits out cosine similarity (i.e. lower values = LESS similar).
        # Therefore, subtract the similarity value from 1 to get a distance measure.
        d = 1-x

        # Insert the distance value into the corresponding row/column
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[1]]=d

        # Finally enter zeros along the diagonal
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[0]]=0

    return matrix

# Visual (correlation distance of silhouette vectors)
def make_visual_matrix(word_list):

    # Create empty list to store vectors
    vectors = []

    # Ensure word list is sorted alphabetically
    word_list_sorted = sorted(word_list)

    for word in word_list_sorted:

        # Define display ratio
        W, H = (1920,1080)

        # Create background image
        win = Image.new('RGB', (W,H), color=(128,128,128) # RGB from experiment
                       )

        # Define word we will draw and font. Letter height should be proportional (0.1) to window height
        thisword = word
        fontsize = int(H * 0.1)
        myfont = ImageFont.truetype("arial.ttf", fontsize)

        # Call background image and "draw" word onto it
        draw = ImageDraw.Draw(win)

        # Define font / text size
        myFont = ImageFont.truetype("arial.ttf", fontsize)
        w, h = draw.textsize(word, font=myFont)

        # Define word position
        pos = ((W-w)/2,(H-h)/2)

        # Put everything together
        draw.text(pos, text=thisword,font=myfont, fill="white")

        # Binarize image (0 for background, 1 for everything else)
        win_bin = win.point( lambda p: 0 if p == 128 else 1 )

        # Convert to array
        arr = np.array(win_bin)
        arr_flat = np.ndarray.flatten(arr)

        # Convert arr to a vector
        vector = arr_flat.tolist()

        # Add to list of vectors
        vectors.append(vector)

    # Once we've looped through all words in this condition, arrange vectors into a DSM (correlation distance)
    matrix = squareform(pdist(vectors, 'correlation'))

    # Plug into a pandas df
    df = pd.DataFrame(data=matrix, index=word_list_sorted, columns=word_list_sorted)

    return df

# Word length (absolute difference in word length)
def make_wordlength_matrix(word_list):

    # Ensure word list is sorted alphabetically
    word_list_sorted = sorted(word_list)

    # Arrange list of words into all possible pairs
    pairs = list(itertools.permutations(word_list_sorted, 2))

    # Define an empty matrix, containing a row/column for ever word
    matrix=pd.DataFrame(index=word_list_sorted, columns=word_list_sorted)

    for pair in pairs:

        # Each pair is a tuple, so let's convert to list
        pair_list = list(pair)

        w1 = pair_list[0]
        w2 = pair_list[1]

        # Get similarity for this pair
        distance = abs(len(w1)-len(w2))  # Note: use feature_edit_distance_div_maxlen() for values normalized for word length

        # Insert the distance value into the corresponding row/column
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[1]]=distance

        # Finally, enter zeros along the diagonal
        matrix.loc[matrix.index==pair[0], matrix.columns==pair[0]]=0

    return matrix
