function [A, B, C, D] = R01_greybox_model(theta, Ts, varargin)
% Grey-box state-space model for the R0-R1 web span.
%
% Inputs (2):  y0, u1
% Output (1):  y1
% States (2):  minimal realization (controller canonical form)
%
% Parameters (5):
%   theta(1) = tau   transport time constant = L1/v
%   theta(2) = f1    beam shape factor f1(KL1)
%   theta(3) = f2    beam shape factor f2(KL1)
%   theta(4) = f3    beam shape factor f3(KL1)
%   theta(5) = k1    u1 channel DC gain, initialised at f3*v^2/(L1*c0)
%
% Transfer functions implemented:
%   Y1/Y0(s) = [(-f3/tau)*s + f1/tau^2] / D(s)
%   Y1/u1(s) = k1                        / D(s)
%   D(s)     = s^2 + (f2/tau)*s + f1/tau^2
%
% Minimal 2-state realization is derived by casting the combined ODE:
%   y1_ddot + a1*y1_dot + a0*y1 = b1_y0*y0_dot + b0_y0*y0 + k1*u1
% into controller canonical form, which eliminates the y0_dot feedthrough
% term via the B matrix:
%   B_y0 = [b1_y0;  b0_y0 - b1_y0*a1]
%   B_u1 = [0;      k1]
% where a0 = f1/tau^2, a1 = f2/tau, b1_y0 = -f3/tau, b0_y0 = f1/tau^2.

    tau = max(theta(1), 1e-6);
    f1  = max(theta(2), 0);
    f2  = max(theta(3), 0);
    f3  = theta(4);
    k1  = theta(5);

    a0    = f1 / tau^2;
    a1    = f2 / tau;
    b1_y0 = -f3 / tau;
    b0_y0 =  f1 / tau^2;

    A = [0,  1; -a0, -a1];
    B = [b1_y0,            0; ...
         b0_y0 - b1_y0*a1, k1];
    C = [1, 0];
    D = [0, 0];
end