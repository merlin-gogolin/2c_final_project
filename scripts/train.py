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

import onnx
import onnxruntime as ort

random.seed(10)
torch.random.manual_seed(10)


# Define the function to Train the R0-R1 Block 

def train_FCN_R0_R1_small(dfs, inputs_list, window_lens, base_folder, train_exps, val_exps, mean_std, all_exps, 
                          hidden_size_fact, num_layers, early_stopping_epochs, learning_rate, p_dropout, added_weight, downsamp, add_noise=False, noise_std=0):


    # Create folder to store models
    #print(inputs_list)
    print("Downsampling Factor = ", downsamp)
    print("Add Noise = ", add_noise)
    print("List of All  experiments = ", all_exps)
    print("List of train  experiments = ", train_exps)
    print("List of validation  experiments = ", val_exps)

    
    inputs_str = "_".join(inputs_list)
    windows_str = "_".join(map(str, window_lens))
    
    #model_folder = f"{base_folder}/inputs_{inputs_str}_window_{windows_str}_hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}"
    model_folder = f"{base_folder}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noise_std_{noise_std}"
    
    if not os.path.exists(base_folder):
        os.makedirs(base_folder)    
    if not os.path.exists(model_folder):
        os.makedirs(model_folder)


    # Create subfolder for validation plots
    validation_plots_folder = f"{model_folder}/validation_plots"
    if not os.path.exists(validation_plots_folder):
        os.makedirs(validation_plots_folder)
        print("Validation folder Created!")

    # Define Experiment wise Datasets
    print("Creating Datasets")

    # Create the individual experiment datasets for the training set
    train_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'], added_weight=added_weight, downsamp=downsamp) for exp_name in train_exps]
    print("Train Datasets Created!")

    # Create the individual experiment datasets for the validation set
    valid_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'], downsamp=downsamp) for exp_name in val_exps]
    print("Validation Datasets Created!")
    
    # Concatenate the individual datasets into the train and valid datasets
    train_dataset = ConcatDataset(train_datasets)
    valid_dataset = ConcatDataset(valid_datasets)

    print("Datasets created!")
    print("Starting Training")
    # Begin Training!
    # Device configuration
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Model hyperparameters
    input_size = train_dataset[0][0].shape[0]
    hidden_size = int(hidden_size_fact*input_size)
    output_size = 1
    num_epochs = 100
    batch_size = 64
    # learning_rate = 0.001
    # early_stopping_epochs = 5

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    print(model)
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # Data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(valid_dataset, batch_size=len(valid_dataset), shuffle=False)

    # Store losses for plot
    train_losses = []
    val_losses = []

    # Best validation loss
    best_val_loss = np.inf

    # Counter for early stopping
    early_stopping_counter = 0

    # Training loop
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        for inputs, targets, weights in tqdm(train_loader):
            inputs, targets, weights = inputs.to(device), targets.to(device), weights.to(device)

            if (add_noise==True):
                # Add Gaussian noise to the targets
                noise = (torch.randn_like(targets))*noise_std       
                targets = targets + noise
            
            optimizer.zero_grad()
            outputs = model(inputs)
            #loss = criterion(outputs, targets[:,:,0])
            
            #Add weighted loss
            loss = torch.nn.functional.mse_loss(outputs, targets[:,:,0], reduction='none')
            loss = (loss * weights).mean()
            
            loss.backward()
            optimizer.step()
            train_loss += loss.item()

        train_losses.append(train_loss / len(train_loader))

        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, targets, _ in val_loader:
                
                inputs, targets = inputs.to(device), targets.to(device)
                
                if (add_noise==True):
                    # Add Gaussian noise to the targets
                    noise = (torch.randn_like(targets))*noise_std           
                    targets = targets + noise                
                
                outputs = model(inputs)
                loss = criterion(outputs, targets[:,:,0])
                val_loss += loss.item()

        val_losses.append(val_loss / len(val_loader))
        print(f'Epoch {epoch+1}, Train Loss: {train_loss / len(train_loader)}, Validation Loss: {val_loss / len(val_loader)}')

        # Plot losses and predictions every 10 epochs
        if (epoch+1) % 5 == 0:
            plt.figure()
            plt.plot(range(epoch+1)[2:], train_losses[2:], label='Train Loss')
            plt.plot(range(epoch+1)[2:], val_losses[2:], label='Validation Loss')
            plt.legend()
            plt.xlabel('Epochs')
            plt.ylabel('Loss')
            plt.title('Train and Validation Loss')

            plt.savefig(f"{validation_plots_folder}/trainval.png", bbox_inches='tight')
            #plt.show()

            plt.figure()
            model.eval()
            with torch.no_grad():
                val_preds = model(next(iter(val_loader))[0].to(device)).cpu().numpy()
            plt.plot(val_preds, label='Predicted')
            plt.plot(next(iter(val_loader))[1].numpy()[:,:,0], label='Actual')
            plt.legend()
            plt.xlabel('Samples')
            plt.ylabel('Value')
            plt.title('Model Predictions vs Actuals')
            plt.savefig(f"{validation_plots_folder}/val_perf.png", bbox_inches='tight')
            #plt.show()

        # Check for early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            early_stopping_counter = 0
            torch.save(model.state_dict(), f'{model_folder}/model.pth')
        else:
            early_stopping_counter += 1
            if early_stopping_counter >= early_stopping_epochs:
                print("Early stopping, no improvement for " + str(early_stopping_epochs) + " epochs.")
                break
      # Save results and hyperparameters
    results = {
        "train_losses": train_losses,
        "val_losses": val_losses,
        "best_val_loss": best_val_loss,
        "hyperparameters": {
            "input_size": input_size,
            "hidden_size": hidden_size,
            "output_size": output_size,
            "num_epochs": num_epochs,
            "batch_size": batch_size,
            "learning_rate": learning_rate,
            "early_stopping_epochs": early_stopping_epochs,
            "p_dropout": p_dropout,
        }
    }

    # Save dictionary to JSON file
    with open(f'{model_folder}/train_info.json', 'w') as f:
        json.dump(results, f)

    print("Training Complete.")

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    model.load_state_dict(torch.load(f'{model_folder}/model.pth'))
    model.eval()
    print("Model Loaded")

    print("Starting Validation Plots")
    
    # Create a dictionary of datasets
    datasets = {f"exp{index + 1}_dataset": NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'],added_weight=added_weight,  downsamp=downsamp) 
                for index, exp_name in enumerate(all_exps)}    

    gof_dict = {}
    max_dev_dict = {}
    true_outputs_dict = {}
    pred_outputs_dict = {}

    # Loop through each dataset
    for name, dataset in datasets.items():

        # Pass the dataset through the model to get predictions
        inputs, true_outputs, weights = zip(*[dataset[i] for i in range(len(dataset))])
        inputs = torch.stack(inputs).to(device)
        true_outputs = torch.stack(true_outputs).to(device)
        weights = torch.stack(weights).to(device)

        with torch.no_grad():
            predicted_outputs = model(inputs)

        # Move data to cpu and convert to numpy for plotting. an scale up
        true_outputs = true_outputs.cpu().numpy()
        predicted_outputs = predicted_outputs.cpu().numpy()
        weights = weights.cpu().numpy()
        # Calculate percentage goodness of fit
        goodness_of_fit = 100 * (1 - ((true_outputs[:,:,0] - predicted_outputs) ** 2).sum() / ((true_outputs[:,:,0] - true_outputs[:,:,0].mean()) ** 2).sum())

        true_outputs = true_outputs*mean_std['y_R1'][1] + mean_std['y_R1'][0]
        predicted_outputs = predicted_outputs*mean_std['y_R1'][1] + mean_std['y_R1'][0]

        #np.abs(true_outputs_dict['exp2_dataset'][:,:,0] - pred_outputs_dict['exp2_dataset']).max()*1000

        # Calculate maximum deviation
        max_deviation = np.abs(true_outputs[:,:,0] - predicted_outputs).max()

        # Update dictionary with goodness of fit for the current experiment
        gof_dict[name] = goodness_of_fit
        max_dev_dict[name]  = max_deviation*1000
        true_outputs_dict[name] = true_outputs
        pred_outputs_dict[name] = predicted_outputs

        # Get the number of data points
        num_samples = len(true_outputs)

        # Create a time array (in seconds) considering the sampling rate (100 Hz)
        time_values = (np.arange(num_samples) / 100.0)  # Divide by the sampling rate to convert sample index to time

        # Calculate the error signal
        error_signal = true_outputs[:,:,0] - predicted_outputs

        # Create a figure with two subplots
        fig, axs = plt.subplots(2, figsize=(10, 12))

        # First subplot: True vs. Predicted Outputs
        axs[0].plot(time_values, 1000*true_outputs[:,:,0], label='True outputs')
        axs[0].plot(time_values, 1000*predicted_outputs, label='Predicted outputs')
        axs[0].plot(time_values, weights[:,:,0], label='Loss weights')
        axs[0].set_title(f'True vs Predicted Outputs for {name} (GoF = {goodness_of_fit:.2f}%, Max deviation = {max_deviation*1000:.2f} mm)')
        axs[0].set_xlabel('Time (s)')
        axs[0].set_ylabel('Output value (mm)')
        axs[0].legend()
        axs[0].set_ylim([-5, 5])

        # Second subplot: Error Signal
        axs[1].plot(time_values, 1000*error_signal, label='Error signal', color='r')
        axs[1].set_title('Error between True and Predicted Outputs')
        axs[1].set_xlabel('Time (s)')
        axs[1].set_ylabel('Error (mm)')
        axs[1].legend()
        axs[1].set_ylim([-5, 5])

        # Display the figure
        plt.tight_layout()

        # Save figure to a .pdf file
        plt.savefig(f"{validation_plots_folder}/{name}.png", bbox_inches='tight')

        # Show the plot
        #plt.show()


    # Saving the model to ONNX
    print("Saving the model to ONNX format for MATLAB use")
    # The 'dummy_input' should have the same dimensions as your input data e.g. (batch_size, channels, height, width) for images.
    dummy_input = torch.randn(1, input_size)

    # Export the model
    torch.onnx.export(model.to('cpu'),                  # model being run
                      dummy_input,                      # model input (or a tuple for multiple inputs)
                      os.path.join(model_folder, "model.onnx"),  # where to save the model (can be a file or file-like object)
                      export_params=True,               # store the trained parameter weights inside the model file
                      opset_version=14,                 # the ONNX version to export the model to
                      do_constant_folding=True)         # whether to execute constant folding for optimization

    return gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict



    
def train_FCN_R1_R4_small(dfs, inputs_list, window_lens, base_folder, train_exps, val_exps, mean_std, all_exps, 
                          hidden_size_fact, num_layers, early_stopping_epochs, learning_rate, p_dropout, added_weight, downsamp, add_noise=False, noise_std=0):

    # Create folder to store models
    #print(inputs_list)
    print("Downsampling Factor = ", downsamp)
    print("Add Noise = ", add_noise)
    print("List of All  experiments = ", all_exps)
    print("List of train  experiments = ", train_exps)
    print("List of validation  experiments = ", val_exps)
    inputs_str = "_".join(inputs_list)
    windows_str = "_".join(map(str, window_lens))
    
    #model_folder = f"{base_folder}/inputs_{inputs_str}_window_{windows_str}_hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}"
    model_folder = f"{base_folder}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noise_std_{noise_std}"
    
    if not os.path.exists(base_folder):
        os.makedirs(base_folder)    
    if not os.path.exists(model_folder):
        os.makedirs(model_folder)


    # Create subfolder for validation plots
    validation_plots_folder = f"{model_folder}/validation_plots"
    if not os.path.exists(validation_plots_folder):
        os.makedirs(validation_plots_folder)
        print("Validation folder Created!")

    # Define Experiment wise Datasets
    print("Creating Datasets")

    # Create the individual experiment datasets for the training set
    train_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'], added_weight=added_weight, downsamp=downsamp) for exp_name in train_exps]

    # Create the individual experiment datasets for the validation set
    valid_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'], downsamp=downsamp) for exp_name in val_exps]

    # Concatenate the individual datasets into the train and valid datasets
    train_dataset = ConcatDataset(train_datasets)
    valid_dataset = ConcatDataset(valid_datasets)

    print("Datasets created!")
    print("Starting Training")
    # Begin Training!
    # Device configuration
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Model hyperparameters
    input_size = train_dataset[0][0].shape[0]
    #hidden_size = (input_size//2)
    #hidden_size = 2*input_size
    hidden_size = int(hidden_size_fact*input_size)
    output_size = 1
    num_epochs = 100
    batch_size = 64
    # learning_rate = 0.001
    # early_stopping_epochs = 5

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    print(model)
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # Data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(valid_dataset, batch_size=len(valid_dataset), shuffle=False)

    # Store losses for plot
    train_losses = []
    val_losses = []

    # Best validation loss
    best_val_loss = np.inf

    # Counter for early stopping
    early_stopping_counter = 0

    # Training loop
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        for inputs, targets, weights in tqdm(train_loader):
            inputs, targets, weights = inputs.to(device), targets.to(device), weights.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            #loss = criterion(outputs, targets[:,:,0])
            
            #Add weighted loss
            loss = torch.nn.functional.mse_loss(outputs, targets[:,:,0], reduction='none')
            loss = (loss * weights).mean()
            
            loss.backward()
            optimizer.step()
            train_loss += loss.item()

        train_losses.append(train_loss / len(train_loader))

        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, targets, _ in val_loader:
                inputs, targets = inputs.to(device), targets.to(device)
                outputs = model(inputs)
                loss = criterion(outputs, targets[:,:,0])
                val_loss += loss.item()

        val_losses.append(val_loss / len(val_loader))
        print(f'Epoch {epoch+1}, Train Loss: {train_loss / len(train_loader)}, Validation Loss: {val_loss / len(val_loader)}')

        # Plot losses and predictions every 10 epochs
        if (epoch+1) % 5 == 0:
            plt.figure()
            plt.plot(range(epoch+1)[2:], train_losses[2:], label='Train Loss')
            plt.plot(range(epoch+1)[2:], val_losses[2:], label='Validation Loss')
            plt.legend()
            plt.xlabel('Epochs')
            plt.ylabel('Loss')
            plt.title('Train and Validation Loss')

            plt.savefig(f"{validation_plots_folder}/trainval.png", bbox_inches='tight')
            #plt.show()

            plt.figure()
            model.eval()
            with torch.no_grad():
                val_preds = model(next(iter(val_loader))[0].to(device)).cpu().numpy()
            plt.plot(val_preds, label='Predicted')
            plt.plot(next(iter(val_loader))[1].numpy()[:,:,0], label='Actual')
            plt.legend()
            plt.xlabel('Samples')
            plt.ylabel('Value')
            plt.title('Model Predictions vs Actuals')
            plt.savefig(f"{validation_plots_folder}/val_perf.png", bbox_inches='tight')
            #plt.show()

        # Check for early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            early_stopping_counter = 0
            torch.save(model.state_dict(), f'{model_folder}/model.pth')
        else:
            early_stopping_counter += 1
            if early_stopping_counter >= early_stopping_epochs:
                print("Early stopping, no improvement for " + str(early_stopping_epochs) + " epochs.")
                break
      # Save results and hyperparameters
    results = {
        "train_losses": train_losses,
        "val_losses": val_losses,
        "best_val_loss": best_val_loss,
        "hyperparameters": {
            "input_size": input_size,
            "hidden_size": hidden_size,
            "output_size": output_size,
            "num_epochs": num_epochs,
            "batch_size": batch_size,
            "learning_rate": learning_rate,
            "early_stopping_epochs": early_stopping_epochs,
            "p_dropout": p_dropout,
        }
    }

    # Save dictionary to JSON file
    with open(f'{model_folder}/train_info.json', 'w') as f:
        json.dump(results, f)

    print("Training Complete.")

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    model.load_state_dict(torch.load(f'{model_folder}/model.pth'))
    model.eval()
    print("Model Loaded")

    print("Starting Validation Plots")

    # Create a dictionary of datasets
    datasets = {f"exp{index + 1}_dataset": NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'],added_weight=added_weight,  downsamp=downsamp) 
                for index, exp_name in enumerate(all_exps)}    

    gof_dict = {}
    max_dev_dict = {}
    true_outputs_dict = {}
    pred_outputs_dict = {}

    # Loop through each dataset
    for name, dataset in datasets.items():

        # Pass the dataset through the model to get predictions
        inputs, true_outputs, weights = zip(*[dataset[i] for i in range(len(dataset))])
        inputs = torch.stack(inputs).to(device)
        true_outputs = torch.stack(true_outputs).to(device)
        weights = torch.stack(weights).to(device)

        with torch.no_grad():
            predicted_outputs = model(inputs)

        # Move data to cpu and convert to numpy for plotting. an scale up
        true_outputs = true_outputs.cpu().numpy()
        predicted_outputs = predicted_outputs.cpu().numpy()
        weights = weights.cpu().numpy()
        # Calculate percentage goodness of fit
        goodness_of_fit = 100 * (1 - ((true_outputs[:,:,0] - predicted_outputs) ** 2).sum() / ((true_outputs[:,:,0] - true_outputs[:,:,0].mean()) ** 2).sum())

        true_outputs = true_outputs*mean_std['y_R4'][1] + mean_std['y_R4'][0]
        predicted_outputs = predicted_outputs*mean_std['y_R4'][1] + mean_std['y_R4'][0]

        #np.abs(true_outputs_dict['exp2_dataset'][:,:,0] - pred_outputs_dict['exp2_dataset']).max()*1000

        # Calculate maximum deviation
        max_deviation = np.abs(true_outputs[:,:,0] - predicted_outputs).max()

        # Update dictionary with goodness of fit for the current experiment
        gof_dict[name] = goodness_of_fit
        max_dev_dict[name]  = max_deviation*1000
        true_outputs_dict[name] = true_outputs
        pred_outputs_dict[name] = predicted_outputs

        # Get the number of data points
        num_samples = len(true_outputs)

        # Create a time array (in seconds) considering the sampling rate (100 Hz)
        time_values = (np.arange(num_samples) / 100.0)  # Divide by the sampling rate to convert sample index to time

        # Calculate the error signal
        error_signal = true_outputs[:,:,0] - predicted_outputs

        # Create a figure with two subplots
        fig, axs = plt.subplots(2, figsize=(10, 12))

        # First subplot: True vs. Predicted Outputs
        axs[0].plot(time_values, 1000*true_outputs[:,:,0], label='True outputs')
        axs[0].plot(time_values, 1000*predicted_outputs, label='Predicted outputs')
        axs[0].plot(time_values, weights[:,:,0], label='Loss weights')
        axs[0].set_title(f'True vs Predicted Outputs for {name} (GoF = {goodness_of_fit:.2f}%, Max deviation = {max_deviation*1000:.2f} mm)')
        axs[0].set_xlabel('Time (s)')
        axs[0].set_ylabel('Output value (mm)')
        axs[0].legend()

        # Second subplot: Error Signal
        axs[1].plot(time_values, 1000*error_signal, label='Error signal', color='r')
        axs[1].set_title('Error between True and Predicted Outputs')
        axs[1].set_xlabel('Time (s)')
        axs[1].set_ylabel('Error (mm)')
        axs[1].legend()

        # Display the figure
        plt.tight_layout()

        # Save figure to a .pdf file
        plt.savefig(f"{validation_plots_folder}/{name}.png", bbox_inches='tight')

        # Show the plot
        #plt.show()


    # Saving the model to ONNX
    print("Saving the model to ONNX format for MATLAB use")
    # The 'dummy_input' should have the same dimensions as your input data e.g. (batch_size, channels, height, width) for images.
    dummy_input = torch.randn(1, input_size)

    # Export the model
    torch.onnx.export(model.to('cpu'),                  # model being run
                      dummy_input,                      # model input (or a tuple for multiple inputs)
                      os.path.join(model_folder, "model.onnx"),  # where to save the model (can be a file or file-like object)
                      export_params=True,               # store the trained parameter weights inside the model file
                      opset_version=14,                 # the ONNX version to export the model to
                      do_constant_folding=True)         # whether to execute constant folding for optimization

    return gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict



def train_pretrained_FCN_R0_R1_small(dfs, inputs_list, window_lens, base_folder, train_exps, val_exps, mean_std, all_exps, hidden_size_fact = 0.5, num_layers = 1, 
                                     early_stopping_epochs=10, learning_rate=0.001, p_dropout=0.7, added_weight=1, downsamp=1, add_noise=False, noise_std=0, model_pretrain=None):

    # Create folder to store models
    #print(inputs_list)
    print("Downsampling Factor = ", downsamp)
    print("Add Noise = ", add_noise)
    print("List of All  experiments = ", all_exps)
    print("List of train  experiments = ", train_exps)
    print("List of validation  experiments = ", val_exps)

    
    inputs_str = "_".join(inputs_list)
    windows_str = "_".join(map(str, window_lens))
   
    model_folder = f"{base_folder}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noise_std_{noise_std}"
    
    if not os.path.exists(base_folder):
        os.makedirs(base_folder)    
    if not os.path.exists(model_folder):
        os.makedirs(model_folder)


    # Create subfolder for validation plots
    validation_plots_folder = f"{model_folder}/validation_plots"
    if not os.path.exists(validation_plots_folder):
        os.makedirs(validation_plots_folder)
        print("Validation folder Created!")

    # Define Experiment wise Datasets
    print("Creating Datasets")

    # Create the individual experiment datasets for the training set
    train_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'], added_weight=added_weight, downsamp=downsamp) for exp_name in train_exps]

    # Create the individual experiment datasets for the validation set
    valid_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'], downsamp=downsamp) for exp_name in val_exps]

    # Concatenate the individual datasets into the train and valid datasets
    train_dataset = ConcatDataset(train_datasets)
    valid_dataset = ConcatDataset(valid_datasets)

    print("Datasets created!")
    print("Starting Training")
    # Begin Training!
    # Device configuration
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Model hyperparameters
    input_size = train_dataset[0][0].shape[0]
    hidden_size = int(hidden_size_fact*input_size)
    output_size = 1
    num_epochs = 100
    batch_size = 64

    # Initialize model, criterion, and optimizer
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    # model.load_state_dict(torch.load(f'{model_folder}/model.pth'))
    model.load_state_dict(torch.load(model_pretrain, map_location=device))
    model.train()
    print("Pretrained Model Loaded")
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # Data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(valid_dataset, batch_size=len(valid_dataset), shuffle=False)

    # Store losses for plot
    train_losses = []
    val_losses = []

    # Best validation loss
    best_val_loss = np.inf

    # Counter for early stopping
    early_stopping_counter = 0

    # Training loop
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        for inputs, targets, weights in tqdm(train_loader):
            inputs, targets, weights = inputs.to(device), targets.to(device), weights.to(device)

            if (add_noise==True):
                # Add Gaussian noise to the targets
                noise = (torch.randn_like(targets))*noise_std       
                targets = targets + noise
            
            optimizer.zero_grad()
            outputs = model(inputs)
            #loss = criterion(outputs, targets[:,:,0])
            
            #Add weighted loss
            loss = torch.nn.functional.mse_loss(outputs, targets[:,:,0], reduction='none')
            loss = (loss * weights).mean()
            
            loss.backward()
            optimizer.step()
            train_loss += loss.item()

        train_losses.append(train_loss / len(train_loader))

        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, targets, _ in val_loader:
                
                inputs, targets = inputs.to(device), targets.to(device)
                
                if (add_noise==True):
                    # Add Gaussian noise to the targets
                    noise = (torch.randn_like(targets))*noise_std           
                    targets = targets + noise                
                
                outputs = model(inputs)
                loss = criterion(outputs, targets[:,:,0])
                val_loss += loss.item()

        val_losses.append(val_loss / len(val_loader))
        print(f'Epoch {epoch+1}, Train Loss: {train_loss / len(train_loader)}, Validation Loss: {val_loss / len(val_loader)}')

        # Plot losses and predictions every 10 epochs
        if (epoch+1) % 5 == 0:
            plt.figure()
            plt.plot(range(epoch+1)[2:], train_losses[2:], label='Train Loss')
            plt.plot(range(epoch+1)[2:], val_losses[2:], label='Validation Loss')
            plt.legend()
            plt.xlabel('Epochs')
            plt.ylabel('Loss')
            plt.title('Train and Validation Loss')

            plt.savefig(f"{validation_plots_folder}/trainval.png", bbox_inches='tight')
            #plt.show()

            plt.figure()
            model.eval()
            with torch.no_grad():
                val_preds = model(next(iter(val_loader))[0].to(device)).cpu().numpy()
            plt.plot(val_preds, label='Predicted')
            plt.plot(next(iter(val_loader))[1].numpy()[:,:,0], label='Actual')
            plt.legend()
            plt.xlabel('Samples')
            plt.ylabel('Value')
            plt.title('Model Predictions vs Actuals')
            plt.savefig(f"{validation_plots_folder}/val_perf.png", bbox_inches='tight')
            #plt.show()

        # Check for early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            early_stopping_counter = 0
            torch.save(model.state_dict(), f'{model_folder}/model.pth')
        else:
            early_stopping_counter += 1
            if early_stopping_counter >= early_stopping_epochs:
                print("Early stopping, no improvement for " + str(early_stopping_epochs) + " epochs.")
                break
      # Save results and hyperparameters
    results = {
        "train_losses": train_losses,
        "val_losses": val_losses,
        "best_val_loss": best_val_loss,
        "hyperparameters": {
            "input_size": input_size,
            "hidden_size": hidden_size,
            "output_size": output_size,
            "num_epochs": num_epochs,
            "batch_size": batch_size,
            "learning_rate": learning_rate,
            "early_stopping_epochs": early_stopping_epochs,
            "p_dropout": p_dropout,
        }
    }

    # Save dictionary to JSON file
    with open(f'{model_folder}/train_info.json', 'w') as f:
        json.dump(results, f)

    print("Training Complete.")

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    model.load_state_dict(torch.load(f'{model_folder}/model.pth'))
    model.eval()
    print("Model Loaded")

    print("Starting Validation Plots")

    # Create a dictionary of datasets
    datasets = {f"exp{index + 1}_dataset": NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R1'],added_weight=added_weight,  downsamp=downsamp) 
                for index, exp_name in enumerate(all_exps)}    

    gof_dict = {}
    max_dev_dict = {}
    true_outputs_dict = {}
    pred_outputs_dict = {}

    # Loop through each dataset
    for name, dataset in datasets.items():

        # Pass the dataset through the model to get predictions
        inputs, true_outputs, weights = zip(*[dataset[i] for i in range(len(dataset))])
        inputs = torch.stack(inputs).to(device)
        true_outputs = torch.stack(true_outputs).to(device)
        weights = torch.stack(weights).to(device)

        with torch.no_grad():
            predicted_outputs = model(inputs)

        # Move data to cpu and convert to numpy for plotting. an scale up
        true_outputs = true_outputs.cpu().numpy()
        predicted_outputs = predicted_outputs.cpu().numpy()
        weights = weights.cpu().numpy()
        # Calculate percentage goodness of fit
        goodness_of_fit = 100 * (1 - ((true_outputs[:,:,0] - predicted_outputs) ** 2).sum() / ((true_outputs[:,:,0] - true_outputs[:,:,0].mean()) ** 2).sum())

        true_outputs = true_outputs*mean_std['y_R1'][1] + mean_std['y_R1'][0]
        predicted_outputs = predicted_outputs*mean_std['y_R1'][1] + mean_std['y_R1'][0]

        #np.abs(true_outputs_dict['exp2_dataset'][:,:,0] - pred_outputs_dict['exp2_dataset']).max()*1000

        # Calculate maximum deviation
        max_deviation = np.abs(true_outputs[:,:,0] - predicted_outputs).max()

        # Update dictionary with goodness of fit for the current experiment
        gof_dict[name] = goodness_of_fit
        max_dev_dict[name]  = max_deviation*1000
        true_outputs_dict[name] = true_outputs
        pred_outputs_dict[name] = predicted_outputs

        # Get the number of data points
        num_samples = len(true_outputs)

        # Create a time array (in seconds) considering the sampling rate (100 Hz)
        time_values = (np.arange(num_samples) / 100.0)  # Divide by the sampling rate to convert sample index to time

        # Calculate the error signal
        error_signal = true_outputs[:,:,0] - predicted_outputs

        # Create a figure with two subplots
        fig, axs = plt.subplots(2, figsize=(10, 12))

        # First subplot: True vs. Predicted Outputs
        axs[0].plot(time_values, 1000*true_outputs[:,:,0], label='True outputs')
        axs[0].plot(time_values, 1000*predicted_outputs, label='Predicted outputs')
        axs[0].plot(time_values, weights[:,:,0], label='Loss weights')
        axs[0].set_title(f'True vs Predicted Outputs for {name} (GoF = {goodness_of_fit:.2f}%, Max deviation = {max_deviation*1000:.2f} mm)')
        axs[0].set_xlabel('Time (s)')
        axs[0].set_ylabel('Output value (mm)')
        axs[0].legend()
        axs[0].set_ylim([-5, 5])

        # Second subplot: Error Signal
        axs[1].plot(time_values, 1000*error_signal, label='Error signal', color='r')
        axs[1].set_title('Error between True and Predicted Outputs')
        axs[1].set_xlabel('Time (s)')
        axs[1].set_ylabel('Error (mm)')
        axs[1].legend()
        axs[1].set_ylim([-5, 5])

        # Display the figure
        plt.tight_layout()

        # Save figure to a .pdf file
        plt.savefig(f"{validation_plots_folder}/{name}.png", bbox_inches='tight')

        # Show the plot
        #plt.show()


    # Saving the model to ONNX
    print("Saving the model to ONNX format for MATLAB use")
    # The 'dummy_input' should have the same dimensions as your input data e.g. (batch_size, channels, height, width) for images.
    dummy_input = torch.randn(1, input_size)

    # Export the model
    torch.onnx.export(model.to('cpu'),                  # model being run
                      dummy_input,                      # model input (or a tuple for multiple inputs)
                      os.path.join(model_folder, "model.onnx"),  # where to save the model (can be a file or file-like object)
                      export_params=True,               # store the trained parameter weights inside the model file
                      opset_version=14,                 # the ONNX version to export the model to
                      do_constant_folding=True)         # whether to execute constant folding for optimization

    return gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict

def train_pretrained_FCN_R1_R4_small(dfs, inputs_list, window_lens, base_folder, train_exps, val_exps, mean_std, all_exps, 
                          hidden_size_fact, num_layers, early_stopping_epochs, learning_rate, p_dropout, added_weight, downsamp, add_noise=False, noise_std=0, model_pretrain=None):

    # Create folder to store models
    #print(inputs_list)
    print("Downsampling Factor = ", downsamp)
    print("Add Noise = ", add_noise)
    print("List of All  experiments = ", all_exps)
    print("List of train  experiments = ", train_exps)
    print("List of validation  experiments = ", val_exps)
    inputs_str = "_".join(inputs_list)
    windows_str = "_".join(map(str, window_lens))
    
    #model_folder = f"{base_folder}/inputs_{inputs_str}_window_{windows_str}_hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}"
    model_folder = f"{base_folder}/hiddensize_{hidden_size_fact}_depth_{num_layers}_dropout_{p_dropout}_downsamp_{downsamp}_addedweight_{added_weight}_noise_std_{noise_std}"
    
    if not os.path.exists(base_folder):
        os.makedirs(base_folder)    
    if not os.path.exists(model_folder):
        os.makedirs(model_folder)


    # Create subfolder for validation plots
    validation_plots_folder = f"{model_folder}/validation_plots"
    if not os.path.exists(validation_plots_folder):
        os.makedirs(validation_plots_folder)
        print("Validation folder Created!")

    # Define Experiment wise Datasets
    print("Creating Datasets")

    # Create the individual experiment datasets for the training set
    train_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'], added_weight=added_weight, downsamp=downsamp) for exp_name in train_exps]

    # Create the individual experiment datasets for the validation set
    valid_datasets = [NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'], downsamp=downsamp) for exp_name in val_exps]

    # Concatenate the individual datasets into the train and valid datasets
    train_dataset = ConcatDataset(train_datasets)
    valid_dataset = ConcatDataset(valid_datasets)

    print("Datasets created!")
    print("Starting Training")
    # Begin Training!
    # Device configuration
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Model hyperparameters
    input_size = train_dataset[0][0].shape[0]
    #hidden_size = (input_size//2)
    #hidden_size = 2*input_size
    hidden_size = int(hidden_size_fact*input_size)
    output_size = 1
    num_epochs = 100
    batch_size = 64
    # learning_rate = 0.001
    # early_stopping_epochs = 5

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    # model.load_state_dict(torch.load(f'/home/sagotech/Documents/Tetra-Pak/training_exps/R1_R4_Model03/hiddensize_2_depth_2_dropout_0.5_downsamp_5_addedweight_5_noise_std_0/model.pth'))
    model.load_state_dict(torch.load(model_pretrain, map_location=device))
    model.train()
    print("Pretrained Model Loaded")
    print(model)
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # Data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(valid_dataset, batch_size=len(valid_dataset), shuffle=False)

    # Store losses for plot
    train_losses = []
    val_losses = []

    # Best validation loss
    best_val_loss = np.inf

    # Counter for early stopping
    early_stopping_counter = 0

    # Training loop
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        for inputs, targets, weights in tqdm(train_loader):
            inputs, targets, weights = inputs.to(device), targets.to(device), weights.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            #loss = criterion(outputs, targets[:,:,0])
            
            #Add weighted loss
            loss = torch.nn.functional.mse_loss(outputs, targets[:,:,0], reduction='none')
            loss = (loss * weights).mean()
            
            loss.backward()
            optimizer.step()
            train_loss += loss.item()

        train_losses.append(train_loss / len(train_loader))

        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, targets, _ in val_loader:
                inputs, targets = inputs.to(device), targets.to(device)
                outputs = model(inputs)
                loss = criterion(outputs, targets[:,:,0])
                val_loss += loss.item()

        val_losses.append(val_loss / len(val_loader))
        print(f'Epoch {epoch+1}, Train Loss: {train_loss / len(train_loader)}, Validation Loss: {val_loss / len(val_loader)}')

        # Plot losses and predictions every 10 epochs
        if (epoch+1) % 5 == 0:
            plt.figure()
            plt.plot(range(epoch+1)[2:], train_losses[2:], label='Train Loss')
            plt.plot(range(epoch+1)[2:], val_losses[2:], label='Validation Loss')
            plt.legend()
            plt.xlabel('Epochs')
            plt.ylabel('Loss')
            plt.title('Train and Validation Loss')

            plt.savefig(f"{validation_plots_folder}/trainval.png", bbox_inches='tight')
            #plt.show()

            plt.figure()
            model.eval()
            with torch.no_grad():
                val_preds = model(next(iter(val_loader))[0].to(device)).cpu().numpy()
            plt.plot(val_preds, label='Predicted')
            plt.plot(next(iter(val_loader))[1].numpy()[:,:,0], label='Actual')
            plt.legend()
            plt.xlabel('Samples')
            plt.ylabel('Value')
            plt.title('Model Predictions vs Actuals')
            plt.savefig(f"{validation_plots_folder}/val_perf.png", bbox_inches='tight')
            #plt.show()

        # Check for early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            early_stopping_counter = 0
            torch.save(model.state_dict(), f'{model_folder}/model.pth')
        else:
            early_stopping_counter += 1
            if early_stopping_counter >= early_stopping_epochs:
                print("Early stopping, no improvement for " + str(early_stopping_epochs) + " epochs.")
                break
      # Save results and hyperparameters
    results = {
        "train_losses": train_losses,
        "val_losses": val_losses,
        "best_val_loss": best_val_loss,
        "hyperparameters": {
            "input_size": input_size,
            "hidden_size": hidden_size,
            "output_size": output_size,
            "num_epochs": num_epochs,
            "batch_size": batch_size,
            "learning_rate": learning_rate,
            "early_stopping_epochs": early_stopping_epochs,
            "p_dropout": p_dropout,
        }
    }

    # Save dictionary to JSON file
    with open(f'{model_folder}/train_info.json', 'w') as f:
        json.dump(results, f)

    print("Training Complete.")

    # Initialize model, criterion, and optimizer
    #model = FullyConnectedNetwork_small(input_size, hidden_size, output_size, p_dropout).to(device)
    model = FullyConnectedNetwork_varDepth(input_size, hidden_size, output_size, num_layers, p_dropout).to(device)
    model.load_state_dict(torch.load(f'{model_folder}/model.pth'))
    model.eval()
    print("Model Loaded")

    print("Starting Validation Plots")

    # Create a dictionary of datasets
    datasets = {f"exp{index + 1}_dataset": NARX_Dataset(df=dfs[exp_name], input_cols=inputs_list, window_lens=window_lens, output_cols=['y_R4'],added_weight=added_weight,  downsamp=downsamp) 
                for index, exp_name in enumerate(all_exps)}    

    gof_dict = {}
    max_dev_dict = {}
    true_outputs_dict = {}
    pred_outputs_dict = {}

    # Loop through each dataset
    for name, dataset in datasets.items():

        # Pass the dataset through the model to get predictions
        inputs, true_outputs, weights = zip(*[dataset[i] for i in range(len(dataset))])
        inputs = torch.stack(inputs).to(device)
        true_outputs = torch.stack(true_outputs).to(device)
        weights = torch.stack(weights).to(device)

        with torch.no_grad():
            predicted_outputs = model(inputs)

        # Move data to cpu and convert to numpy for plotting. an scale up
        true_outputs = true_outputs.cpu().numpy()
        predicted_outputs = predicted_outputs.cpu().numpy()
        weights = weights.cpu().numpy()
        # Calculate percentage goodness of fit
        goodness_of_fit = 100 * (1 - ((true_outputs[:,:,0] - predicted_outputs) ** 2).sum() / ((true_outputs[:,:,0] - true_outputs[:,:,0].mean()) ** 2).sum())

        true_outputs = true_outputs*mean_std['y_R4'][1] + mean_std['y_R4'][0]
        predicted_outputs = predicted_outputs*mean_std['y_R4'][1] + mean_std['y_R4'][0]

        #np.abs(true_outputs_dict['exp2_dataset'][:,:,0] - pred_outputs_dict['exp2_dataset']).max()*1000

        # Calculate maximum deviation
        max_deviation = np.abs(true_outputs[:,:,0] - predicted_outputs).max()

        # Update dictionary with goodness of fit for the current experiment
        gof_dict[name] = goodness_of_fit
        max_dev_dict[name]  = max_deviation*1000
        true_outputs_dict[name] = true_outputs
        pred_outputs_dict[name] = predicted_outputs

        # Get the number of data points
        num_samples = len(true_outputs)

        # Create a time array (in seconds) considering the sampling rate (100 Hz)
        time_values = (np.arange(num_samples) / 100.0)  # Divide by the sampling rate to convert sample index to time

        # Calculate the error signal
        error_signal = true_outputs[:,:,0] - predicted_outputs

        # Create a figure with two subplots
        fig, axs = plt.subplots(2, figsize=(10, 12))

        # First subplot: True vs. Predicted Outputs
        axs[0].plot(time_values, 1000*true_outputs[:,:,0], label='True outputs')
        axs[0].plot(time_values, 1000*predicted_outputs, label='Predicted outputs')
        axs[0].plot(time_values, weights[:,:,0], label='Loss weights')
        axs[0].set_title(f'True vs Predicted Outputs for {name} (GoF = {goodness_of_fit:.2f}%, Max deviation = {max_deviation*1000:.2f} mm)')
        axs[0].set_xlabel('Time (s)')
        axs[0].set_ylabel('Output value (mm)')
        axs[0].legend()

        # Second subplot: Error Signal
        axs[1].plot(time_values, 1000*error_signal, label='Error signal', color='r')
        axs[1].set_title('Error between True and Predicted Outputs')
        axs[1].set_xlabel('Time (s)')
        axs[1].set_ylabel('Error (mm)')
        axs[1].legend()

        # Display the figure
        plt.tight_layout()

        # Save figure to a .pdf file
        plt.savefig(f"{validation_plots_folder}/{name}.png", bbox_inches='tight')

        # Show the plot
        #plt.show()


    # Saving the model to ONNX
    print("Saving the model to ONNX format for MATLAB use")
    # The 'dummy_input' should have the same dimensions as your input data e.g. (batch_size, channels, height, width) for images.
    dummy_input = torch.randn(1, input_size)

    # Export the model
    torch.onnx.export(model.to('cpu'),                  # model being run
                      dummy_input,                      # model input (or a tuple for multiple inputs)
                      os.path.join(model_folder, "model.onnx"),  # where to save the model (can be a file or file-like object)
                      export_params=True,               # store the trained parameter weights inside the model file
                      opset_version=14,                 # the ONNX version to export the model to
                      do_constant_folding=True)         # whether to execute constant folding for optimization

    return gof_dict, max_dev_dict, true_outputs_dict, pred_outputs_dict