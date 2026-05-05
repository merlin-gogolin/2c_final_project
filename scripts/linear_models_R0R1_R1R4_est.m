%% Read in experiments data + Physical model
close all; clear all; clc;

all_exps_data = load('data/all_exps_data.mat');
all_exps_data = all_exps_data.all_exps_data ; 

% Load Web model
TP_sys_disc_01 = load('mat_files/TP_flat_web_disc_tr_coeffs.mat'); % This is the model used to run the simulations

TP_sys_disc_01 = TP_sys_disc_01.TP_sys_disc ; 

%% Update iddata object

% Rename an experiment '28_4mm,'
all_exps_data.ExperimentName{strcmp(all_exps_data.ExperimentName,'28_4mm,')} = '28_4mm';

% Rename a single input
all_exps_data.InputName{strcmp(all_exps_data.InputName,'fEdgeDetectorValue')} = 'y0';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'ActualPosition')} = 'u1';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'AI_PMSSpeedBendingRoller')} = 'velocity';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'PID_WebEdgePositionControl_SP')} = 'setpoint';

% Rename outputs
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R1')} = 'y1';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R4')} = 'y4';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R5')} = 'y5';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R7')} = 'y7';

% 1. Find the index of the signal you want to move in the Inputs
target_name = 'y0'; 
in_idx = find(strcmp(all_exps_data.InputName, target_name));

if ~isempty(in_idx)
    
    % 2. Extract the raw data for 'y0' from all 30 experiments
    y0_data = cell(size(all_exps_data.InputData));
    for k = 1:length(y0_data)
        y0_data{k} = all_exps_data.InputData{k}(:, in_idx);
    end
    
    % 3. Create a clean, temporary iddata object with 'y0' as an OUTPUT
    % (We pass [] for inputs since it has none)
    y0_as_output = iddata(y0_data, [], all_exps_data.Ts);
    y0_as_output.OutputName = {target_name};
    y0_as_output.OutputUnit = all_exps_data.InputUnit(in_idx);
    y0_as_output.ExperimentName = all_exps_data.ExperimentName; % preserve names
    
    % 4. Isolate the rest of the data (Keep all outputs, drop y0 from inputs)
    % size(all_exps_data, 3) gives the number of input channels
    inputs_to_keep = setdiff(1:size(all_exps_data, 3), in_idx);
    rest_data = all_exps_data(:, :, inputs_to_keep); 
    
    % 5. Combine them! 
    % In MATLAB, horizontal concatenation [A, B] of iddata objects 
    % safely merges their Outputs and Inputs together.
    new_exps_data = [y0_as_output, rest_data];
    
    disp(['Successfully moved ''', target_name, ''' to the first Output!']);
else
    disp(['Input ''', target_name, ''' not found. Check your channel names.']);
end

new_exps_data;

%% Plot experiments
expNames = {'21_4mm_test2','22_2mm_fast','23_splice','24_step_gain_1_75', ...
            '25_step_gain_2_6','26_splice_fast','27_4mm_fast','28_4mm', ...
            '29_2mm_test2','30_2mm'};
outNames = {'y1','y4','y5','y7'};
inNames  = {'y0','u1','setpoint'};

sel = all_exps_data(:, outNames, inNames, expNames);

for j = 1:numel(expNames)
    d = getexp(sel, j);
    t = (0:size(d,1)-1) * d.Ts;

    figure('Color','w','Name',expNames{j},'NumberTitle','off');
    tl = tiledlayout(2, 1, 'TileSpacing','compact', 'Padding','compact');

    % Top: outputs + y0
    nexttile; hold on; grid on;
    topSigs = [outNames, {'y0'}];
    for i = 1:numel(topSigs)
        s = topSigs{i};
        if ismember(s, outNames)
            y = d.OutputData(:, strcmp(d.OutputName, s));
        else
            y = d.InputData(:,  strcmp(d.InputName,  s));
        end
        plot(t, y, 'DisplayName', s);
    end
    legend('Interpreter','none','Location','best');
    ylabel('outputs & y0');
    set(gca,'XTickLabel',[]);

    % Bottom: u1 + setpoint
    nexttile; hold on; grid on;
    botSigs = {'u1','setpoint'};
    for i = 1:numel(botSigs)
        s = botSigs{i};
        y = d.InputData(:, strcmp(d.InputName, s));
        plot(t, y, 'DisplayName', s);
    end
    legend('Interpreter','none','Location','best');
    ylabel('u1 & setpoint');
    xlabel('t [s]');

    title(tl, expNames{j}, 'Interpreter','none');
end

%% Train - Test Split

% All data

% cExperiments = {'21_4mm_test2', '22_2mm_fast', '24_step_gain_1_75','25_step_gain_2_6', '27_4mm_fast', '28_4mm','29_2mm_test2', '30_2mm'};
% 
% cExpNames = {'21_\4mm_test2', '22\_2mm_fast', '24\_step\_gain\_1\_75', '25\_step\_gain\_2\_6','27\_4mm_fast', '28\_4mm,', '29\_2mm\_test2', '30\_2mm'};

cExperiments = {'1_2mm', '2_4mm', '3_Splices1', '4_Splices2', '5_Splices3', '6_fastSplices', '7_slowSplices','8_Step2mm',...
    '9_steps4mm', '10_FastSplices2', '11_SlowSplices2', '12_NormalFunctioning_Fast', '13_NormalFunctioning_Slow',...
    '14_notchtest', '15_Step2mm_fast', '16_Step4mm_fast', '17_step2mm_slow', '18_step4mm_slow', '19_splice_slow', '20_splice_fast',...
    '21_4mm_test2', '22_2mm_fast', '23_splice', '24_step_gain_1_75','25_step_gain_2_6', '26_splice_fast','27_4mm_fast', '28_4mm',...
    '29_2mm_test2', '30_2mm'};

cExpNames = {'1\_2mm', '2\_4mm', '3\_Splices1', '4\_Splices2', '5\_Splices3', '6\_fastSplices', '7\_slowSplices','8\_Step2mm',...
    '9\_steps4mm', '10\_FastSplices2', '11\_SlowSplices2', '12\_NormalFunctioning\_Fast', '13\_NormalFunctioning\_Slow',...
    '14\_notchtest', '15_\Step2mm\_fast', '16\_Step4mm\_fast', '17\_step2mm_slow', '18\_step4mm_slow', '19\_splice\_slow',...
    '20\_splice_fast','21_\4mm_test2', '22\_2mm_fast', '23\_splice', '24\_step\_gain\_1\_75', '25\_step\_gain\_2\_6', '26\_splice\_fast',...
    '27\_4mm_fast', '28\_4mm', '29\_2mm\_test2', '30\_2mm'};


dExperiments = str2double(extractBefore(cExperiments, '_'));

% Train data
cExpTrain = {'21_4mm_test2', '22_2mm_fast', '24_step_gain_1_75','25_step_gain_2_6','27_4mm_fast', '30_2mm' };
dExpTrain = str2double(extractBefore(cExpTrain, '_'));

% Test data
cExpTest = {'28_4mm', '29_2mm_test2'};
dExpTest = str2double(extractBefore(cExpTest, '_'));

%% Full Physical Model plots for selected experiments
Fs = 100;
save_directory = 'plots/physical_model/roller_comparison';
if ~exist(save_directory, 'dir')
    mkdir(save_directory);
end
dShowPlots = 0;
dSavePlots = 0;

% Experiments to plot
expNames = {'21_4mm_test2','22_2mm_fast','24_step_gain_1_75','25_step_gain_2_6','26_splice_fast','27_4mm_fast','28_4mm','29_2mm_test2','30_2mm'};

% Signal and section names
outNames = {'y1','y4','y5','y7'};   % PMEdgePosn, R4, R5, R7
inNames  = {'y0','u1'};
sectionTitles = {'R0-R1','R1-R4','R4-R5','R5-R7'};

% Select experiments by name (errors out if any name is wrong)
sel = all_exps_data(:, outNames, inNames, expNames);

for k = 1:numel(expNames)
    % Get data for current experiment
    exp_data    = getexp(sel, k);
    expName     = expNames{k};
    time_vector = (0:size(exp_data,1)-1) / Fs;

    % Ground truth signals (by name)
    Var_PMEdgePosn = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y1'));
    R4 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y4'));
    R5 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y5'));
    R7 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y7'));

    % Inputs for simulation (by name)
    Y0_input = exp_data.InputData(:, strcmp(exp_data.InputName, 'y0')) * 0.001;
    u1_input = exp_data.InputData(:, strcmp(exp_data.InputName, 'u1')) * 0.001;

    % Simulate the model
    [~, ~, sim_sys_opt] = lsim(TP_sys_disc_01, transpose([Y0_input u1_input]), time_vector);
    sim_R1 = 1000 * sim_sys_opt(:, 1);
    sim_R4 = 1000 * sim_sys_opt(:, 7);
    sim_R5 = 1000 * sim_sys_opt(:, 9);
    sim_R7 = 1000 * sim_sys_opt(:, 13);

    % Pack ground truth and simulated for easy looping
    gt  = {Var_PMEdgePosn, R4, R5, R7};
    sim = {sim_R1,         sim_R4, sim_R5, sim_R7};

    if dShowPlots
        figure('Color','w','Name',expName,'NumberTitle','off');
        for s = 1:4
            subplot(4, 1, s);
            plot(time_vector, gt{s}, 'b', time_vector, sim{s}, 'r');
            title(sectionTitles{s});
            ylabel('Position');
            legend('Ground Truth', 'Simulated', 'Location', 'best');
            grid on;
            gof = goodnessOfFit(sim{s}, gt{s}, 'MSE');
            text(0.02, 0.9, ['MSE: ', num2str(gof)], ...
                 'Units','normalized', 'BackgroundColor','w', 'EdgeColor','k');
            if s < 4
                set(gca, 'XTickLabel', []);
            else
                xlabel('Time (s)');
            end
        end
        sgtitle(expName, 'Interpreter','none', 'FontWeight','bold');
    end

    if dSavePlots
        set(gcf, 'Units','Inches', 'Position',[0,0,10,12], ...
                 'PaperUnits','Inches', 'PaperSize',[10,12]);
        safeName = regexprep(expName, '[^\w\-]', '_');
        print(gcf, fullfile(save_directory, ...
              ['Roller_Comparison_Experiment_', safeName, '.png']), ...
              '-dpng', '-r300');
        savefig(gcf, fullfile(save_directory, ...
                ['Roller_Comparison_Experiment_', safeName, '.fig']));
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

%% Define transfer function span 1 : R0 - R1
% For this span, there are a couple details 1) Set u0 = 0, ie. no TF
% component from 1) motion 2) Set impact of dY0/dt on output to zero
% (simplification)

% Compute f1(KL1), f2(KL1), f3(KL1) for this segment

f1_L1 = double(vpa(subs(f1,  KL, Kgam_*L1))) ; 
f2_L1 = double(vpa(subs(f2,  KL, Kgam_*L1))) ;
f3_L1 = double(vpa(subs(f3,  KL, Kgam_*L1))) ;

% TF for Y1/Y0
numY1_Y0 = [f1_L1/(tau1^2)] ; % Using only constant here because do not want to consider dY0/dt --> For later segments will be different
denY1 = [1 (1/tau1)*f2_L1 (1/tau1^2)*f1_L1] ; 
%TFY1_Y0 = tf(numY1_Y0, denY1); 

% TF for Y1/u1 
numY1_u1 = [(f2_L1*(v_^2))/(L1*c1)] ;
denY1 = [1 (1/tau1)*f2_L1 (1/tau1^2)*f1_L1] ; 
%TFY1_u1 = tf(numY1_u1, denY1) ; 

% TF1 = TF
%TF1 = tf({numY1_Y0, numY1_u1},{denY1, denY1}) ;
TF1 = [tf({numY1_Y0, numY1_u1},{denY1, denY1}) ; s*tf({numY1_Y0, numY1_u1},{denY1, denY1})] ;

%% Estimate Transfer function R4-R5 with speed and input
% Check  train and test data
train_data = modify_iddata(new_exps_data(:, [1 2], [1 4], dExpTrain))
test_data = modify_iddata(new_exps_data(:, [1 2], [1 4], dExpTest))

%% Estimate Transfer function R4-R5 with speed

% directory
cPath = 'models/R0_R1/narrow/y0-u1-v/model_0_2_and_0_2_and_0_1/';

% section options
dLoadOrTrain = 1; % 0: Load; 1: Train
dSaveModels = 1;

if dLoadOrTrain
    
    % wo speed first train
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [0 0 0] ;
    np = [2 2 1] ; 

    TFest = tfest(train_data, np, nz, opt);

    % Save figures
    if dSaveModels
        % Save models
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest');
    end

else
    TFest = load(append(cPath,'TFest.mat'));
    TFest = TFest.TFest;
end

%% Plots for R0-R1

% Section options
dSaveFigures = 1; 

% Models
models = {'physical', 'estimated'};
sim_models = {TF1, TFest};
exps_data_all = {test_data, test_data};


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
        set(gcf, 'Position', [100, 100, 1600, 800]);

        % Plot the comparison for the current experiment
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        

        if dSaveFigures
            if j == 1 
                % Explicitly set both title and subtitle
                title('Simulated Response Comparison');
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_physical']);
                % Save the figure
                exportgraphics(gcf, fullfile(model_folder, ['R0_R1_', cExperiments{k},'_physical' ,'.png']));           
                
            elseif j == 2
                % Explicitly set both title and subtitle
                title('Simulated Response Comparison');
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_est']);
                % Save the figure
                exportgraphics(gcf, fullfile(model_folder, ['R0_R1_', cExperiments{k},'_est' ,'.png']));
                
            else 
                print("Error")
            end
        end
    end
end

%% Pause












%%
mkdir('new_models/R0_R1/'); 
save('new_models/R0_R1/TF_0_1_est_wo_speed_20.mat', 'TF_0_1_est_wo_speed_20');
save('new_models/R0_R1/TF_0_1_est_speed_20.mat', 'TF_0_1_est_speed_20');
save('new_models/R0_R1/TF_0_1_est_wo_speed_42.mat', 'TF_0_1_est_wo_speed_42');
save('new_models/R0_R1/TF_0_1_est_speed_42.mat', 'TF_0_1_est_speed_42');

%%
% Plot plots for R0-R1

% Set test data
test_data_0_1_wo_speed = all_exps_data(:,1,[1 2], dExpTest) ; 
test_data_0_1_speed = all_exps_data(:,1,[1 2 5], dExpTest) ; 

% Specify  variables specific for this experiment
exps_data = test_data_0_1_wo_speed ; 
exps_data_speed = test_data_0_1_speed ; 
folder_to_save_in = 'new_plots/R0_R1/' ; 

% Models
% models = {'physical', 'estimated_nospeed_20', 'estimated_speed_20', 'estimated_nospeed_42', 'estimated_speed_42'};
% sim_models = {TF1(1,:), TF_0_1_est_wo_speed_20, TF_0_1_est_speed_20, TF_0_1_est_wo_speed_42, TF_0_1_est_speed_42};
% exps_data_all = {exps_data, exps_data, exps_data_speed, exps_data, exps_data_speed};

models = {'physical'};
sim_models = {TF1(1,:)};
exps_data_all = {exps_data};

ExpNames = {"4mm Step","2mm Step Up/Down","Splice"};

% % Loop through each model
% for j = 1:length(models)
%     model_folder = fullfile(folder_to_save_in, models{j}); 
%     if ~exist(model_folder, 'dir')
%         mkdir(model_folder);
%     end
% 
%     % Plot for each model
%     sim_model = sim_models{j}; 
% 
%     % Loop through each experiment
%     for i = 1:length(cExpTest)
%         % Initialize a figure for each experiment
%         figure; 
% 
%         % Set figure size
%         set(gcf, 'Position', [100, 100, 1000, 500]);
% 
%         % Plot the comparison for the current experiment
%         compare(exps_data_all{j}(:,:,:,i), sim_model);
% 
%         % Label the plot with the experiment name
%         title(['M01', ExpNames{i}]);
% 
%         % Save the figure as a PNG
%         print(gcf, fullfile(model_folder, [cExpTest{i}, '.png']), '-dpng', '-r300');
%         % savefig(gcf, fullfile(model_folder, [cExpTest{i}, '.fig']));
%     end
% end

% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(folder_to_save_in, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(cExpTest)
        figure; 
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot comparison
        compare(exps_data_all{j}(:,:,:,i), sim_model);

        % Extract data and simulated output
        data   = exps_data_all{j}(:,:,:,i);
        [ySim, ~] = compare(data, sim_model);
        yTrue  = data.y;        % [N×ny]
        yHat   = ySim.y;        % [N×ny]

        % Compute MSE
        mse_per_channel = mean((yTrue - yHat).^2, 1);
        overall_mse      = mean(mse_per_channel);

        % Overlay the MSE on the plot (upper‐left corner)
        ax = gca;
        text( ...
            ax, ...                            % parent axes
            0.05, 0.95, ...                    % normalized position [x y]
            sprintf('MSE = %.4g', overall_mse), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'EdgeColor', 'black' ...
        );

        % Label and save
        title(['Physics-Based Transfer Function', 'M_{01} - '+ ExpNames{i}]);
        print(gcf, fullfile(model_folder, [cExpTest{i}, '.png']), '-dpng', '-r300');
    end
end

%
%% Define Transfer function R1-R4
%transfer function span 1 : R1 - R2
% For this span, there are a couple details 1) Set u2 = 0, ie. no TF
% component from R2 motion 

% Compute f1(KL1), f2(KL1), f3(KL1) for this segment

f1_L2 = double(vpa(subs(f1,  KL, Kgam_*L2))) ; 
f2_L2 = double(vpa(subs(f2,  KL, Kgam_*L2))) ;
f3_L2 = double(vpa(subs(f3,  KL, Kgam_*L2))) ;

% TF for Y1/Y0
numY2_Y1 = [-(f3_L2/tau2) f1_L2/(tau2^2)] ; % Want to use dy1/dt as input as well
denY2 = [1 (1/tau2)*f2_L2 (1/tau2^2)*f1_L2] ; 
%TFY2_Y1 = tf(numY2_Y1, denY2); 

% TF for Y1/u1 
numY2_u1 = [(f3_L2*(v_^2))/(L2*c1)] ;
denY2 = [1 (1/tau2)*f2_L2 (1/tau2^2)*f1_L2] ; 
%TFY2_u1 = tf(numY2_u1, denY2) ; 

% TF1 = TF
%TF2 = tf({numY2_Y1, numY2_u1},{denY2, denY2}) ;
TF2 = [tf({numY2_Y1, numY2_u1},{denY2, denY2}) ; s*tf({numY2_Y1, numY2_u1},{denY2, denY2})] ;

% Define transfer function span 2 : R2 - R3
% For this span, there are a couple details 1) Set u2 = 0, u3 = 0, ie. no TF
% component from R2 motion 

% Compute f1(KL3), f2(KL3), f3(KL3) for this segment

f1_L3 = double(vpa(subs(f1,  KL, Kgam_*L3))) ; 
f2_L3 = double(vpa(subs(f2,  KL, Kgam_*L3))) ;
f3_L3 = double(vpa(subs(f3,  KL, Kgam_*L3))) ;

% TF for Y3/Y2
numY3_Y2 = [-(f3_L3/tau3) f1_L3/(tau3^2)] ; % Want to use dy1/dt as input as well
denY3 = [1 (1/tau3)*f2_L3 (1/tau3^2)*f1_L3] ; 
TFY3_Y2 = tf(numY3_Y2, denY3); 

%TF3 = TFY3_Y2 ; 
TF3 = [TFY3_Y2 ; s*TFY3_Y2] ; 

% Define transfer function span 2 : R3 - R4
% For this span, there are a couple details 1) Set u2 = 0, u3 = 0

% Compute f1(KL4), f2(KL4), f3(KL4) for this segment

f1_L4 = double(vpa(subs(f1,  KL, Kgam_*L4))) ; 
f2_L4 = double(vpa(subs(f2,  KL, Kgam_*L4))) ;
f3_L4 = double(vpa(subs(f3,  KL, Kgam_*L4))) ;

% TF for Y4/Y3
numY4_Y3 = [-(f3_L4/tau4) f1_L4/(tau4^2)] ; % Want to use dy1/dt as input as well
denY4 = [1 (1/tau4)*f2_L4 (1/tau4^2)*f1_L4] ; 
TFY4_Y3 = tf(numY4_Y3, denY4); 

%TF4 = TFY4_Y3 ; 
TF4 = [TFY4_Y3 ; s*TFY4_Y3] ; 

% Combining these transfer functions 

TF2.u = {'Y1';'u1'} ; 
TF2.y = {'Y2';'dY2/dt'} ; 

TF3.u = 'Y2' ;
TF3.y = {'Y3';'dY3/dt'} ;

TF4.u = 'Y3' ;
TF4.y = {'Y4';'dY4/dt'} ;

TF_234_temp = connect(TF2,TF3,TF4,{'Y1';'u1'}, {'Y2';'dY2/dt';'Y3';'dY3/dt';'Y4';'dY4/dt'}) ; 
%TF_234_temp = connect(TF2,TF3,TF4,{'Y1';'u1'}, {'Y4'}) ; 
TF_234_temp = minreal(ss(TF_234_temp)) ;

TF_234 = ss2ss(TF_234_temp, TF_234_temp.C) ; 

TF_234_Y4out = TF_234(5,:) ; 
TF_234_Y4out.u = {'y_R1' ; 'ActualPosition'} ; 
TF_234_Y4out.y = 'y_R4' ; 

TF_234.A(logical((-(10^-8)<TF_234.A).*(TF_234.A<10^-8))) = 0 ; 
TF_234.B(logical((-(10^-8)<TF_234.B).*(TF_234.B<10^-8))) = 0 ; 
TF_234.C(logical((-(10^-8)<TF_234.C).*(TF_234.C<10^-8))) = 0 ; 
TF_234.D(logical((-(10^-8)<TF_234.D).*(TF_234.D<10^-8))) = 0 ; 

%% Estimate R1-R4 Linear model
train_data_1_4_wo_speed = modify_iddata(all_exps_data(:,[1 2],[2], dExpTrain)) ; 
train_data_1_4_speed = modify_iddata(all_exps_data(:,[1 2],[2 5], dExpTrain)) ; 

%%
Opt = tfestOptions('Display','on', 'EnforceStability', true);
 
n_poles = [4 4] ; 
n_zeroes = [2 2] ; 

TF1_4_est_wo_speed_42 = tfest(train_data_1_4_wo_speed, n_poles, n_zeroes, Opt);

%%
Opt = tfestOptions('Display','on', 'EnforceStability', true);
n_poles = [4 6 4] ; 
n_zeroes = [2 2 4] ; 

TF1_4_est_speed_42 = tfest(train_data_1_4_speed, n_poles, n_zeroes, Opt);

%%
Opt = tfestOptions('Display','on', 'EnforceStability', true);
n_poles = [6 8] ; 
n_zeroes = [2 2] ; 

TF1_4_est_wo_speed_62 = tfest(train_data_1_4_wo_speed, n_poles, n_zeroes, Opt);

%%
Opt = tfestOptions('Display','on', 'EnforceStability', true);
n_poles = [6 8 4] ; 
n_zeroes = [2 2 4] ; 

TF1_4_est_speed_62 = tfest(train_data_1_4_speed, n_poles, n_zeroes, Opt);

%%
mkdir('new_models/R1_R4/'); 
% save('new_models/R1_R4/TF1_4_est_wo_speed_42.mat', 'TF1_4_est_wo_speed_42');
save('new_models/R1_R4/TF1_4_est_speed_42.mat', 'TF1_4_est_speed_42');
% save('new_models/R1_R4/TF1_4_est_wo_speed_62.mat', 'TF1_4_est_wo_speed_62');
save('new_models/R1_R4/TF1_4_est_speed_62.mat', 'TF1_4_est_speed_62');

%% Plot R1-R4 plots
test_data_1_4_wo_speed = modify_iddata(all_exps_data(:,[1 2],[2], dExpTest)) ; 
test_data_1_4_speed = modify_iddata(all_exps_data(:,[1 2],[2 5], dExpTest)) ; 

% Specify variables specific for this experiment
exps_data = test_data_1_4_wo_speed ; 
exps_data_speed = test_data_1_4_speed ; 
folder_to_save_in = 'new_plots/R1_R4/' ; 


% Models
models = {'physical'};
%sim_models = {TF_234_Y4out, TF1_4_est_wo_speed_42, TF1_4_est_speed_42, TF1_4_est_wo_speed_62, TF1_4_est_speed_62};
sim_models = {TF_234_Y4out};
exps_data_all = {exps_data};



ExpNames = {"4mm Step","2mm Step Up/Down","Splice"};

% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(folder_to_save_in, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(cExpTest)
        figure; 
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot comparison
        compare(exps_data_all{j}(:,:,:,i), sim_model);

        % Extract data and simulated output
        data   = exps_data_all{j}(:,:,:,i);
        [ySim, ~] = compare(data, sim_model);
        yTrue  = data.y;        % [N×ny]
        yHat   = ySim.y;        % [N×ny]

        % Compute MSE
        mse_per_channel = mean((yTrue - yHat).^2, 1);
        overall_mse      = mean(mse_per_channel);

        % Overlay the MSE on the plot (upper‐left corner)
        ax = gca;
        text( ...
            ax, ...                            % parent axes
            0.05, 0.95, ...                    % normalized position [x y]
            sprintf('MSE = %.4g', overall_mse), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'EdgeColor', 'black' ...
        );

        % Label and save
        title(['Physics-Based Transfer Function', 'M_{14} - '+ ExpNames{i}]);
        print(gcf, fullfile(model_folder, [cExpTest{i}, '.png']), '-dpng', '-r300');
    end
end


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
train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain)) ;
train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain)) ;

test_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTest)) ;
test_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest)) ;

train_data_4_5_speed
test_data_4_5_speed

%% Estimate Transfer function R4-R5
% section options
dLoadOrTrain = 0; % Load = 0; Train = 1;
dSaveModels = 0; % Save = 1;

% directory
model = "model_06/";
cPath = "new_models/R4_R5/"+ model;

if dLoadOrTrain
    % model without speed
    % load data wo speed
    train_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain)) ;

    % set options
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    % set zeros and poles
    np = [3] ; 
    nz = [1] ; 

    % estimate model wo speed
    TF4_5_est_wo_speed = tfest(train_data_4_5_wo_speed, np, nz, opt);
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    % model with speed
    % with speed data
    train_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain)) ;

    % set options
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    % set zeros and poles
    np = [3 3] ; 
    nz = [1 2] ; 

    % estimate model with speed
    TF4_5_est_speed = tfest(train_data_4_5_speed, np, nz, opt);


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

%% Plot plots for R4-R5

% Section options
dSaveFigures = 1 ;

% directory
model = "model_06/";
cPath = "thesis_plots/R4_R5/"+ model;

% Load test data
test_data_4_5_wo_speed = modify_iddata(all_exps_data(:, [2 3], [], dExpTest)) ;
test_data_4_5_speed = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest)) ;

% Models
models = {'physical'};
sim_models = {TF5(1,:)};
exps_data_all = {test_data_4_5_wo_speed};

% 
% % Loop through each model
% for j = 1:length(models)
%     model_folder = fullfile(cPath, models{j}); 
%     if ~exist(model_folder, 'dir')
%         mkdir(model_folder);
%     end
% 
%     %Plot for each model
%     sim_model = sim_models{j}; 
% 
%     % Loop through each experiment
%     for i = 1:length(dExpTest)
%         k = dExpTest(i);
%         % Initialize a figure for each experiment
%         figure; 
% 
%         % Set figure size
%         set(gcf, 'Position', [100, 100, 1000, 500]);
% 
%         % Plot the comparison for the current experiment
%         compare(exps_data_all{j}(:,:,:,i), sim_model);
% 
% 
%         if dSaveFigures
%             if j == 1 
% 
%             % Label the plot with the experiment name
%             title(['R4\_R5 Experiment: ', cExpNames{k}, '\_physical']);
%             % Save the figure as a PNG
%             print(gcf, fullfile(model_folder, ['R4_R5_',cExperiments{k},'_physical' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'physical', '.fig']));
% 
%             elseif j == 2
% 
%             % Label the plot with the experiment name
%             title(['R4\_R5 Experiment: ', cExpNames{k}, '\_no\_speed']);
%             % Save the figure as a PNG
% 
%             print(gcf, fullfile(model_folder, ['R4_R5_',cExperiments{k},'_no_speed' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'no_speed', '.fig']));
% 
%             elseif j== 3
% 
%             % Label the plot with the experiment name
%             title(['R4\_R5 Experiment: ', cExpNames{k}, '\_speed']);
%             % Save the figure as a PNG
%             print(gcf, fullfile(model_folder, ['R4_R5_',cExperiments{k},'_speed' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'speed', '.fig']));
% 
%             else 
%                 print("Error")
%             end
%         end
%     end
% end

% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(cPath, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(cExpTest)
        figure; 
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot comparison
        compare(exps_data_all{j}(:,:,:,i), sim_model);

        % Extract data and simulated output
        data   = exps_data_all{j}(:,:,:,i);
        [ySim, ~] = compare(data, sim_model);
        yTrue  = data.y;        % [N×ny]
        yHat   = ySim.y;        % [N×ny]

        % Compute MSE
        mse_per_channel = mean((yTrue - yHat).^2, 1);
        overall_mse      = mean(mse_per_channel);

        % Overlay the MSE on the plot (upper‐left corner)
        ax = gca;
        text( ...
            ax, ...                            % parent axes
            0.05, 0.95, ...                    % normalized position [x y]
            sprintf('MSE = %.4g', overall_mse), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'EdgeColor', 'black' ...
        );

        % Label and save
        title(['Physics-Based Transfer Function', 'M_{45} - '+ ExpNames{i}]);
        print(gcf, fullfile(model_folder, [cExpTest{i}, '.png']), '-dpng', '-r300');
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

test_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTest)) ;
test_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTest)) ;

train_data_5_7_speed
test_data_5_7_speed
%% Estimate Transfer function R5-R7
% section options
dLoadOrTrain = 0;
dSaveModels = 0;

% directory
model = "model_06/";
cPath = "new_models/R5_R7/"+ model;

if dLoadOrTrain
    % model wo speed
    % load data wo speed
    train_data_5_7_wo_speed = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain)) ;
    
    % set options
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;

    % set poles and zeros
    np = [4] ; 
    nz = [2] ; 

    % estimate model wo speed
    TF5_7_est_wo_speed = tfest(train_data_5_7_wo_speed, np, nz, opt);

    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    % model with speed
    % load data with speed
    train_data_5_7_speed = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain)) ;
    
    % estimate model w speed
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    
    % set poles and zero
    np = [4 2] ; 
    nz = [2 2] ; 

    % estimate model w speed    
    TF5_7_est_speed = tfest(train_data_5_7_speed, np, nz, opt);

    % save models
    if dSaveModels
        % save models
        mkdir(cPath);
        save(append(cPath,'TF5_7_est_wo_speed.mat'), 'TF5_7_est_wo_speed');
        save(append(cPath, 'TF5_7_est_speed.mat'), 'TF5_7_est_speed');
    end

% load models
else
    TF5_7_est_wo_speed = load(append(cPath,'TF5_7_est_wo_speed.mat'))
    TF5_7_est_wo_speed = TF5_7_est_wo_speed.TF5_7_est_wo_speed;

    TF5_7_est_speed = load(append(cPath,'TF5_7_est_speed.mat'));
    TF5_7_est_speed = TF5_7_est_speed.TF5_7_est_speed;
end

%% Plot plots for R5-R7
% section options
dSaveFigures = 1;

% directory
cPath = "thesis_plots/R5_R7/"+ model;

% Load test data
test_data_5_7_wo_speed = modify_iddata(all_exps_data(:,[3 4],[], dExpTest)) ;
test_data_5_7_speed = modify_iddata(all_exps_data(:,[3 4],[5], dExpTest)) ;

% Models
models = {'physical'};
sim_models = {TF_67_tf};
exps_data_all = {test_data_5_7_wo_speed};

% % Loop through each model
% for j = 1:length(models)
%     model_folder = fullfile(cPath, models{j}); 
%     if ~exist(model_folder, 'dir')
%         mkdir(model_folder);
%     end
% 
%     %Plot for each model
%     sim_model = sim_models{j}; 
% 
%     % Loop through each experiment
%     for i = 1:length(dExpTest)
%         k = dExpTest(i) ;
%         % Initialize a figure for each experiment
%         figure; 
% 
%         % Set figure size
%         set(gcf, 'Position', [100, 100, 1000, 500]);
% 
%         % Plot the comparison for the current experiment
%         compare(exps_data_all{j}(:,:,:,i), sim_model);
% 
% 
%         if dSaveFigures
%             if j == 1 
% 
%             % Label the plot with the experiment name
%             title(['R5\_R7 Experiment: ', cExpNames{k}, '\_physical']);
%             % Save the figure as a PNG
%             print(gcf, fullfile(model_folder, ['R5_R7_',cExperiments{k},'_physical' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'physical', '.fig']));
% 
%             elseif j == 2
% 
%             % Label the plot with the experiment name
%             title(['R5\_R7 Experiment: ', cExpNames{k}, '\_no\_speed']);
%             % Save the figure as a PNG
%             print(gcf, fullfile(model_folder, ['R5_R7_',cExperiments{k},'_no_speed' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'no_speed', '.fig']));
% 
%             elseif j== 3
% 
%             % Label the plot with the experiment name
%             title(['R5\_R7 Experiment: ', cExpNames{k}, '\_speed']);
%             % Save the figure as a PNG
%             print(gcf, fullfile(model_folder, ['R5_R7_',cExperiments{k},'_speed' ,'.png']), '-dpng', '-r300');
%             % savefig(gcf, fullfile(model_folder, [cExperiments{k}, 'speed', '.fig']));
% 
%             else 
%                 print("Error")
%             end
%         end
%     end
% end

% Loop through each model
for j = 1:length(models)
    model_folder = fullfile(cPath, models{j}); 
    if ~exist(model_folder, 'dir')
        mkdir(model_folder);
    end

    sim_model = sim_models{j}; 

    % Loop through each experiment
    for i = 1:length(cExpTest)
        figure; 
        set(gcf, 'Position', [100, 100, 1000, 500]);

        % Plot comparison
        compare(exps_data_all{j}(:,:,:,i), sim_model);

        % Extract data and simulated output
        data   = exps_data_all{j}(:,:,:,i);
        [ySim, ~] = compare(data, sim_model);
        yTrue  = data.y;        % [N×ny]
        yHat   = ySim.y;        % [N×ny]

        % Compute MSE
        mse_per_channel = mean((yTrue - yHat).^2, 1);
        overall_mse      = mean(mse_per_channel);

        % Overlay the MSE on the plot (upper‐left corner)
        ax = gca;
        text( ...
            ax, ...                            % parent axes
            0.05, 0.95, ...                    % normalized position [x y]
            sprintf('MSE = %.4g', overall_mse), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'EdgeColor', 'black' ...
        );

        % Label and save
        title(['Physics-Based Transfer Function', 'M_{57} - '+ ExpNames{i}]);
        print(gcf, fullfile(model_folder, [cExpTest{i}, '.png']), '-dpng', '-r300');
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

%%
tf = tf2ss(TF4_5_est_speed);



