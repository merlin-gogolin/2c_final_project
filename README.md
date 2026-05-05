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
| Black-box tfest (Y4 + velocity) | 97.7% | 95.5% |
| Nonlinear grey-box (nlgreyest) | 89.2% | 65.6% |

The physical beam equations capture the dynamics well. The dominant error is a small
DC offset, not missing dynamics. The hybrid model corrects this without sacrificing
physical interpretability. See the Interpretation section below for a detailed
explanation of what the DC offset is, why it exists, and why the velocity model
performs so well.

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

The web is modelled as a tensioned Timoshenko beam under lateral loading, following
the formulation of Sievers, Balas, and von Flotow (1988). For each span between
rollers, the lateral transfer function takes the form:

    G(s) = [(-f3/tau)s + (f1/tau^2)] / [s^2 + (f2/tau)s + (f1/tau^2)]

where tau = L/v is the transport time constant and f1, f2, f3 are dimensionless
shape factors derived from the beam lateral stiffness parameter K_gamma.
Parameters are computed analytically from:

- Web geometry: width b = 166 mm, thickness h = 0.2 mm
- Material properties: E = 3.5 GPa, mu = 0.45
- Operating conditions: tension T = 100 N, speed v = 1.125 m/s

The grey-box model uses `greyest` to refine tau, f1, f2, f3 from data while
preserving the beam equation structure. Key findings from estimation:

- tau nearly triples relative to the physical prediction (0.44 to 1.18 s),
  suggesting the effective transport delay is much larger than geometry alone
  predicts — possibly due to sensor/actuator lag, longer effective web path,
  or speed-dependent effects not captured by constant-velocity assumption
- f3 collapses to zero — no non-minimum phase behaviour is observed in practice,
  meaning the system is actually easier to control than pure theory suggests
- Most residual error between the physical model and data is a small DC offset,
  not missing dynamics (see Interpretation section below)

The difference between `greyest` and `nlgreyest` is that `greyest` fits a single
fixed set of parameters, while `nlgreyest` allows tau = L/v(t) to vary continuously
with the measured velocity signal at each timestep. In practice the `nlgreyest`
approach did not improve significantly over `greyest` for this dataset, likely
because web speed is approximately constant within each experiment.

---

## Interpretation of Results

### What DC means and what a DC offset is

The term DC (Direct Current) comes from electrical engineering, where it refers to
a constant, non-varying signal. In control and signal processing, DC has been
adopted to mean the zero-frequency, constant component of any signal.

In a transfer function G(s), the variable s encodes frequency. Evaluating G(0) —
plugging in s = 0 — gives the DC gain: the ratio of output to input when the input
is held perfectly constant forever and the system has fully settled. This is the
same number you read off a step response once the transient has died out.

For the Sievers physical model:

    G(0) = (f1/tau^2) / (f1/tau^2) = 1

The DC gain is exactly 1 by construction. This reflects a physical truth: with
perfectly parallel rollers, uniform tension, and a straight web, a lateral
displacement at the upstream roller propagates downstream unchanged in steady
state. If y4 holds constant at some value, y5 must eventually settle to that
same value.

A DC offset is a constant bias between two signals — one is always shifted by a
fixed amount relative to the other, regardless of the dynamics. In this dataset,
y5_measured is consistently about 0.0002 mm higher than the physical model
predicts. This is a zero-frequency error only. The dynamics — poles, zeros,
frequency response — can all be perfectly correct while this constant shift remains.


### Why the DC offset exists

The physical model predicts DC gain = 1 exactly, so any constant difference between
the measured y4 and y5 signals must come from outside the model. The most likely
causes in order of probability are:

**Sensor zeroing mismatch (most likely).** y4 and y5 are measured by two separate
cameras calibrated independently. Standard camera calibration converts pixel
coordinates to real-world millimetres, but leaves small systematic errors in the
absolute zero reference. A 0.2 mm calibration error in one camera appears as a
constant offset in the data regardless of what the web is doing physically.

**Roller misalignment.** The Sievers model assumes all roller axes are exactly
parallel. Any small skew in a roller axis exerts a steady-state lateral force on
the web, pushing it to a slightly different equilibrium than the model predicts.
Deshpande et al. (2026) explicitly note this as a limitation of the physics-based
approach for this system.

**Web camber.** Real webs have built-in lateral curvature from the manufacturing
process. A cambered web steers itself toward a preferred lateral position determined
by its natural geometry, introducing a constant lateral forcing term that is
entirely absent from the Sievers equations.

**Non-uniform tension.** The model assumes uniform tension across the web width.
In practice, tension varies due to web formation history, edge effects, and roller
crown profiles, shifting the equilibrium position slightly.

The key implication is that this is an installation and calibration issue, not a
modelling failure. The beam dynamics are essentially correct. The DC offset section
of the script confirms this: correcting for an offset of ~0.0002 mm (less than a
quarter of a millimetre) improves the physical model from 89% to 96% on the 4mm
test and from 65% to 93% on the 2mm test. The larger improvement on the 2mm test
is a mathematical artefact of the NMSE metric — because the 2mm web moves half
as far, the fixed-size offset represents a larger fraction of the signal variance,
so correcting it produces a proportionally larger gain in fit percentage.


### Why the improvement from adding velocity is not what it appears

Adding velocity as a second input to tfest produces a large performance jump
(roughly 89% to 97%). It is tempting to interpret this as the model learning
speed-dependent dynamics — for example, tau = L/v changing as the machine
accelerates. The actual explanation is more mundane.

The velocity signal is approximately constant within each experiment. Normal speed
experiments sit at roughly 12.85 velocity units throughout; fast speed experiments
sit at roughly 20.17. When the optimizer fits a two-input transfer function:

    y5 = G1(s) * y4 + G2(s) * velocity

the G2(s) term has an input that barely varies. The only way a constant input can
affect the output is through its DC gain. The optimizer discovers that G2(0) = -14.6
is useful: multiplying -14.6 by the velocity value gives a different constant for
each experiment, which the model uses as a per-experiment bias correction.

In other words, the velocity channel is not capturing how web dynamics change with
speed. It is using velocity as a lookup key to identify which experiment is running
and apply the appropriate DC offset correction. Normal speed experiments get one
correction, fast speed experiments get another.

This has important consequences for generalization. If the model is evaluated at
a speed not seen in training, the large DC gain on the velocity channel will
extrapolate to produce an arbitrary offset that may be completely wrong. The model
has learned a correlation, not a mechanism.

The hybrid model (grey-box + residual) achieves comparable performance (~96%) by
a physically transparent route: the residual tfest term absorbs the DC offset
directly from the simulation error during training, without confounding it with
velocity. This approach would generalize correctly to any operating speed because
the correction is applied as a fixed bias, not as a gain on a scheduling variable.


### Summary of what each model is actually doing

| Model | What explains its performance |
|---|---|
| Physical | Correct dynamics, wrong DC reference due to sensor calibration |
| Physical + DC offset | Correct dynamics, corrected reference — near-ceiling performance |
| Black-box tfest (Y4 only) | Fits dynamics from data but inherits the same DC reference error |
| Grey-box | Physically constrained dynamics, same DC reference error |
| Hybrid | Grey-box dynamics plus residual that automatically absorbs the DC offset |
| tfest with velocity | Correct dynamics plus velocity used as a proxy to correct per-experiment DC offset |

The physical + DC offset and the hybrid achieve nearly identical results by
different routes, which is strong evidence that the DC offset is the dominant
source of error and the beam equation dynamics are otherwise sound.