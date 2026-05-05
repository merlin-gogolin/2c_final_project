%% Read in experiments data + Physical model
close all; clear all; clc;

all_exps_data = load('data/all_exps_data.mat');
all_exps_data = all_exps_data.all_exps_data ; 

% Load Web model
TP_sys_disc_01 = load('mat_files/TP_flat_web_disc_tr_coeffs.mat'); % This is the model used to run the simulations

TP_sys_disc_01 = TP_sys_disc_01.TP_sys_disc ; 

%% Train - Test Split

% All data

cExperiments = {'1_2mm', '2_4mm', '3_Splices1', '4_Splices2', '5_Splices3', '6_fastSplices', '7_slowSplices','8_Step2mm',...
    '9_steps4mm', '10_FastSplices2', '11_SlowSplices2', '12_NormalFunctioning_Fast', '13_NormalFunctioning_Slow',...
    '14_notchtest', '15_Step2mm_fast', '16_Step4mm_fast', '17_step2mm_slow', '18_step4mm_slow', '19_splice_slow', '20_splice_fast',...
    '21_4mm_test2', '22_2mm_fast', '23_splice', '24_step_gain_1_75','25_step_gain_2_6', '26_splice_fast','27_4mm_fast', '28_4mm,',...
    '29_2mm_test2', '30_2mm'};

cExpNames = {'1\_2mm', '2\_4mm', '3\_Splices1', '4\_Splices2', '5\_Splices3', '6\_fastSplices', '7\_slowSplices','8\_Step2mm',...
    '9\_steps4mm', '10\_FastSplices2', '11\_SlowSplices2', '12\_NormalFunctioning\_Fast', '13\_NormalFunctioning\_Slow',...
    '14\_notchtest', '15_\Step2mm\_fast', '16\_Step4mm\_fast', '17\_step2mm_slow', '18\_step4mm_slow', '19\_splice\_slow',...
    '20\_splice_fast','21_\4mm_test2', '22\_2mm_fast', '23\_splice', '24\_step\_gain\_1\_75', '25\_step\_gain\_2\_6', '26\_splice\_fast',...
    '27\_4mm_fast', '28\_4mm,', '29\_2mm\_test2', '30\_2mm'};

dExperiments = str2double(extractBefore(cExperiments, '_'));


% Train data
cExpTrain = {'1_2mm', '2_4mm', '3_Splices1', '4_Splices2', '5_Splices3', '6_fastSplices', '7_slowSplices','8_Step2mm',...
    '9_steps4mm', '10_FastSplices2', '11_SlowSplices2', '12_NormalFunctioning_Fast', '13_NormalFunctioning_Slow',...
    '14_notchtest', '15_Step2mm_fast', '17_step2mm_slow', '18_step4mm_slow', '19_splice_slow', '20_splice_fast'};
dExpTrain = str2double(extractBefore(cExpTrain, '_'));

cExpTrain02 = { '22_2mm_fast','26_splice_fast','27_4mm_fast', '29_2mm_test2', '25_step_gain_2_6', '28_4mm,', '30_2mm'};
dExpTrain02 = str2double(extractBefore(cExpTrain02, '_'));


% Test data
cExpTest = {'21_4mm_test2','24_step_gain_1_75', '23_splice',};
dExpTest = str2double(extractBefore(cExpTest, '_'));

%% Plot data vs simulated model evolution

sampling_rate = 100;
time_step = 1/sampling_rate ;

% section options
dShowPlots = 0;
dSavePlots = 0;

for i = 1:numel(cExperiments)
    
    % Get the iddata object for the current experiment
    exp_data = getexp(all_exps_data, i);

    % Extract true roller position evolution
    Var_PMEdgePosn = exp_data.OutputData(:, 1);
    R4 = exp_data.OutputData(:, 2);
    R5 = exp_data.OutputData(:, 3);
    R7 = exp_data.OutputData(:, 4);
    
    % Extract inputs for lsim
    Y0_input = (exp_data.InputData(:, 1))*0.001;
    u1_input = (exp_data.InputData(:, 2))*0.001;
    
    time_vector = (0:time_step:(size(Var_PMEdgePosn, 1)-1) * time_step)';
    
    % Define the initial state of the simulation - SUch that it matches the
    % data
    x0 = zeros(14,1) ;
    x0(1) = 10*0.001 ; 
    x0(3) = 10*0.001 ; 
    x0(5) = 10*0.001 ; 
    x0(7) = 10*0.001 ;
    x0(9) = 10*0.001 ; 
    x0(11) = 10*0.001 ;
    x0(13) = 10*0.001 ; 
   

    % Simulate the system
    [a_, b_, sim_sys_opt] = lsim(TP_sys_disc_01, transpose([Y0_input u1_input]), time_vector);
    
    % Extract simulated R1, R4, R5, R7
    sim_R1 = 1000*sim_sys_opt(:, 1);
    sim_R4 = 1000*sim_sys_opt(:, 7);
    sim_R5 = 1000*sim_sys_opt(:, 9);
    sim_R7 = 1000*sim_sys_opt(:, 13);

    

    if dShowPlots
        % Create new figure
        fig = figure('Position', [100, 100, 1200, 400]);

        % Subplot for true roller position evolution
        subplot(1, 2, 1);
        plot(time_vector, Var_PMEdgePosn, 'b', time_vector, R4, 'g', time_vector, R5, 'r', time_vector, R7, 'k');
        title('True Roller Position Evolution');
        xlabel('Time (s)');
        ylabel('Position');
        legend('R1', 'R4', 'R5', 'R7');
        
        % Subplot for model simulated roller positions
        subplot(1, 2, 2);
        plot(time_vector, sim_R1, 'b', time_vector, sim_R4, 'g', time_vector, sim_R5, 'r', time_vector, sim_R7, 'k');
        title('Model Simulated Roller Positions');
        xlabel('Time (s)');
        ylabel('Position');
        legend('R1', 'R4', 'R5', 'R7');
    end

    if dSavePlots
        
        save_directory = 'plots/physical_model/side_by_side'; 
        if ~exist(save_directory, 'dir')
            mkdir(save_directory);
        end

        % Set figure size
        set(gcf, 'Units', 'Inches', 'Position', [0, 0, 12, 8], 'PaperUnits', 'Inches', 'PaperSize', [12, 8]);
        
        % Save the figure
        print(gcf, fullfile(save_directory, ['Side_by_Side_Experiment_', cExperiments{i}, '.png']), '-dpng', '-r300');
        savefig(gcf, fullfile(save_directory, ['Side_by_Side_Experiment_', cExperiments{i}, '.fig']));
    end
end


%% Full Physical Model plots for ALL experiments

Fs = 100; % Sampling frequency

% Directory to save plots
save_directory = 'plots/physical_model/roller_comparison'; 
if ~exist(save_directory, 'dir')
    mkdir(save_directory);
end

% section options
dShowPlots = 0;
dSavePlots = 0;

% Iterate through each experiment
for i = (dExperiments)
    
    % Get data for current experiment
    exp_data = getexp(all_exps_data, i);
    time_vector = (0:(length(exp_data.OutputData(:, 1))-1)) / Fs; % Time in seconds
    
    % Ground truth signals
    Var_PMEdgePosn = exp_data.OutputData(:, 1);
    R4 = exp_data.OutputData(:, 2);
    R5 = exp_data.OutputData(:, 3);
    R7 = exp_data.OutputData(:, 4);
    
    % Inputs for simulation
    Y0_input = exp_data.InputData(:, 1)*0.001;
    u1_input = exp_data.InputData(:, 2)*0.001;
    
    % Simulate the model
    [~, ~, sim_sys_opt] = lsim(TP_sys_disc_01, transpose([Y0_input u1_input]), time_vector);
    
    % Extract simulated R1, R4, R5, R7
    sim_R1 = 1000*sim_sys_opt(:, 1);
    sim_R4 = 1000*sim_sys_opt(:, 7);
    sim_R5 = 1000*sim_sys_opt(:, 9);
    sim_R7 = 1000*sim_sys_opt(:, 13);

    if dShowPlots

    % Create figure
        figure;
        subplot(2, 2, 1);
        plot(time_vector, Var_PMEdgePosn, 'b', time_vector, sim_R1, 'r');
        title('R1');
        xlabel('Time (s)');
        ylabel('Position');
        legend('Ground Truth', 'Simulated');
        text(0.5, 0.5, ['Goodness of Fit: ', num2str(goodnessOfFit(sim_R1, Var_PMEdgePosn, 'MSE')), '%'], 'Units', 'normalized');
        
        subplot(2, 2, 2);
        plot(time_vector, R4, 'b', time_vector, sim_R4, 'r');
        title('R4');
        xlabel('Time (s)');
        ylabel('Position');
        legend('Ground Truth', 'Simulated');
        text(0.5, 0.5, ['Goodness of Fit: ', num2str(goodnessOfFit(sim_R4, R4, 'MSE')), '%'], 'Units', 'normalized');
   
        subplot(2, 2, 3);
        plot(time_vector, R5, 'b', time_vector, sim_R5, 'r');
        title('R5');
        xlabel('Time (s)');
        ylabel('Position');
        legend('Ground Truth', 'Simulated');
        text(0.5, 0.5, ['Goodness of Fit: ', num2str(goodnessOfFit( sim_R5, R5, 'MSE') ), '%'], 'Units', 'normalized');
    
        subplot(2, 2, 4);
        plot(time_vector, R7, 'b', time_vector, sim_R7, 'r');
        title('R7');
        xlabel('Time (s)');
        ylabel('Position');
        legend('Ground Truth', 'Simulated');
        text(0.5, 0.5, ['Goodness of Fit: ', num2str(goodnessOfFit(sim_R7, R7, 'MSE') ), '%'], 'Units', 'normalized');
    end

    if dSavePlots
        % Set figure size
        set(gcf, 'Units', 'Inches', 'Position', [0, 0, 12, 8], 'PaperUnits', 'Inches', 'PaperSize', [12, 8]);
        
        % Save the figure
        print(gcf, fullfile(save_directory, ['Roller_Comparison_Experiment_', cExperiments{i}, '.png']), '-dpng', '-r300');
        savefig(gcf, fullfile(save_directory, ['Roller_Comparison_Experiment_', cExperiments{i}, '.fig']));
    end
end

%% Physical model setup

%===== All these parameter values are constant for all segments ===========
b_   = 0.166;        %Web width in meters
h_   = 0.20/1000;   %web thicness in meters
E_   = 3.5e9;       %Youngs modulus in GPa
mu_  = .45;         %Poisson module
T_ = 100 ; 
v_   = 1.125 ;
I_   = 1/2 * b_^3*h_; %Moment of inertia
A_   = b_*h_; %Cross-sectional area of web
G_  = E_/(2*(1+mu_)); %
kn_ = (12+11*mu_)/(10+10*mu_);  %kn

Kgam_ = ((T_/(E_*I_))/(1+(kn_*T_)/(A_*G_)))^(.5); % KGamma

L1   = sqrt(2.470^2 + (0.256)^2) + 0.3;       %Web length in meter of first segment
L2   = sqrt(0.133^2 + (0.027)^2) + sqrt(0.236^2 + (0.053)^2) ; % + 0.15;       %Web length in meter of second segment
L3   = sqrt(1.590^2 + (0.094)^2) ; % + 0.2 ;       %Web length in meter of third segment
L4   = 1.590 + 0.166  + 0.05 + 0.355 ; % + 0.2;       %Web length in meter of fourth segment
L5   = 0.486 + 0.005 ; % + 0.1;       %Web length in meter of fifth segment
L6   = 0.187 + 0.05;       %Web length in meter of sixth segment
L7   = 0.187 + 0.045 + 0.05;       %Web length in meter of seventh segment


c0 = 0.4 ; % Length of Roller 0  in meters taken from slides
c1 = 0.4 ; % Length of Roller 1  in meters taken from slides
c2 = 0.4   ; % Length of Roller 2  in meters taken from slides
c3 = 0.4 ; % Length of Roller 3  in meters taken from slides
c4 = 0.334 ; % Length of Roller 4  in meters taken from slides
c5 = 0.141   ; % Length of Roller 5  in meters taken from slides
c6 = 0.17   ; % Length of Roller 6  in meters taken from slides
c7 = 0.142   ; % Length of Roller 7  in meters taken from slides

tau1 = L1/v_ ; 
tau2 = L2/v_ ;
tau3 = L3/v_ ; 
tau4 = L4/v_ ;
tau5 = L5/v_ ; 
tau6 = L6/v_ ;
tau7 = L7/v_ ; 

% In this section define symbolic functions f1(KL), f2(KL), f3(KL)
% These functions appear in the transfer function for each section

syms KL real 

f1 = (((KL)^2)*(cosh(KL)-1)) / (KL*sinh(KL)+2*(1-cosh(KL)));
f2 = KL*((KL*(cosh(KL)))-sinh(KL)) / (KL*sinh(KL)+2*(1-cosh(KL)));
f3 = (KL * (sinh(KL)-KL)) / (KL*sinh(KL)+2*(1-cosh(KL)));

% Misc vars
s = tf([1 0], 1) ; 

%% Define physical Transfer function R4-R5
% For this span, there are a couple details 1) Set u2 = 0, u3 = 0

% Compute f1(KL5), f2(KL5), f3(KL5) for this segment

f1_L5 = double(vpa(subs(f1,  KL, Kgam_*L5))) ; 
f2_L5 = double(vpa(subs(f2,  KL, Kgam_*L5))) ;
f3_L5 = double(vpa(subs(f3,  KL, Kgam_*L5))) ;

% TF for Y5/Y4
numY5_Y4 = [-(f3_L5/tau5) f1_L5/(tau5^2)] ; % Want to use dy1/dt as input as well
denY5 = [1 (1/tau5)*f2_L5 (1/tau5^2)*f1_L5] ; 
TFY5_Y4 = tf(numY5_Y4, denY5); 

%TF5 = TFY5_Y4 ; 
TF5 = [TFY5_Y4 ; s*TFY5_Y4] ; 

%% Check  train and test data
% train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain)) ;
train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain)) ;

train_data_4_5_speed

% train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain02)) ;
train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain02)) ;

train_data_4_5_speed

% test_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTest)) 
test_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest)) ;

test_data_4_5_speed

%% Estimate Transfer function R4-R5

% directory
cPath = 'models/R4_R5/model_1_2/';

% section options
dLoadOrTrain = 0; % 0: Load; 1: Train
dSaveModels = 0;

if dLoadOrTrain
    % wo speed first data
    train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2  3], [], dExpTrain)) ;
    
    % wo speed first train
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1] ;
    np = [2] ; 
     

    TF4_5_est_wo_speed = tfest(train_data_4_5_wo_speed, np, nz, opt);


    % wo speed second data
    train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain02)) ;
    
    % wo speed second train
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    TF4_5_est_wo_speed = tfest(train_data_4_5_wo_speed, TF4_5_est_wo_speed, opt);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    % speed first data
    train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain)) ;

    % speed first train
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1 2] ; 
    np = [2 2] ; 
    

    TF4_5_est_speed = tfest(train_data_4_5_speed, np, nz, opt);


    % speed second data
    train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain02)) ;

    % speed second train
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    TF4_5_est_speed = tfest(train_data_4_5_speed, TF4_5_est_speed, opt);


    % Save figures
    if dSaveModels
        % Save models
        mkdir(cPath);
        save(append(cPath,'TF4_5_est_wo_speed.mat'), 'TF4_5_est_wo_speed');
        save(append(cPath,'TF4_5_est_speed.mat'), 'TF4_5_est_speed');
    end

else
    TF4_5_est_wo_speed = load(append(cPath,'TF4_5_est_wo_speed.mat'));
    TF4_5_est_wo_speed = TF4_5_est_wo_speed.TF4_5_est_wo_speed;

    TF4_5_est_speed = load(append(cPath,'TF4_5_est_speed.mat'));
    TF4_5_est_speed = TF4_5_est_speed.TF4_5_est_speed;
end

%% Plots for R4-R5

% directory
cPath = 'plots/R4_R5/model_1_2/';

% Section options
dSaveFigures = 0; 

% Load test data
test_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTest)) ;
test_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest)) ;

% Models
models = {'physical', 'estimated_nospeed', 'estimated_speed'};
sim_models = {TF5(1,:), TF4_5_est_wo_speed, TF4_5_est_speed};
exps_data_all = {test_data_4_5_wo_speed, test_data_4_5_wo_speed , test_data_4_5_speed};


% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(cPath, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    %Plot for each model
    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        % Initialize a figure for each experiment
        figure; 

        % Set figure size
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot the comparison for the current experiment
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        

        if dSaveFigures
            if j == 1 

            % Label the plot with the experiment name
            title(['R4\_R5 Experiment: ', cExpNames{k}, '_physical']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_physical' ,'.png']), 'Resolution', 300);
            % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'physical', '.fig']));

            elseif j == 2

            % Label the plot with the experiment name
            title(['R4\_R5 Experiment: ', cExpNames{k}, '_no_speed']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_no_speed' ,'.png']), 'Resolution', 300);
            % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'no_speed', '.fig']));

            elseif j== 3

            % Label the plot with the experiment name
            title(['R4\_R5 Experiment: ', cExpNames{k}, '_speed']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_speed' ,'.png']), 'Resolution', 300);
            % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'speed', '.fig']));

            else 
                print("Error")
            end
        end
    end
end


%% Define Transfer function R5-R7

% Define transfer function span 2 : R5 - R6
% For this span, there are a couple details 1) Set u5 = 0, u6 = 0

% Compute f1(KL6), f2(KL6), f3(KL6) for this segment

f1_L6 = double(vpa(subs(f1,  KL, Kgam_*L6))) ; 
f2_L6 = double(vpa(subs(f2,  KL, Kgam_*L6))) ;
f3_L6 = double(vpa(subs(f3,  KL, Kgam_*L6))) ;

% TF for Y6/Y5
numY6_Y5 = [-(f3_L6/tau6) f1_L6/(tau6^2)] ; % Want to use dy1/dt as input as well
denY6 = [1 (1/tau6)*f2_L6 (1/tau6^2)*f1_L6] ; 
TFY6_Y5 = tf(numY6_Y5, denY6); 

%TF6 = TFY6_Y5 ; 
TF6 = [TFY6_Y5 ; s*TFY6_Y5] ; 

% Define transfer function span 2 : R6- R7
% For this span, there are a couple details 1) Set u2 = 0, u3 = 0

% Compute f1(KL7), f2(KL7), f3(KL7) for this segment

f1_L7 = double(vpa(subs(f1,  KL, Kgam_*L7))) ; 
f2_L7 = double(vpa(subs(f2,  KL, Kgam_*L7))) ;
f3_L7 = double(vpa(subs(f3,  KL, Kgam_*L7))) ;

% TF for Y7/Y6
numY7_Y6 = [-(f3_L7/tau7) f1_L7/(tau7^2)] ; % Want to use dy1/dt as input as well
denY7 = [1 (1/tau7)*f2_L7 (1/tau7^2)*f1_L7] ; 
TFY7_Y6 = tf(numY7_Y6, denY7); 

%TF7 = TFY7_Y6 ; 
TF7 = [TFY7_Y6 ; s*TFY7_Y6] ; 

TF6.u = 'y_R5' ;
TF6.y = {'Y6';'dY6/dt'} ; 

TF7.u = 'Y6' ;
TF7.y = {'y_R7';'dY7/dt'} ; 

TF_67_temp = connect(TF6,TF7,{'y_R5'}, {'y_R7'}) ; 
TF_67 = minreal(ss(TF_67_temp)) ;

TF_67_tf = TF6(1)*TF7(1) ; 

TF_67_tf.u = 'y_R5' ;
TF_67_tf.y = 'y_R7' ;

%% Check train and test data
train_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain)) ;
train_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain)) ;

train_data_5_7_speed

train_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain02)) ;
train_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain02)) ;

train_data_5_7_speed

test_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTest)) ;
test_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTest)) ;

test_data_5_7_speed
%% Estimate Transfer function R5-R7

% directory
cPath = 'models/R5_R7/model_2_4/';

% section options
dLoadOrTrain = 1;
dSaveModels = 1;


if dLoadOrTrain
    % model wo speed
    % load first data
    train_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain)) ;
    
    % set options
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    % set poles and zeros
    nz = [2] ; 
    np = [4] ; 

    % estimate model wo speed
    TF5_7_est_wo_speed = tfest(train_data_5_7_wo_speed, np, nz, opt);


    % load second data
    train_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain02)) ;
    
    % set options
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    
    % set poles and zeros
    nz = [2] ; 
    np = [4] ; 

    % estimate model wo speed
    TF5_7_est_wo_speed = tfest(train_data_5_7_wo_speed, TF5_7_est_wo_speed, opt);

    % model with speed
    % load first data
    train_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain)) ;
    
    % estimate model w speed
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    
    % set poles and zero
    nz = [2 2] ;
    np = [4 2] ; 
     
    % estimate model w speed    
    TF5_7_est_speed = tfest(train_data_5_7_speed, np, nz, opt);

    % load second data
    train_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain02)) ;
    
    % estimate model w speed
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    
    % set poles and zero
    nz = [2 2] ;
    np = [4 2] ;  

    % estimate model w speed    
    TF5_7_est_speed = tfest(train_data_5_7_speed, TF5_7_est_speed, opt);

    
    if dSaveModels
        % save models
        mkdir(cPath);
        save(append(cPath,'TF5_7_est_wo_speed.mat'), 'TF5_7_est_wo_speed');
        save(append(cPath, 'TF5_7_est_speed.mat'), 'TF5_7_est_speed');
    end

else
    TF5_7_est_wo_speed = load(append(cPath,'TF5_7_est_wo_speed.mat'))
    TF5_7_est_wo_speed = TF5_7_est_wo_speed.TF5_7_est_wo_speed;

    TF5_7_est_speed = load(append(cPath,'TF5_7_est_speed.mat'));
    TF5_7_est_speed = TF5_7_est_speed.TF5_7_est_speed;
end

%% Plot plots for R5-R7

% directory
cPath = 'validation_plots/R5_R7/model_06/'

% section options
dSaveFigures = 0;

% Load test data
test_data_5_7_wo_speed = modify_iddata(all_exps_data(:,[3 4],[], dExpTest)) ;
test_data_5_7_speed = modify_iddata(all_exps_data(:,[3 4],[5], dExpTest)) ;

% Models
models = {'physical', 'estimated_nospeed', 'estimated_speed'};
sim_models = {TF_67_tf, TF5_7_est_wo_speed, TF5_7_est_speed};
exps_data_all = {test_data_5_7_wo_speed, test_data_5_7_wo_speed, test_data_5_7_speed};

% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(cPath, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    %Plot for each model
    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(dExpTest)
        k = dExpTest(i) ;
        % Initialize a figure for each experiment
        figure; 

        % Set figure size
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot the comparison for the current experiment
        compare(exps_data_all{j}(:,:,:,i), sim_model);

        % Label the plot with the experiment name
        title(['Experiment: ', cExpNames{k}]);


        if dSaveFigures
            if j == 1 

            % Label the plot with the experiment name
            title(['R5\_R7 Experiment: ', cExpNames{k}, '\_physical']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_physical' ,'.png']), 'Resolution', 300);

            elseif j == 2

            % Label the plot with the experiment name
            title(['R5\_R7 Experiment: ', cExpNames{k}, '\_no\_speed']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_no_speed' ,'.png']), 'Resolution', 300);

            elseif j== 3

            % Label the plot with the experiment name
            title(['R5\_R7 Experiment: ', cExpNames{k}, '\_speed']);
            % Save the figure as a PNG
            exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_speed' ,'.png']), 'Resolution', 300);

            else 
                print("Error")
            end
        end
    end
end


%% Functions
% modify_iddata(samples, outputs, inputs, experiments)
function new_data = modify_iddata(curr_data2)
    % Get number of experiments
    num_experiments = numel(curr_data2.ExperimentName);

    % Initialize new_inputs and new_outputs as cell arrays
    new_inputs = cell(num_experiments, 1);
    new_outputs = cell(num_experiments, 1);

    % Loop through each experiment
    for expIdx = 1:num_experiments
        % Extract inputs and outputs for current experiment
        all_inputs = curr_data2.InputData{expIdx};
        all_outputs = curr_data2.OutputData{expIdx};

        % Create new inputs and outputs for current experiment
        new_inputs{expIdx} = [all_outputs(:,1), all_inputs]; % Add the first output as a new input
        new_outputs{expIdx} = all_outputs(:,2:end); % Remove the first output
    end

    % Create a new iddata object with the modified inputs and outputs
    new_data = iddata(new_outputs, new_inputs, curr_data2.Ts);

    % Copy the experiment names from the original iddata object
    new_data.ExperimentName = curr_data2.ExperimentName;

    % Copy the input and output names from the original iddata object
    new_data.InputName = [curr_data2.OutputName(1) ; curr_data2.InputName]; 
    new_data.OutputName = curr_data2.OutputName(2:end);
end
