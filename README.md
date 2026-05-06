# Web Lateral Dynamics — Linear Model Estimation

## Overview

This repository contains MATLAB code for modelling the lateral dynamics of a moving web
(thin flexible sheet) through a series of rollers in an industrial web-guiding system.
The goal is to identify transfer functions between roller sensor positions and evaluate
how well physics-based, black-box, and hybrid models describe the real system.

The analysis is split into two independent scripts, one per roller section:

- `all_models_R4R5.m` — models the R4 to R5 span
- `all_models_R5R7.m` — models the R5 to R7 span (two chained spans)
- `all_models_R1R4.m` — models the R1 to R4 span (three chained spans, actuated roller)

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

### `all_models_R1R4.m`

Applied to the R1 to R4 section, which is the most complex section in the system.
The physical model chains three spans (R1-R2, R2-R3, R3-R4), producing a 6th-order
transfer function in two inputs (y1 and u1). The actuated roller R1 sits at the
upstream boundary of this section, meaning u1 enters directly into the first span's
boundary conditions rather than being a remote input. Model orders for tfest reflect
the higher-order physical structure. The nonlinear grey-box is computationally
prohibitive at 8 states and is included for completeness only. There is no
separate speed+u1 variant for this section because u1 is already a fundamental
input to all R1-R4 models.

---

## Key Results

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
| Black-box tfest (Y1 + U1 + velocity + extra U1) | N/A | N/A |

See the Interpretation section for discussion of these results, including what
negative fit percentages mean and why R1-R4 presents a qualitatively harder
modelling problem than the downstream sections.

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

**`R14_greybox_model.m`** — State-space function for `greyest` on the R1-R4 span.
Implements three chained spans as an 8-state system with 13 parameters. The Y1 and
u1 paths through span 2 require separate 2-state realisations because their output
vectors differ:

    function [A,B,C,D] = R14_greybox_model(theta, Ts, varargin)
        % theta: [tau2, f1_2, f2_2, f3_2, k2, tau3, f1_3, f2_3, f3_3,
        %         tau4, f1_4, f2_4, f3_4]
        % States: x(1:2)=Y1->Y2, x(3:4)=u1->Y2, x(5:6)=Y2->Y3, x(7:8)=Y3->Y4
        ...
    end

**`R14_nlgrey_model.m`** — ODE function for `nlgreyest` on the R1-R4 span.
tau_i = L_i/v(t) and k2 = f3_2*v(t)^2/(L2*c1) are recomputed at each timestep.
Note: computationally prohibitive in practice due to 8-state chained ODE:

    function [dx, y] = R14_nlgrey_model(t, x, u, f1_2, f2_2, f3_2, ...)
        ...
    end

---

## Directory Structure

    .
    ├── all_models_R4R5.m                <- R4 to R5 script
    ├── all_models_R5R7.m                <- R5 to R7 script
    ├── all_models_R1R4.m                <- R1 to R4 script
    ├── R45_greybox_model.m              <- required helper for R4-R5
    ├── R45_nlgrey_model.m               <- required helper for R4-R5
    ├── R57_greybox_model.m              <- required helper for R5-R7
    ├── R57_nlgrey_model.m               <- required helper for R5-R7
    ├── R14_greybox_model.m              <- required helper for R1-R4
    ├── R14_nlgrey_model.m               <- required helper for R1-R4
    │
    ├── data/
    │   └── all_exps_data.mat
    │
    ├── mat_files/
    │   └── TP_flat_web_disc_tr_coeffs.mat
    │
    ├── models/
    │   ├── R4_R5/
    │   │   ├── narrow/nospeed/model_1_2/
    │   │   ├── narrow/speed/model_1_2_and_1_2/
    │   │   ├── narrow/speed/model_1_2_and_1_2_and_1_2/
    │   │   ├── greybox_hybrid/dec10/
    │   │   └── nlgreybox/dec10/
    │   ├── R5_R7/
    │   │   ├── narrow/nospeed/model_2_4/
    │   │   ├── narrow/speed/model_2_4_and_1_2/
    │   │   ├── narrow/speed/model_2_4_and_1_2_and_1_2/
    │   │   ├── greybox_hybrid/dec10/
    │   │   └── nlgreybox/dec10/
    │   └── R1_R4/
    │       ├── narrow/nospeed/model_6_3_and_2_0/
    │       ├── narrow/speed/model_6_3_and_2_0_and_2_1/
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
is prohibitive at 4 states, and R1-R4 is more so at 8 states.

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

The R5-R7 physical model chains two single-span transfer functions in series,
producing a 4th-order system. The R1-R4 physical model chains three spans,
producing a 6th-order system in two inputs. For the R1-R4 section, u1 enters
through the upstream boundary condition of span 2, yielding a separate transfer
function path: Y4/u1 has a constant numerator (no zeros) derived from the
actuator boundary condition k2 = f3*v^2/(L2*c1), then shaped by the two
downstream passive spans.

Key findings from grey-box estimation on R4-R5:

- tau nearly triples relative to the physical prediction (0.44 to 1.18 s)
- f3 collapses to zero — no non-minimum phase behaviour observed in practice
- Most residual error is a small DC offset, not missing dynamics

For R1-R4, grey-box estimation reveals a qualitatively different picture: the
dominant errors are dynamic rather than a simple DC offset, and the residual
correction in the hybrid captures genuine frequency-domain discrepancies rather
than just a bias.

---

## Interpretation of Results

### The fit percentage metric

All performance numbers in this repository are reported as NMSE fit percentages,
defined as:

    fit = 100 * (1 - ||y - y_hat|| / ||y - mean(y)||)

where y is the measured output and y_hat is the model prediction. This gives:

- 100% — perfect prediction
- 0% — the model does no better than predicting the constant mean
- Negative — the model is actively worse than predicting a constant

A negative fit percentage means the model introduces more error than ignoring
all dynamics entirely. This is almost always a symptom of overfitting.


### What DC means and what a DC offset is

In a transfer function G(s), evaluating G(0) gives the DC gain: the ratio of
output to input when the system has fully settled to a constant input. For the
Sievers physical model, G(0) = 1 exactly. A DC offset is a constant bias
between two signals that persists regardless of dynamics.

For R4-R5 and R5-R7, adding a measured DC offset to the physical model
simulation recovers near-ceiling performance (~96%), demonstrating that the
physics correctly captures the dynamics and only the absolute reference is wrong.
For R1-R4, this correction only reaches 74%/62%, which is the key diagnostic
showing that the R1-R4 physical model has genuine dynamic errors beyond a
simple calibration mismatch.


### Why the DC offset exists

The most likely causes in order of probability:

**Sensor zeroing mismatch (most likely).** Each roller uses a separate independently
calibrated camera or edge sensor. Sub-millimetre calibration errors appear as
constant offsets in the data.

**Roller misalignment.** Any small skew in a roller axis exerts a steady-state
lateral force, shifting the equilibrium position.

**Web camber.** Built-in lateral curvature from the manufacturing process steers
the web toward a geometry-determined equilibrium absent from the Sievers model.

**Non-uniform tension.** Tension variation across the web width shifts the
equilibrium position.


### Why pure tfest performs comparatively better for R5-R7 than R4-R5

For R4-R5, physical and pure tfest score ~89% — essentially identical. For R5-R7,
physical scores 77-80% but tfest scores 93-94% — a 15 percentage point gap.

The higher model order for R5-R7 (4 poles, 2 zeros vs 2 poles, 1 zero) gives the
optimizer room to shift the effective DC gain away from 1 and implicitly absorb
the sensor offset. Additionally, chaining two spans compounds physical modeling
errors, giving the data-driven model more room to improve from a lower baseline.


### Why adding U1 causes catastrophically negative results for R5-R7

Adding U1 to the R5-R7 model produces -31.9%/−49.4%. U1 is the position of the
actuated roller R1, whose effect on the web has already been absorbed into y5
by the time it reaches R5. The optimizer finds spurious training-set correlations
between U1 and y7 that do not generalise. The effect is less severe for R4-R5
because the model order is lower and U1 has a somewhat larger physical influence.

The consistent conclusion is that U1 should not be included as a direct input to
downstream sub-models once its effect has already been absorbed into the upstream
position signal.


### Why R1-R4 is a fundamentally harder modelling problem

The R1-R4 section differs from R4-R5 and R5-R7 in three ways that compound to
make it structurally harder.

**Three chained spans instead of one or two.** Each span introduces its own
modelling approximations. Chaining three spans multiplies these errors, which
is why the physical model scores 63.3%/−3.4% here compared to 89% and 77-80%
for the downstream sections.

**The actuated roller sits at the upstream boundary.** R1 is the control actuator.
Its out-of-plane displacement introduces a boundary condition (k2 = f3·v²/(L2·c1))
that is derived from idealised end-pivot geometry. Any deviation from this
idealisation — friction, mechanical compliance, non-ideal pivot axis — appears
as a systematic error in the u1 input channel that compounds through all three
downstream spans.

**Extreme span length heterogeneity.** L2 ≈ 0.27 m, L3 ≈ 1.59 m, L4 ≈ 2.16 m.
The spans differ by nearly an order of magnitude, meaning each operates in a
different dynamic regime with a different tau. This variety makes a single set
of physical parameters harder to get right simultaneously across all three spans.


### Why the physical model's failure for R1-R4 is dynamic, not just a bias

The DC offset correction test is the sharpest diagnostic available. For R4-R5
and R5-R7, adding the optimal constant offset brings performance to ~96%,
confirming that the dynamics are correct and only the reference is wrong.

For R1-R4, the same correction only reaches 74%/62%. The remaining ~20-30%
of error cannot be explained by a constant shift. The physical model is
predicting the wrong shape of response — wrong time constants, wrong gain
profile across frequencies — not just a shifted version of the right response.
The physical model's −3.4% score for the 2mm test means it is actively
misleading: its predictions diverge from reality more than simply predicting
the mean of y4 would.


### Why pure tfest catastrophically overfits for R1-R4

The 20.9%/−57.7% result for pure tfest is the worst in the study, worse even
than the R5-R7 U1 overfitting case. Two effects combine.

**Correlated inputs.** y1 and u1 are not independent. The controller drives u1
in direct response to y1 measured at the same roller. This correlation makes
the identification problem ill-conditioned: the optimizer cannot cleanly separate
the y1 and u1 contributions to y4, and the high-order model (6+2 poles, 3+0
zeros) has enough freedom to overfit this ambiguity.

**Amplitude-dependent behaviour.** The 4mm and 2mm test experiments may excite
slightly different operating regimes. A model fitted primarily on the 4mm
training experiments can easily memorise 4mm patterns while failing at 2mm,
which is exactly what the 20.9% vs −57.7% gap reflects.


### Why the grey-box is protective despite the physical model's failure

The grey-box scores 83.1%/34.5% — dramatically better than pure tfest despite
starting from the same poor physical model baseline. The physical structure
constrains the parameter search space enough to prevent catastrophic overfitting
even when the initial parameters are significantly wrong.

The large gap between 4mm (83.1%) and 2mm (34.5%) is informative. It is a
signature of model bias rather than model variance. The grey-box has found
parameters that work for one amplitude regime but do not transfer to the other.
This is the kind of systematic error that the hybrid's residual correction is
designed to address.


### Why the hybrid's improvement is so large for the 2mm test

The grey-box to hybrid jump across sections:

- R4-R5: +7 pp for 4mm, +29 pp for 2mm
- R5-R7: +15 pp for 4mm, +16 pp for 2mm
- R1-R4: +10 pp for 4mm, **+56 pp for 2mm**

For R4-R5, the residual tfest correction was essentially a DC term — a pole
near the origin capturing a constant offset. For R1-R4, the residual must be
absorbing genuine frequency-domain errors in the grey-box, not just a bias.
The 56 percentage point jump means the residual correction is doing substantial
dynamic modelling work, rescuing the 2mm prediction entirely.

This makes the hybrid the most important model for R1-R4 specifically. It
maintains the physical interpretability of the grey-box parametrisation while
letting the data correct the systematic errors that the physics cannot represent.


### What N/A means for tfest+U1 in R1-R4 versus R5-R7

These two N/A entries mean different things and should not be conflated.

For R5-R7, the N/A for tfest+U1 means the experiment was run and produced
catastrophically negative results (−31.9%/−49.4%) that were excluded. The
failure mode was severe overfitting from a physically irrelevant input channel.

For R1-R4, the N/A for a "+U1" variant means the experiment is not applicable.
U1 is already a fundamental input to every R1-R4 model — it enters through the
actuated roller boundary condition in span 2. There is no separate "+U1"
experiment to run because U1 cannot be removed from the R1-R4 problem.


### Why the improvement from adding velocity is not what it appears

Adding velocity as an input produces a large performance jump in all three
sections. The velocity signal is approximately constant within each experiment:
normal-speed experiments sit at ~12.85 velocity units, fast-speed at ~20.17.
When the optimizer fits:

    y_out = G1(s) * y_in + G2(s) * velocity

the G2(s) term receives a nearly constant input. The only way a constant input
affects the output is through its DC gain. The optimizer discovers a large DC
gain for G2 that, when multiplied by the experiment's velocity value, applies
a different constant correction to each experiment — effectively a per-experiment
bias lookup, not a learned physical dependence on speed.

The hybrid achieves comparable performance by a physically transparent route:
the residual tfest absorbs the offset from simulation error during training
without confounding it with velocity. This approach generalises correctly to
any operating speed because the correction is a fixed bias, not an extrapolating
gain on a scheduling variable.


### Summary of what each model is actually doing

| Model | R4-R5 / R5-R7 | R1-R4 |
|---|---|---|
| Physical | Correct dynamics, wrong DC reference | Genuinely wrong dynamics — three compounding sources of error |
| Physical + DC offset | Near-ceiling once bias corrected (~96%) | Insufficient — only ~74%/62% because errors are dynamic, not a bias |
| Black-box tfest (position inputs only) | Reasonable; absorbs DC offset via higher model order for R5-R7 | Catastrophically overfits due to correlated inputs and high model order |
| Grey-box | Same DC reference error as physical | Protective against overfitting — physical structure constrains search space enough to avoid −57% failure mode |
| Hybrid | DC offset absorbed by residual; near-ceiling | Residual captures genuine dynamic errors beyond DC; 56 pp improvement for 2mm shows residual is doing real dynamic work |
| tfest with velocity | Uses velocity as per-experiment bias lookup | Same mechanism; comparable performance to hybrid |
| tfest with velocity + U1 | Severe overfitting (R5-R7); modest drop (R4-R5) | Not applicable — U1 already a fundamental input |