# Mediation Analysis: Model Specification and Variables

## Overview

This mediation analysis examines the indirect pathways through which treatment (intervention exposure) affects child stunting outcomes. The framework decomposes the total treatment effect into direct and indirect (mediated) components.

------------------------------------------------------------------------

## Model Specification

### **Three-Model Framework**

#### **Model 1: Mediator Model**

$$
\large
M_i = \alpha_0 + \alpha_1 X_i + \alpha_2 \mathbf{C}_i + \alpha_3 \mathbf{Y}_{ear_i} + \epsilon_{M,i}
$$

Where:

-    $M_i$ = mediator variable for individual $i$
-    $X_i$ = treatment status (0 = control, 1 = treated)
-    $\mathbf{C}_i$ = vector of selected covariates from LASSO regularization
-    $\mathbf{Y}_{ear_i}$ = year fixed effects
-    $\alpha_0, \alpha_1, \alpha_2, \alpha_3$ = coefficients to be estimated
-    $\epsilon_{M,i}$ = error term

**Distribution**: Binomial (logistic) if mediator is binary; Gaussian (linear) if continuous

------------------------------------------------------------------------

#### **Model 2: Outcome Model**

$$
\large
Y_i = \beta_0 + \beta_1 X_i + \beta_2 M_i + \beta_3 \mathbf{C}_i + \beta_4 \mathbf{Y}_{ear_i} + \epsilon_{Y,i}
$$

Where:

-    $Y_i$ = outcome variable (child stunting status: 0 = not stunted, 1 = stunted)
-    $X_i$ = treatment status
-    $M_i$ = mediator variable
-    $\mathbf{C}_i$ = vector of selected covariates
-    $\mathbf{Y}_{ear_i}$ = year fixed effects
-    $\beta_0, \beta_1, \beta_2, \beta_3, \beta_4$ = coefficients to be estimated
-    $\epsilon_{Y,i}$ = error term

**Distribution**: Binomial (logistic regression)

------------------------------------------------------------------------

#### **Model 3: Reduced Form (Total Effect Model)**

$$
\large
Y_i = \tau_0 + \tau_1 X_i + \tau_2 \mathbf{C}_i + \tau_3 \mathbf{Y}_{ear_i} + \epsilon_{\tau,i}
$$

Where:

-    $\tau_1$ represents the total effect of treatment on the outcome (before inclusion of mediator)

------------------------------------------------------------------------

## Mediation Effects Decomposition

### **Average Causal Mediation Effect (ACME)**

$$
\text{ACME} = E[Y_i(M_i(1)) - Y_i(M_i(0))]
$$

The ACME represents the **indirect effect** of treatment through the mediator. It reflects how treatment changes the mediator, which in turn affects the outcome.

**Interpretation**: The change in stunting probability attributable to treatment-induced changes in the mediator, holding treatment constant.

------------------------------------------------------------------------

### **Average Direct Effect (ADE)**

$$
\text{ADE} = E[Y_i(1, M_i(0)) - Y_i(0, M_i(0))]
$$

The ADE represents the **direct effect** of treatment on the outcome, independent of the mediator. It captures pathways not operating through the focal mediator.

**Interpretation**: The change in stunting probability attributable to treatment, holding the mediator at its value under control conditions.

------------------------------------------------------------------------

### **Total Effect**

$$
\text{Total Effect} = \text{ACME} + \text{ADE}
$$

The total effect is the combined impact of direct and indirect pathways.

------------------------------------------------------------------------

### **Proportion Mediated**

$$
\text{Proportion Mediated} = \frac{\text{ACME}}{\text{Total Effect}}
$$

This measure indicates the percentage of the total treatment effect that operates through the mediator.

**Interpretation**: A proportion of 0.30 means 30% of the treatment effect is mediated by the pathway specified.

------------------------------------------------------------------------

## Variable Definitions

### **Treatment Variable**

-   **Name**: `treated_status2`
-   **Coding**: 0 = Control group (no intervention exposure), 1 = Treated group (early-treated or late-treated combined)
-   **Timing**: Assessed at baseline (pre-intervention period)

------------------------------------------------------------------------

### **Outcome Variable**

-   **Name**: `nt_ch_stunt` (child stunting indicator)
-   **Coding**: 0 = Not stunted (height-for-age ≥ -1 SD), 1 = Stunted (height-for-age \< -1 SD)
-   **Measurement**: Anthropometric status of child (typically ages 0-5)

------------------------------------------------------------------------

### **Mediator Variables**

Selected mediators are chosen through LASSO regularization to reduce dimensionality and identify the most predictive pathways:

| Mediator Variable | Label | Conceptual Domain |
|------------------------|------------------------|------------------------|
| `rc_edu` | Caregiver education level | Human capital / Knowledge |
| `rh_anc_pvskill` | Antenatal care by skilled provider | Healthcare access / Quality |
| `dm_weath_index` | Wealth/socioeconomic index | Socioeconomic resources |
| `ph_wtr_trt_cloth` | Water treatment practices | Household practices / WASH |
| `nt_mdd` | Minimum dietary diversity | Nutrition/dietary adequacy |

------------------------------------------------------------------------

### **Covariates** (`\mathbf{C}_i`)

-   **Source**: LASSO-selected predictors from the baseline covariate matrix
-   **Selection**: Variables retained from LASSO regularization (λ = 1 SD above minimum cross-validated error)
-   **Purpose**: Control for confounding that could bias mediation estimates
-   **Number**: Variable, typically 15–25 covariates depending on LASSO selection

------------------------------------------------------------------------

### **Year Fixed Effects** (`\mathbf{Y}_{ear_i`)

-   **Name**: `year` (categorical, as factor)
-   **Purpose**: Account for temporal trends and survey wave-specific effects
-   **Specification**: Included as factor variable with baseline year as reference

------------------------------------------------------------------------

## Key Assumptions

1.  **Sequential Ignorability**: No unmeasured confounding of the treatment-mediator, treatment-outcome, and mediator-outcome relationships, conditional on measured covariates.

2.  **No Interaction**: The treatment does not interact with the mediator in affecting the outcome (standard mediation assumption). Tested via separate model variants if necessary.

3.  **Consistency**: The treatment and mediator are well-defined and stable across units.

4.  **Positivity**: All treatment-mediator-covariate combinations have positive probability of occurrence.

------------------------------------------------------------------------

## Estimation Procedure

1.  **Fit Mediator Model**: Estimate Model 1 using appropriate GLM family (binomial for binary mediators, Gaussian for continuous).

2.  **Fit Outcome Model**: Estimate Model 2 using binomial GLM.

3.  **Run Mediation Analysis**: Use the `mediation` R package to:

    -   Simulate or analytically derive ACME, ADE, and total effect estimates
    -   Compute 95% confidence intervals via bootstrapping (1,000 simulations)
    -   Calculate proportion mediated and associated p-values

4.  **Report Results**: Present point estimates, confidence intervals, and significance tests for each mediation pathway.

------------------------------------------------------------------------

## Interpretation Guidelines

-   **ACME p-value \< 0.05**: Statistically significant indirect effect (mediator pathway is active)
-   **ADE p-value \< 0.05**: Statistically significant direct effect
-   **Proportion Mediated**: Indicates relative importance of the mediated pathway
    -   Close to 0 = minimal mediation
    -   Close to 1 = effect operates primarily through mediator
    -   Can exceed 1 if ADE and ACME have opposite signs (inconsistent/competitive mediation)

------------------------------------------------------------------------

## Output Structure

Results are stored as a data frame with the following columns:

| Column | Description |
|------------------------------------|------------------------------------|
| `mediator` | Name of the mediator variable |
| `label` | Human-readable label for the mediator |
| `num_obs` | Number of complete observations used in analysis |
| `num_vars` | Number of variables in the full model (mediator + outcome + covariates) |
| `acme` | Average Causal Mediation Effect (point estimate) |
| `acme_p` | P-value for ACME |
| `acme_ci1, acme_ci2` | 95% confidence interval bounds for ACME |
| `ade` | Average Direct Effect (point estimate) |
| `ade_p` | P-value for ADE |
| `ade_ci1, ade_ci2` | 95% confidence interval bounds for ADE |
| `total_effect` | Total treatment effect (ACME + ADE) |
| `total_effect_p` | P-value for total effect |
| `total_effect_ci1, total_effect_ci2` | 95% confidence interval bounds for total effect |
| `prop_mediated` | Proportion of total effect mediated |
| `prop_mediated_p` | P-value for proportion mediated |
| `prop_mediated_ci1, prop_mediated_ci2` | 95% confidence interval bounds for proportion mediated |

------------------------------------------------------------------------

## References

The estimation approach follows the framework of: - **Imai, K., Keele, L., & Tingley, D.** (2010). A general approach to causal mediation analysis. *Psychological Methods*, 15(4), 309–334. - Implemented via the **`mediation`** R package (Tingley et al., 2014)
