import json
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
import torch
import torch.nn as nn
import itertools
import math
import random

import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader

from tqdm import tqdm
import scipy
from sklearn.metrics import mean_squared_error

import copy
from sklearn.metrics import r2_score

import torch
from torch import nn, optim
import matplotlib.pyplot as plt
from torch.utils.data import DataLoader
import numpy as np
import os

from torch.nn.utils import weight_norm
from torch.utils.data import ConcatDataset

from networks import FullyConnectedNetwork_small, NARX_Dataset

random.seed(10)
torch.random.manual_seed(10)

import pandas as pd
import os

def load_and_process_data(folder, downsample_factor, all_exps, train_exps):
    # Define experiment names
    
    # Initialize an empty dictionary to hold all dataframes
    dfs = {}

    # Loop over each experiment
    for experiment in all_exps:
        # Generate filename with the folder name
        filename = os.path.join(folder, f"experiment_{experiment}.csv")

        # Read CSV file into a DataFrame
        df = pd.read_csv(filename)

        # Add DataFrame to the dictionary
        dfs[experiment] = df

    # Concatenate all dataframes to calculate overall max for 'AI_PMSSpeedBendingRoller'
    all_data = pd.concat([dfs[exp] for exp in train_exps])
    print(all_data.head())
    max_AI_PMSSpeedBendingRoller = all_data['AI_PMSSpeedBendingRoller'].max()
    max_AI_PendulumRoller_posn = all_data['AI_PendulumRoller_posn'].max()

    # Also compute overall mean and standard deviation for other columns
    columns_to_normalize = ['ActualPosition', 'fEdgeDetectorValue', 'y_R1', 'y_R4', 'y_R5', 'y_R7']
    mean_std = {col: (all_data[col].mean(), all_data[col].std()) for col in columns_to_normalize}
    mean_std['max_AI_PMSSpeedBendingRoller'] = max_AI_PMSSpeedBendingRoller 
    mean_std['max_AI_PendulumRoller_posn'] = max_AI_PendulumRoller_posn 


    dfs_downsamp = {}
    # Loop over each dataframe in the dictionary
    for experiment in dfs:
        # Normalize 'AI_PMSSpeedBendingRoller' and 'AI_PendulumRoller_posn' using overall max
        dfs[experiment]['AI_PMSSpeedBendingRoller'] /= max_AI_PMSSpeedBendingRoller
        dfs[experiment]['AI_PendulumRoller_posn'] /= max_AI_PendulumRoller_posn

        # Normalize the other columns using overall mean and standard deviation
        for col in columns_to_normalize:
            mean_col, std_col = mean_std[col]
            dfs[experiment][col] = (dfs[experiment][col] - mean_col) / std_col

        # Downsample and reset index
        dfs_downsamp[experiment] = dfs[experiment].iloc[::downsample_factor, :].reset_index(drop=True)

    return dfs_downsamp, mean_std


def load_raw_data(folder, all_exps):
    # Define experiment names
    

    # Initialize an empty dictionary to hold all dataframes
    dfs = {}

    # Loop over each experiment
    for experiment in all_exps:
        # Generate filename with the folder name
        filename = os.path.join(folder, f"{experiment}.csv")

        # Read CSV file into a DataFrame
        df = pd.read_csv(filename)

        # Add DataFrame to the dictionary
        dfs[experiment] = df

    return dfs
