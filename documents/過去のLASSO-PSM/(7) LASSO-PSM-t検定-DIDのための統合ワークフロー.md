<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# インパクト評価のための統合ワークフロー

以下では、**DHSデータ**を用いて

1.  **LASSOによる共変量選択**
2.  **多項ロジスティック回帰（GLM）による傾向スコア推定（PSM）**
3.  **介入後＋コントロールデータへの重み適用**
4.  **重み付き多群t検定・ANOVAおよびStaggered DID** の全手順とRコードをまとめています。

------------------------------------------------------------------------

## 1. 初期設定・データ読み込み

``` r
# パッケージ読み込み
library(tinytex); library(here); library(haven)
library(glmnet); library(dplyr); library(fastDummies)
library(nnet);  # 多項ロジスティック回帰
library(survey); library(ggplot2); library(did)

# 作業環境クリア
rm(list = ls(all = TRUE))
source(here("myTools.R"))

# データ読み込み
path_data_file <- normalizePath(here("..","output","alldata","merged_all_years.dta"))
df_org <- read_dta(path_data_file)
```

------------------------------------------------------------------------

## 2. 介入前データでの前処理 & LASSO

``` r
# 除外変数・管理変数の定義
drop_cols  <- c("caseid","cluster_id","strata_id",/*…*/"nt_ch_ovwt_age")
drop_cols2 <- grep("^ch_pneumo|^ch_rotav", names(df_org), value=TRUE)
grouping_cols <- c("caseid","cluster_id","strata_id","sampling_weight","treatment_start",/*…*/)

# 介入前サブセット
df_pre <- df_org[df_org$treated_status %in% c("never_treated","not_yet_treated"), ]
df_pre <- dummy_cols(df_pre, select_columns="year")
df_pre <- df_pre %>% mutate(
  treatment_group = case_when(
    treatment_start=="2009"~1,
    treatment_start=="2011"~2,
    TRUE~0
  ) %>% factor()
)

# NA多列除去 & NA行除去
df_pre <- df_pre[, sapply(df_pre, function(x) sum(is.na(x))<=.1*nrow(df_pre))]
covariate_names <- setdiff(names(df_pre), c(drop_cols,drop_cols2,grouping_cols,"treatment_group"))
df_pre <- df_pre[complete.cases(df_pre[,covariate_names]), ]

# 説明変数行列化・標準化
X_matrix <- model.matrix(~.-1, df_pre[,covariate_names])
X_scaled <- scale(X_matrix)
Y <- df_pre$treatment_group

# LASSO変数選択（multinomial, cv.glmnet）
set.seed(123)
cv_model <- cv.glmnet(X_scaled, Y, family="multinomial", alpha=1, nfolds=10)
best_lambda <- cv_model$lambda.min

# 選択変数抽出
coef_list <- coef(cv_model, s="lambda.min")
selected_vars <- Reduce(union, lapply(coef_list, function(m) rownames(m)[m[,1]!=0 & rownames(m)!="(Intercept)"]))
```

------------------------------------------------------------------------

## 3. 介入前データでの多項GLM-PSM学習

``` r
# LASSOと同じ形式のモデル行列を再構成
psm_matrix    <- model.matrix(~.-1, df_pre[,covariate_names])
psm_covariates<- as.data.frame(psm_matrix[,selected_vars])
psm_data      <- cbind(
  treatment_group = df_pre$treatment_group,
  psm_covariates,
  df_pre[, intersect(grouping_cols,names(df_pre))]
)

# 多項ロジスティック回帰モデル
psm_formula <- as.formula(paste("treatment_group~",paste(selected_vars,collapse="+")))
psm_model   <- multinom(psm_formula, data=psm_data, trace=FALSE)

# 傾向スコア（確率）算出
pscore_mat <- predict(psm_model, type="probs")
pscore_df  <- as.data.frame(pscore_mat)
names(pscore_df) <- paste0("prob_",levels(psm_data$treatment_group))

# IPTW重み計算
psm_data$iptw_weight <- sapply(1:nrow(psm_data), function(i) {
  col <- paste0("prob_", as.character(psm_data$treatment_group[i]))
  1 / max(pscore_df[i,col], 1e-3)
})
summary(psm_data$iptw_weight)
```

------------------------------------------------------------------------

## 4. 介入後＋コントロールデータへの重み適用

``` r
# 介入後+control抽出・群再定義
df_post <- df_org[df_org$treated_status %in% c("never_treated","early_treated","late_treated"), ] %>%
  mutate(treatment_group = case_when(
    treated_status=="never_treated"~0,
    treated_status=="early_treated"  ~1,
    treated_status=="late_treated"   ~2
  ) %>% factor())

# 年ダミー・共変量行列化
df_post <- dummy_cols(df_post,select_columns="year")
post_matrix <- model.matrix(~.-1, df_post[,covariate_names])
post_covariates <- as.data.frame(post_matrix[,selected_vars,drop=FALSE])

# 予測用データ
predict_data <- cbind(treatment_group=df_post$treatment_group, post_covariates)
post_pscore_mat <- predict(psm_model, newdata=predict_data, type="probs")
post_pscore_df  <- as.data.frame(post_pscore_mat)
names(post_pscore_df) <- paste0("prob_",levels(df_post$treatment_group))

# IPTW重み
df_post$iptw_weight <- sapply(1:nrow(df_post), function(i) {
  col <- paste0("prob_",as.character(df_post$treatment_group[i]))
  1 / max(post_pscore_df[i,col],1e-3)
})

# DHSサンプリングウェイト正規化 & 組み合わせ
df_post$sampling_weight_norm <- df_post$v005/1e6
df_post$w_combined <- df_post$iptw_weight * df_post$sampling_weight_norm
```

------------------------------------------------------------------------

## 5. 重み付き多群比較・t検定・ANOVA

``` r
# surveyデザイン構築
design_post <- svydesign(
  ids    = ~v001,
  strata = ~v022,
  weights= ~w_combined,
  data   = df_post,
  nest   = TRUE
)
options(survey.lonely.psu="adjust")

# 群別平均
svyby(~nt_ch_stunt, ~treatment_group, design_post, svymean)

# ペアごと2群 t検定
for(pair in list(c(0,1),c(0,2),c(1,2))) {
  subd <- subset(design_post, treatment_group%in%pair)
  subd <- update(subd, treatment_group=droplevels(treatment_group))
  cat("\\n=== group",pair,"t-test ===\\n")
  if(length(unique(subd$variables$treatment_group))==2) {
    print(svyttest(nt_ch_stunt~treatment_group,design=subd))
  }
}

# 3群ANOVA
anova_mod <- svyglm(nt_ch_stunt~factor(treatment_group), design=design_post)
anova(anova_mod)
```

------------------------------------------------------------------------

## 6. （オプション）Staggered DID

``` r
did_data <- df_org %>%
  mutate(
    G      = ifelse(treated_status=="never_treated",0,as.integer(treatment_start)),
    T      = as.integer(year),
    D      = as.integer(post_treatment),
    unit_id= as.integer(as.factor(paste(caseid,v001,sep="_")))
  ) %>%
  arrange(unit_id,T)

# 重み統合
did_weights <- df_post %>%
  select(caseid,year,w_combined) %>%
  mutate(T=as.integer(year))
did_data <- left_join(did_data,did_weights,by=c("caseid","T")) %>%
  mutate(weights=coalesce(w_combined,1))

# DID実行
did_res <- att_gt(
  yname="nt_ch_stunt",tname="T",idname="unit_id",gname="G",
  data=did_data,weightsname="weights",panel=TRUE
)
summary(did_res)
plot(aggte(did_res,type="dynamic"))
```

------------------------------------------------------------------------

> **ポイント** - **共変量選択**は事前データでLASSO、**傾向スコア推定**は多項GLMで学術的原則を厳守 - 介入後データへは**`predict()`**で確率を適用し、**ループで安全に重み計算** - `survey`パッケージで**重み付きt検定・ANOVA**、必要であれば**Staggered DID**まで一貫実装

このワークフローにより、**因果推論の理論的原則**と**実務上の再現性・可視化要件**を両立したインパクト評価が可能となります。
