<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# ペルーDHSデータを用いた栄養介入事業のPSM分析フローまとめ

以下では、①LASSOによる変数選択、②3群対応PSM（IPTW推奨）、③重み付きStaggered DIDやt検定への準備という一連の手順をコード付きで整理します。

------------------------------------------------------------------------

## ① LASSOによる共変量選択

``` r
# パッケージ読み込み
library(glmnet); library(dplyr); library(fastDummies)

# 前処理：除外変数ドロップ、介入前サンプル抽出、年ダミー作成
drop_cols <- c("caseid","cluster_id",…)
drop_cols2 <- grep("^ch_pneumo|^ch_rotav", names(df_org), value = TRUE)
df2 <- df_org %>%
  filter(treated_status %in% c("never_treated","not_yet_treated")) %>%
  dummy_cols("year") %>%
  mutate(
    treatment_group = case_when(
      treatment_start=="2009"~1,
      treatment_start=="2011"~2,
      TRUE~0
    )
  ) %>%
  select(-c(drop_cols, drop_cols2,"treatment_start")) %>%
  select_if(~sum(is.na(.)) <= nrow(.)*0.1) %>%
  na.omit()

# 説明変数X, 目的変数Y作成および行列化・標準化
X <- df2 %>% select(-treatment_group)
Y <- as.factor(df2$treatment_group)
X_mat <- model.matrix(~.–1, data=X)
X_scaled <- scale(X_mat)

# 多項分類LASSO＋交差検証でλ最適化
cv_model <- cv.glmnet(X_scaled, Y, alpha=1, family="multinomial", nfolds=10)
best_lambda <- cv_model$lambda.min

# 選択変数抽出
coef_list <- coef(cv_model, s=best_lambda)
selected_vars <- Reduce(
  union,
  lapply(coef_list, function(m) rownames(m)[m[,1]!=0 & rownames(m)!="(Intercept)"])
)

# マッチング用データ作成
matching_data <- as.data.frame(X_mat[, selected_vars, drop=FALSE])
matching_data$treatment_group <- Y
```

------------------------------------------------------------------------

## ② IPTW（逆確率重み付け）による多項PSM

``` r
# パッケージ読み込み
library(twang)

# 傾向スコア＆重み推定 (ATE)
mnps_ate <- mnps(
  treatment_group ~ .,
  data = matching_data,
  estimand = "ATE",
  stop.method = c("es.mean","ks.mean"),
  n.trees = 3000
)
weights_ate <- get.weights(mnps_ate, stop.method="es.mean")
matching_data$w_ate <- weights_ate

# ATT: early-treated (group=1)
mnps_att1 <- mnps(
  treatment_group ~ .,
  data = matching_data,
  estimand = "ATT",
  treatATT = "1",
  stop.method = c("es.mean","ks.mean"),
  n.trees = 3000
)
matching_data$w_att1 <- get.weights(mnps_att1, stop.method="es.mean")

# ATT: late-treated (group=2)
mnps_att2 <- mnps(
  treatment_group ~ .,
  data = matching_data,
  estimand = "ATT",
  treatATT = "2",
  stop.method = c("es.mean","ks.mean"),
  n.trees = 3000
)
matching_data$w_att2 <- get.weights(mnps_att2, stop.method="es.mean")

# バランス診断例
bal_ate  <- bal.table(mnps_ate,  stop.method="es.mean")
bal_att1 <- bal.table(mnps_att1, stop.method="es.mean")
bal_att2 <- bal.table(mnps_att2, stop.method="es.mean")
```

------------------------------------------------------------------------

## ③ 重み付きStaggered DID（またはt検定）への展開

``` r
# Staggered DIDモデル例（plmパッケージ使用）
library(plm)
did_data <- matching_data %>%
  mutate(post = if_else(year >= as.integer(treatment_start), 1, 0))

# 重み付き回帰
did_model <- plm(
  outcome ~ post * factor(treatment_group) + covariates,
  data = did_data,
  index = c("cluster_id","year"),
  model = "within",
  weights = w_att1  # or w_att2 / w_ate
)
summary(did_model)

# t検定例
library(survey)
design <- svydesign(~1, data=matching_data, weights=~w_att1)
svyttest(outcome ~ treatment_group, design)
```

------------------------------------------------------------------------

## ④全体コード

```{r}
# ================== 必要なパッケージ ==================

library(twang)      # IPTW/多群対応PSM
library(dplyr)
library(ggplot2)

# ============== ① 傾向スコア推定式の定義 ==============
# LASSOで選択された変数が selected_vars、マッチングデータが matching_data であるとする

# 目的変数: treatment_group（factor型: 0, 1, 2 など）
if(length(selected_vars) > 0){
  psm_formula <- as.formula(
    paste("treatment_group ~", paste(selected_vars, collapse = " + "))
  )
} else {
  stop("LASSOで選択された変数がありません。")
}

# =============== ② IPTW (多項分類) の実行 ===============

# --- 2-1. ATE (全体平均治療効果) の推定 ---
cat("\n=== IPTW (ATE: Average Treatment Effect) ===\n")
mnps_ate <- mnps(
  formula        = psm_formula,
  data           = matching_data,
  estimand       = "ATE",                 # 全体平均
  stop.method    = c("es.mean", "ks.mean"),
  n.trees        = 3000,
  verbose        = TRUE
)
# 各サンプルの重み取得
matching_data$iptw_weights_ate <- get.weights(mnps_ate, stop.method = "es.mean")

# --- 2-2. ATT - それぞれのtreated群を指定して推定 ---
cat("\n=== IPTW (ATT: Early Treated, group=1) ===\n")
mnps_att1 <- mnps(
  formula        = psm_formula,
  data           = matching_data,
  estimand       = "ATT",
  treatATT       = "1",                   # group 1 (early treated)をtreatedとして指定
  stop.method    = c("es.mean", "ks.mean"),
  n.trees        = 3000,
  verbose        = TRUE
)
matching_data$iptw_weights_att1 <- get.weights(mnps_att1, stop.method = "es.mean")

cat("\n=== IPTW (ATT: Late Treated, group=2) ===\n")
mnps_att2 <- mnps(
  formula        = psm_formula,
  data           = matching_data,
  estimand       = "ATT",
  treatATT       = "2",                   # group 2 (late treated)をtreatedとして指定
  stop.method    = c("es.mean", "ks.mean"),
  n.trees        = 3000,
  verbose        = TRUE
)
matching_data$iptw_weights_att2 <- get.weights(mnps_att2, stop.method = "es.mean")

# ============== ③ バランス診断例 ==============

cat("\n--- バランス診断（ATE）---\n")
bal_ate <- bal.table(mnps_ate, stop.method = "es.mean")
print(summary(bal_ate))

cat("\n--- バランス診断（ATT, Early）---\n")
bal_att1 <- bal.table(mnps_att1, stop.method = "es.mean")
print(summary(bal_att1))

cat("\n--- バランス診断（ATT, Late）---\n")
bal_att2 <- bal.table(mnps_att2, stop.method = "es.mean")
print(summary(bal_att2))

# ============== ④ 有効サンプルサイズの確認 ==============

cat("\n--- 有効サンプルサイズ（ATE）---\n")
ess_ate <- aggregate(matching_data$iptw_weights_ate, by = list(matching_data$treatment_group),
                     FUN = function(x) sum(x)^2 / sum(x^2))
colnames(ess_ate) <- c("group", "effective_sample_size")
print(ess_ate)

cat("\n--- 有効サンプルサイズ（ATT, Early）---\n")
ess_att1 <- aggregate(matching_data$iptw_weights_att1, by = list(matching_data$treatment_group),
                      FUN = function(x) sum(x)^2 / sum(x^2))
colnames(ess_att1) <- c("group", "effective_sample_size")
print(ess_att1)

cat("\n--- 有効サンプルサイズ（ATT, Late）---\n")
ess_att2 <- aggregate(matching_data$iptw_weights_att2, by = list(matching_data$treatment_group),
                      FUN = function(x) sum(x)^2 / sum(x^2))
colnames(ess_att2) <- c("group", "effective_sample_size")
print(ess_att2)

# ============== ⑤ 傾向スコア分布の可視化（例） ==============

# 重み付き分布が必要な場合は surveyパッケージ等も利用可能

ggplot(matching_data, aes(x = iptw_weights_ate, fill = treatment_group)) +
  geom_histogram(alpha = 0.6, bins = 40, position = "identity") +
  labs(
    x = "IPTW (ATE) weights",
    y = "Frequency",
    fill = "Treatment group",
    title = "Distribution of IPTW weights (ATE)"
  ) +
  theme_minimal()



```

------------------------------------------------------------------------

## ⑤ ポイントまとめ

### ポイント

-   **LASSO選択変数**のみを使用し、過剰適合を抑制した共変量調整
-   **IPTW (mnps)** により3群すべてを同時に考慮し、Pairwiseマッチングの煩雑さを回避
-   **ATT/ATE** は`estimand`と`treatATT`で明示的に指定
-   バランス診断（SMD, KS検定等）で重みの品質を確認
-   重み付きStaggered DIDやt検定でアウトカム効果を推定
-   必ず有効サンプルサイズやバランス統計もセットで確認
-   得られた重み（iptw_weights_xx）は重み付き回帰やStaggered DIDなどで直接利用可能

以上により、Repeated Cross Sectionデータでの栄養介入事業評価のPSM→DID分析が完遂できます。 [^(5-ペルーdhs：栄養介入事業のpsm分析フローまとめ-1][^(5-ペルーdhs：栄養介入事業のpsm分析フローまとめ-2]

[^(5-ペルーdhs：栄養介入事業のpsm分析フローまとめ-1]: [3-LASSOFen-Xi-Hou-nomatutinkuJing-Du-Fen-Xi-Bian-Shu-Zhui-Jia-noKao-eFang.md]{style="display:none"}

[^(5-ペルーdhs：栄養介入事業のpsm分析フローまとめ-2]: 4-Repeated-Cross-SectiontetawoYong-itaPSMFen-Xi-noJin-meFang-matome.md

::: {style="text-align: center"}
⁂
:::
