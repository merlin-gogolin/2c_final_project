function [dx, y] = R01_nlgrey_model(t, x, u, f1, f2, f3, L1, c0, varargin)
% Nonlinear grey-box ODE for the R0-R1 span with velocity-varying tau.
%
% tau = L1/v(t) and k1 = f3*v(t)^2/(L1*c0) are recomputed at every timestep
% from the measured web velocity signal.
%
% Inputs (3):  u(1) = y0,  u(2) = u1,  u(3) = velocity (raw sensor units)
% Output (1):  y1
% States (4):  x(1:2) = y0-channel states,  x(3:4) = u1-channel states
%
% The 4-state parallel realization uses two copies of the same 2-state
% subsystem running side by side with different inputs and a combined output:
%   dx_y0 = A2(tau)*x(1:2) + [0;1]*y0
%   dx_u1 = A2(tau)*x(3:4) + [0;1]*u1
%   y1    = [f1/tau^2, -f3/tau] * x(1:2)  +  k1 * x(3)
%
% This is preferred over the minimal 2-state form for the NL case because
% the minimal form's B matrix entries (b0_y0 - b1_y0*a1) depend on tau,
% making the ODE harder to express cleanly when tau varies each timestep.
%
% Free parameters:   f1, f2, f3   (f1>=0, f2>=0, f3 unbounded)
% Fixed parameters:  L1, c0       (set .Fixed=true in idnlgrey definition)

    y0_in = u(1);
    u1_in = u(2);
    v_sig = u(3);

    v   = max(v_sig * 0.0875, 1e-3);  % convert raw units to m/s
    tau = L1 / v;
    k1  = f3 * v^2 / (L1 * c0);      % updated each timestep

    A2 = [0, 1; -f1/tau^2, -f2/tau];

    dx_y0 = A2 * x(1:2) + [0; 1] * y0_in;
    dx_u1 = A2 * x(3:4) + [0; 1] * u1_in;

    dx = [dx_y0; dx_u1];

    % Output combines both channels using time-varying coefficients
    y  = (f1/tau^2) * x(1) + (-f3/tau) * x(2) + k1 * x(3);
end