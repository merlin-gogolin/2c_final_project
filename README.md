# Web Lateral Dynamics — Linear Model Estimation

## Overview

This repository contains MATLAB code for modelling the lateral dynamics of a moving web
(thin flexible sheet) through a series of rollers in an industrial web-guiding system.
The goal is to identify transfer functions between roller sensor positions (y4 to y5,
y5 to y7, etc.) and evaluate how well physics-based, black-box, and hybrid models
describe the real system.

The main script is `linear_models_est.m`. Everything else supports it.

---

## Main Script: `linear_models_est.m`

This is the only file you need to run. It is organised into labelled sections (`%%`)
that build on each other and should be run **in order**, section by section
(`Ctrl+Enter` in MATLAB).

### What it does

| Section | Description |
|---|---|
| Read in data | Loads experimental iddata and the pre-computed physical web model |
| Update iddata | Renames signals to consistent short names (y0, u1, y1, y4, y5, y7, velocity, setpoint) |
| Plot experiments | Visualises all 10 new experiments (21-30) |
| Train/Test Split | Defines training experiments (21, 22, 24, 25, 27, 30) and test experiments (28, 29) |
| Physical model plots | Simulates the full web physical model against selected experiments |
| Physical model setup | Computes beam equation parameters from first principles |
| R4 to R5 (no speed) | Black-box tfest and physical model comparison for the R4-R5 span |
| R4 to R5 grey-box/hybrid | Physics-informed greyest + residual tfest hybrid model |
| DC offset analysis | Shows that a tiny DC offset (~0.0002 mm) explains most of the physical model error |
| Extra plotting | Custom side-by-side comparison of all models with reported fit percentages |
| R4 to R5 (with speed) | Black-box tfest using velocity as a second input |
| R4 to R5 (speed + u1) | Black-box tfest using velocity and actuator position as inputs |
| NL grey-box | Nonlinear grey-box where tau = L/v(t) varies with measured speed |
| R5 to R7 | Same model progression applied to the R5-R7 span |

### Key findings (R4 to R5 span)

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 89.0% | 65.3% |
| Physical + DC offset | 96.3% | 93.1% |
| Black-box tfest (Y4 only) | 89.6% | 70.2% |
| Grey-box (greyest) | 89.2% | 65.6% |
| Hybrid (grey-box + residual) | 96.3% | 94.3% |
| Black-box tfest (Y4 + velocity) | ~97.5% | ~95.0% |

The physical beam equations capture the dynamics well. The dominant error is a small
DC offset, not missing dynamics. The hybrid model corrects this without sacrificing
physical interpretability.

---

## Dependencies

### MATLAB Toolboxes

- System Identification Toolbox (required)
- Control System Toolbox (required)
- Optimization Toolbox (optional — only needed if using `lsqnonlin` search method)

### Helper function files

These must be in the same directory as `linear_models_est.m` or on the MATLAB path.

**`R45_greybox_model.m`** — State-space function for `greyest`. Implements the beam
equation structure:

    function [A,B,C,D] = R45_greybox_model(theta, Ts, varargin)
        tau = max(theta(1), 1e-6);
        f1  = max(theta(2), 0);
        f2  = max(theta(3), 0);
        f3  = theta(4);
        A = [0, 1; -f1/tau^2, -f2/tau];
        B = [0; 1];
        C = [f1/tau^2, -f3/tau];
        D = 0;
    end

**`R45_nlgrey_model.m`** — ODE function for `nlgreyest`. tau = L/v(t) is recomputed
at each timestep from the live velocity input:

    function [dx, y] = R45_nlgrey_model(t, x, u, f1, f2, f3, L5, varargin)
        v   = max(u(2) * 0.0875, 1e-3);
        tau = L5 / v;
        A = [0, 1; -f1/tau^2, -f2/tau];
        B = [0; 1];
        C = [f1/tau^2, -f3/tau];
        dx = A*x + B*u(1);
        y  = C*x;
    end

---

## Directory Structure

    .
    ├── linear_models_est.m              <- main script (run this)
    ├── R45_greybox_model.m              <- required helper
    ├── R45_nlgrey_model.m               <- required helper
    │
    ├── data/                            <- FILL IN (see below)
    │   └── all_exps_data.mat
    │
    ├── mat_files/                       <- FILL IN (see below)
    │   └── TP_flat_web_disc_tr_coeffs.mat
    │
    ├── models/                          <- auto-generated on first train run
    │   ├── R4_R5/
    │   │   ├── narrow/nospeed/model_1_2/
    │   │   ├── narrow/speed/model_1_2_and_1_2/
    │   │   ├── narrow/speed/model_1_2_and_1_2_and_1_2/
    │   │   ├── greybox_hybrid/dec10/
    │   │   └── nlgreybox/dec10/
    │   └── R5_R7/
    │       ├── narrow/nospeed/model_2_4/
    │       ├── narrow/speed/model_2_4_and_1_2/
    │       └── narrow/speed/model_2_4_and_1_2_and_1_2/
    │
    └── plots/                           <- auto-generated if save flags are on
        └── physical_model/

---

## Data Requirements

To replicate results, you need to provide two files.

### `data/all_exps_data.mat`

A MATLAB System Identification Toolbox `iddata` object containing all 30 experiments,
sampled at 100 Hz, with the following signals:

**Outputs:** `y_R1`, `y_R4`, `y_R5`, `y_R7`
(lateral web position at rollers 1, 4, 5, 7, in mm)

**Inputs:** `fEdgeDetectorValue`, `ActualPosition`, `AI_PMSSpeedBendingRoller`,
`PID_WebEdgePositionControl_SP`

**Experiments:** Named `1_2mm` through `30_2mm`.

### `mat_files/TP_flat_web_disc_tr_coeffs.mat`

A pre-computed discrete-time state-space model (`TP_sys_disc`) of the full web
transport system, used for physical model validation plots in the early sections
of the script.

---

## Running the Script

1. Place `linear_models_est.m`, `R45_greybox_model.m`, and `R45_nlgrey_model.m`
   in the same folder.
2. Fill in `data/` and `mat_files/` as described above.
3. Open `linear_models_est.m` in MATLAB.
4. Run sections in order using `Ctrl+Enter`.
5. By default all `dLoadOrTrain` flags are set to `0` (load pre-saved models).
   To retrain, set `dLoadOrTrain = 1` and `dSaveModels = 1` in the relevant
   section before running it. Models are saved under `models/` automatically.

The grey-box section decimates training data by a factor of 10 (100 Hz to 10 Hz)
before estimation to keep computation tractable. Expect the `greyest` call to
take a few minutes.

---

## Physical Model Background

The web is modelled as a tensioned Euler-Bernoulli beam under lateral loading.
For each span between rollers, the lateral transfer function takes the form:

    G(s) = [(-f3/tau)s + (f1/tau^2)] / [s^2 + (f2/tau)s + (f1/tau^2)]

where tau = L/v is the transport time constant and f1, f2, f3 are dimensionless
shape factors derived from the beam lateral stiffness parameter K_gamma.
Parameters are computed analytically from:

- Web geometry: width b = 166 mm, thickness h = 0.2 mm
- Material properties: E = 3.5 GPa, mu = 0.45
- Operating conditions: tension T = 100 N, speed v = 1.125 m/s

The grey-box model uses `greyest` to refine tau, f1, f2, f3 from data while
preserving the beam equation structure. Key findings from estimation:

- tau nearly triples relative to the physical prediction (0.44 to 1.18 s)
- f3 collapses to zero — no non-minimum phase behaviour observed in practice
- Most residual error between the physical model and data is a small DC offset,
  not missing dynamics

The difference between `greyest` and `nlgreyest` is that `greyest` fits a single
fixed set of parameters, while `nlgreyest` allows tau = L/v(t) to vary continuously
with the measured velocity signal at each timestep. In practice the `nlgreyest`
approach did not improve significantly over `greyest` for this dataset, likely
because web speed is approximately constant within each experiment.