# ================================================================================
# PSM 2群比較版コード（Control vs Early-treated）
# ================================================================================

library(dplyr)
library(ggplot2)

# ================================================================================
# 0. 初期設定・パッケージ読み込み
# ================================================================================
library(here)
library(haven)
library(labelled)
library(glmnet)
library(tidyverse)
library(nnet)      # 多項ロジスティック回帰
library(survey)    # 重み付き統計解析
library(did)       # Staggered DID用（必要に応じて）
library(sjlabelled)　# ラベル付きデータ処理用
library(tableone)
library(fixest)   # 回帰分析の推定結果から係数表（推定値、標準誤差、t値、p値など）を抽出

# オブジェクトクリア
rm(list = ls(all = TRUE))

# 自作関数読み込み
source("myTools.R")

# ================================================================================
# 1. データ読み込み
# ================================================================================
# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

gdrive__dir_enaho <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_enaho"

# 結果保存先
save_path <- file.path(gdrive_dir, "output")

# データベース一覧
endes_list <- readRDS(file.path(gdrive_dir, "output","endes_data_list.rds"))

# 変数ラベル一覧
endes_var_labels <- readRDS(file.path(gdrive_dir, "output", "endes_var_labels.rds"))



# ================================================================================
# 1. データ読み込み
# ================================================================================

df_org <- readRDS(
  file.path(gdrive_dir, "output", "all_data_merged.rds")
)

# ================================================================================
# 2. 介入前データ抽出
# ================================================================================

df_pre <- df_org[df_org$treated_status %in% c("never_treated", "not_yet_treated"), ]

# treatment_group定義
df_pre <- df_pre %>%
  mutate(
    treatment_group = case_when(
      treatment_start == "2009" ~ 1,  # 早期介入
      treatment_start == "2011" ~ 2,  # 後期介入
      TRUE ~ 0                        # コントロール
    ),
    treatment_group = as.factor(treatment_group)
  )

cat("介入前データの群別サンプル数:\n")
print(table(df_pre$treatment_group))

# ================================================================================
# 3. PSM共変量選択（メディエーター除外版）
# ================================================================================

# Con変数を明示的に定義（30個）
con_vars <- c(
  # Health status (4)
  "ch_below_2p5", "nt_wm_ht", "nt_wm_any_anem", "nt_wm_ovobese",
  
  # Health service (4)
  "rh_anc_pvskill", "rh_anc_urine", "rh_prob_minone", "nt_wm_micro_dwm",
  
  # Water & hygiene (3)
  "ph_sani_improve_dummy", "ph_wtr_improve_dummy", "ph_wtr_far",
  
  # Social environment (4)
  "dm_hh_head_30plus", "rc_edu_acceptable", "dm_child_more_than3", "ms_afm_15",
  
  # Assets (11)
  "dm_weath_index", "ph_electric", "ph_mobile", "ph_radio", "ph_moto",
  "rc_agri_yes", "dm_cattle_own", "dm_sheeep_own", "dm_ag_land_ha",
  "dm_cooking_fuel_traditional"
)

# アウトカム変数
outcome_vars <- c("nt_ch_stunt", "nt_ch_haz")

# メディエーター変数（PSMから除外）
mediator_vars <- c(
  "re_anc_4vs", "rh_anc_4mo", "nt_bf_start_1hr",
  "dm_sani_open_yes", "ch_stool_safe_no", "ph_wtr_trt_none",
  "nt_mdd", "nt_grains", "nt_root", "nt_nuts", "nt_meatfish",
  "nt_milk", "nt_dairy", "nt_eggs", "nt_vita", "nt_frtveg"
)

# PSM用共変量（メディエーターを除外）
covariate_names <- con_vars


# ================================================================================
# 1. 2群のみにフィルタリング
# ================================================================================

# 介入前データから2群（0=Control, 1=Early-treated 2009）を抽出
df_pre_2group <- df_pre %>%
  filter(treatment_group %in% c(0, 1)) %>%
  mutate(
    treatment_group = factor(treatment_group, levels = c(0, 1))
  )

cat("=== 2群比較への絞り込み ===\n")
cat("元のサンプル数:", nrow(df_pre), "\n")
cat("2群フィルタ後:", nrow(df_pre_2group), "\n")
cat("群別サンプル数:\n")
print(table(df_pre_2group$treatment_group))

# ================================================================================
# 2. 欠損値処理（2群版）
# ================================================================================

required_cols_2group <- c(covariate_names, "treatment_group", "v001", "v005", "v022")
existing_cols <- intersect(required_cols_2group, names(df_pre_2group))
complete_idx_2group <- complete.cases(df_pre_2group[, existing_cols])

initial_rows_2group <- nrow(df_pre_2group)
df_pre_2group <- df_pre_2group[complete_idx_2group, ]

cat("\nNA値を含む行を", initial_rows_2group - nrow(df_pre_2group), "行削除\n")
cat("最終的な2群データサイズ:", nrow(df_pre_2group), "行\n\n")

# ================================================================================
# 3. ロジスティック回帰でPSM（2群版）
# ================================================================================

# PSM用データ準備
psm_data_2group <- df_pre_2group[, c("treatment_group", covariate_names)]
psm_data_2group <- psm_data_2group[complete.cases(psm_data_2group), ]

cat("PSM実行サンプル数:", nrow(psm_data_2group), "\n")
cat("PSM共変量数:", length(covariate_names), "\n")

# ロジスティック回帰の式（2群なのでglmで十分）
psm_formula_2group <- as.formula(
  paste("treatment_group ~", paste(covariate_names, collapse = " + "))
)

cat("\nロジスティック回帰で傾向スコア推定中...\n")
psm_model_2group <- glm(
  psm_formula_2group,
  data = psm_data_2group,
  family = binomial(link = "logit"),
  control = list(maxit = 50)
)

# モデル要約
cat("\n=== PSMモデル要約（2群版） ===\n")
print(summary(psm_model_2group))

# 傾向スコア計算
pscore_2group <- predict(psm_model_2group, type = "response")

cat("\n傾向スコア要約統計:\n")
cat("群別傾向スコア平均:\n")
cat("  Control (0):", round(mean(pscore_2group[psm_data_2group$treatment_group == 0], na.rm=TRUE), 4), "\n")
cat("  Treated (1):", round(mean(pscore_2group[psm_data_2group$treatment_group == 1], na.rm=TRUE), 4), "\n")
cat("\n全体の傾向スコア分布:\n")
print(summary(pscore_2group))

# 傾向スコアのオーバーラップ確認（重要）
cat("\n傾向スコアのオーバーラップ確認:\n")
cat("  全体の最小値:", round(min(pscore_2group, na.rm=TRUE), 4), "\n")
cat("  全体の最大値:", round(max(pscore_2group, na.rm=TRUE), 4), "\n")

overlap_check <- table(pscore_2group > 0.2 & pscore_2group < 0.8)
cat("  0.2-0.8の範囲内:", overlap_check["TRUE"], "/", nrow(psm_data_2group), "\n")

if(overlap_check["TRUE"] < nrow(psm_data_2group) * 0.8) {
  cat("  警告: オーバーラップが十分でない可能性があります\n")
}

# ================================================================================
# 4. IPTW重み計算（2群版）
# ================================================================================

# IPTW = 1 / p_i for treated, 1 / (1-p_i) for control
psm_data_2group$iptw_weight <- ifelse(
  psm_data_2group$treatment_group == 1,
  1 / pscore_2group,              # 処置群
  1 / (1 - pscore_2group)         # 対照群
)

# 極小確率値の処理
min_prob <- min(pscore_2group, 1 - pscore_2group, na.rm = TRUE)
if(min_prob < 0.001) {
  cat("警告: 傾向スコアが極端に小さい (", round(min_prob, 4), ")\n")
  cat("重みが極端に大きくなる可能性があります\n")
}

cat("\n=== IPTW重み（2群版）===\n")
print(summary(psm_data_2group$iptw_weight))

# 群別の重み統計
cat("\n群別のIPTW重み:\n")
cat("Control群 (n=", sum(psm_data_2group$treatment_group == 0), "):\n", sep="")
print(summary(psm_data_2group$iptw_weight[psm_data_2group$treatment_group == 0]))
cat("\nTreated群 (n=", sum(psm_data_2group$treatment_group == 1), "):\n", sep="")
print(summary(psm_data_2group$iptw_weight[psm_data_2group$treatment_group == 1]))

# 極端な重み確認
weight_quantiles <- quantile(psm_data_2group$iptw_weight, c(0.01, 0.99), na.rm = TRUE)
extreme_weights_99 <- psm_data_2group$iptw_weight > weight_quantiles["99%"]
extreme_weights_01 <- psm_data_2group$iptw_weight < weight_quantiles["1%"]

if(sum(extreme_weights_99, na.rm = TRUE) > 0) {
  cat("\n警告: 極端に大きな重み（99th以上）が", 
      sum(extreme_weights_99, na.rm = TRUE), "個あります\n")
}

if(sum(extreme_weights_01, na.rm = TRUE) > 0) {
  cat("警告: 極端に小さな重み（1st未満）が", 
      sum(extreme_weights_01, na.rm = TRUE), "個あります\n")
}

# ================================================================================
# 5. 元のdf_pre_2groupにIPTW重みをマージ
# ================================================================================

# 行番号マッピング用：PSM実行前後で行が変わっているため、行番号で対応
# より安全な方法として、行名（rownames）を保持

df_pre_2group$iptw_weight <- NA

# psm_data_2groupの行インデックスに対応する df_pre_2group の行に重みを割り当て
matching_rows <- match(rownames(psm_data_2group), rownames(df_pre_2group))
df_pre_2group$iptw_weight[matching_rows] <- psm_data_2group$iptw_weight

cat("\nIPTW重みをマージ完了\n")
cat("重み付き観測数:", sum(!is.na(df_pre_2group$iptw_weight)), "/", nrow(df_pre_2group), "\n")

# ================================================================================
# 6. サンプリングウェイトとの結合
# ================================================================================

df_pre_2group$sampling_weight_norm <- df_pre_2group$v005 / 1000000
df_pre_2group$w_combined <- df_pre_2group$iptw_weight * df_pre_2group$sampling_weight_norm

# トリミング（1st - 99th percentile）
weight_quantiles_combined <- quantile(df_pre_2group$w_combined, c(0.01, 0.99), na.rm = TRUE)
df_pre_2group$w_combined_trimmed <- pmax(
  pmin(df_pre_2group$w_combined, weight_quantiles_combined[2]),
  weight_quantiles_combined[1]
)

cat("\n=== 最終重み（2群版）===\n")
cat("Combined weight (IPTW × sampling):\n")
print(summary(df_pre_2group$w_combined))
cat("\nTrimmed weight (1st-99th percentile):\n")
print(summary(df_pre_2group$w_combined_trimmed))

# ================================================================================
# 7. バランスチェック関数（修正版）- カテゴリ変数対応
# ================================================================================

calculate_smd_robust <- function(data, group_var, vars) {
  results <- data.frame(
    variable = character(0),
    smd = numeric(0),
    mean_control = numeric(0),
    mean_treated = numeric(0),
    var_type = character(0),
    stringsAsFactors = FALSE
  )
  
  for(var in vars) {
    if(!var %in% names(data)) next
    
    tryCatch({
      control_data <- data[data[[group_var]] == 0, var]
      treated_data <- data[data[[group_var]] == 1, var]
      
      if(length(control_data) == 0 || length(treated_data) == 0) next
      
      var_class <- class(data[[var]])[1]
      
      # ============================================================
      # ケース1: 数値変数（numeric, integer）
      # ============================================================
      if(var_class %in% c("numeric", "integer")) {
        mean_c <- mean(control_data, na.rm = TRUE)
        mean_t <- mean(treated_data, na.rm = TRUE)
        var_c <- var(control_data, na.rm = TRUE)
        var_t <- var(treated_data, na.rm = TRUE)
        
        if(is.na(mean_c) || is.na(mean_t) || is.na(var_c) || is.na(var_t)) next
        
        if(var_c + var_t > 0) {
          smd <- abs((mean_t - mean_c) / sqrt((var_t + var_c) / 2))
        } else {
          smd <- abs(mean_t - mean_c)
        }
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd,
          mean_control = mean_c, mean_treated = mean_t,
          var_type = "numeric", stringsAsFactors = FALSE
        ))
        
      # ============================================================
      # ケース2: バイナリ変数（factor with 2 levels）
      # ============================================================
      } else if(var_class == "factor" && nlevels(data[[var]]) == 2) {
        levels_var <- levels(data[[var]])
        positive_level <- levels_var[2]
        
        prop_c <- mean(control_data == positive_level, na.rm = TRUE)
        prop_t <- mean(treated_data == positive_level, na.rm = TRUE)
        
        pooled_var <- prop_c * (1 - prop_c) + prop_t * (1 - prop_t)
        if(pooled_var > 0) {
          smd <- abs((prop_t - prop_c) / sqrt(pooled_var / 2))
        } else {
          smd <- abs(prop_t - prop_c)
        }
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd,
          mean_control = prop_c, mean_treated = prop_t,
          var_type = "binary", stringsAsFactors = FALSE
        ))
        
      # ============================================================
      # ケース3: カテゴリ変数（factor with 3+ levels）
      # ============================================================
      } else if(var_class == "factor" && nlevels(data[[var]]) > 2) {
        levels_var <- levels(data[[var]])
        smd_max <- 0
        
        for(level in levels_var) {
          prop_c <- mean(control_data == level, na.rm = TRUE)
          prop_t <- mean(treated_data == level, na.rm = TRUE)
          
          pooled_var <- prop_c * (1 - prop_c) + prop_t * (1 - prop_t)
          if(pooled_var > 0) {
            smd_level <- abs((prop_t - prop_c) / sqrt(pooled_var / 2))
          } else {
            smd_level <- abs(prop_t - prop_c)
          }
          
          smd_max <- max(smd_max, smd_level)
        }
        
        mean_c <- mean(as.numeric(as.factor(control_data)), na.rm = TRUE)
        mean_t <- mean(as.numeric(as.factor(treated_data)), na.rm = TRUE)
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd_max,
          mean_control = mean_c, mean_treated = mean_t,
          var_type = "categorical", stringsAsFactors = FALSE
        ))
      }
      
    }, error = function(e) {})
  }
  
  return(results)
}

# ================================================================================
# 8. バランスチェック実行（2群版）
# ================================================================================

df_pre_balance_check_2group <- df_pre_2group[!is.na(df_pre_2group$iptw_weight), ]

cat("\n=== バランスチェック開始（2群版） ===\n")
cat("対象サンプル数:", nrow(df_pre_balance_check_2group), "\n")
cat("共変量数:", length(covariate_names), "\n")

balance_before_2group <- calculate_smd_robust(
  df_pre_balance_check_2group,
  "treatment_group",
  covariate_names
)

cat("\n=== バランスチェック（Before PSM、2群版） ===\n")

if(nrow(balance_before_2group) > 0) {
  cat("計算成功した変数数:", nrow(balance_before_2group), "/", length(covariate_names), "\n")
  cat("Mean SMD:", round(mean(balance_before_2group$smd, na.rm=TRUE), 4), "\n")
  cat("Median SMD:", round(median(balance_before_2group$smd, na.rm=TRUE), 4), "\n")
  cat("Max SMD:", round(max(balance_before_2group$smd, na.rm=TRUE), 4), "\n")
  cat("SMD < 0.1:", sum(balance_before_2group$smd < 0.1, na.rm=TRUE), "/", nrow(balance_before_2group), "\n")
  cat("SMD < 0.05:", sum(balance_before_2group$smd < 0.05, na.rm=TRUE), "/", nrow(balance_before_2group), "\n")
  
  # 変数型別の内訳
  if("var_type" %in% names(balance_before_2group)) {
    cat("\n変数型別の内訳:\n")
    print(table(balance_before_2group$var_type))
  }
  
  # バランス結果の表示
  cat("\nTop 10 worst balanced variables (2群版):\n")
  balance_sorted_2group <- balance_before_2group[order(-balance_before_2group$smd), ]
  if("var_type" %in% names(balance_sorted_2group)) {
    print(head(balance_sorted_2group[, c("variable", "smd", "mean_control", "mean_treated", "var_type")], 10))
  } else {
    print(head(balance_sorted_2group[, c("variable", "smd", "mean_control", "mean_treated")], 10))
  }
  
  # Best balanced variables
  cat("\nTop 10 best balanced variables (2群版):\n")
  print(head(balance_sorted_2group[order(balance_sorted_2group$smd), ][, c("variable", "smd", "var_type")], 10))
  
} else {
  cat("エラー: SMD計算が成功した変数が0個です\n")
}

# ================================================================================
# 9. 結果の保存
# ================================================================================

saveRDS(psm_model_2group, file.path(gdrive_dir, "output", "psm_model_2group.rds"))
saveRDS(df_pre_2group, file.path(gdrive_dir, "output", "df_pre_2group_weighted.rds"))

if(nrow(balance_before_2group) > 0) {
  saveRDS(balance_before_2group, file.path(gdrive_dir, "output", "balance_before_2group.rds"))
}

cat("\n=== 2群PSM処理完了 ===\n")
cat("- PSMモデル保存: psm_model_2group.rds\n")
cat("- 重み付きデータ保存: df_pre_2group_weighted.rds\n")
if(nrow(balance_before_2group) > 0) {
  cat("- バランス結果保存: balance_before_2group.rds\n")
}

# ================================================================================
# 10. 可視化（オプション）
# ================================================================================

if(nrow(balance_before_2group) > 0) {
  
  # SMDヒストグラム
  p_smd <- ggplot(balance_before_2group, aes(x = smd)) +
    geom_histogram(bins = 20, alpha = 0.7, fill = "skyblue", color = "black") +
    geom_vline(xintercept = 0.1, color = "red", linetype = "dashed", size = 1) +
    geom_vline(xintercept = 0.05, color = "green", linetype = "dotted", size = 1) +
    labs(
      title = "Distribution of SMD (Before PSM, 2-group)",
      x = "SMD", y = "Count",
      caption = "Red: 0.1 (acceptable) | Green: 0.05 (excellent)"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(p_smd)
  
  # Worst 10変数の棒グラフ
  worst_10 <- head(balance_before_2group[order(-balance_before_2group$smd), ], 10)
  worst_10$variable <- factor(worst_10$variable, levels = worst_10$variable)
  
  p_worst <- ggplot(worst_10, aes(x = smd, y = variable, fill = var_type)) +
    geom_col(alpha = 0.7) +
    geom_vline(xintercept = 0.1, color = "red", linetype = "dashed") +
    labs(
      title = "Top 10 Worst Balanced Variables (2-group)",
      x = "SMD",
      y = "Variable",
      fill = "Type"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(p_worst)
  
  cat("\n=== 可視化完了 ===\n")
}

# ================================================================================
# 11. サマリー出力
# ================================================================================

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("PSM分析サマリー（2群版）\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("サンプルサイズ:\n")
cat("  - 介入前データ(2群):", nrow(df_pre_2group), "行\n")
cat("  - PSM実行:", nrow(psm_data_2group), "行\n")
cat("  - Control:", sum(df_pre_2group$treatment_group == 0, na.rm=TRUE), 
    "/ Early-treated:", sum(df_pre_2group$treatment_group == 1, na.rm=TRUE), "\n")
cat("\nPSM共変量:\n")
cat("  - 使用変数数:", length(covariate_names), "個\n")
cat("  - メディエーター除外: はい (", length(mediator_vars), "個)\n", sep="")
cat("  - アウトカム除外: はい (介入前stunting)\n")
cat("\nIPTW重み:\n")
cat("  - 中央値:", round(median(df_pre_2group$iptw_weight, na.rm=TRUE), 3), "\n")
cat("  - 平均値:", round(mean(df_pre_2group$iptw_weight, na.rm=TRUE), 3), "\n")
cat("  - 最大値:", round(max(df_pre_2group$iptw_weight, na.rm=TRUE), 3), "\n")

if(nrow(balance_before_2group) > 0) {
  cat("\nバランスチェック:\n")
  cat("  - 平均SMD:", round(mean(balance_before_2group$smd, na.rm=TRUE), 4), "\n")
  cat("  - SMD<0.1:", sum(balance_before_2group$smd < 0.1, na.rm=TRUE), "/", 
      nrow(balance_before_2group),
      sprintf("(%.1f%%)", 100*sum(balance_before_2group$smd < 0.1, na.rm=TRUE)/nrow(balance_before_2group)), "\n")
  cat("  - SMD<0.05:", sum(balance_before_2group$smd < 0.05, na.rm=TRUE), "/", 
      nrow(balance_before_2group),
      sprintf("(%.1f%%)", 100*sum(balance_before_2group$smd < 0.05, na.rm=TRUE)/nrow(balance_before_2group)), "\n")
}

cat(paste(rep("=", 70), collapse = ""), "\n")

cat("\n✓ 2群PSM完了。次のステップに進めます。\n")
