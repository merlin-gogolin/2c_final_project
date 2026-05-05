function [A,B,C,D] = R45_greybox_model(theta, Ts, varargin)
    tau = max(theta(1), 1e-6);  % guard against zero
    f1  = max(theta(2), 0);
    f2  = max(theta(3), 0);
    f3  = theta(4);

    A = [0,          1      ; ...
        -f1/tau^2,  -f2/tau ];
    B = [0; 1];
    C = [f1/tau^2,  -f3/tau];
    D = 0;
end