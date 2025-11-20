---
---
---

# PSM-DID Model Specification and Variable Definitions

## Model Overview

The Propensity Score Matching - Difference-in-Differences (PSM-DID) approach combines two causal inference techniques:

-   **Propensity Score Matching (PSM)**: Creates comparable treatment and control groups based on observed characteristics

-   **Difference-in-Differences (DID)**: Isolates the causal effect by comparing outcome changes before and after treatment

-   

    ## Phase 1: Pre-Period Analysis (Propensity Score Model)

### Propensity Score Model Specification

$$
\large
\text{Pr}(\text{Treatment}_i = g \mid \mathbf{X}_i) = \frac{\exp(\mathbf{X}_i \boldsymbol{\beta}_g)}{\sum_{j=0}^{G} \exp(\mathbf{X}_i \boldsymbol{\beta}_j)}$$

Where:

-   $\text{Treatment}_i \in \{0, 1, 2\}$: Treatment group assignment (0 = never treated, 1 = early treated 2009, 2 = late treated 2011)
-   $\mathbf{X}_i$: Vector of pre-treatment covariates selected via LASSO
-   $\boldsymbol{\beta}_g$: Multinomial logistic regression coefficients for group $g$ - $i$: Individual observation index

### Covariate Selection via LASSO

$$
\large
\hat{\boldsymbol{\beta}}^{\text{LASSO}} = \underset{\boldsymbol{\beta}}{\arg\min} \left\{ \frac{1}{2n} \sum_{i=1}^{n} (\text{Treatment}_i - \mathbf{X}_i \boldsymbol{\beta})^2 + \lambda \sum_{j=1}^{p} |\beta_j| \right\}$$

Where:

-   $\lambda$: Regularization parameter selected via cross-validation (cv.glmnet with 3 folds)

-   $p$: Total number of potential covariates

-   $n$: Sample size - Selected variables are retained based on $\lambda_{1\text{se}}$ criterion

```         
### Inverse Probability of Treatment Weighting (IPTW)
```

$$
\large
w_i = \frac{1}{\hat{P}(\text{Treatment}_i = g_i \mid \mathbf{X}_i)}
$$

Where:

-   $\hat{P}(\text{Treatment}_i = g_i \mid \mathbf{X}_i)$: Estimated propensity score for observed treatment assignment

-   Flooring applied: $w_i \geq 0.001$ (minimum weight = 1/0.001 = 1000)

-   Combined with survey sampling weights: $w_{\text{combined}, i} = w_i \times \frac{v005_i}{1,000,000}$

-   Trimming applied: weights between 1st and 99th percentiles, capped at 95th percentile

## Phase 2: Post-Period Analysis (DID Regression)

### Difference-in-Differences Specification

$$
\large
Y_{it} = \alpha + \delta_1 \text{Group}_i + \delta_2 \text{Post}_t + \beta \text{Group}_i \times \text{Post}_t + \sum_{t} \gamma_t \text{Year}_t + \boldsymbol{\theta} \mathbf{X}_i + \varepsilon_{it}$$

Where:

-   $Y_{it}$: Outcome for individual $i$ at period $t$ (child stunting indicator: $\text{ntchstunt}$)
-   $\text{Group}_i \in \{1, 2\}$: Treatment group indicator (reference: never treated)
-   $\text{Group}_i = 1$: Early treated (CRECER 2009)
-   $\text{Group}_i = 2$: Late treated (CRECER 2011)
-   $\text{Post}_t$: Period indicator (0 = pre-treatment, 1 = post-treatment)
-   $\text{Group}_i \times \text{Post}_t$: Interaction term capturing the **Average Treatment Effect (ATE)**
-   $\text{Year}_t$: Year fixed effects (controls for time trends)
-   $\mathbf{X}_i$: Baseline covariates selected via LASSO
-   Weights: $w_i$ (PSM-derived IPTW)
-   Clustering: Standard errors clustered at household ($\text{caseid}$) level

### DID Interpretation

$$\beta_g = \mathbb{E}[Y^1_{it,g} - Y^0_{it,g} - (Y^1_{i,\text{pre},g} - Y^0_{i,\text{pre},g})]$$

-   $\beta_1$: Treatment effect for early treated group
-   $\beta_2$: Treatment effect for late treated group
-   Controls for:
    -   Pre-existing differences between groups ($\delta_1$)
    -   Secular time trends ($\delta_2, \gamma_t$)
    -   Baseline imbalances in covariates ($\boldsymbol{\theta} \mathbf{X}_i$)

## Key Variables

| Variable | Definition | Type |
|----|----|----|
| $\text{ntchstunt}$ | Outcome: Child stunted (binary) | Dependent variable |
| $\text{treatmentgroup}$ | Treatment assignment: 0 = control, 1 = early 2009, 2 = late 2011 | Factor |
| $\text{treatedstatus}$ | Cohort membership (never, early, late treated) | Categorical |
| $\text{year}$ | Survey year (2007-2016) | Continuous |
| $\text{post}$ | Period indicator (0 = pre, 1 = post-intervention) | Binary |
| $\text{period}$ | Label for period (pre/post) | Text |
| $v005$ | DHS sampling weight | Continuous |
| $\text{finalweight}$ | Combined IPTW × normalized sampling weight | Continuous |
| $\text{clustervar}$ | Clustering variable (household ID) | Categorical |

## Covariates Selected via LASSO

Post-LASSO covariates include (example domains): - Household characteristics (composition, head education, occupation) - Asset ownership and wealth indices - Housing conditions (roof type, floor type, water source) - Dietary diversity indicators - Maternal health behaviors - Sanitation and hygiene practices - Geographic fixed effects (state indicators)

Year dummies (2007-2016) forced into all models to preserve temporal structure.

## Implementation Notes

1.  **Sample Construction**:
    -   Pre-period: Observations of never/not-yet-treated children (2007-2008 for early; 2007-2010 for late)
    -   Post-period: Observations of treated/control children (2009-2016 for early; 2011-2016 for late)
    -   Complete case analysis: Missing data in LASSO-selected covariates leads to deletion
2.  **Balance Diagnostics**:
    -   Standardized Mean Differences (SMD) computed pre and post-weighting
    -   Threshold: SMD \< 0.1 indicates adequate balance
    -   Survey-weighted balance table used for final assessment
3.  **Robustness Checks**:
    -   Unweighted DID regression
    -   Year-clustered standard errors
    -   Placebo tests (false treatment timing)
4.  **Statistical Software**:
    -   LASSO: `cv.glmnet()` (multinomial with cross-validation)
    -   PSM: `nnet::multinom()` (multinomial logistic regression)
    -   DID: `fixest::feols()` (fixed effects OLS with weighted estimator)
    -   Survey balance: `survey::svyCreateTableOne()` with sampling weights
