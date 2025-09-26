<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# LASSOとPSMを用いた多群介入効果評価 — マークダウン付き最終まとめ

------------------------------------------------------------------------

## 基本設計と主な手順

### 分析背景

-   対象は **non-treated, early-treated, late-treated** の3群。
-   early/late-treated群には「介入前」「介入後」データがある。
-   **傾向スコアマッチング（PSM）** で介入効果（例：child_stunted, 栄養指標）を検証する。

------------------------------------------------------------------------

### マッチング変数選定の原則

-   **介入効果推定バイアス防止のため、介入前の変数だけで変数選定を行う。**
-   アウトカム（child_stunted）はマッチング時に目的変数として使わず、介入前指標としてのみ候補とする。
-   介入前child_stuntedもグループ特異的差の補正のため説明変数に組み込む。

------------------------------------------------------------------------

### LASSO変数選定の操作論

#### 2群比較 ×2回

-   例）non-treated vs early-treated, non-treated vs late-treated でそれぞれLASSO。
-   全バイナリ比較で「非ゼロ係数」となった変数の和集合をマッチングに使う。

#### 多クラス（3群）分類LASSO（推奨）

-   `glmnet`パッケージの `family="multinomial"` を利用し、「non-treated」「early」「late」の3値因子を目的変数に。
-   各群への割付けを判別するための重要な共変量を選択。
-   **多クラスLASSOが簡便かつ理論的に推奨。**

------------------------------------------------------------------------

### 固定効果・年次ダミーの扱い

-   固定効果や年次ダミーも **LASSOのダミー化工程に同時投入**で可。
-   ゼロになれば「説明力が弱い」と判断できる。
-   年次等、必ず残したい変数はロックして投入する設計もOK。

------------------------------------------------------------------------

### 実際のPSMフロー

1.  **介入前データから共変量候補（child_stunted含む）を抽出。**
2.  （2群 or 多群LASSOで）目的変数を群ラベルとし変数選定。
3.  非ゼロ係数の変数で傾向スコア推定。
4.  マッチ後のアウトカムで効果検証。

------------------------------------------------------------------------

## 最終的なRコード（推奨パターン）

``` r
# パッケージ
# install.packages("glmnet"); install.packages("fastDummies"); install.packages("dplyr")
library(glmnet)
library(dplyr)
library(fastDummies)

# 除外変数指定
drop_cols <- c(
  "caseid", "cluster_id", "strata_id", "state_id", "state",
  "treated_status", "time_period", "group_summary", "nt_ch_whz", "age",
  "v001", "v002", "v003", "v005", "v008", "v013", "v022", "v024", "v025", "v026",
  "b3", "b9", "bidx", "age_months", "b4", "v106", "v190", "hv024", "hv103", 
  "hv270", "hc1", "hc27", "sampling_weight", "treated_ever", "treated", 
  "treatment_cohort", "post_treatment", "dm_refrigerator", "nt_bbyfood", 
  "rc_tobc_other", "ph_wtr_trt_solar", "ms_sex_never"
)
drop_cols2 <- grep("^ch_pneumo|^ch_rotav", names(df_org), value = TRUE)

# 1. 介入前で抽出
df2 <- df_org[df_org$treated_status %in% c("never_treated", "not_yet_treated"), ]

# 2. 年をダミー化
df2 <- dummy_cols(df2, select_columns = "year")

# 3. 群の因子変数を付与
df2 <- df2 %>% mutate(
  treatment_group = case_when(
    treatment_start == "2009" ~ 1,
    treatment_start == "2011" ~ 2,
    TRUE ~ 0
  )
)
df2$treatment_group <- as.factor(df2$treatment_group)

# 4. 不要列を除去
df2 <- df2[, !(names(df2) %in% c(drop_cols, drop_cols2, "treatment_start"))]

# 5. NA率で列を除去（例: 5%超NAは削除）
na_threshold <- 0.05
df2 <- df2 %>% select(where(~sum(is.na(.)) <= nrow(df2) * na_threshold))

# 6. NAの完全ケースのみ残す
Y <- df2$treatment_group
X_df <- df2[, !names(df2) %in% "treatment_group", drop = FALSE]
complete_cases <- complete.cases(X_df, Y)
X_df <- X_df[complete_cases, , drop = FALSE]
Y <- Y[complete_cases]

# 7. ダミー化・行列化・NA補完
X_matrix <- makeX(X_df, na.impute = TRUE)  # glmnet::makeX

# 標準化（分散0列は自動除去推奨）
var_check <- apply(X_matrix, 2, var, na.rm=TRUE)
if(any(var_check == 0)) {
  X_matrix <- X_matrix[, var_check > 0, drop=FALSE]
}
X_scaled <- scale(X_matrix)

# 8. LASSO実行
lasso_model <- glmnet(X_scaled, Y, alpha=1, family="multinomial")
cv_model <- cv.glmnet(X_scaled, Y, alpha=1, family="multinomial", nfolds=10)

# 9. 変数選択
coef_min <- coef(cv_model, s="lambda.min")
selected_vars <- c()
for(i in 1:length(coef_min)) {
  class_vars <- rownames(coef_min[[i]])[coef_min[[i]][,1] != 0 & rownames(coef_min[[i]]) != "(Intercept)"]
  selected_vars <- union(selected_vars, class_vars)
}

# 10. 出力用データフレーム作成
if(length(selected_vars) > 0) {
  matching_data <- as.data.frame(X_matrix[, selected_vars, drop=FALSE])
  matching_data$treatment_group <- Y
  matching_data <- matching_data[, c("treatment_group", selected_vars)]
  cat("マッチング用データの準備完了: matching_data\n")
  cat("データサイズ:", nrow(matching_data), "行 ×", ncol(matching_data), "列\n")
} else {
  cat("警告: 変数が選択されませんでした。λ調整を推奨\n")
}

# 11. クロスバリデーションプロット
plot(cv_model, main = "多項分類LASSO: クロスバリデーション結果")
```

------------------------------------------------------------------------

## 次のステップ

1.  **選択変数を使い、傾向スコア推定を実行**。
2.  **傾向スコアマッチング（PSM）を行う**。
3.  **マッチ後のアウトカム比較で介入効果を推定する**。

------------------------------------------------------------------------

## 補足

-   LASSOで選ばれた変数名は `model.matrix`/`makeX`由来のものになっているため、「元データ」から `matching_data` を作る際は**X_matrixの列を使う**のが正解です。
-   個別のNA値閾値、モデルパラメータ（λ等）はサンプル・目的に応じて適宜調整してください。

------------------------------------------------------------------------

このマークダウンを`.Rmd`や`.md`でそのまま文書化・再利用できます。 [^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-1][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-2][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-3][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-4][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-5][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-6][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-7][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-8][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-9][^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-10]

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-1]: [<https://rmarkdown.rstudio.com>]{style="display:none"}

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-2]: <https://quarto.org/docs/authoring/markdown-basics.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-3]: <https://kazutan.github.io/kazutanR/Rmd_intro.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-4]: <https://bookdown.org/yihui/rmarkdown/markdown-syntax.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-5]: <https://r4ds.had.co.nz/r-markdown-formats.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-6]: <https://cran.r-project.org/web/packages/roxygen2/vignettes/rd-formatting.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-7]: <https://rstudio.github.io/visual-markdown-editing/markdown.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-8]: <https://www.appsilon.com/post/r-markdown-tips>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-9]: <https://rmarkdown.rstudio.com/lesson-8.html>

[^(2-lassoとpsmを用いた多群介入効果評価-—-rスクリプト付き最終まとめ-10]: <https://www.neonscience.org/resources/learning-hub/tutorials/document-your-code-r-markdown>

::: {style="text-align: center"}
⁂
:::
