%% Read in experiments data + Physical model
close all; clear all; clc;

all_exps_data = load('data/all_exps_data.mat');
all_exps_data = all_exps_data.all_exps_data;

% Load Web model
TP_sys_disc_01 = load('mat_files/TP_flat_web_disc_tr_coeffs.mat');
TP_sys_disc_01 = TP_sys_disc_01.TP_sys_disc;

%% Update iddata object

all_exps_data.ExperimentName{strcmp(all_exps_data.ExperimentName,'28_4mm,')} = '28_4mm';

all_exps_data.InputName{strcmp(all_exps_data.InputName,'fEdgeDetectorValue')}            = 'y0';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'ActualPosition')}                 = 'u1';
all_exps_data.InputName{strcmp(all_exps_data.InputName,'AI_PMSSpeedBendingRoller')}      = 'velocity';
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

cExperiments = {'1_2mm', '2_4mm', '3_Splices1', '4_Splices2', '5_Splices3', ...
    '6_fastSplices', '7_slowSplices','8_Step2mm', '9_steps4mm', '10_FastSplices2', ...
    '11_SlowSplices2', '12_NormalFunctioning_Fast', '13_NormalFunctioning_Slow', ...
    '14_notchtest', '15_Step2mm_fast', '16_Step4mm_fast', '17_step2mm_slow', ...
    '18_step4mm_slow', '19_splice_slow', '20_splice_fast', '21_4mm_test2', ...
    '22_2mm_fast', '23_splice', '24_step_gain_1_75','25_step_gain_2_6', ...
    '26_splice_fast','27_4mm_fast', '28_4mm', '29_2mm_test2', '30_2mm'};

cExpNames = {'1\_2mm', '2\_4mm', '3\_Splices1', '4\_Splices2', '5\_Splices3', ...
    '6\_fastSplices', '7\_slowSplices','8\_Step2mm', '9\_steps4mm', '10\_FastSplices2', ...
    '11\_SlowSplices2', '12\_NormalFunctioning\_Fast', '13\_NormalFunctioning\_Slow', ...
    '14\_notchtest', '15_\Step2mm\_fast', '16\_Step4mm\_fast', '17\_step2mm_slow', ...
    '18\_step4mm_slow', '19\_splice\_slow', '20\_splice_fast', '21_\4mm_test2', ...
    '22\_2mm_fast', '23\_splice', '24\_step\_gain\_1\_75', '25\_step\_gain\_2\_6', ...
    '26\_splice\_fast', '27\_4mm_fast', '28\_4mm', '29\_2mm\_test2', '30\_2mm'};

dExperiments = str2double(extractBefore(cExperiments, '_'));

cExpTrain = {'21_4mm_test2', '22_2mm_fast', '24_step_gain_1_75', ...
             '25_step_gain_2_6', '27_4mm_fast', '30_2mm'};
dExpTrain = str2double(extractBefore(cExpTrain, '_'));

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

expNames      = {'21_4mm_test2','22_2mm_fast','24_step_gain_1_75','25_step_gain_2_6', ...
                 '26_splice_fast','27_4mm_fast','28_4mm','29_2mm_test2','30_2mm'};
outNames      = {'y1','y4','y5','y7'};
inNames       = {'y0','u1'};
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

    gt       = {Var_PMEdgePosn, R4, R5, R7};
    sim_cell = {sim_R1, sim_R4, sim_R5, sim_R7};

    if dShowPlots
        figure('Color','w','Name',expName,'NumberTitle','off');
        for s = 1:4
            subplot(4, 1, s);
            plot(time_vector, gt{s}, 'b', time_vector, sim_cell{s}, 'r');
            title(sectionTitles{s});
            ylabel('Position');
            legend('Ground Truth', 'Simulated', 'Location', 'best');
            grid on;
            gof = goodnessOfFit(sim_cell{s}, gt{s}, 'MSE');
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
              ['Roller_Comparison_Experiment_', safeName, '.png']), '-dpng', '-r300');
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

%% Define physical Transfer function R0-R1
%
% Span 1 (R0 to R1):
%   R0 is a passive roller — no out-of-plane displacement, u0 = 0.
%   R1 is an end-pivot guide — out-of-plane displacement = u1, arm = c0.
%
% From Deshpande et al. eq. (3) and the M01 transfer function table:
%
%   Y1(s)/Y0(s) = [-(f3/tau1)*s + f1/tau1^2] / D(s)
%   Y1(s)/u1(s) = [f3*v^2/(L1*c0)]           / D(s)
%   D(s)        = s^2 + (f2/tau1)*s + f1/tau1^2
%
% The Y1/Y0 numerator is the standard passive-span form: a first-order
% numerator with a zero in the right half-plane (non-minimum phase).
% The teammate's implementation incorrectly dropped the -(f3/tau)*s term,
% leaving only the constant f1/tau^2. That error is corrected here.
%
% The Y1/u1 numerator is a constant (no zeros). The coefficient f3 — not
% f2 — arises because R1 is an end-pivot guide: its rotation creates a
% slope discontinuity at the boundary rather than a pure lateral shift,
% which in the Sievers formulation introduces f3 rather than f2. The
% denominator and both shapes factors are evaluated at KL = Kgam_*L1.
%
% Note: c0 = c1 = 0.4 numerically, so there is no arithmetic difference
% between using c0 or c1 here. The distinction is conceptual and follows
% the paper's notation for the M01 transfer function.

f1_L1 = double(vpa(subs(f1, KL, Kgam_*L1)));
f2_L1 = double(vpa(subs(f2, KL, Kgam_*L1)));
f3_L1 = double(vpa(subs(f3, KL, Kgam_*L1)));

numY1_Y0 = [-(f3_L1/tau1), f1_L1/tau1^2];   % first-order numerator, 1 zero
numY1_u1 = f3_L1 * v_^2 / (L1 * c0);        % constant numerator, 0 zeros
denY1    = [1, (f2_L1/tau1), (f1_L1/tau1^2)];

TFY1_Y0 = tf(numY1_Y0, denY1);
TFY1_u1 = tf(numY1_u1, denY1);

TF_01   = [TFY1_Y0, TFY1_u1];   % 1-output, 2-input transfer matrix
TF_01.u = {'y0', 'u1'};
TF_01.y = {'y1'};

fprintf('Physical model parameters for R0-R1:\n');
fprintf('  KL1   = %.4f\n',  Kgam_*L1);
fprintf('  tau1  = %.4f s\n', tau1);
fprintf('  f1_L1 = %.4f\n',  f1_L1);
fprintf('  f2_L1 = %.4f\n',  f2_L1);
fprintf('  f3_L1 = %.4f\n',  f3_L1);
fprintf('  k1    = %.6f  (f3*v^2/(L1*c0))\n', numY1_u1);
fprintf('  DC gain Y1/Y0 = %.4f  (should be 1 by construction)\n', ...
        dcgain(TFY1_Y0));

%% Check train and test data
%
% For R0-R1, y0 is already an INPUT in all_exps_data (input index 1) and
% y1 is already an OUTPUT (output index 1). No modify_iddata is needed.
% Direct channel selection gives: output y1, inputs [y0, u1].
%
% This contrasts with all downstream scripts (R4-R5, R5-R7, R1-R4) which
% call modify_iddata to promote the first output to the first input position.

train_data = all_exps_data(:, [1], [1 2], dExpTrain);
test_data  = all_exps_data(:, [1], [1 2], dExpTest);

%% Estimate Transfer function R0-R1 without speed
%
% Model orders from the physical transfer function structure (Table 1 of
% Deshpande et al.):
%   Y0 channel: 2 poles, 1 zero
%   u1 channel: 2 poles, 0 zeros

cPath = 'models/R0_R1/narrow/nospeed/model_1_2_and_0_2/';
dLoadOrTrain = 0;
dSaveModels  = 0;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1, 0]; np = [2, 2];
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
dSaveFigures  = 0;
models        = {'physical', 'estimated'};
sim_models    = {TF_01, TFest};
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
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ...
                    ['R0_R1_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_est']);
                exportgraphics(gcf, fullfile(model_folder, ...
                    ['R0_R1_', cExperiments{k},'_est','.png']));
            end
        end
    end
end

%% Grey-box estimation for R0-R1 (physics-informed)
% Requires R01_greybox_model.m in the same directory.
%
% Single span with 2 inputs (y0, u1) and 1 output (y1).
% Uses a 2-state minimal realization with 5 free parameters:
%   theta = [tau1, f1, f2, f3, k1]
%
% The minimal realization is derived by writing the combined ODE:
%   y1_ddot + (f2/tau)*y1_dot + (f1/tau^2)*y1
%       = -(f3/tau)*y0_dot + (f1/tau^2)*y0 + k1*u1
%
% Converting to state space via controller canonical form gives a B matrix
% with a non-trivial entry for the y0 channel (to represent the y0_dot term
% without a feedthrough D):
%   B = [-f3/tau,               0  ]
%       [f1/tau^2+f3*f2/tau^2,  k1 ]
%   C = [1, 0]
%
% k1 is estimated as a free parameter initialised at the physical value
% f3*v^2/(L1*c0). Separating k1 from f3 allows the optimizer to adjust the
% u1 gain independently of the zero location in the Y0 channel, giving more
% flexibility than constraining k1 = f3*v^2/(L1*c0) at all times.

cPath = 'models/R0_R1/greybox_hybrid/dec10/';
dLoadOrTrain = 0;
dSaveModels  = 0;

decFactor      = 10;
train_data_dec = resample(train_data, 1, decFactor);
test_data_dec  = resample(test_data,  1, decFactor);

if dLoadOrTrain

    k1_init = f3_L1 * v_^2 / (L1 * c0);
    theta0  = [tau1; f1_L1; f2_L1; f3_L1; k1_init];

    sys_init = idgrey('R01_greybox_model', theta0, 'c');
    sys_init.InputName  = {'y0', 'u1'};
    sys_init.OutputName = {'y1'};

    sys_init.Structure.Parameters(1).Minimum = 1e-6;  % tau >= 0
    sys_init.Structure.Parameters(2).Minimum = 0;     % f1  >= 0
    sys_init.Structure.Parameters(3).Minimum = 0;     % f2  >= 0
    % f3 (theta(4)): unbounded — can collapse to zero
    % k1 (theta(5)): unbounded — sign carries physical meaning

    opt = greyestOptions;
    opt.Display      = 'on';
    opt.SearchMethod = 'gna';
    opt.SearchOptions.MaxIterations = 20;
    opt.SearchOptions.Tolerance     = 1e-4;

    sys_grey = greyest(train_data_dec, sys_init, opt);

    disp('Grey-box estimated parameters [tau, f1, f2, f3, k1]:')
    disp(sys_grey.Report.Parameters.ParVector)

    % ===== Residual correction =====
    % Simulate the grey-box on the decimated training data, compute the
    % residual (measured minus predicted), then fit a lightweight transfer
    % function to this residual. For a 2-input model, the residual tfest
    % uses np=[1,1], nz=[0,0]: one pole and no zeros per input channel,
    % giving an effective DC gain correction for each channel.
    clear sim
    n_exp = numel(train_data_dec.ExperimentName);
    residual_outputs = cell(n_exp, 1);
    for ei = 1:n_exp
        exp_i  = getexp(train_data_dec, ei);
        simout = sim(sys_grey, exp_i);
        residual_outputs{ei} = exp_i.OutputData - simout.OutputData;
    end

    residual_data = iddata(residual_outputs, train_data_dec.InputData, ...
                           train_data_dec.Ts);
    residual_data.ExperimentName = train_data_dec.ExperimentName;
    residual_data.InputName      = train_data_dec.InputName;
    residual_data.OutputName     = train_data_dec.OutputName;

    sys_resid  = tfest(residual_data, [1 1], [0 0]);
    sys_hybrid = sys_grey + sys_resid;

    % Ensure signal names are preserved after addition
    sys_hybrid.InputName  = {'y0', 'u1'};
    sys_hybrid.OutputName = {'y1'};

    if dSaveModels
        mkdir(cPath);
        save(fullfile(cPath, 'sys_grey.mat'),   'sys_grey');
        save(fullfile(cPath, 'sys_resid.mat'),  'sys_resid');
        save(fullfile(cPath, 'sys_hybrid.mat'), 'sys_hybrid');
    end

else
    sys_grey   = load(fullfile(cPath, 'sys_grey.mat'));
    sys_resid  = load(fullfile(cPath, 'sys_resid.mat'));
    sys_hybrid = load(fullfile(cPath, 'sys_hybrid.mat'));

    sys_grey   = sys_grey.sys_grey;
    sys_resid  = sys_resid.sys_resid;
    sys_hybrid = sys_hybrid.sys_hybrid;
end

%% DC offset analysis
%
% For R0-R1, both y0 and y1 are measured by the same type of sensor (edge
% sensors, not cameras), so calibration mismatch may be smaller than in
% downstream sections. However, the u1 channel introduces its own systematic
% modeling error through the idealised end-pivot boundary condition.
%
% The DC offset here represents any combination of:
%   (1) a small y0-y1 sensor zero-reference mismatch
%   (2) a systematic error in the u1 steady-state gain
% Because u1 is non-zero during the step experiments, both contributions
% are entangled in the single offset number printed below. The physical
% model's DC gain from y0 is 1 by construction; the DC gain from u1 is
% k1 * tau1^2 / f1_L1 (the DC value of H_u1).

exp1   = getexp(test_data, 1);
t1     = (0:size(exp1,1)-1) * exp1.Ts;
y1_sim_4mm  = lsim(TF_01, exp1.InputData, t1);
offset_4mm  = mean(exp1.OutputData - y1_sim_4mm);
fprintf('Optimal DC offset for 4mm: %.4f mm\n', offset_4mm)

exp2   = getexp(test_data, 2);
t2     = (0:size(exp2,1)-1) * exp2.Ts;
y1_sim_2mm  = lsim(TF_01, exp2.InputData, t2);
offset_2mm  = mean(exp2.OutputData - y1_sim_2mm);
fprintf('Optimal DC offset for 2mm: %.4f mm\n', offset_2mm)

y1_corrected_4mm = y1_sim_4mm + offset_4mm;
y1_corrected_2mm = y1_sim_2mm + offset_2mm;

fit_4mm = 100*(1 - norm(exp1.OutputData - y1_corrected_4mm) / ...
               norm(exp1.OutputData - mean(exp1.OutputData)));
fit_2mm = 100*(1 - norm(exp2.OutputData - y1_corrected_2mm) / ...
               norm(exp2.OutputData - mean(exp2.OutputData)));

fprintf('Physical + offset fit 4mm: %.2f%%\n', fit_4mm)
fprintf('Physical + offset fit 2mm: %.2f%%\n', fit_2mm)

%% ===== Compare all models =====
figure;
compare(getexp(test_data_dec, 1), TF_01, TFest, sys_grey, sys_hybrid);
title('Model Comparison (R0 → R1) for 4mm');
figure;
compare(getexp(test_data_dec, 2), TF_01, TFest, sys_grey, sys_hybrid);
title('Model Comparison (R0 → R1) for 2mm');

%% EXTRA PLOTTING

nmse = @(y, yhat) 100*(1 - norm(y - yhat)/norm(y - mean(y)));

% ---- 4mm test ----
exp1   = getexp(test_data, 1);
t1     = (0:size(exp1,1)-1) * exp1.Ts;

y1_phys_4mm        = lsim(TF_01, exp1.InputData, t1);
offset_4mm         = mean(exp1.OutputData - y1_phys_4mm);
y1_phys_offset_4mm = y1_phys_4mm + offset_4mm;

fit_phys_4mm        = nmse(exp1.OutputData, y1_phys_4mm);
fit_phys_offset_4mm = nmse(exp1.OutputData, y1_phys_offset_4mm);
fprintf('DC offset 4mm:              %.6f mm\n', offset_4mm)
fprintf('Physical fit 4mm:           %.2f%%\n',  fit_phys_4mm)
fprintf('Physical+offset fit 4mm:    %.2f%%\n',  fit_phys_offset_4mm)

exp1_dec = getexp(test_data_dec, 1);
t1_dec   = (0:size(exp1_dec,1)-1) * exp1_dec.Ts;

[y1_grey_sim_4mm,   fit_grey_4mm]   = compare(exp1_dec, sys_grey);
[y1_hybrid_sim_4mm, fit_hybrid_4mm] = compare(exp1_dec, sys_hybrid);
[y1_tfest_sim_4mm,  fit_tfest_4mm]  = compare(exp1_dec, TFest);
fprintf('Grey-box fit 4mm:           %.2f%%\n', fit_grey_4mm)
fprintf('Hybrid fit 4mm:             %.2f%%\n', fit_hybrid_4mm)
fprintf('TFest fit 4mm:              %.2f%%\n', fit_tfest_4mm)

figure;
plot(t1,     exp1.OutputData,                  'k', 'LineWidth', 1.5, ...
     'DisplayName', 'Measured y1'); hold on;
plot(t1,     y1_phys_4mm,                      'b', 'LineWidth', 1, ...
     'DisplayName', sprintf('Physical (%.1f%%)',        fit_phys_4mm));
plot(t1,     y1_phys_offset_4mm,               'c', 'LineWidth', 1, ...
     'DisplayName', sprintf('Physical+offset (%.1f%%)', fit_phys_offset_4mm));
plot(t1_dec, y1_grey_sim_4mm.OutputData,       'r', 'LineWidth', 1, ...
     'DisplayName', sprintf('Grey-box (%.1f%%)',        fit_grey_4mm));
plot(t1_dec, y1_hybrid_sim_4mm.OutputData,     'm', 'LineWidth', 1, ...
     'DisplayName', sprintf('Hybrid (%.1f%%)',          fit_hybrid_4mm));
plot(t1_dec, y1_tfest_sim_4mm.OutputData,      'g', 'LineWidth', 1, ...
     'DisplayName', sprintf('TFest (%.1f%%)',           fit_tfest_4mm));
legend('Location','best'); grid on;
xlabel('t (s)'); ylabel('y1 (mm)');
title('Model Comparison (R0 → R1) — 4mm test');
improvePlot;
fprintf("4mm done\n");

% ---- 2mm test ----
exp2   = getexp(test_data, 2);
t2     = (0:size(exp2,1)-1) * exp2.Ts;

y1_phys_2mm        = lsim(TF_01, exp2.InputData, t2);
offset_2mm         = mean(exp2.OutputData - y1_phys_2mm);
y1_phys_offset_2mm = y1_phys_2mm + offset_2mm;

fit_phys_2mm        = nmse(exp2.OutputData, y1_phys_2mm);
fit_phys_offset_2mm = nmse(exp2.OutputData, y1_phys_offset_2mm);
fprintf('DC offset 2mm:              %.6f mm\n', offset_2mm)
fprintf('Physical fit 2mm:           %.2f%%\n',  fit_phys_2mm)
fprintf('Physical+offset fit 2mm:    %.2f%%\n',  fit_phys_offset_2mm)

exp2_dec = getexp(test_data_dec, 2);
t2_dec   = (0:size(exp2_dec,1)-1) * exp2_dec.Ts;

[y1_grey_sim_2mm,   fit_grey_2mm]   = compare(exp2_dec, sys_grey);
[y1_hybrid_sim_2mm, fit_hybrid_2mm] = compare(exp2_dec, sys_hybrid);
[y1_tfest_sim_2mm,  fit_tfest_2mm]  = compare(exp2_dec, TFest);
fprintf('Grey-box fit 2mm:           %.2f%%\n', fit_grey_2mm)
fprintf('Hybrid fit 2mm:             %.2f%%\n', fit_hybrid_2mm)
fprintf('TFest fit 2mm:              %.2f%%\n', fit_tfest_2mm)

figure;
plot(t2,     exp2.OutputData,                  'k', 'LineWidth', 1.5, ...
     'DisplayName', 'Measured y1'); hold on;
plot(t2,     y1_phys_2mm,                      'b', 'LineWidth', 1, ...
     'DisplayName', sprintf('Physical (%.1f%%)',        fit_phys_2mm));
plot(t2,     y1_phys_offset_2mm,               'c', 'LineWidth', 1, ...
     'DisplayName', sprintf('Physical+offset (%.1f%%)', fit_phys_offset_2mm));
plot(t2_dec, y1_grey_sim_2mm.OutputData,       'r', 'LineWidth', 1, ...
     'DisplayName', sprintf('Grey-box (%.1f%%)',        fit_grey_2mm));
plot(t2_dec, y1_hybrid_sim_2mm.OutputData,     'm', 'LineWidth', 1, ...
     'DisplayName', sprintf('Hybrid (%.1f%%)',          fit_hybrid_2mm));
plot(t2_dec, y1_tfest_sim_2mm.OutputData,      'g', 'LineWidth', 1, ...
     'DisplayName', sprintf('TFest (%.1f%%)',           fit_tfest_2mm));
legend('Location','best'); grid on;
xlabel('t (s)'); ylabel('y1 (mm)');
title('Model Comparison (R0 → R1) — 2mm test');
improvePlot;
fprintf("2mm done\n");

%% Check train and test data — R0-R1 with speed
% Adds velocity as a third input channel (input index 5 in all_exps_data).
train_data = all_exps_data(:, [1], [1 2 5], dExpTrain);
test_data  = all_exps_data(:, [1], [1 2 5], dExpTest);

%% Estimate Transfer function R0-R1 with speed
%
% Adds a 2nd-order, 1-zero transfer function from velocity to y1.
% As for all downstream sections, velocity is approximately constant within
% each experiment, so the velocity channel primarily functions as a
% per-experiment DC bias lookup rather than capturing genuine speed-dependent
% dynamics. See the Interpretation section of the README for detail.

cPath = 'models/R0_R1/narrow/speed/model_1_2_and_0_2_and_1_2/';
dLoadOrTrain = 1;
dSaveModels  = 1;

if dLoadOrTrain
    opt = tfestOptions;
    opt.Display = 'on';
    opt.EnforceStability = true;
    nz = [1, 0, 1]; np = [2, 2, 2];
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
sim_models    = {TF_01, TFest_speed};
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
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_physical']);
                exportgraphics(gcf, fullfile(model_folder, ...
                    ['R0_R1_', cExperiments{k},'_physical','.png']));
            elseif j == 2
                title('Simulated Response Comparison');
                subtitle(['R0\_R1 Experiment: ', cExpNames{k}, '\_speed']);
                exportgraphics(gcf, fullfile(model_folder, ...
                    ['R0_R1_', cExperiments{k},'_speed','.png']));
            end
        end
    end
end

%% ===== Compare all models (no-speed grey-box for context) =====
figure;
compare(getexp(test_data_dec, 1), TF_01, TFest, sys_grey, sys_hybrid);
title('Model Comparison (R0 → R1) for 4mm, no-speed models');
figure;
compare(getexp(test_data_dec, 2), TF_01, TFest, sys_grey, sys_hybrid);
title('Model Comparison (R0 → R1) for 2mm, no-speed models');

% Speed model evaluated on its own (speed) test data
test_data_speed     = all_exps_data(:, [1], [1 2 5], dExpTest);
test_data_speed_dec = resample(test_data_speed, 1, decFactor);

figure;
compare(getexp(test_data_speed_dec, 1), TFest_speed);
title('TFest with Speed — 4mm test');

figure;
compare(getexp(test_data_speed_dec, 2), TFest_speed);
title('TFest with Speed — 2mm test');

%% NL Grey-box estimation for R0-R1 (speed-varying tau)
% Requires R01_nlgrey_model.m in the same directory.
%
% tau = L1/v(t) and k1 = f3*v(t)^2/(L1*c0) are recomputed at each timestep.
% Uses a 4-state parallel realization (cleaner ODE than the 2-state minimal
% form, which would require time-varying B matrix entries for the y0_dot term):
%   x(1:2) track the y0 channel — dx/dt = A2(tau)*x + [0;1]*y0
%   x(3:4) track the u1 channel — dx/dt = A2(tau)*x + [0;1]*u1
%   y1 = f1/tau^2*x(1) - f3/tau*x(2) + k1*x(3)
%
% Free parameters: f1, f2, f3 (3 parameters)
% Fixed parameters: L1, c0 (known geometry)
%
% Note on tractability: R0-R1 has 4 states (same as R5-R7 which was
% computationally prohibitive) but only 3 free parameters vs 6 for R5-R7.
% The tau1 ≈ 2.47 s time constant is large, meaning the ODE integrator
% takes larger steps and estimation may be faster than for shorter spans.
% It is worth attempting with MaxIterations = 10 before committing to more.

cPath_nl        = 'models/R0_R1/nlgreybox/dec10/';
dLoadOrTrain_nl = 0;   % set to 1 cautiously — run time may be long
dSaveModels_nl  = 0;

train_data_nl = all_exps_data(:, [1], [1 2 5], dExpTrain);
test_data_nl  = all_exps_data(:, [1], [1 2 5], dExpTest);

train_data_nl_dec = resample(train_data_nl, 1, decFactor);
test_data_nl_dec  = resample(test_data_nl,  1, decFactor);

%% SEPARATE

if dLoadOrTrain_nl

    parameters     = {f1_L1; f2_L1; f3_L1; L1; c0};
    initial_states = zeros(4, 1);

    % [ny, nu, nx] = [1 output, 3 inputs (y0, u1, velocity), 4 states]
    sys_nl_init = idnlgrey('R01_nlgrey_model', [1 3 4], parameters, ...
                            initial_states, 0);

    sys_nl_init.InputName  = {'y0', 'u1', 'velocity'};
    sys_nl_init.OutputName = {'y1'};

    sys_nl_init.Parameters(1).Name = 'f1';
    sys_nl_init.Parameters(2).Name = 'f2';
    sys_nl_init.Parameters(3).Name = 'f3';
    sys_nl_init.Parameters(4).Name = 'L1';
    sys_nl_init.Parameters(5).Name = 'c0';

    sys_nl_init.Parameters(4).Fixed = true;  % L1: known geometry
    sys_nl_init.Parameters(5).Fixed = true;  % c0: known geometry

    sys_nl_init.Parameters(1).Minimum = 0;   % f1 >= 0
    sys_nl_init.Parameters(2).Minimum = 0;   % f2 >= 0
    % f3: unbounded — can collapse to zero

    opt_nl = nlgreyestOptions;
    opt_nl.Display = 'on';
    opt_nl.SearchMethod = 'gna';
    opt_nl.SearchOptions.MaxIterations = 20;

    sys_nlgrey = nlgreyest(train_data_nl_dec, sys_nl_init, opt_nl);

    disp('NL Grey-box estimated parameters [f1, f2, f3, L1, c0]:')
    getpar(sys_nlgrey, 'Value')

    if dSaveModels_nl
        mkdir(cPath_nl);
        save(fullfile(cPath_nl, 'sys_nlgrey.mat'), 'sys_nlgrey');
    end

else
    sys_nlgrey = load(fullfile(cPath_nl, 'sys_nlgrey.mat'));
    sys_nlgrey = sys_nlgrey.sys_nlgrey;
end

%% ===== Compare nlgrey vs speed tfest =====
figure;
compare(getexp(test_data_nl_dec, 1), TFest_speed);
title('NL Grey-box vs TFest-Speed — 4mm test');
improvePlot;

figure;
compare(getexp(test_data_nl_dec, 2), TFest_speed);
title('NL Grey-box vs TFest-Speed — 2mm test');
improvePlot;