import numpy as np
from sklearn import preprocessing
from scipy.io.wavfile import read
from python_speech_features import mfcc
from python_speech_features import delta
from speechpy.processing import cmvn
from dtw import dtw

def acoustic_distance(file1, file2):
  """Computes the acoustic distance between audio files based on Bartelds (2020)."""

  """L Bailey made a single change to this function: the nfft parameter in mfcc() is
  set to 2048 instead of the original 1024, to be compatible with the sample rate of
  the recorded audios. This value was detremined using:

  rate, audio = read( < recording.wav > )
  calculate_nfft(rate, < default winlen in function below > )

  read() and calculate_nfft() are both functions from python_speech_features



  """
  rate1, audio1 = read(file1)
  rate2, audio2 = read(file2)
  mfcc_feature1 = mfcc(audio1,
                      rate1,
                      winlen = 0.025,
                      winstep = 0.01,
                      preemph = 0.97,
                      numcep = 12,
                      appendEnergy = True,
                      winfunc = np.hamming,
                      #nfft=1024
                      nfft=2048)   # Changed from 1024 by L Bailey
  mfcc_feature2 = mfcc(audio2,
                      rate2,
                      winlen = 0.025,
                      winstep = 0.01,
                      preemph = 0.97,
                      numcep = 12,
                      appendEnergy = True,
                      winfunc = np.hamming,
                      #nfft=1024
                      nfft=2048)   # Changed from 1024 by L Bailey
  deltas1 = delta(mfcc_feature1, 2)
  double_deltas1 = delta(deltas1, 2)
  deltas2 = delta(mfcc_feature2, 2)
  double_deltas2 = delta(deltas2, 2)
  combined1 = np.hstack((mfcc_feature1, deltas1, double_deltas1))
  combined2 = np.hstack((mfcc_feature2, deltas2, double_deltas2))
  combined1 = cmvn(combined1, variance_normalization=True)
  combined2 = cmvn(combined2, variance_normalization=True)
  res = dtw(combined1, combined2, window_type="slantedband", window_args={"window_size" : 200}, distance_only=True)
  return res.distance / (combined1.shape[1] + combined2.shape[1])
