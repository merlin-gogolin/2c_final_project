function [A, B, C, D] = R14_greybox_model(theta, Ts, varargin)
% Grey-box state-space model for the R1-R4 web span (three chained spans).
%
% Inputs (2):  y1, u1
% Output (1):  y4
% States (8):  x(1:2) — Y1->Y2 channel (span 2)
%              x(3:4) — u1->Y2 channel (span 2)
%              x(5:6) — Y2->Y3 span (span 3)
%              x(7:8) — Y3->Y4 span (span 4)
%
% The Y1 and u1 paths through span 2 need separate 2-state blocks
% because they have different output (C) vectors and cannot share states.
%
% Parameters (13):
%   theta(1)  = tau2   transport time constant, span R1-R2
%   theta(2)  = f1_2   shape factor f1, span R1-R2
%   theta(3)  = f2_2   shape factor f2, span R1-R2
%   theta(4)  = f3_2   shape factor f3, span R1-R2
%   theta(5)  = k2     u1 gain into Y2 — free parameter, physically
%                      ≈ f3_2 * v^2 / (L2 * c1) at nominal speed
%   theta(6)  = tau3   transport time constant, span R2-R3
%   theta(7)  = f1_3   shape factor f1, span R2-R3
%   theta(8)  = f2_3   shape factor f2, span R2-R3
%   theta(9)  = f3_3   shape factor f3, span R2-R3
%   theta(10) = tau4   transport time constant, span R3-R4
%   theta(11) = f1_4   shape factor f1, span R3-R4
%   theta(12) = f2_4   shape factor f2, span R3-R4
%   theta(13) = f3_4   shape factor f3, span R3-R4

    tau2 = max(theta(1),  1e-6);
    f1_2 = max(theta(2),  0);
    f2_2 = max(theta(3),  0);
    f3_2 = theta(4);
    k2   = theta(5);

    tau3 = max(theta(6),  1e-6);
    f1_3 = max(theta(7),  0);
    f2_3 = max(theta(8),  0);
    f3_3 = theta(9);

    tau4 = max(theta(10), 1e-6);
    f1_4 = max(theta(11), 0);
    f2_4 = max(theta(12), 0);
    f3_4 = theta(13);

    % ---- Span 2 (R1-R2) ----
    % Shared denominator A matrix
    A2 = [0, 1; -f1_2/tau2^2, -f2_2/tau2];

    % Y1 -> Y2 channel:  H = [(-f3_2/tau2)*s + f1_2/tau2^2] / D2(s)
    %   Realization: x_dot = A2*x + [0;1]*Y1,  y = [f1_2/tau2^2, -f3_2/tau2]*x
    B2_Y1 = [0; 1];
    C2_Y1 = [f1_2/tau2^2, -f3_2/tau2];

    % u1 -> Y2 channel:  H = k2 / D2(s)
    %   Realization: x_dot = A2*x + [0;k2]*u1,  y = [1, 0]*x
    B2_u1 = [0; k2];
    C2_u1 = [1, 0];

    % ---- Span 3 (R2-R3, passive) ----
    A3 = [0, 1; -f1_3/tau3^2, -f2_3/tau3];
    B3 = [0; 1];
    C3 = [f1_3/tau3^2, -f3_3/tau3];

    % ---- Span 4 (R3-R4, passive) ----
    A4 = [0, 1; -f1_4/tau4^2, -f2_4/tau4];
    B4 = [0; 1];
    C4 = [f1_4/tau4^2, -f3_4/tau4];

    % ---- Assemble full 8-state system ----
    %
    % State order: [x_Y1(1:2), x_u1(3:4), x3(5:6), x4(7:8)]
    %
    % Dynamics:
    %   x_Y1_dot = A2 * x_Y1  +  B2_Y1 * y1
    %   x_u1_dot = A2 * x_u1  +  B2_u1 * u1
    %   Y2       = C2_Y1 * x_Y1  +  C2_u1 * x_u1
    %   x3_dot   = A3 * x3  +  B3 * Y2   (expands to use x_Y1, x_u1)
    %   Y3       = C3 * x3
    %   x4_dot   = A4 * x4  +  B4 * Y3   (expands to use x3)
    %   y4       = C4 * x4

    z22 = zeros(2, 2);
    z21 = zeros(2, 1);

    A = [A2,          z22,        z22,   z22;
         z22,         A2,         z22,   z22;
         B3*C2_Y1,    B3*C2_u1,   A3,    z22;
         z22,         z22,        B4*C3, A4];

    B = [B2_Y1, z21;
         z21,   B2_u1;
         z21,   z21;
         z21,   z21];

    C = [zeros(1,2), zeros(1,2), zeros(1,2), C4];

    D = [0, 0];
end