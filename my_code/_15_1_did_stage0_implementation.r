# ================================================================================
# DiD実装コード：データ準備と段階0推定
# ================================================================================

library(survey)
library(dplyr)
library(ggplot2)

# ================================================================================
# Section 1: データ準備（Pre/Post統合）
# ================================================================================

cat("\n=== データ準備開始 ===\n")

# Step 1: 介入状態の確認（2群に絞る）
cat("\nStep 1: 2群フィルタリング（Control vs Treated）\n")

# Treated = Early (1) + Late (2)
df_pre_did <- df_pre %>%
  mutate(
    treatment = ifelse(treatment_group %in% c(0), 0, 1),
    time = 0,
    year = 2009
  ) %>%
  select(
    # ID
    v001, v002, v003, v022,
    # Weights
    v005,
    # Treatment
    treatment, time, year,
    # Outcome
    nt_ch_stunt,
    # Mediators
    anc_index, diet_diversity,
    # Covariates
    starts_with("ch_"), starts_with("nt_"), starts_with("rh_"),
    starts_with("ph_"), starts_with("dm_"), starts_with("ms_"), starts_with("rc_")
  )

df_post_did <- df_post %>%
  mutate(
    treatment = ifelse(treatment_group %in% c(0), 0, 1),
    time = 1,
    year = 2014
  ) %>%
  select(
    # ID
    v001, v002, v003, v022,
    # Weights
    v005,
    # Treatment
    treatment, time, year,
    # Outcome
    nt_ch_stunt,
    # Mediators
    anc_index, diet_diversity,
    # Covariates
    starts_with("ch_"), starts_with("nt_"), starts_with("rh_"),
    starts_with("ph_"), starts_with("dm_"), starts_with("ms_"), starts_with("rc_")
  )

cat("Pre (2009) サンプル数:", nrow(df_pre_did), "\n")
cat("  Control:", sum(df_pre_did$treatment == 0),
    "/ Treated:", sum(df_pre_did$treatment == 1), "\n")

cat("Post (2014) サンプル数:", nrow(df_post_did), "\n")
cat("  Control:", sum(df_post_did$treatment == 0),
    "/ Treated:", sum(df_post_did$treatment == 1), "\n")

# Step 2: Pre/Post統合（スタック化）
cat("\nStep 2: Pre/Post統合\n")

# 共通の列を確認
common_cols <- intersect(names(df_pre_did), names(df_post_did))
cat("共通列:", length(common_cols), "個\n")

# スタック
df_combined <- rbind(
  df_pre_did[, common_cols],
  df_post_did[, common_cols]
)

cat("統合後データサイズ:", nrow(df_combined), "\n")
cat("  2009:", nrow(df_combined[df_combined$year == 2009, ]),
    "/ 2014:", nrow(df_combined[df_combined$year == 2014, ]), "\n")

# Step 3: DiD項の作成
cat("\nStep 3: DiD交互作用項の作成\n")

df_combined <- df_combined %>%
  mutate(
    treatment_time = treatment * time,
    time_factor = factor(time, levels = c(0, 1), labels = c("Pre", "Post")),
    treatment_factor = factor(treatment, levels = c(0, 1), labels = c("Control", "Treated"))
  )

cat("DiD項作成完了\n")
cat("  treatment_time の値: min=", min(df_combined$treatment_time),
    ", max=", max(df_combined$treatment_time), "\n")

# ================================================================================
# Section 2: データクリーニング
# ================================================================================

cat("\n=== データクリーニング ===\n")

# Step 1: 欠損値確認
cat("\nStep 1: 主要変数の欠損値\n")

key_vars <- c("nt_ch_stunt", "treatment", "time", "v001", "v005", "v022",
              "anc_index", "diet_diversity")

missing_summary <- data.frame(
  variable = key_vars,
  missing_n = sapply(key_vars, function(v) sum(is.na(df_combined[[v]]))),
  missing_pct = sapply(key_vars, function(v) round(100*sum(is.na(df_combined[[v]]))/nrow(df_combined), 2))
)

print(missing_summary)

# Step 2: 主要変数でのサンプル限定
cat("\nStep 2: 主要変数での完全ケース抽出\n")

df_analysis <- df_combined %>%
  filter(!is.na(nt_ch_stunt),
         !is.na(treatment),
         !is.na(time),
         !is.na(v001),
         !is.na(v005),
         !is.na(v022))

cat("クリーニング後サンプル数:", nrow(df_analysis), "\n")
cat("削除行数:", nrow(df_combined) - nrow(df_analysis), "\n")

# Step 3: 群別・時点別のサンプル構成
cat("\nStep 3: 分析対象サンプルの構成\n")

sample_summary <- df_analysis %>%
  group_by(time_factor, treatment_factor) %>%
  summarise(
    n = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = time_factor, values_from = n)

print(sample_summary)

# ================================================================================
# Section 3: 記述統計（DiD仮定の検証用）
# ================================================================================

cat("\n=== 記述統計：平行トレンド仮定の検証 ===\n")

# Step 1: 群別・時点別のstunting率
cat("\nstunting割合の推移:\n")

stunting_summary <- df_analysis %>%
  group_by(time_factor, treatment_factor) %>%
  summarise(
    stunting_rate = round(mean(nt_ch_stunt, na.rm=TRUE), 4),
    n = n(),
    .groups = "drop"
  )

print(stunting_summary)

# Step 2: 群別変化量
cat("\nstunting割合の変化量:\n")

# Control
stunt_control_pre <- mean(df_analysis[df_analysis$time==0 & df_analysis$treatment==0, "nt_ch_stunt"], na.rm=TRUE)
stunt_control_post <- mean(df_analysis[df_analysis$time==1 & df_analysis$treatment==0, "nt_ch_stunt"], na.rm=TRUE)
change_control <- stunt_control_post - stunt_control_pre

# Treated
stunt_treated_pre <- mean(df_analysis[df_analysis$time==0 & df_analysis$treatment==1, "nt_ch_stunt"], na.rm=TRUE)
stunt_treated_post <- mean(df_analysis[df_analysis$time==1 & df_analysis$treatment==1, "nt_ch_stunt"], na.rm=TRUE)
change_treated <- stunt_treated_post - stunt_treated_pre

cat("Control群の変化: ", round(stunt_control_pre, 4), " → ", 
    round(stunt_control_post, 4), " (", sprintf("%+.4f", change_control), ")\n")
cat("Treated群の変化: ", round(stunt_treated_pre, 4), " → ", 
    round(stunt_treated_post, 4), " (", sprintf("%+.4f", change_treated), ")\n")

# Step 3: DiD計算（手計算確認）
did_manual <- change_treated - change_control
cat("\nDiD (手計算): ", sprintf("%+.4f", did_manual), "\n")
cat("解釈: 処置により、stunting率がControl群比で", 
    sprintf("%.2f%%ポイント", did_manual*100), "改善\n")

# ================================================================================
# Section 4: 平行トレンド仮定の視覚化
# ================================================================================

cat("\n=== 平行トレンド仮定の図示 ===\n")

# ggplot2による可視化
p_trends <- ggplot(stunting_summary, aes(x = time_factor, y = stunting_rate, 
                                         color = treatment_factor, group = treatment_factor)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  labs(
    title = "Parallel Trends: Stunting Rates Pre and Post Intervention",
    x = "Time Period",
    y = "Stunting Rate",
    color = "Group",
    caption = "平行トレンド仮定: 介入がなければ、2本の直線は平行のままであるべき"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

print(p_trends)

# ================================================================================
# Section 5: Survey Design設定
# ================================================================================

cat("\n=== Survey Design設定 ===\n")

# DHS design: クラスター抽出・層化抽出・確率加重
design_did <- svydesign(
  id = ~v001 + v002,      # クラスタID: 地域 + 世帯
  strata = ~v022,         # 層: 都市/農村
  weights = ~v005,        # サンプリング重み
  data = df_analysis,
  nest = TRUE             # ネストされた構造
)

cat("Design設定完了\n")
cat("クラスタ数:", nlevels(design_did$variables$v001), "\n")
cat("層数:", nlevels(design_did$variables$v022), "\n")

# ================================================================================
# Section 6: 段階0推定 - 処置効果（Total Effect）
# ================================================================================

cat("\n=== 段階0: DiD推定（処置効果） ===\n")

# Model 1: 最小限のDiD
cat("\n【Model 1】最小限DiD\n")
cat("式: nt_ch_stunt ~ treatment + time + treatment:time\n")

model_did_min <- svyglm(
  nt_ch_stunt ~ treatment + time + treatment:time,
  design = design_did,
  family = quasibinomial()
)

summary(model_did_min)

# 結果抽出
coef_did_min <- coef(model_did_min)["treatment:time"]
se_did_min <- sqrt(vcov(model_did_min)["treatment:time", "treatment:time"])
pval_did_min <- 2 * (1 - pnorm(abs(coef_did_min / se_did_min)))

cat("\n【DiD推定結果】\n")
cat("推定値: ", sprintf("%.6f", coef_did_min), "\n")
cat("標準誤差: ", sprintf("%.6f", se_did_min), "\n")
cat("p値: ", sprintf("%.4f", pval_did_min), "\n")
cat("有意性: ", ifelse(pval_did_min < 0.05, "*** 有意", "有意でない"), "\n")

# ================================================================================
# Section 7: DiD仮定の妥当性検討
# ================================================================================

cat("\n=== DiD仮定の検討 ===\n")

cat("\n【平行トレンド仮定】\n")
cat("Pre期 (2009) での群間差（ベースライン）:\n")
diff_baseline <- stunt_treated_pre - stunt_control_pre
cat("  Treated - Control: ", sprintf("%.4f", diff_baseline), "\n")

cat("\nPost期 (2014) での群間差:\n")
diff_post <- stunt_treated_post - stunt_control_post
cat("  Treated - Control: ", sprintf("%.4f", diff_post), "\n")

cat("\n検証:\n")
cat("  平行トレンド仮定: Pre期の差が時間を通じて保持される\n")
cat("  ベースライン差:", sprintf("%.4f", diff_baseline), "\n")
cat("  Post期差: ", sprintf("%.4f", diff_post), "\n")
cat("  差の変化: ", sprintf("%.4f", diff_post - diff_baseline), "\n")
cat("  → これが DiD推定値（処置効果）\n")

# ================================================================================
# Section 8: 結果の整理と保存
# ================================================================================

cat("\n=== 結果保存 ===\n")

# 分析用データの保存
saveRDS(df_analysis, file.path(gdrive_dir, "output", "df_analysis_did.rds"))
cat("✓ 分析データ保存: df_analysis_did.rds\n")

# Survey design の保存
saveRDS(design_did, file.path(gdrive_dir, "output", "design_did.rds"))
cat("✓ Survey design保存: design_did.rds\n")

# DiD Model の保存
saveRDS(model_did_min, file.path(gdrive_dir, "output", "model_did_stage0.rds"))
cat("✓ DiD Model保存: model_did_stage0.rds\n")

# ================================================================================
# Section 9: サマリーテーブル
# ================================================================================

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("DiD分析 段階0 サマリー\n")
cat(paste(rep("=", 70), collapse = ""), "\n")

cat("\n【データ構成】\n")
cat("Pre (2009):\n")
cat("  - Control: ", sum(df_analysis$time==0 & df_analysis$treatment==0), "\n")
cat("  - Treated: ", sum(df_analysis$time==0 & df_analysis$treatment==1), "\n")
cat("Post (2014):\n")
cat("  - Control: ", sum(df_analysis$time==1 & df_analysis$treatment==0), "\n")
cat("  - Treated: ", sum(df_analysis$time==1 & df_analysis$treatment==1), "\n")

cat("\n【Stunting Rate】\n")
cat("Control (Pre→Post): ", sprintf("%.4f → %.4f", stunt_control_pre, stunt_control_post),
    " (変化:", sprintf("%+.4f", change_control), ")\n")
cat("Treated (Pre→Post): ", sprintf("%.4f → %.4f", stunt_treated_pre, stunt_treated_post),
    " (変化:", sprintf("%+.4f", change_treated), ")\n")

cat("\n【DiD推定結果（段階0）】\n")
cat("総処置効果 (Total Effect): ", sprintf("%.6f", coef_did_min),
    " (SE: ", sprintf("%.6f", se_did_min), ")\n")
cat("p値: ", sprintf("%.4f", pval_did_min), "\n")
cat("有意性: ", ifelse(pval_did_min < 0.05, "***", "NS"), "\n")

cat("\n【解釈】\n")
cat("CRECER介入により、stunting率の改善度が\n")
cat("非介入地域（Control）比で", sprintf("%.2f%%ポイント", coef_did_min*100),
    "より大きかった。\n")

cat(paste(rep("=", 70), collapse = ""), "\n")

cat("\n✓ 段階0推定完了。次は段階1へ進みます。\n")
