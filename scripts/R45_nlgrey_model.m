function [dx, y] = R45_nlgrey_model(t, x, u, f1, f2, f3, L5, varargin)
    v_raw  = max(u(2), 1e-3);
    v      = v_raw * 0.0875;   % convert to m/s
    tau    = L5 / v;

    A = [0, 1; -f1/tau^2, -f2/tau];
    B = [0; 1];
    C = [f1/tau^2, -f3/tau];

    dx = A*x + B*u(1);
    y  = C*x;
end