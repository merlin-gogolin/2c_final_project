# Web Lateral Dynamics — Linear Model Estimation

## Overview

This repository contains MATLAB code for modelling the lateral dynamics of a moving web
(thin flexible sheet) through a series of rollers in an industrial web-guiding system.
The goal is to identify transfer functions between roller sensor positions and evaluate
how well physics-based, black-box, and hybrid models describe the real system.

The analysis is split into four independent scripts, one per roller section:

- `all_models_R0R1.m` — models the R0 to R1 span (actuated roller at downstream boundary)
- `all_models_R1R4.m` — models the R1 to R4 span (three chained spans, actuated roller)
- `all_models_R4R5.m` — models the R4 to R5 span
- `all_models_R5R7.m` — models the R5 to R7 span (two chained spans)

Each script is self-contained and can be run independently.

---

## Scripts

### `all_models_R0R1.m`

Applied to the R0 to R1 section. This section is unique in several ways. The physical
model has two inputs from the start — y0 (upstream lateral position) and u1 (actuated
roller displacement) — because R1 is the actuated roller whose out-of-plane displacement
directly appears in the downstream boundary condition. The Y1/Y0 transfer function takes
the standard single-span form with a first-order numerator; the Y1/u1 transfer function
has a constant numerator derived from the end-pivot actuator boundary condition. Unlike
all downstream scripts, no `modify_iddata` call is needed — y0 is already an input
and y1 is already an output in the raw data. The grey-box uses a 2-state minimal
realization with 5 free parameters (tau, f1, f2, f3, k1), where k1 is the u1 channel
gain estimated independently from f3 to allow the actuator boundary condition to be
corrected from data. The nonlinear grey-box uses a 4-state parallel realization
(cleaner ODE when tau varies with speed) but was not run due to computational concerns
and evidence from R4-R5 that speed-varying tau provides no practical benefit when speed
is approximately constant within experiments.

### `all_models_R1R4.m`

Applied to the R1 to R4 section, which chains three spans (R1-R2, R2-R3, R3-R4),
producing a 6th-order transfer function in two inputs (y1 and u1). The actuated roller
R1 sits at the upstream boundary of this section, meaning u1 enters directly into the
first span's boundary conditions. Model orders for tfest reflect the higher-order
physical structure. The nonlinear grey-box is computationally prohibitive at 8 states.
There is no separate speed+u1 variant because u1 is already a fundamental input to
all R1-R4 models.

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

### R0 to R1 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 39.5% | -39.6% |
| Physical + DC offset | 66.2% | 51.2% |
| Black-box tfest (Y0 + U1) | 61.7% | 53.6% |
| Grey-box (greyest) | 65.5% | 36.5% |
| Hybrid (grey-box + residual) | 78.6% | 69.9% |
| Black-box tfest (Y0 + U1 + velocity) | 54.3% | 52.5% |
| Nonlinear grey-box (nlgreyest) | N/A | N/A |
| Black-box tfest (Y0 + U1 + velocity + extra) | N/A | N/A |

### R1 to R4 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 63.3% | -3.4% |
| Physical + DC offset | 74.0% | 61.6% |
| Black-box tfest (Y1 + U1) | 20.9% | -57.7% |
| Grey-box (greyest) | 83.1% | 34.5% |
| Hybrid (grey-box + residual) | 93.2% | 90.6% |
| Black-box tfest (Y1 + U1 + velocity) | 94.1% | 89.2% |
| Nonlinear grey-box (nlgreyest) | N/A | N/A |
| Black-box tfest (Y1 + U1 + velocity + extra) | N/A | N/A |

### R4 to R5 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 89.0% | 65.3% |
| Physical + DC offset | 96.3% | 93.1% |
| Black-box tfest (Y4 only) | 89.6% | 70.2% |
| Grey-box (greyest) | 89.2% | 65.6% |
| Hybrid (grey-box + residual) | 96.3% | 94.3% |
| Black-box tfest (Y4 + velocity) | 97.7% | 95.5% |
| Nonlinear grey-box (nlgreyest) | 89.2% | 65.6% |
| Black-box tfest (Y4 + velocity + U1) | 96.5% | 94.7% |

### R5 to R7 span

| Model | 4mm test | 2mm test |
|---|---|---|
| Physical (beam equations) | 80.6% | 77.3% |
| Physical + DC offset | 96.2% | 92.1% |
| Black-box tfest (Y5 only) | 94.2% | 93.0% |
| Grey-box (greyest) | 80.9% | 78.0% |
| Hybrid (grey-box + residual) | 96.2% | 93.7% |
| Black-box tfest (Y5 + velocity) | 97.3% | 94.5% |
| Nonlinear grey-box (nlgreyest) | N/A | N/A |
| Black-box tfest (Y5 + velocity + U1) | -49.4% | -31.9% |

See the Interpretation section for detailed discussion of all results.

---

## Dependencies

### MATLAB Toolboxes

- System Identification Toolbox (required)
- Control System Toolbox (required)
- Optimization Toolbox (optional — only needed if using `lsqnonlin` search method)

### Helper function files

These must be in the same directory as the scripts or on the MATLAB path.

**`R01_greybox_model.m`** — State-space function for `greyest` on the R0-R1 span.
2-state minimal realization with 5 parameters [tau, f1, f2, f3, k1].
The controller canonical form eliminates the y0_dot feedthrough term via the B matrix:

    function [A,B,C,D] = R01_greybox_model(theta, Ts, varargin)
        tau=max(theta(1),1e-6); f1=max(theta(2),0); f2=max(theta(3),0);
        f3=theta(4); k1=theta(5);
        a0=f1/tau^2; a1=f2/tau; b1=-f3/tau; b0=f1/tau^2;
        A=[0,1;-a0,-a1]; B=[b1,0; b0-b1*a1,k1]; C=[1,0]; D=[0,0];
    end

**`R01_nlgrey_model.m`** — ODE function for `nlgreyest` on the R0-R1 span.
4-state parallel realization; tau = L1/v(t) and k1 = f3*v(t)^2/(L1*c0) updated
each timestep. Not run in practice — see Interpretation section:

    function [dx,y] = R01_nlgrey_model(t, x, u, f1, f2, f3, L1, c0, varargin)
        v=max(u(3)*0.0875,1e-3); tau=L1/v; k1=f3*v^2/(L1*c0);
        A2=[0,1;-f1/tau^2,-f2/tau];
        dx=[A2*x(1:2)+[0;1]*u(1); A2*x(3:4)+[0;1]*u(2)];
        y=(f1/tau^2)*x(1)+(-f3/tau)*x(2)+k1*x(3);
    end

**`R14_greybox_model.m`** — State-space function for `greyest` on the R1-R4 span.
Implements three chained spans as an 8-state system with 13 parameters. The Y1 and
u1 paths through span 2 require separate 2-state realisations because their output
vectors differ:

    function [A,B,C,D] = R14_greybox_model(theta, Ts, varargin)
        % theta: [tau2,f1_2,f2_2,f3_2,k2, tau3,f1_3,f2_3,f3_3,
        %         tau4,f1_4,f2_4,f3_4]
        % States: x(1:2)=Y1->Y2, x(3:4)=u1->Y2, x(5:6)=Y2->Y3, x(7:8)=Y3->Y4
        ...
    end

**`R14_nlgrey_model.m`** — ODE function for `nlgreyest` on the R1-R4 span.
tau_i = L_i/v(t) and k2 = f3_2*v(t)^2/(L2*c1) recomputed each timestep.
Computationally prohibitive in practice (8-state chained ODE):

    function [dx,y] = R14_nlgrey_model(t, x, u, f1_2, f2_2, f3_2, ...)
        ...
    end

**`R45_greybox_model.m`** — State-space function for `greyest` on the R4-R5 span.
Single-span beam equation with 4 parameters [tau, f1, f2, f3]:

    function [A,B,C,D] = R45_greybox_model(theta, Ts, varargin)
        tau=max(theta(1),1e-6); f1=max(theta(2),0);
        f2=max(theta(3),0); f3=theta(4);
        A=[0,1;-f1/tau^2,-f2/tau]; B=[0;1];
        C=[f1/tau^2,-f3/tau]; D=0;
    end

**`R45_nlgrey_model.m`** — ODE function for `nlgreyest` on the R4-R5 span.
tau = L/v(t) recomputed each timestep:

    function [dx,y] = R45_nlgrey_model(t, x, u, f1, f2, f3, L5, varargin)
        v=max(u(2)*0.0875,1e-3); tau=L5/v;
        A=[0,1;-f1/tau^2,-f2/tau]; B=[0;1]; C=[f1/tau^2,-f3/tau];
        dx=A*x+B*u(1); y=C*x;
    end

**`R57_greybox_model.m`** — State-space function for `greyest` on the R5-R7 span.
Two chained spans as a 4th-order system with 8 parameters:

    function [A,B,C,D] = R57_greybox_model(theta, Ts, varargin)
        tau6=max(theta(1),1e-6); f1_6=max(theta(2),0);
        f2_6=max(theta(3),0); f3_6=theta(4);
        tau7=max(theta(5),1e-6); f1_7=max(theta(6),0);
        f2_7=max(theta(7),0); f3_7=theta(8);
        A1=[0,1;-f1_6/tau6^2,-f2_6/tau6]; B1=[0;1];
        C1=[f1_6/tau6^2,-f3_6/tau6];
        A2=[0,1;-f1_7/tau7^2,-f2_7/tau7]; B2=[0;1];
        C2=[f1_7/tau7^2,-f3_7/tau7];
        A=[A1,zeros(2,2);B2*C1,A2]; B=[B1;zeros(2,1)];
        C=[zeros(1,2),C2]; D=0;
    end

**`R57_nlgrey_model.m`** — ODE function for `nlgreyest` on the R5-R7 span.
Computationally prohibitive in practice:

    function [dx,y] = R57_nlgrey_model(t, x, u, f1_6, f2_6, f3_6, ...
                                        f1_7, f2_7, f3_7, L6, L7, varargin)
        v=max(u(2)*0.0875,1e-3); tau6=L6/v; tau7=L7/v;
        ...
    end

---

## Directory Structure

    .
    ├── all_models_R0R1.m                <- R0 to R1 script
    ├── all_models_R1R4.m                <- R1 to R4 script
    ├── all_models_R4R5.m                <- R4 to R5 script
    ├── all_models_R5R7.m                <- R5 to R7 script
    ├── R01_greybox_model.m              <- required helper for R0-R1
    ├── R01_nlgrey_model.m               <- required helper for R0-R1
    ├── R14_greybox_model.m              <- required helper for R1-R4
    ├── R14_nlgrey_model.m               <- required helper for R1-R4
    ├── R45_greybox_model.m              <- required helper for R4-R5
    ├── R45_nlgrey_model.m               <- required helper for R4-R5
    ├── R57_greybox_model.m              <- required helper for R5-R7
    ├── R57_nlgrey_model.m               <- required helper for R5-R7
    │
    ├── data/
    │   └── all_exps_data.mat
    │
    ├── mat_files/
    │   └── TP_flat_web_disc_tr_coeffs.mat
    │
    ├── models/
    │   ├── R0_R1/
    │   │   ├── narrow/nospeed/model_1_2_and_0_2/
    │   │   ├── narrow/speed/model_1_2_and_0_2_and_1_2/
    │   │   ├── greybox_hybrid/dec10/
    │   │   └── nlgreybox/dec10/
    │   ├── R1_R4/
    │   │   ├── narrow/nospeed/model_6_3_and_2_0/
    │   │   ├── narrow/speed/model_6_3_and_2_0_and_2_1/
    │   │   ├── greybox_hybrid/dec10/
    │   │   └── nlgreybox/dec10/
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
    └── plots/
        └── physical_model/

---

## Data Requirements

### `data/all_exps_data.mat`

A MATLAB System Identification Toolbox `iddata` object containing all 30 experiments,
sampled at 100 Hz, with the following signals:

**Outputs:** `y_R1`, `y_R4`, `y_R5`, `y_R7`

**Inputs:** `fEdgeDetectorValue`, `ActualPosition`, `AI_PMSSpeedBendingRoller`,
`PID_WebEdgePositionControl_SP`

**Experiments:** Named `1_2mm` through `30_2mm`.

### `mat_files/TP_flat_web_disc_tr_coeffs.mat`

A pre-computed discrete-time state-space model (`TP_sys_disc`) of the full web
transport system, used for physical model validation plots.

---

## Running the Scripts

1. Place all helper `.m` files in the same folder as the scripts.
2. Open the relevant script in MATLAB.
3. Run sections in order using `Ctrl+Enter`.
4. By default all `dLoadOrTrain` flags are set to `0` (load pre-saved models).
   Set `dLoadOrTrain = 1` and `dSaveModels = 1` to retrain.

Decimation by a factor of 10 (100 Hz to 10 Hz) is applied before grey-box
estimation to keep computation tractable. The nonlinear grey-box models are
included for completeness but are not recommended to run in practice: R5-R7
is prohibitive at 4 states, and R1-R4 is more so at 8 states. For R0-R1,
the NL grey-box also has 4 states but was not run — there is evidence across
all sections that speed-varying tau provides no practical benefit when web
speed is approximately constant within each experiment.

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

For the R0-R1 section, R1 is the actuated end-pivot guide. Its boundary condition
introduces a second transfer function path: Y1/u1 = k1/D(s) where k1 = f3*v^2/(L1*c0)
and D(s) is the same second-order denominator. The Y1/Y0 path takes the standard
first-order-numerator form. The R1-R4 physical model chains three spans into a
6th-order system in two inputs; the R5-R7 physical model chains two spans into a
4th-order system.

Physical model performance degrades progressively moving upstream:

| Section | Physical (4mm) | Physical (2mm) | Physical + DC offset (4mm) | Physical + DC offset (2mm) |
|---|---|---|---|---|
| R5-R7 | 80.6% | 77.3% | 96.2% | 92.1% |
| R4-R5 | 89.0% | 65.3% | 96.3% | 93.1% |
| R1-R4 | 63.3% | -3.4% | 74.0% | 61.6% |
| R0-R1 | 39.5% | -39.6% | 66.2% | 51.2% |

The progressive deterioration of the DC offset correction (from ~96% to ~51%) is
the key diagnostic showing that upstream sections have genuinely wrong dynamics,
not just miscalibrated references.

Key findings from grey-box estimation on R4-R5:

- tau nearly triples relative to the physical prediction (0.44 to 1.18 s)
- f3 collapses to zero — no non-minimum phase behaviour observed in practice
- Most residual error is a small DC offset, not missing dynamics

For R1-R4 and R0-R1, grey-box estimation reveals qualitatively different pictures:
the dominant errors are dynamic rather than a simple DC offset, and the hybrid's
residual correction captures genuine frequency-domain discrepancies.

---

## Interpretation of Results

### The fit percentage metric

All performance numbers are reported as NMSE fit percentages:

    fit = 100 * (1 - ||y - y_hat|| / ||y - mean(y)||)

- 100% — perfect prediction
- 0% — the model does no better than predicting the constant mean
- Negative — the model is actively worse than predicting a constant


### What DC means and what a DC offset is

In a transfer function G(s), evaluating G(0) gives the DC gain. For the Sievers
physical model, G(0) = 1 exactly by construction. A DC offset is a constant bias
between signals that persists regardless of dynamics.

For R4-R5 and R5-R7, adding the optimal DC offset recovers ~96% performance,
confirming that the beam dynamics are correct and only the absolute reference is
wrong. For R1-R4 and R0-R1, this correction is insufficient, confirming that those
sections have genuine dynamic modeling errors.


### Why the DC offset exists

**Sensor zeroing mismatch (most likely).** Each roller uses a separately calibrated
camera or edge sensor. Sub-millimetre calibration errors appear as constant offsets.

**Roller misalignment.** Any small skew exerts a steady-state lateral force.

**Web camber.** Built-in lateral curvature steers the web toward a geometry-determined
equilibrium not represented in the Sievers model.

**Non-uniform tension.** Tension variation across the web width shifts equilibrium.


### The DC offset correction as a diagnostic tool

The DC offset test partitions physical model error into two components: a constant
calibration bias (correctable by a single number) and genuine dynamic error (not
correctable by any constant). The test results across sections are:

| Section | Physical | Physical + DC offset | Remaining dynamic error |
|---|---|---|---|
| R4-R5 | ~77% avg | ~95% avg | ~5% — negligible |
| R5-R7 | ~79% avg | ~94% avg | ~6% — negligible |
| R1-R4 | ~30% avg | ~68% avg | ~32% — substantial |
| R0-R1 | ~0% avg | ~59% avg | ~41% — dominant |

Moving upstream, dynamic error increasingly dominates. By R0-R1, the physical model
is approximately as useful as predicting the mean — the beam equations, despite being
formally derived from first principles, are failing to represent what actually happens
in this section.


### Why pure tfest performs comparatively better for R5-R7 than R4-R5

For R4-R5, physical and pure tfest both score ~89%. For R5-R7, physical scores
77-80% but tfest scores 93-94%. The higher model order for R5-R7 gives the optimizer
room to absorb the sensor offset implicitly, and chaining two spans amplifies
physical modeling errors from a lower baseline.


### Why adding U1 causes catastrophically negative results for R5-R7

Adding U1 to R5-R7 produces −31.9%/−49.4% — severe overfitting from a physically
irrelevant high-order input channel. U1's effect is already absorbed into y5. The
consistent conclusion is that U1 should not be included as a direct input once its
effect has been absorbed into the upstream position signal.


### Why R0-R1 is the hardest section physically

Four structural factors combine to make R0-R1 more resistant to physical modeling
than any other section in the system.

**The longest single span by far.** L1 ≈ 2.53 m, compared to L5 ≈ 0.49 m,
L6 ≈ 0.24 m, and L7 ≈ 0.28 m. The Timoshenko beam quasi-static assumption —
that single-span natural frequencies greatly exceed disturbance frequencies — is
most questionable for the longest span. The longer the span, the lower the
fundamental natural frequency, and the closer it gets to the disturbance regime
of interest. When the quasi-static assumption weakens, the simplified ODE that
underpins all the transfer functions becomes inaccurate.

**The actuated roller is the downstream boundary.** R1 is both the output
measurement point and the control actuator. Its out-of-plane displacement enters
directly into the boundary condition as the output of this span, not as a remote
upstream input attenuated by distance. The u1 coefficient k1 = f3·v²/(L1·c0) is
derived from idealised end-pivot geometry — a perfect frictionless pivot at a known
arm length. Any mechanical non-ideality (compliance, friction, pivot axis offset)
corrupts the u1 channel with a systematic error that cannot be corrected without
re-deriving the boundary condition. Since u1 is also the largest-amplitude signal
driving y1 during step experiments, this error dominates the prediction residual.

**tau1 ≈ 2.25 s — the longest transport time constant.** Small fractional errors
in tau produce large absolute prediction errors over long prediction horizons.
If the true effective transport delay differs from L1/v by even 20%, that
translates to a half-second timing error that accumulates across the full step
response.

**The system is in closed loop.** During all experiments, the PID controller is
active, driving u1 in response to the measured y1 error. This means the web at
R0-R1 experiences active forcing at every timestep whose magnitude and timing
depend on the closed-loop dynamics, not just the open-loop web physics. The
Sievers model assumes open-loop transport. Closed-loop operation introduces
correlations between the input (u1) and the output (y1) that the open-loop model
cannot represent.


### Why the DC offset correction is so much less effective for R0-R1

For R4-R5 and R5-R7, adding the optimal DC offset recovers from ~80-89% to ~96%.
For R0-R1, it only recovers from ~0% to ~59%. The 41 percentage points of remaining
error after offset correction represents dynamic prediction errors — the physical
model is predicting the wrong shape of y1, not just a shifted version of the right
shape. The wrong tau creates timing errors in the transient; the wrong k1 creates
amplitude errors in the step response; and closed-loop operation introduces
correlations that no open-loop linear model can fully represent.


### Why the best achievable performance is lower for R0-R1

The best result in the entire study across all sections:

| Section | Best model | Best fit (4mm) | Best fit (2mm) |
|---|---|---|---|
| R5-R7 | tfest + speed | 97.3% | 94.5% |
| R4-R5 | tfest + speed | 97.7% | 95.5% |
| R1-R4 | tfest + speed | 94.1% | 89.2% |
| R0-R1 | Hybrid | 78.6% | 69.9% |

The R0-R1 ceiling of ~78%/70% is substantially lower than all other sections.
This is not a data or training issue — the hybrid model has been given every
available correction mechanism (physically constrained grey-box parameters plus
a data-fitted residual). The remaining ~22-30% of unexplained variance represents
signal complexity that the linear model family cannot represent. This is precisely
consistent with the finding of Deshpande et al. that R0-R1 required nonlinear
autoregressive (NARX) models to achieve comparable accuracy to the linear models
used for downstream sections.


### Why tfest does not catastrophically overfit for R0-R1

For R1-R4, pure tfest scored 20.9% / −57.7% — catastrophic. For R0-R1, tfest
scores 61.7% / 53.6% — mediocre but not catastrophic. The key structural difference
is input correlation.

For R1-R4, y1 and u1 are directly correlated: the PID controller drives u1 in
immediate response to y1 measured at the same roller. Both signals carry the same
closed-loop information, severely ill-conditioning the identification problem.

For R0-R1, y0 is measured upstream of the actuated roller at a physically separate
location. The PID controller responds to y1 (not y0) to generate u1. While u1
does affect y0 indirectly through web dynamics, the correlation is much weaker
than the direct y1-u1 feedback loop. This gives the optimizer a substantially
less degenerate identification problem, allowing tfest to find a reasonable
(if not excellent) model without collapsing into the −57% failure mode.


### Why adding velocity hurts tfest for R0-R1

For all downstream sections (R4-R5, R5-R7, R1-R4), adding velocity to tfest
produced substantial performance improvements, primarily through the per-experiment
DC bias correction mechanism described below. For R0-R1, adding velocity makes
things slightly worse (4mm: 61.7% → 54.3%, 2mm: 53.6% → 52.5%).

The explanation lies in the already complex interaction between y0 and u1 for
this section. The u1 channel introduces a strong low-frequency signal into the
model (control steps that dominate the time series at low frequencies). The y0
channel has its own varying mean across experiments. When velocity is added as
a third input, the optimizer must now resolve the DC level of y1 across three
correlated channels simultaneously. It cannot cleanly assign the per-experiment
bias to the velocity channel (as it does downstream) because u1 already accounts
for much of the low-frequency variation. The extra degrees of freedom from the
velocity channel therefore lead to slight overfitting rather than bias correction.

This is the only section in the study where adding velocity hurts rather than
helps. It reinforces the conclusion that the velocity channel's benefit in other
sections is mechanical — it acts as a per-experiment index for DC offset correction
— and that when other channels already compete for the low-frequency degrees of
freedom, this mechanism breaks down.


### Why the grey-box is below physical + DC offset for 2mm in R0-R1

For 2mm, grey-box (36.5%) is noticeably worse than physical + DC offset (51.2%).
This is the sharpest instance in the study of the grey-box optimizer finding
parameters that are good for training but harmful for the 2mm test.

The grey-box optimizer saw predominantly 4mm training data (experiments 21, 24,
25, 27) alongside 2mm data (22, 30). The 4mm experiments have larger-amplitude
steps that produce stronger gradients for the optimizer. The fitted parameters
drift toward values that reduce 4mm error at the expense of 2mm accuracy. The
physical + DC offset result avoids this by holding all dynamics fixed at physical
values and only adding a constant correction — it cannot overfit because it has
only one free parameter. The grey-box, with five free parameters, has just enough
freedom to overfit the amplitude imbalance in the training set.


### Why the hybrid's improvement over grey-box is substantial for R0-R1

Grey-box to hybrid improvements:

| Section | 4mm gain | 2mm gain |
|---|---|---|
| R4-R5 | +7 pp | +29 pp |
| R5-R7 | +15 pp | +16 pp |
| R1-R4 | +10 pp | +56 pp |
| R0-R1 | +13 pp | +33 pp |

For R4-R5, the residual was essentially a DC correction. For R0-R1, the +13/+33 pp
improvement means the residual is doing genuine dynamic work — correcting shape
errors in the grey-box response, not just a constant shift. The larger gain for 2mm
reflects the grey-box's amplitude-biased parameters being corrected by the residual
on the 2mm regime specifically.


### What N/A means in the R0-R1 and R1-R4 tables

For R5-R7, tfest + velocity + U1 was run and produced −31.9%/−49.4% — catastrophic
overfitting. The N/A in that table reflects a result that was excluded.

For R0-R1 and R1-R4, the N/A for a "+extra U1" variant means the experiment is
not applicable. U1 is already a fundamental input to all models for those sections.

For R0-R1 and R1-R4, the NL grey-box N/A reflects a decision not to run, based
on two findings: (1) the R4-R5 NL grey-box showed no improvement over the linear
grey-box despite speed being the only structural change, because speed is
approximately constant within each experiment; (2) the fundamental errors in R0-R1
and R1-R4 are structural model errors and potential nonlinearity, neither of which
the NL grey-box (which only adds speed-varying tau) addresses.


### Why the improvement from adding velocity is not what it appears

Adding velocity as an input produces a large performance jump in R1-R4 and the
downstream sections. The velocity signal is approximately constant within each
experiment: normal-speed experiments sit at ~12.85 velocity units, fast-speed
at ~20.17. The optimizer finds a large DC gain on the velocity channel that
applies a different constant correction to each experiment — a per-experiment
bias lookup, not a learned physical speed dependence.

The hybrid achieves comparable performance by a physically transparent route:
the residual tfest absorbs the offset directly from simulation error during
training, without confounding it with velocity. This generalises correctly to
any operating speed. For R0-R1 specifically, even this mechanism is insufficient,
reinforcing that the section's errors are nonlinear rather than a simple bias.


### Summary of what each model is actually doing

| Model | R4-R5 / R5-R7 | R1-R4 | R0-R1 |
|---|---|---|---|
| Physical | Correct dynamics, wrong DC reference | Genuinely wrong dynamics — three compounding sources of error | Most severely wrong — longest span, idealized actuator boundary, closed-loop operation |
| Physical + DC offset | Near-ceiling (~96%) | Insufficient (~68% avg) — errors are dynamic | Poor (~59% avg) — dominant dynamic errors dwarf the bias |
| Black-box tfest | Reasonable; absorbs DC offset implicitly for R5-R7 | Catastrophic overfitting from correlated inputs | Mediocre but not catastrophic — y0 and u1 are less correlated than y1 and u1 |
| Grey-box | Same DC reference error as physical | Protective against overfitting despite poor physical model | Can overfit amplitude imbalance in training — worse than physical+offset for 2mm |
| Hybrid | DC offset absorbed by residual; near-ceiling | Residual captures genuine dynamic errors; 56 pp improvement for 2mm | Best available model; still only ~74% avg — linear family structurally insufficient |
| tfest with velocity | Per-experiment bias lookup; large improvement | Same mechanism | Slightly harmful — velocity channel cannot cleanly absorb bias with competing low-frequency inputs |
| tfest with velocity + U1 | Severe overfitting (R5-R7); modest drop (R4-R5) | Not applicable | Not applicable |