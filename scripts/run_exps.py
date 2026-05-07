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

from networks import FullyConnectedNetwork_small, NARX_Dataset, FullyConnectedNetwork_varDepth
from train import train_FCN_R0_R1_small, train_FCN_R1_R4_small, train_pretrained_FCN_R0_R1_small, train_pretrained_FCN_R1_R4_small
from read_data import load_and_process_data

import onnx
import onnxruntime as ort

random.seed(10)
torch.random.manual_seed(10)

# directory where data is stored. Change if needed.
data_dir = 'C:/Users/mgogo/Projects/2.C01/project/data_raw/' 
model_folder = 'C:/Users/mgogo/Projects/2.C01/project/models/'

# Set options
exp_running = 'R0_R1' # 'R1_R4'
training = 'train' # 'train' or 'pretrain'
model_num = 'Model_Best'

# Read data and calculate mean and std for normalization. 
if training == 'train':
    
    model_dir = f'{model_folder}{exp_running}_{model_num}/{training}'
    
    all_exps = ['01_2mm', '02_4mm', '03_Splices1', '04_Splices2', '05_Splices3', '06_fastSplices', '07_slowSplices', '08_Step2mm', 
                '09_steps4mm', '10_FastSplices2', '11_SlowSplices2', '12_NormalFunctioning_Fast', '13_NormalFunctioning_Slow', 
                '15_Step2mm_fast', '16_Step4mm_fast',  '17_step2mm_slow', '18_step4mm_slow', '19_splice_slow1', '19_splice_slow2', 
                '20_splice_fast1', '20_splice_fast2'] 

    train_exps = ['01_2mm', '02_4mm', '03_Splices1', '04_Splices2', '05_Splices3', '06_fastSplices', '07_slowSplices', '08_Step2mm', 
                  '09_steps4mm', '10_FastSplices2', '11_SlowSplices2', '13_NormalFunctioning_Slow', '15_Step2mm_fast', '16_Step4mm_fast',  
                  '17_step2mm_slow', '18_step4mm_slow', '19_splice_slow1', '19_splice_slow2', '20_splice_fast1', '20_splice_fast2']
    
    val_exps = ['12_NormalFunctioning_Fast']
    
    dfs, mean_std = load_and_process_data(data_dir, 1, all_exps, train_exps)

if training == 'pretrain':

    model_dir = f'{model_folder}{exp_running}_{model_num}/{training}'
    model_pretrain = f'{model_folder}{exp_running}_{model_num}/train/hiddensize_2_depth_2_dropout_0.5_downsamp_5_addedweight_5_noise_std_0/model.pth'

    all_exps = ['21_4mm_test2', '22_2mm_fast', '23_splice', '24_step_gain_1_75', '25_step_gain_2_6', '26_splice_fast', '27_4mm_fast', '28_4mm', '29_2mm_test2', '30_2mm'] 
    train_exps = ['21_4mm_test2', '22_2mm_fast',  '24_step_gain_1_75', '26_splice_fast', '27_4mm_fast', '29_2mm_test2']
    val_exps = ['23_splice', '25_step_gain_2_6', '28_4mm', '30_2mm']
    
    dfs, mean_std = load_and_process_data(data_dir, 1, all_exps, train_exps)


## This it To run Experiments on ALL of the Dataset
if (exp_running=='R0_R1'):

    print("Running R0-R1 Experiments")
    
    inputs = ['fEdgeDetectorValue' , 'ActualPosition' , 'AI_PMSSpeedBendingRoller', 'y_R1']
    window_lens = [1500, 1000, 100]

    p_dropout_list = [0.5]
    num_layers_list = [2]
    hidden_size_fact_list = [2]
    downsamp_list = [5]
    added_weights_list = [5]
    noise_std_list = [0]

    # Initialize empty list to hold dictionary of results for each model
    results = []

    for p_dropout in p_dropout_list:
        for num_layers in num_layers_list:
            for hidden_size_fact in hidden_size_fact_list:
                for downsamp in downsamp_list:
                    for added_weight in added_weights_list:
                        for noise_std in noise_std_list:
                        
                            model_folder = f"{model_dir}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noise_std_{noise_std}"
                            print(model_folder)
                            
                            if training == 'train':
                                gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict = train_FCN_R0_R1_small(
                                                                                                                    dfs, 
                                                                                                                    inputs_list=inputs, 
                                                                                                                    window_lens=window_lens, 
                                                                                                                    base_folder=model_dir, 
                                                                                                                    train_exps=train_exps, 
                                                                                                                    val_exps=val_exps, 
                                                                                                                    mean_std=mean_std, 
                                                                                                                    hidden_size_fact = hidden_size_fact, 
                                                                                                                    num_layers = num_layers, 
                                                                                                                    all_exps=all_exps, 
                                                                                                                    early_stopping_epochs=5, 
                                                                                                                    learning_rate=0.001, 
                                                                                                                    p_dropout=p_dropout, 
                                                                                                                    added_weight=added_weight, 
                                                                                                                    downsamp=downsamp, 
                                                                                                                    add_noise=False, 
                                                                                                                    noise_std=noise_std)
                            
                            if training == 'pretrain':
                                gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict = train_pretrained_FCN_R0_R1_small(dfs, 
                                                                                                                                inputs_list=inputs, 
                                                                                                                                window_lens=window_lens, 
                                                                                                                                base_folder=model_dir, 
                                                                                                                                train_exps=train_exps, 
                                                                                                                                val_exps=val_exps, 
                                                                                                                                mean_std=mean_std, 
                                                                                                                                hidden_size_fact = hidden_size_fact, 
                                                                                                                                num_layers = num_layers, 
                                                                                                                                all_exps=all_exps, 
                                                                                                                                early_stopping_epochs=5, 
                                                                                                                                learning_rate=0.001, 
                                                                                                                                p_dropout=p_dropout, 
                                                                                                                                added_weight=added_weight, 
                                                                                                                                downsamp=downsamp, 
                                                                                                                                add_noise=False, 
                                                                                                                                noise_std=noise_std, 
                                                                                                                                model_pretrain=model_pretrain)
                            
                            model_results = {}
                            model_outputs = {}

                            # Add window lengths to dictionary, using a default value of 0 if index is not available
                            model_results['Y0_history'] = window_lens[0] if len(window_lens) > 0 else 0
                            model_results['u1_history'] = window_lens[1] if len(window_lens) > 1 else 0
                            model_results['speed_history'] = window_lens[2] if len(window_lens) > 2 else 0
                            model_results['target_roller_history'] = window_lens[3] if len(window_lens) > 3 else 0
                            model_results['p_dropout'] = p_dropout
                            model_results['num_layers'] = num_layers
                            model_results['hidden_size_fact'] = hidden_size_fact
                            model_results['downsamp_rate'] = downsamp
                            model_results['added_weight'] = added_weight
                            model_results['noise_std'] = noise_std

                            # Add GoF values to dictionary
                            for exp_name, gof in gof_dict.items():
                                model_results[exp_name + '_gof'] = gof_dict[exp_name]
                                model_results[exp_name + '_maxdev'] = max_dev_dict[exp_name]
                                model_outputs[exp_name + '_pred'] = pred_outputs_dict[exp_name]

                            # Print out results for that model
                            print(model_results)

                            # Save dictionary to JSON file
                            with open(f'{model_folder}/val_info.json', 'w') as f:
                                json.dump(model_results, f)
                            # with open(f'{model_folder}/val_outputs.json', 'w') as f:
                            #     json.dump(model_outputs, f)

                            # Append dictionary to results list
                            results.append(model_results)

    # Convert results list to DataFrame
    df = pd.DataFrame(results)

    # Display DataFrame
    print(df)

    # Save DataFrame to csv file
    df.to_csv(os.path.join(model_dir, "gof_values.csv"), index=False)
                    

else:

    print("Running R1-R4 Experiments")

    inputs = ['y_R1' , 'ActualPosition' , 'AI_PMSSpeedBendingRoller']
    window_lens = [1500, 1000, 100]

    p_dropout_list = [0.5]
    num_layers_list = [2]
    hidden_size_fact_list = [2]
    downsamp_list = [5]
    added_weights_list = [5]
    noise_std_list = [0]
    results = []

    for p_dropout in p_dropout_list:
        for num_layers in num_layers_list:
            for hidden_size_fact in hidden_size_fact_list:
                for downsamp in downsamp_list:
                    for added_weight in added_weights_list:
                        for noise_std in noise_std_list:
                        
                            model_folder = f"{model_dir}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noisestd_{noise_std}"
                            print(model_folder)
                            
                            if training == 'train':
                                gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict = train_FCN_R1_R4_small(
                                                                                                                    dfs, 
                                                                                                                    inputs_list=inputs, 
                                                                                                                    window_lens=window_lens, 
                                                                                                                    base_folder=model_dir, 
                                                                                                                    train_exps=train_exps, 
                                                                                                                    val_exps=val_exps, 
                                                                                                                    mean_std=mean_std, 
                                                                                                                    hidden_size_fact = hidden_size_fact, 
                                                                                                                    num_layers = num_layers, 
                                                                                                                    all_exps=all_exps, 
                                                                                                                    early_stopping_epochs=5, 
                                                                                                                    learning_rate=0.001, 
                                                                                                                    p_dropout=p_dropout, 
                                                                                                                    added_weight=added_weight, 
                                                                                                                    downsamp=downsamp, 
                                                                                                                    add_noise=False, 
                                                                                                                    noise_std=noise_std)
                                
                            if training == 'pretrain':
                                gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict = train_pretrained_FCN_R1_R4_small(dfs, 
                                                                                                                                inputs_list=inputs, 
                                                                                                                                window_lens=window_lens, 
                                                                                                                                base_folder=model_dir, 
                                                                                                                                train_exps=train_exps, 
                                                                                                                                val_exps=val_exps, 
                                                                                                                                mean_std=mean_std, 
                                                                                                                                hidden_size_fact = hidden_size_fact, 
                                                                                                                                num_layers = num_layers, 
                                                                                                                                all_exps=all_exps, 
                                                                                                                                early_stopping_epochs=5, 
                                                                                                                                learning_rate=0.001, 
                                                                                                                                p_dropout=p_dropout, 
                                                                                                                                added_weight=added_weight, 
                                                                                                                                downsamp=downsamp, 
                                                                                                                                add_noise=False, 
                                                                                                                                noise_std=noise_std, 
                                                                                                                                model_pretrain=model_pretrain)                        

                            model_results = {}
                            model_outputs = {}

                            # Add window lengths to dictionary, using a default value of 0 if index is not available
                            model_results['Y0_history'] = window_lens[0] if len(window_lens) > 0 else 0
                            model_results['u1_history'] = window_lens[1] if len(window_lens) > 1 else 0
                            model_results['speed_history'] = window_lens[2] if len(window_lens) > 2 else 0
                            model_results['roller_press_history'] = window_lens[3] if len(window_lens) > 3 else 0
                            model_results['p_dropout'] = p_dropout
                            model_results['num_layers'] = num_layers
                            model_results['hidden_size_fact'] = hidden_size_fact
                            model_results['downsamp_rate'] = downsamp
                            model_results['added_weight'] = added_weight

                            # Add GoF values to dictionary
                            for exp_name, gof in gof_dict.items():
                                model_results[exp_name + '_gof'] = gof_dict[exp_name]
                                model_results[exp_name + '_maxdev'] = max_dev_dict[exp_name]
                                model_outputs[exp_name + '_pred'] = pred_outputs_dict[exp_name]

                            # Print out results for that model
                            print(model_results)

                            # Save dictionary to JSON file
                            with open(f'{model_folder}/val_info.json', 'w') as f:
                                json.dump(model_results, f)
                            # with open(f'{model_folder}/val_outputs.json', 'w') as f:
                            #     json.dump(model_outputs, f)

                            # Append dictionary to results list
                            results.append(model_results)

    # Convert results list to DataFrame
    df = pd.DataFrame(results)

    # Display DataFrame
    print(df)

    # Save DataFrame to csv file
    df.to_csv(os.path.join(model_dir, "gof_values.csv"), index=False)