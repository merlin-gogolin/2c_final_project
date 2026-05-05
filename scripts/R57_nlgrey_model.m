function [dx, y] = R57_nlgrey_model(t, x, u, f1_6, f2_6, f3_6, f1_7, f2_7, f3_7, L6, L7, varargin)
    v    = max(u(2) * 0.0875, 1e-3);
    tau6 = L6 / v;
    tau7 = L7 / v;

    A1 = [0, 1; -f1_6/tau6^2, -f2_6/tau6];
    B1 = [0; 1];
    C1 = [f1_6/tau6^2, -f3_6/tau6];

    A2 = [0, 1; -f1_7/tau7^2, -f2_7/tau7];
    B2 = [0; 1];
    C2 = [f1_7/tau7^2, -f3_7/tau7];

    A_mat = [A1, zeros(2,2); B2*C1, A2];
    B_mat = [B1; zeros(2,1)];
    C_mat = [zeros(1,2), C2];

    dx = A_mat*x + B_mat*u(1);
    y  = C_mat*x;
end