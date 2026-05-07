%% ===== LOAD ONNX MODEL =====
onnxPath = 'models/R0_R1_Model_Best/pretrain/hiddensize_2_depth_2_dropout_0.5_downsamp_5_addedweight_5_noise_std_0/model.onnx';
try
    importNet = importNetworkFromONNX(onnxPath);
catch ME
    error('ONNX import failed: %s\nEnsure Deep Learning Toolbox and VC++ Redistributable are installed.', ME.message);
end

%% ===== NORMALIZATION CONSTANTS =====
% IMPORTANT: Replace these with the actual mean_std values from your
% Python training run. Check val_info.json or add a print(mean_std) in
% load_and_process_data to get the exact values.
%
% Column order matches inputs list in run_exps.py:
%   ['fEdgeDetectorValue', 'ActualPosition', 'AI_PMSSpeedBendingRoller', 'y_R1']
u_means = [0, 0, 0, 0];  % <-- REPLACE with real training means
u_stds  = [1, 1, 1, 1];  % <-- REPLACE with real training stds
y_mean  = 0;              % <-- REPLACE with real output mean
y_std   = 1;              % <-- REPLACE with real output std

%% ===== PYTHON CONFIG (must match run_exps.py exactly) =====
% window_lens = [1500, 1000, 100] in Python for 4 inputs.
% Column mapping:
%   col 1 (fEdgeDetectorValue)      -> win_lens(1) = 1500
%   col 2 (ActualPosition)          -> win_lens(2) = 1000
%   col 3 (AI_PMSSpeedBendingRoller)-> win_lens(3) = 100
%   col 4 (y_R1 feedback)           -> win_lens(4) = 1500
%
% NOTE: Python only defines 3 window lengths for 4 inputs. If your
% NARX_Dataset assigns the 4th input the same window as index 0, use
% 1500. If it causes an IndexError in Python, it only uses 3 inputs.
% Verify by checking NARX_Dataset.__getitem__ in networks.py.
win_lens = [1500, 1000, 100, 1500];
ds       = 5;   % downsample rate (matches 'downsamp=5' in run_exps.py)

%% ===== LOAD & PREPARE TEST DATA =====
% Pull experiment 1 from your NARX dataset object
exp_i  = getexp(test_data_narx, 1);
u_raw  = exp_i.InputData;   % [N x 3]: EdgeDetector, ActualPos, Speed
y_raw  = exp_i.OutputData;  % [N x 1]: true output (e.g. y_R0 or y_R1)

% Build y_R1 feedback column (one-step delayed output, open-loop)
% First sample has no history so repeat the initial value
y_feedback = [y_raw(1); y_raw(1:end-1)];  % [N x 1]

% Concatenate to form the full 4-column input matrix
% Column order must match the Python 'inputs' list exactly
U_total = [u_raw, y_feedback];  % [N x 4]

%% ===== STANDARDIZE INPUTS =====
U_scaled = (U_total - u_means) ./ u_stds;  % broadcast over rows

%% ===== INFERENCE LOOP =====
max_win      = max(win_lens);
N            = size(U_scaled, 1);
y_pred_scaled = zeros(N, 1);

for t = max_win + 1 : N

    input_vec = [];

    for col = 1 : 4
        % Python: win = U_scaled[t - win_lens[col] : t : ds, col]
        % i.e. indices from (t - win_len) up to (t-1), step ds
        % MATLAB is 1-indexed; equivalent slice:
        idx_start = t - win_lens(col);   % inclusive start (1-indexed)
        idx_end   = t - 1;               % inclusive end (last sample before t)
        win = U_scaled(idx_start : ds : idx_end, col);  % [win_len/ds x 1]
        input_vec = [input_vec; win];
    end

    % Feed to network — shape must be [Features x 1] (column vector)
    % importNetworkFromONNX returns a dlnetwork; use predict() with dlarray
    dl_input  = dlarray(single(input_vec), 'CB');  % 'C'=channel, 'B'=batch
    dl_out    = predict(importNet, dl_input);
    y_pred_scaled(t) = extractdata(dl_out);
end

%% ===== DE-STANDARDIZE OUTPUT =====
y_pred = (y_pred_scaled .* y_std) + y_mean;

%% ===== EVALUATE (aligned to valid prediction region) =====
y_true_eval = y_raw(max_win + 1 : end);
y_pred_eval = y_pred(max_win + 1 : end);

rmse = sqrt(mean((y_true_eval - y_pred_eval).^2));
r2   = 1 - sum((y_true_eval - y_pred_eval).^2) / ...
               sum((y_true_eval - mean(y_true_eval)).^2);

fprintf('=== R0-R1 ONNX Model Evaluation ===\n');
fprintf('  RMSE : %.4f mm\n', rmse);
fprintf('  R²   : %.4f\n',    r2);

%% ===== PLOT =====
t_axis = (max_win + 1 : N)';
figure;
plot(t_axis, y_true_eval, 'b-',  'LineWidth', 1.2, 'DisplayName', 'True');
hold on;
plot(t_axis, y_pred_eval, 'r--', 'LineWidth', 1.2, 'DisplayName', 'Predicted');
xlabel('Sample index');
ylabel('Output');
title(sprintf('R0-R1 ONNX Prediction  |  RMSE = %.4f  |  R² = %.4f', rmse, r2));
legend('Location', 'best');
grid on;