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


random.seed(10)
torch.random.manual_seed(10)

# Define the Dataset Object required for the NARX modeling

'''
This Dataset object, given a dataframe corresponding to an experiment; arranges
the data frame to get samples for time-series prediction based on the requred inputs
and their window lengths in the past
'''

class NARX_Dataset(Dataset):
    
    def __init__(self, df, input_cols, window_lens, output_cols, added_weight=1, downsamp=1):
        self.df = df
        self.input_cols = input_cols
        self.window_lens = window_lens
        self.output_cols = output_cols
        self.max_window_len = max(window_lens)
        self.added_weight = added_weight
        self.downsamp = downsamp

    def __len__(self):
        # The length of the dataset is the number of rows in the inputs
        return len(self.df) - self.max_window_len - 1

    def __getitem__(self, idx):
        # Get the input and output for the requested index directly from the dataframe

        # Prepare input
        input_data = []
        for col, window_len in zip(self.input_cols, self.window_lens):
            # Window of data for each input column
            input_data.append(self.df[col][idx+self.max_window_len-window_len : idx+self.max_window_len : self.downsamp].values)
            # if col == 'y_R1': 
            #     # prevent data peeking for roller R1
            #     data = self.df[col][idx+self.max_window_len-window_len : idx+self.max_window_len-1].values
            #     data = np.append(data, self.df[col][idx+self.max_window_len-2])
            #     input_data.append(data[::self.downsamp])
                
            # else:
            #     input_data.append(self.df[col][idx+self.max_window_len-window_len : idx+self.max_window_len : self.downsamp].values)

        input_row = np.concatenate(input_data, axis=0)

        # Prepare output
        output_data = []
        for col in self.output_cols:
            output_data.append(self.df[col][idx+self.max_window_len])

        output_sample = np.array(output_data).reshape(-1, 1)

        # Prepare Weight 
        weight_data = []
        #if(sum(self.df['VAR_SpliceR0'][idx:idx+self.max_window_len])>1):
        if(sum(self.df['VAR_SpliceR1'][max(0, idx-self.max_window_len):idx+self.max_window_len])>1):
            weight_data.append(self.added_weight)
            #print("Needed HIGHER weight")
        else:
            weight_data.append(1)
        weight_sample = np.array(weight_data).reshape(-1, 1)

        # Convert to PyTorch tensors and return
        return torch.FloatTensor(input_row), torch.FloatTensor(output_sample), torch.FloatTensor(weight_sample)
    
## Define the Neural networks to be used for Training

class FullyConnectedNetwork_small(nn.Module):
    def __init__(self, input_size, hidden_size, output_size, p_dropout):
        super(FullyConnectedNetwork_small, self).__init__()

        # Define the architecture
        self.fc1 = weight_norm(nn.Linear(input_size, hidden_size))
        self.dropout1 = nn.Dropout(0.2)
        self.fc2 = weight_norm(nn.Linear(hidden_size, hidden_size//2))
        self.dropout2 = nn.Dropout(p_dropout)
        self.fc3 = weight_norm(nn.Linear(hidden_size//2, output_size))
        # Define the activation
        self.relu = nn.ReLU()

    def forward(self, x):
        x = self.relu(self.fc1(x))
        x = self.dropout1(x)
        x = self.relu(self.fc2(x))
        x = self.dropout2(x)
        # No activation and no dropout on the last layer
        x = self.fc3(x)

        return x
    
## Define variable depth Hidden Neural Network ##

class FullyConnectedNetwork_varDepth(nn.Module):
    def __init__(self, input_size, hidden_size, output_size, num_layers, p_dropout):
        super(FullyConnectedNetwork_varDepth, self).__init__()

        self.hidden_layers = nn.ModuleList()
        
        # Input layer
        self.hidden_layers.append(weight_norm(nn.Linear(input_size, hidden_size)))
        self.hidden_layers.append(nn.Dropout(0.2))

        # Hidden layers
        for i in range(num_layers-1):
            next_hidden_size = max(hidden_size // (1**(i+1)), 1)
            self.hidden_layers.append(weight_norm(nn.Linear(hidden_size, next_hidden_size)))
            self.hidden_layers.append(nn.Dropout(p_dropout))
            hidden_size = next_hidden_size

        # Output layer
        self.fc_out = weight_norm(nn.Linear(hidden_size, output_size))

        # Activation
        self.relu = nn.ReLU()

    def forward(self, x):
        for layer in self.hidden_layers:
            if isinstance(layer, nn.Dropout):
                x = layer(x)
            else:
                x = self.relu(layer(x))
        
        x = self.fc_out(x)
        
        return x
