# Web Lateral Dynamics — Linear Model Estimation

## Overview

This repository contains MATLAB code for modelling the lateral dynamics of a moving web
(thin flexible sheet) through a series of rollers in an industrial web-guiding system.
The goal is to identify transfer functions between roller sensor positions and evaluate
how well physics-based, black-box, and hybrid models describe the real system.

The analysis is split into two independent scripts, one per roller section:

- `all_models_R4R5.m` — models the R4 to R5 span
- `all_models_R5R7.m` — models the R5 to R7 span (two chained spans)

Each script is self-contained and can be run independently.

---

## Scripts

### `all_models_R4R5.m`

| Section | Description |
|---|---|
| Read in data | Loads experimental iddata and the pre-computed physical web model |
| Update iddata | Renames signals to consistent short names (y0, u1, y1, y4, y5, y7, velocity, setpoint) |
| Plot experiments | Visualises all 10 new experiments (21-30) |
| Train/Test Split | Defines training experiments (21, 22, 24, 25, 27, 30) and test experiments (28, 29) |
| Physical model plots | Simulates the full web physical model against selected experiments |
| Physical model setup | Computes beam equation parameters from first principles |
| R4 to R5 (no speed) | Black-box tfest and physical model comparison |
| R4 to R5 grey-box/hybrid | Physics-informed greyest + residual tfest hybrid model |
| DC offset analysis | Shows that a tiny DC offset (~0.0002 mm) explains most of the physical model error |
| Extra plotting | Custom side-by-side comparison of all models with reported fit percentages |
| R4 to R5 (with speed) | Black-box tfest using velocity as a second input |
| R4 to R5 (speed + u1) | Black-box tfest using velocity and actuator position as inputs |
| NL grey-box | Nonlinear grey-box where tau = L/v(t) varies with measured speed |

### `all_models_R5R7.m`

Mirrors the structure of `all_models_R4R5.m` exactly, but applied to the R5 to R7
section. The physical model for this section chains two spans (R5-R6 and R6-R7),
producing a 4th-order transfer function. Model orders for tfest are doubled accordingly.
The nonlinear grey-box section is included but is computationally prohibitive for the
chained 4th-order system and is noted as skipped in the results.

---

## Key Results

### R4 to R5 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 89.0% | 65.3% |
| Physical + DC offset | 96.3% | 93.1% |
| Black-box tfest (Y5 only) | 89.6% | 70.2% |
| Grey-box (greyest) | 89.2% | 65.6% |
| Hybrid (grey-box + residual) | 96.3% | 94.3% |
| Black-box tfest (Y4 + velocity) | 97.7% | 95.5% |
| Nonlinear grey-box (nlgreyest) | 89.2% | 65.6% |
| Black-box tfest (Y4 + velocity + U1) | 96.5% | 94.7% |

### R5 to R7 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 77.3% | 80.6% |
| Physical + DC offset | 92.1% | 96.2% |
| Black-box tfest (Y5 only) | 93.0% | 94.2% |
| Grey-box (greyest) | 78.0% | 80.9% |
| Hybrid (grey-box + residual) | 93.7% | 96.2% |
| Black-box tfest (Y5 + velocity) | 94.5% | 97.3% |
| Nonlinear grey-box (nlgreyest) | N/A | N/A |
| Black-box tfest (Y5 + velocity + U1) | -31.9% | -49.4% |

See the Interpretation section for discussion of these results, including what
negative fit percentages mean and why the pure tfest performs comparatively better
for R5-R7 than for R4-R5.

---

## Dependencies

### MATLAB Toolboxes

- System Identification Toolbox (required)
- Control System Toolbox (required)
- Optimization Toolbox (optional — only needed if using `lsqnonlin` search method)

### Helper function files

These must be in the same directory as the scripts or on the MATLAB path.

**`R45_greybox_model.m`** — State-space function for `greyest` on the R4-R5 span.
Implements the single-span beam equation structure with 4 parameters
[tau, f1, f2, f3]:

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

**`R45_nlgrey_model.m`** — ODE function for `nlgreyest` on the R4-R5 span.
tau = L/v(t) is recomputed at each timestep from the live velocity input:

    function [dx, y] = R45_nlgrey_model(t, x, u, f1, f2, f3, L5, varargin)
        v   = max(u(2) * 0.0875, 1e-3);
        tau = L5 / v;
        A = [0, 1; -f1/tau^2, -f2/tau];
        B = [0; 1];
        C = [f1/tau^2, -f3/tau];
        dx = A*x + B*u(1);
        y  = C*x;
    end

**`R57_greybox_model.m`** — State-space function for `greyest` on the R5-R7 span.
Implements two chained spans as a 4th-order system with 8 parameters
[tau6, f1_6, f2_6, f3_6, tau7, f1_7, f2_7, f3_7]:

    function [A,B,C,D] = R57_greybox_model(theta, Ts, varargin)
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

**`R57_nlgrey_model.m`** — ODE function for `nlgreyest` on the R5-R7 span.
Both tau6 and tau7 vary with velocity at each timestep. Note: this model was
found to be computationally prohibitive in practice for this dataset and is
included for completeness only:

    function [dx, y] = R57_nlgrey_model(t, x, u, f1_6, f2_6, f3_6, ...
                                         f1_7, f2_7, f3_7, L6, L7, varargin)
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

---

## Directory Structure

    .
    ├── all_models_R4R5.m                <- R4 to R5 script (run this for R4-R5)
    ├── all_models_R5R7.m                <- R5 to R7 script (run this for R5-R7)
    ├── R45_greybox_model.m              <- required helper for R4-R5
    ├── R45_nlgrey_model.m               <- required helper for R4-R5
    ├── R57_greybox_model.m              <- required helper for R5-R7
    ├── R57_nlgrey_model.m               <- required helper for R5-R7
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
    │       ├── narrow/speed/model_2_4_and_1_2_and_1_2/
    │       ├── greybox_hybrid/dec10/
    │       └── nlgreybox/dec10/
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
of each script.

---

## Running the Scripts

1. Place all four helper `.m` files in the same folder as the scripts.
2. Fill in `data/` and `mat_files/` as described above.
3. Open either `all_models_R4R5.m` or `all_models_R5R7.m` in MATLAB.
4. Run sections in order using `Ctrl+Enter`.
5. By default all `dLoadOrTrain` flags are set to `0` (load pre-saved models).
   To retrain, set `dLoadOrTrain = 1` and `dSaveModels = 1` in the relevant
   section before running it. Models are saved under `models/` automatically.

The grey-box sections decimate training data by a factor of 10 (100 Hz to 10 Hz)
before estimation to keep computation tractable. Expect `greyest` to take a few
minutes for R4-R5 and somewhat longer for R5-R7 due to the higher model order.
The nonlinear grey-box (`nlgreyest`) for R5-R7 is extremely slow due to the
4-state chained ODE and is not recommended to run in practice.

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

The R5-R7 physical model chains two single-span transfer functions (R5-R6 and
R6-R7) in series, producing a 4th-order system. The grey-box model for this
section estimates 8 parameters (tau and f1, f2, f3 independently for each sub-span).

Key findings from grey-box estimation on R4-R5:

- tau nearly triples relative to the physical prediction (0.44 to 1.18 s),
  suggesting the effective transport delay is much larger than geometry alone
  predicts
- f3 collapses to zero — no non-minimum phase behaviour is observed in practice,
  meaning the system is actually easier to control than pure theory suggests
- Most residual error is a small DC offset, not missing dynamics

The difference between `greyest` and `nlgreyest` is that `greyest` fits a single
fixed set of parameters, while `nlgreyest` allows tau = L/v(t) to vary continuously
with the measured velocity signal at each timestep. In practice this did not improve
results because web speed is approximately constant within each experiment.

---

## Interpretation of Results

### The fit percentage metric

All performance numbers in this repository are reported as NMSE fit percentages,
defined as:

    fit = 100 * (1 - ||y - y_hat|| / ||y - mean(y)||)

where y is the measured output and y_hat is the model prediction. The denominator
normalises by how much the signal varies around its own mean. This gives:

- 100% — perfect prediction
- 0% — the model does no better than predicting the constant mean of the output
- Negative — the model's predictions are further from the truth than simply
  predicting the mean would be

A negative fit percentage is a strong warning sign. It means the model is actively
harmful: it introduces more error than ignoring all dynamics and guessing a constant.
This is almost always a symptom of overfitting — the model found patterns in the
training data that happen to hurt it on the test data.


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
the measured upstream and downstream position signals must come from outside the
model. The most likely causes in order of probability are:

**Sensor zeroing mismatch (most likely).** The position signals at each roller are
measured by separate cameras calibrated independently. Standard camera calibration
converts pixel coordinates to real-world millimetres but leaves small systematic
errors in the absolute zero reference. A sub-millimetre calibration error in one
camera appears as a constant offset in the data regardless of what the web is
doing physically.

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
modelling failure. The beam dynamics are essentially correct. Correcting for offsets
of sub-millimetre magnitude recovers near-ceiling performance for both sections.


### Why pure tfest performs comparatively better for R5-R7 than R4-R5

For R4-R5, the physical model scores ~89% and the pure black-box tfest scores ~89.6%
— essentially identical. For R5-R7, the physical model scores 77-80% but the pure
tfest scores 93-94% — a gap of roughly 15 percentage points.

Two effects explain this.

First, the R5-R7 tfest uses a higher model order (4 poles, 2 zeros vs 2 poles,
1 zero for R4-R5). Those extra degrees of freedom give the optimizer room to shift
the effective DC gain away from 1 and implicitly absorb the sensor offset, which
the physical model cannot do by construction. For R4-R5, the lower-order tfest
does not have enough freedom to do this as effectively, so it lands at roughly the
same performance as the physical model.

Second, the R5-R7 physical model chains two spans and compounds modeling errors
from both. Any inaccuracy in how each sub-span is parameterised (wrong tau, edge
effects, boundary condition approximations) multiplies across the cascade. The
physical model therefore starts from a lower baseline for R5-R7, giving the
data-driven model more room to improve.


### Why adding U1 causes catastrophically negative results for R5-R7

Adding U1 (actuator position) as an input to the R5-R7 model produces fit
percentages of -31.9% (4mm) and -49.4% (2mm). These are not just bad — they are
worse than predicting a constant. This is classic severe overfitting.

The mechanism is straightforward. U1 is the position of the actuated roller R1,
which directly drives the web at R1. By the time the web reaches R5 and R7, the
effect of U1 has propagated through three additional roller sections and been
substantially attenuated. For the R5-R7 sub-model specifically, U1 has essentially
no direct causal effect — it is already absorbed into y5, which is the input.

Despite this, the optimizer is given a high-order transfer function from U1 to y7
(2 poles, 1 zero) and 6 experiments of training data. It finds spurious correlations
between U1 and y7 in the training set — perhaps because the controller moves U1 in
response to web deviations that also happen to correlate with downstream position
for other reasons. These correlations do not generalize, and on the test set the
U1 channel actively makes predictions worse rather than better.

The same effect occurs for R4-R5 but is less severe (fit drops from 97.7% to 96.5%
rather than going negative) because the model order is lower, giving the optimizer
fewer parameters to overfit with, and because U1 has a somewhat larger physical
influence on R4-R5 than on R5-R7.

The consistent conclusion across both sections is that U1 should not be included
as a direct input to downstream sub-models once it has already been absorbed into
the upstream position signal.


### Why the improvement from adding velocity is not what it appears

Adding velocity as a second input to tfest produces a large performance jump in
both sections. It is tempting to interpret this as the model learning speed-dependent
dynamics. The actual explanation is more mundane.

The velocity signal is approximately constant within each experiment. Normal speed
experiments sit at roughly 12.85 velocity units throughout; fast speed experiments
sit at roughly 20.17. When the optimizer fits a two-input transfer function:

    y_out = G1(s) * y_in + G2(s) * velocity

the G2(s) term has an input that barely varies. The only way a constant input can
affect the output is through its DC gain. The optimizer discovers a large DC gain
for G2 that, when multiplied by the velocity value, gives a different constant for
each experiment — effectively a per-experiment bias correction.

In other words, the velocity channel is not capturing how web dynamics change with
speed. It is using velocity as a lookup key to identify which experiment is running
and apply the appropriate DC offset correction.

This has important consequences for generalization. If the model is evaluated at
a speed not seen in training, the large DC gain on the velocity channel will
extrapolate to produce an arbitrary offset that may be completely wrong. The model
has learned a correlation, not a mechanism.

The hybrid model achieves comparable performance by a physically transparent route:
the residual tfest term absorbs the DC offset directly from the simulation error
during training, without confounding it with velocity. This approach generalizes
correctly to any operating speed because the correction is applied as a fixed bias,
not as a gain on a scheduling variable.


### Summary of what each model is actually doing

| Model | What explains its performance |
|---|---|
| Physical | Correct dynamics, wrong DC reference due to sensor calibration |
| Physical + DC offset | Correct dynamics, corrected reference — near-ceiling performance |
| Black-box tfest (position only) | Fits dynamics from data; for R5-R7 the higher order implicitly absorbs the DC offset |
| Grey-box | Physically constrained dynamics, same DC reference error as physical |
| Hybrid | Grey-box dynamics plus residual that automatically absorbs the DC offset |
| tfest with velocity | Uses velocity as a per-experiment bias lookup key — good performance but poor generalization |
| tfest with velocity + U1 | Severe overfitting from a physically irrelevant high-order input channel |

The physical + DC offset and the hybrid achieve nearly identical results by
different routes in both sections, which is strong evidence that the DC offset
is the dominant source of error and the beam equation dynamics are otherwise sound.