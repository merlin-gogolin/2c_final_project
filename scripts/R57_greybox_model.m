function [A,B,C,D] = R57_greybox_model(theta, Ts, varargin)
    % Two chained spans: R5-R6 and R6-R7
    tau6 = max(theta(1), 1e-6);
    f1_6 = max(theta(2), 0);
    f2_6 = max(theta(3), 0);
    f3_6 = theta(4);
    tau7 = max(theta(5), 1e-6);
    f1_7 = max(theta(6), 0);
    f2_7 = max(theta(7), 0);
    f3_7 = theta(8);

    A1 = [0, 1; -f1_6/tau6^2, -f2_6/tau6];
    B1 = [0; 1];
    C1 = [f1_6/tau6^2, -f3_6/tau6];

    A2 = [0, 1; -f1_7/tau7^2, -f2_7/tau7];
    B2 = [0; 1];
    C2 = [f1_7/tau7^2, -f3_7/tau7];

    A = [A1, zeros(2,2); B2*C1, A2];
    B = [B1; zeros(2,1)];
    C = [zeros(1,2), C2];
    D = 0;
end