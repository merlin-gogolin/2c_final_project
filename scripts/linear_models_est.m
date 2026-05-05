%% Read in experiments data + Physical model
close all; clear all; clc;

all_exps_data = load('data/all_exps_data.mat');
all_exps_data = all_exps_data.all_exps_data ; 

% Load Web model
TP_sys_disc_01 = load('mat_files/TP_flat_web_disc_tr_coeffs.mat');
TP_sys_disc_01 = TP_sys_disc_01.TP_sys_disc ; 

%% Update iddata object

all_exps_data.ExperimentName{strcmp(all_exps_data.ExperimentName,'28_4mm,')} = '28_4mm';

all_exps_data.InputName{strcmp(all_exps_data.InputName,'fEdgeDetectorValue')}       = 'y0';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'ActualPosition')}            = 'u1';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'AI_PMSSpeedBendingRoller')} = 'velocity';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'PID_WebEdgePositionControl_SP')} = 'setpoint';

all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R1')} = 'y1';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R4')} = 'y4';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R5')} = 'y5';
all_exps_data.OutputName{strcmp(all_exps_data.OutputName,'y_R7')} = 'y7';

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
% cExpTrain = {'21_4mm_test2', '24_step_gain_1_75','25_step_gain_2_6', '30_2mm' };

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

expNames     = {'21_4mm_test2','22_2mm_fast','24_step_gain_1_75','25_step_gain_2_6','26_splice_fast','27_4mm_fast','28_4mm','29_2mm_test2','30_2mm'};
outNames     = {'y1','y4','y5','y7'};
inNames      = {'y0','u1'};
sectionTitles = {'R0-R1','R1-R4','R4-R5','R5-R7'};

sel = all_exps_data(:, outNames, inNames, expNames);

for k = 1:numel(expNames)
    exp_data    = getexp(sel, k);
    expName     = expNames{k};
    time_vector = (0:size(exp_data,1)-1) / Fs;

    Var_PMEdgePosn = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y1'));
    R4 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y4'));
    R5 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y5'));
    R7 = exp_data.OutputData(:, strcmp(exp_data.OutputName, 'y7'));

    Y0_input = exp_data.InputData(:, strcmp(exp_data.InputName, 'y0')) * 0.001;
    u1_input = exp_data.InputData(:, strcmp(exp_data.InputName, 'u1')) * 0.001;

    [~, ~, sim_sys_opt] = lsim(TP_sys_disc_01, transpose([Y0_input u1_input]), time_vector);
    sim_R1 = 1000 * sim_sys_opt(:, 1);
    sim_R4 = 1000 * sim_sys_opt(:, 7);
    sim_R5 = 1000 * sim_sys_opt(:, 9);
    sim_R7 = 1000 * sim_sys_opt(:, 13);

    gt  = {Var_PMEdgePosn, R4, R5, R7};
    sim = {sim_R1, sim_R4, sim_R5, sim_R7};

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

b_   = 0.166;
h_   = 0.20/1000;
E_   = 3.5e9;
mu_  = .45;
T_   = 100;
v_   = 1.125;
% v_ = 20.1;
I_   = 1/2 * b_^3*h_;
A_   = b_*h_;
G_   = E_/(2*(1+mu_));
kn_  = (12+11*mu_)/(10+10*mu_);
Kgam_ = ((T_/(E_*I_))/(1+(kn_*T_)/(A_*G_)))^(.5);

L1 = sqrt(2.470^2 + (0.256)^2) + 0.3;
L2 = sqrt(0.133^2 + (0.027)^2) + sqrt(0.236^2 + (0.053)^2);
L3 = sqrt(1.590^2 + (0.094)^2);
L4 = 1.590 + 0.166 + 0.05 + 0.355;
L5 = 0.486 + 0.005;
L6 = 0.187 + 0.05;
L7 = 0.187 + 0.045 + 0.05;

c0 = 0.4; c1 = 0.4; c2 = 0.4; c3 = 0.4;
c4 = 0.334; c5 = 0.141; c6 = 0.17; c7 = 0.142;

tau1 = L1/v_; tau2 = L2/v_; tau3 = L3/v_; tau4 = L4/v_;
tau5 = L5/v_; tau6 = L6/v_; tau7 = L7/v_;

syms KL real

f1 = (((KL)^2)*(cosh(KL)-1)) / (KL*sinh(KL)+2*(1-cosh(KL)));
f2 = KL*((KL*(cosh(KL)))-sinh(KL)) / (KL*sinh(KL)+2*(1-cosh(KL)));
f3 = (KL * (sinh(KL)-KL)) / (KL*sinh(KL)+2*(1-cosh(KL)));

s = tf([1 0], 1);

%% Define physical Transfer function R4-R5

f1_L5 = double(vpa(subs(f1, KL, Kgam_*L5)));
f2_L5 = double(vpa(subs(f2, KL, Kgam_*L5)));
f3_L5 = double(vpa(subs(f3, KL, Kgam_*L5)));

numY5_Y4 = [-(f3_L5/tau5) f1_L5/(tau5^2)];
denY5    = [1 (1/tau5)*f2_L5 (1/tau5^2)*f1_L5];
TFY5_Y4  = tf(numY5_Y4, denY5);
TF5      = [TFY5_Y4; s*TFY5_Y4];

%% Check train and test data
train_data = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [2 3], [], dExpTest));

%% Estimate Transfer function R4-R5 without speed

cPath = 'models/R4_R5/narrow/nospeed/model_1_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1]; np = [2];
    TFest = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest');
    end
else
    TFest = load(append(cPath,'TFest.mat'));
    TFest = TFest.TFest;
end

%% PLOTTING SEPARATED
dSaveFigures = 0;
models       = {'physical', 'estimated'};
sim_models   = {TF5(1,:), TFest};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% Grey-box estimation for R4-R5 (physics-informed)
cPath = 'models/R4_R5/greybox_hybrid/dec10/';
dLoadOrTrain = 0;   % 1 = train, 0 = load
dSaveModels  = 0;

train_data = modify_iddata(all_exps_data(:, [2 3], [], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [2 3], [], dExpTest));

% ===== Decimate =====
decFactor      = 10;
train_data_dec = resample(train_data, 1, decFactor);
test_data_dec  = resample(test_data,  1, decFactor);

if dLoadOrTrain

    % ===== Initial model =====
    theta0   = [tau5; f1_L5; f2_L5; f3_L5];
    sys_init = idgrey('R45_greybox_model', theta0, 'c');

    sys_init.InputName  = {'y4'};
    sys_init.OutputName = {'y5'};

    sys_init.Structure.Parameters(1).Minimum = 1e-6;
    sys_init.Structure.Parameters(2).Minimum = 0;
    sys_init.Structure.Parameters(3).Minimum = 0;

    % ===== Grey-box estimation =====
    opt = greyestOptions;
    opt.Display      = 'on';
    opt.SearchMethod = 'gna';
    opt.SearchOptions.MaxIterations = 20;
    opt.SearchOptions.Tolerance     = 1e-4;

    sys_grey = greyest(train_data_dec, sys_init, opt);

    % ===== Residual =====
    % 1. Simulate grey-box on decimated training data
    clear sim
    n_exp = numel(train_data_dec.ExperimentName);
    residual_outputs = cell(n_exp, 1);
    for ei = 1:n_exp
        exp_i  = getexp(train_data_dec, ei);
        simout = sim(sys_grey, exp_i);
        residual_outputs{ei} = exp_i.OutputData - simout.OutputData;
    end
    
    % 2. Build residual iddata
    residual_data = iddata(residual_outputs, train_data_dec.InputData, train_data_dec.Ts);
    residual_data.ExperimentName = train_data_dec.ExperimentName;
    residual_data.InputName      = train_data_dec.InputName;
    residual_data.OutputName     = train_data_dec.OutputName;
    
    % 3. Fit residual model
    sys_resid  = tfest(residual_data, 1, 0);
    
    % 4. Combine
    sys_hybrid = sys_grey + sys_resid;

    % ===== SAVE =====
    if dSaveModels
        mkdir(cPath);
        save(fullfile(cPath, 'sys_grey.mat'),   'sys_grey');
        save(fullfile(cPath, 'sys_resid.mat'),  'sys_resid');
        save(fullfile(cPath, 'sys_hybrid.mat'), 'sys_hybrid');
    end

else
    % ===== LOAD =====
    sys_grey   = load(fullfile(cPath, 'sys_grey.mat'));   
    sys_resid  = load(fullfile(cPath, 'sys_resid.mat'));  
    sys_hybrid = load(fullfile(cPath, 'sys_hybrid.mat'));

    sys_grey   = sys_grey.sys_grey;
    sys_resid  = sys_resid.sys_resid;
    sys_hybrid = sys_hybrid.sys_hybrid;
end

%% Trying some DC offsets
clear sim

% 4mm test
exp1    = getexp(test_data, 1);
t1      = (0:size(exp1,1)-1) * exp1.Ts;
y4_idx  = strcmp(exp1.InputName, 'y4');
y1_sim  = lsim(TF5(1,:), exp1.InputData(:, y4_idx), t1);
offset_4mm = mean(exp1.OutputData - y1_sim);
fprintf('Optimal DC offset for 4mm: %.4f\n', offset_4mm)

% 2mm test
exp2    = getexp(test_data, 2);
t2      = (0:size(exp2,1)-1) * exp2.Ts;
y2_sim  = lsim(TF5(1,:), exp2.InputData(:, y4_idx), t2);
offset_2mm = mean(exp2.OutputData - y2_sim);
fprintf('Optimal DC offset for 2mm: %.4f\n', offset_2mm)

% Apply offset and compute fit
y1_corrected = y1_sim + offset_4mm;
y2_corrected = y2_sim + offset_2mm;

fit_4mm = 100*(1 - norm(exp1.OutputData - y1_corrected) / norm(exp1.OutputData - mean(exp1.OutputData)));
fit_2mm = 100*(1 - norm(exp2.OutputData - y2_corrected) / norm(exp2.OutputData - mean(exp2.OutputData)));

fprintf('Physical + offset fit 4mm: %.2f%%\n', fit_4mm)
fprintf('Physical + offset fit 2mm: %.2f%%\n', fit_2mm)

%% ===== Compare all models =====
figure;
compare(getexp(test_data_dec, 1), TF5(1,:), TFest, sys_grey, sys_hybrid);
% legend('Data', 'Physical', 'TFest', 'Grey-box', 'Hybrid');
title('Model Comparison (R4 → R5) for 4mm');
figure;
compare(getexp(test_data_dec, 2), TF5(1,:), TFest, sys_grey, sys_hybrid);
title('Model Comparison (R4 → R5) for 2mm');

%% EXTRA PLOTTING
 
% ---- 4mm test ----
exp1   = getexp(test_data, 1);
t1     = (0:size(exp1,1)-1) * exp1.Ts;
y4_idx = strcmp(exp1.InputName, 'y4');
 
y1_phys        = lsim(TF5(1,:), exp1.InputData(:, y4_idx), t1);
offset_4mm     = mean(exp1.OutputData - y1_phys);
y1_phys_offset = y1_phys + offset_4mm;
fprintf('DC offset 4mm: %.6f\n', offset_4mm)
 
nmse = @(y, yhat) 100*(1 - norm(y - yhat)/norm(y - mean(y)));
fit_phys_4mm        = nmse(exp1.OutputData, y1_phys);
fit_phys_offset_4mm = nmse(exp1.OutputData, y1_phys_offset);
fprintf('Physical fit 4mm:          %.2f%%\n', fit_phys_4mm)
fprintf('Physical+offset fit 4mm:   %.2f%%\n', fit_phys_offset_4mm)
 
exp1_dec = getexp(test_data_dec, 1);
t1_dec   = (0:size(exp1_dec,1)-1) * exp1_dec.Ts;

[y1_grey_sim,   fit_grey_4mm]   = compare(exp1_dec, sys_grey);
[y1_hybrid_sim, fit_hybrid_4mm] = compare(exp1_dec, sys_hybrid);
[y1_tfest_sim,  fit_tfest_4mm]  = compare(exp1_dec, TFest);
fprintf('Grey-box fit 4mm:          %.2f%%\n', fit_grey_4mm)
fprintf('Hybrid fit 4mm:            %.2f%%\n', fit_hybrid_4mm)
fprintf('TFest fit 4mm:             %.2f%%\n', fit_tfest_4mm)

figure;
plot(t1,     exp1.OutputData,         'k',   'LineWidth', 1.5, 'DisplayName', 'Measured y5'); hold on;
plot(t1,     y1_phys,                 'b', 'LineWidth', 1,   'DisplayName', sprintf('Physical (%.1f%%)',        fit_phys_4mm));
plot(t1,     y1_phys_offset,          'c',   'LineWidth', 1,   'DisplayName', sprintf('Physical+offset (%.1f%%)', fit_phys_offset_4mm));
plot(t1_dec, y1_grey_sim.OutputData,  'r', 'LineWidth', 1,   'DisplayName', sprintf('Grey-box (%.1f%%)',        fit_grey_4mm));
plot(t1_dec, y1_hybrid_sim.OutputData,'m',   'LineWidth', 1,   'DisplayName', sprintf('Hybrid (%.1f%%)',          fit_hybrid_4mm));
plot(t1_dec, y1_tfest_sim.OutputData, 'g',   'LineWidth', 1,   'DisplayName', sprintf('TFest (%.1f%%)',           fit_tfest_4mm));
legend('Location','best'); grid on;
xlabel('t (s)'); ylabel('y5 (m)');
title('Model Comparison (R4 → R5) — 4mm test');
improvePlot;
fprintf("4mm done\n");

% ---- 2mm test ----
exp2   = getexp(test_data, 2);
t2     = (0:size(exp2,1)-1) * exp2.Ts;
 
y2_phys        = lsim(TF5(1,:), exp2.InputData(:, y4_idx), t2);
offset_2mm     = mean(exp2.OutputData - y2_phys);
y2_phys_offset = y2_phys + offset_2mm;
fprintf('DC offset 2mm: %.6f\n', offset_2mm)
 
fit_phys_2mm        = nmse(exp2.OutputData, y2_phys);
fit_phys_offset_2mm = nmse(exp2.OutputData, y2_phys_offset);
fprintf('Physical fit 2mm:          %.2f%%\n', fit_phys_2mm)
fprintf('Physical+offset fit 2mm:   %.2f%%\n', fit_phys_offset_2mm)
 
exp2_dec = getexp(test_data_dec, 2);
t2_dec   = (0:size(exp2_dec,1)-1) * exp2_dec.Ts;

[y2_grey_sim,   fit_grey_2mm]   = compare(exp2_dec, sys_grey);
[y2_hybrid_sim, fit_hybrid_2mm] = compare(exp2_dec, sys_hybrid);
[y2_tfest_sim,  fit_tfest_2mm]  = compare(exp2_dec, TFest);
fprintf('Grey-box fit 2mm:          %.2f%%\n', fit_grey_2mm)
fprintf('Hybrid fit 2mm:            %.2f%%\n', fit_hybrid_2mm)
fprintf('TFest fit 2mm:             %.2f%%\n', fit_tfest_2mm)

figure;
plot(t2,     exp2.OutputData,         'k',   'LineWidth', 1.5, 'DisplayName', 'Measured y5'); hold on;
plot(t2,     y2_phys,                 'b', 'LineWidth', 1,   'DisplayName', sprintf('Physical (%.1f%%)',        fit_phys_2mm));
plot(t2,     y2_phys_offset,          'c',   'LineWidth', 1,   'DisplayName', sprintf('Physical+offset (%.1f%%)', fit_phys_offset_2mm));
plot(t2_dec, y2_grey_sim.OutputData,  'r', 'LineWidth', 1,   'DisplayName', sprintf('Grey-box (%.1f%%)',        fit_grey_2mm));
plot(t2_dec, y2_hybrid_sim.OutputData,'m',   'LineWidth', 1,   'DisplayName', sprintf('Hybrid (%.1f%%)',          fit_hybrid_2mm));
plot(t2_dec, y2_tfest_sim.OutputData, 'g',   'LineWidth', 1,   'DisplayName', sprintf('TFest (%.1f%%)',           fit_tfest_2mm));
legend('Location','best'); grid on;
xlabel('t (s)'); ylabel('y5 (m)');
title('Model Comparison (R4 → R5) — 2mm test');
improvePlot;
fprintf("2mm done\n");

%% Check train and test data — R4-R5 with speed
train_data = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest));

%% Estimate Transfer function R4-R5 with speed

cPath = 'models/R4_R5/narrow/speed/model_1_2_and_1_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1 1]; np = [2 2];
    TFest_speed = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest_speed');
    end
else
    TFest_speed = load(append(cPath,'TFest.mat'));
    TFest_speed = TFest_speed.TFest;
end

%% PLOTTING

dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF5(1,:), TFest_speed};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% ===== Compare all models =====
figure;
compare(getexp(test_data_dec, 1), TF5(1,:), TFest, sys_grey, sys_hybrid);
% legend('Data', 'Physical', 'TFest', 'Grey-box', 'Hybrid');
title('Model Comparison (R4 → R5) for 4mm, with speed');
figure;
compare(getexp(test_data_dec, 2), TF5(1,:), TFest, sys_grey, sys_hybrid);
title('Model Comparison (R4 → R5) for 2mm, with speed');

% Test data with velocity for speed model comparison
test_data_speed     = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest));
test_data_speed_dec = resample(test_data_speed, 1, decFactor);

% Compare speed model separately (needs velocity input)
figure;
compare(getexp(test_data_speed_dec, 1), TFest_speed);
title('TFest with Speed — 4mm test');

figure;
compare(getexp(test_data_speed_dec, 2), TFest_speed);
title('TFest with Speed — 2mm test');

%% NL Grey-box estimation for R4-R5 (speed-varying tau)
% Requires R45_nlgrey_model.m in the same directory
% and training data that includes velocity as an input
 
cPath_nl     = 'models/R4_R5/nlgreybox/dec10/';
dLoadOrTrain_nl = 0;   % 1 = train, 0 = load
dSaveModels_nl  = 0;
 
% Training/test data must include velocity as second input
train_data_nl = modify_iddata(all_exps_data(:, [2 3], [5], dExpTrain));
test_data_nl  = modify_iddata(all_exps_data(:, [2 3], [5], dExpTest));
 
% Decimate
train_data_nl_dec = resample(train_data_nl, 1, decFactor);
test_data_nl_dec  = resample(test_data_nl,  1, decFactor);
 
if dLoadOrTrain_nl
 
    % ===== Initial parameters =====
    % Pass as plain numeric cell array
    parameters = {f1_L5; f2_L5; f3_L5; L5};
 
    % Initial states [x1; x2] = [position; velocity] of web lateral motion
    initial_states = [0; 0];
 
    % Create nlgrey model
    % Order: [ny, nu, nx] = [1 output, 2 inputs (y4+velocity), 2 states]
    sys_nl_init = idnlgrey('R45_nlgrey_model', [1 2 2], parameters, initial_states, 0);
 
    sys_nl_init.InputName  = {'y4', 'velocity'};
    sys_nl_init.OutputName = {'y5'};
 
    % Set parameter names after construction
    sys_nl_init.Parameters(1).Name    = 'f1';
    sys_nl_init.Parameters(2).Name    = 'f2';
    sys_nl_init.Parameters(3).Name    = 'f3';
    sys_nl_init.Parameters(4).Name    = 'L5';
 
    % Fix L5 — geometry is known
    sys_nl_init.Parameters(4).Fixed   = true;
 
    % Set bounds
    sys_nl_init.Parameters(1).Minimum = 0;
    sys_nl_init.Parameters(2).Minimum = 0;
 
    % ===== Estimation options =====
    opt_nl = nlgreyestOptions;
    opt_nl.Display = 'on';
    opt_nl.SearchMethod = 'gna';
    opt_nl.SearchOptions.MaxIterations = 20;
 
    % ===== Estimate =====
    sys_nlgrey = nlgreyest(train_data_nl_dec, sys_nl_init, opt_nl);
 
    disp('NL Grey-box estimated parameters [f1, f2, f3, L5]:')
    getpar(sys_nlgrey, 'Value')
 
    % ===== Save =====
    if dSaveModels_nl
        mkdir(cPath_nl);
        save(fullfile(cPath_nl, 'sys_nlgrey.mat'), 'sys_nlgrey');
    end
 
else
    % ===== Load =====
    sys_nlgrey = load(fullfile(cPath_nl, 'sys_nlgrey.mat'));
    sys_nlgrey = sys_nlgrey.sys_nlgrey;
end
 
%% ===== Compare nlgrey vs speed tfest =====
figure;
compare(getexp(test_data_nl_dec, 1), TFest_speed, sys_nlgrey);
title('NL Grey-box vs TFest-Speed — 4mm test');
improvePlot;
 
figure;
compare(getexp(test_data_nl_dec, 2), TFest_speed, sys_nlgrey);
title('NL Grey-box vs TFest-Speed — 2mm test');
improvePlot;

%% Check train and test data — R4-R5 with speed and u1
train_data = modify_iddata(all_exps_data(:, [2 3], [2 5], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [2 3], [2 5], dExpTest));

%% Estimate Transfer function R4-R5 with speed and u1

cPath = 'models/R4_R5/narrow/speed/model_1_2_and_1_2_and_1_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1 1 1]; np = [2 2 2];
    TFest_speed = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest_speed');
    end
else
    TFest_speed = load(append(cPath,'TFest.mat'));
    TFest_speed = TFest_speed.TFest;
end

dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF5(1,:), TFest_speed};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R4\_R5 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R4_R5_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% Define Transfer function R5-R7

f1_L6 = double(vpa(subs(f1, KL, Kgam_*L6)));
f2_L6 = double(vpa(subs(f2, KL, Kgam_*L6)));
f3_L6 = double(vpa(subs(f3, KL, Kgam_*L6)));

numY6_Y5 = [-(f3_L6/tau6) f1_L6/(tau6^2)];
denY6    = [1 (1/tau6)*f2_L6 (1/tau6^2)*f1_L6];
TFY6_Y5  = tf(numY6_Y5, denY6);
TF6      = [TFY6_Y5; s*TFY6_Y5];

f1_L7 = double(vpa(subs(f1, KL, Kgam_*L7)));
f2_L7 = double(vpa(subs(f2, KL, Kgam_*L7)));
f3_L7 = double(vpa(subs(f3, KL, Kgam_*L7)));

numY7_Y6 = [-(f3_L7/tau7) f1_L7/(tau7^2)];
denY7    = [1 (1/tau7)*f2_L7 (1/tau7^2)*f1_L7];
TFY7_Y6  = tf(numY7_Y6, denY7);
TF7      = [TFY7_Y6; s*TFY7_Y6];

TF6.u = 'y5';
TF6.y = {'Y6'; 'dY6/dt'};
TF7.u = 'Y6';
TF7.y = {'y7'; 'dY7/dt'};

TF_67_temp = connect(TF6, TF7, {'y5'}, {'y7'});
TF_67      = minreal(ss(TF_67_temp));
TF_67_tf   = TF6(1)*TF7(1);
TF_67_tf.u = 'y5';
TF_67_tf.y = 'y7';

%% Check train and test data — R5-R7
train_data = modify_iddata(all_exps_data(:, [3 4], [], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [3 4], [], dExpTest));

%% Estimate Transfer function R5-R7 without speed

cPath = 'models/R5_R7/narrow/nospeed/model_2_4/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [2]; np = [4];
    TFest_speed = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest_speed');
    end
else
    TFest_speed = load(append(cPath,'TFest.mat'));
    TFest_speed = TFest_speed.TFest;
end

dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF_67_tf, TFest_speed};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% Check train and test data — R5-R7 with speed
train_data = modify_iddata(all_exps_data(:, [3 4], [5], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [3 4], [5], dExpTest));

%% Estimate Transfer function R5-R7 with speed

cPath = 'models/R5_R7/narrow/speed/model_2_4_and_1_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [2 1]; np = [4 2];
    TFest_speed = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest_speed');
    end
else
    TFest_speed = load(append(cPath,'TFest.mat'));
    TFest_speed = TFest_speed.TFest;
end

dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF_67_tf, TFest_speed};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% Check train and test data — R5-R7 with speed and u1
train_data = modify_iddata(all_exps_data(:, [3 4], [2 5], dExpTrain));
test_data  = modify_iddata(all_exps_data(:, [3 4], [2 5], dExpTest));

%% Estimate Transfer function R5-R7 with speed and u1

cPath = 'models/R5_R7/narrow/speed/model_2_4_and_1_2_and_1_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [2 1 1]; np = [4 2 2];
    TFest_speed = tfest(train_data, np, nz, opt);
    if dSaveModels
        mkdir(cPath);
        save(append(cPath,'TFest.mat'), 'TFest_speed');
    end
else
    TFest_speed = load(append(cPath,'TFest.mat'));
    TFest_speed = TFest_speed.TFest;
end

dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF_67_tf, TFest_speed};
exps_data_all = {test_data, test_data};

for j = 1:length(models)
    model_folder = fullfile(cPath, models{j});
    if ~exist(model_folder, 'dir'); mkdir(model_folder); end
    sim_model = sim_models{j};
    for i = 1:length(dExpTest)
        k = dExpTest(i);
        figure; set(gcf, 'Position', [100, 100, 1600, 800]);
        compare(exps_data_all{j}(:,:,:,i), sim_model);
        if dSaveFigures
            if j == 1
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R5\_R7 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ['R5_R7_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% ========================================================================
%  FUNCTIONS
%  ========================================================================

function new_data = modify_iddata(curr_data2)
    num_experiments = numel(curr_data2.ExperimentName);
    new_inputs  = cell(num_experiments, 1);
    new_outputs = cell(num_experiments, 1);
    for expIdx = 1:num_experiments
        all_inputs  = curr_data2.InputData{expIdx};
        all_outputs = curr_data2.OutputData{expIdx};
        new_inputs{expIdx}  = [all_outputs(:,1), all_inputs];
        new_outputs{expIdx} = all_outputs(:,2:end);
    end
    new_data = iddata(new_outputs, new_inputs, curr_data2.Ts);
    new_data.ExperimentName = curr_data2.ExperimentName;
    new_data.InputName  = [curr_data2.OutputName(1); curr_data2.InputName];
    new_data.OutputName = curr_data2.OutputName(2:end);
end