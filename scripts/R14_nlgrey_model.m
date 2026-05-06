function [dx, y] = R14_nlgrey_model(t, x, u, ...
        f1_2, f2_2, f3_2, f1_3, f2_3, f3_3, f1_4, f2_4, f3_4, ...
        L2, L3, L4, c1, varargin)
% Nonlinear grey-box ODE for the R1-R4 span with velocity-varying tau.
% tau_i = L_i / v(t) is recomputed at every timestep.
% The u1 gain k2 = f3_2 * v(t)^2 / (L2 * c1) is also updated each step.
%
% Inputs (3):  u(1) = y1,  u(2) = u1,  u(3) = velocity
% Output (1):  y4
% States (8):  x(1:2) = x_Y1  (Y1->Y2 channel, span 2)
%              x(3:4) = x_u1  (u1->Y2 channel, span 2)
%              x(5:6) = x3    (Y2->Y3, span 3)
%              x(7:8) = x4    (Y3->Y4, span 4)
%
% Free parameters:   f1_2, f2_2, f3_2, f1_3, f2_3, f3_3, f1_4, f2_4, f3_4
% Fixed parameters:  L2, L3, L4, c1  (set .Fixed = true in idnlgrey)

    Y1       = u(1);
    u1_ctrl  = u(2);
    velocity = u(3);

    v    = max(velocity * 0.0875, 1e-3);  % convert to m/s
    tau2 = L2 / v;
    tau3 = L3 / v;
    tau4 = L4 / v;
    k2   = f3_2 * v^2 / (L2 * c1);  % recomputed at each timestep

    % ---- Span 2 matrices ----
    A2    = [0, 1; -f1_2/tau2^2, -f2_2/tau2];
    B2_Y1 = [0; 1];
    B2_u1 = [0; k2];
    C2_Y1 = [f1_2/tau2^2, -f3_2/tau2];
    C2_u1 = [1, 0];

    % ---- Span 3 matrices ----
    A3 = [0, 1; -f1_3/tau3^2, -f2_3/tau3];
    B3 = [0; 1];
    C3 = [f1_3/tau3^2, -f3_3/tau3];

    % ---- Span 4 matrices ----
    A4 = [0, 1; -f1_4/tau4^2, -f2_4/tau4];
    B4 = [0; 1];
    C4 = [f1_4/tau4^2, -f3_4/tau4];

    % ---- Extract state sub-vectors ----
    x_Y1 = x(1:2);
    x_u1 = x(3:4);
    x3   = x(5:6);
    x4   = x(7:8);

    % ---- Intermediate signals ----
    Y2 = C2_Y1 * x_Y1 + C2_u1 * x_u1;  % combines both span-2 paths
    Y3 = C3 * x3;

    % ---- State derivatives ----
    dx_Y1 = A2 * x_Y1 + B2_Y1 * Y1;
    dx_u1 = A2 * x_u1 + B2_u1 * u1_ctrl;
    dx3   = A3 * x3   + B3    * Y2;
    dx4   = A4 * x4   + B4    * Y3;

    dx = [dx_Y1; dx_u1; dx3; dx4];
    y  = C4 * x4;
end