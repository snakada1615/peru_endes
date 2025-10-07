<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Survey-Weighted モデル結果を **gt()** で出力する手順

以下は、`svydesign` から始めて `gt()` を使った回帰結果テーブルを作成し、重み付きR²を含めるまでの一連の流れです。

------------------------------------------------------------------------

## 1. サンプルデータと調査デザインの定義

``` r
library(survey)

# データ読み込み例
data <- read.csv("your_data.csv")

# svydesign オブジェクトの作成
svy_design <- svydesign(
  id      = ~cluster_id,
  strata  = ~strata_var,
  weights = ~weight_var,
  data    = data
)
```

------------------------------------------------------------------------

## 2. Survey-weighted 線形回帰モデルの適合

``` r
# モデル式を定義（例: y_var をアウトカムとする）
final_model_svy <- svyglm(
  formula = y_var ~ var1 + var2 + var3,
  design  = svy_design,
  family  = gaussian()
)
```

------------------------------------------------------------------------

## 3. 重み付きR²の計算

``` r
# 予測値と実測値を抽出
predicted <- predict(final_model_svy, type = "response")
observed  <- svy_design$variables[["y_var"]]

# 加重分散を計算
var_total <- svyvar(~y_var,              design = svy_design)[1]
var_pred  <- svyvar(~I(predicted),      design = svy_design)[1]

# Survey-weighted R² の算出
R2_weighted <- as.numeric(var_pred / var_total)
```

------------------------------------------------------------------------

## 4. `gtsummary`＋`gt` テーブルの作成

``` r
library(gtsummary)
library(broom.helpers)
library(gt)

gt_table <- final_model_svy %>%
  tbl_regression(
    exponentiate = FALSE,
    intercept    = TRUE,
    pvalue_fun   = function(x) style_pvalue(x, digits = 3, stars = TRUE)
  ) %>%
  add_significance_stars() %>%
  add_glance_source_note(
    include = c(AIC, BIC, nobs, deviance),
    label   = list(
      AIC     ~ "AIC",
      BIC     ~ "BIC",
      nobs    ~ "N",
      deviance~ "Deviance"
    )
  ) %>%
  as_gt() %>%
  gt::tab_header(
    title    = "Survey-weighted Linear Regression",
    subtitle = "※ *p<0.05, **p<0.01, ***p<0.001"
  ) %>%
  # R² をソースノートとして追加
  gt::tab_source_note(
    source_note = paste0("Survey-weighted R² = ", round(R2_weighted, 3))
  )
```

------------------------------------------------------------------------

## 5. テーブルの表示

``` r
print(gt_table)
```

------------------------------------------------------------------------

**ポイントまとめ**

-   `svydesign()` で調査デザインを定義
-   `svyglm()` で重み付き回帰を適合
-   `svyvar()` を使い重み付き分散からR²を算出
-   `tbl_regression()` + `add_glance_source_note()` でAIC/BICなどを追加
-   `gt::tab_source_note()` で重み付きR²を脚注に表示

これにより、**Survey-weighted モデル**の主要統計量と**R²**を一つのGTテーブルにまとめて出力できます。
