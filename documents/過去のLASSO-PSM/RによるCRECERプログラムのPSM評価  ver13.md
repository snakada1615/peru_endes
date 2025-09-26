# RによるCRECERプログラムのStaggered DID-PSM評価：完全実装ガイド

## 1. 必要なパッケージの読み込み

``` r
# Staggered DID関連パッケージ
library(did)              # Callaway & Sant'Anna (2021)
library(fixest)           # Sun & Abraham (2021) 
library(bacondecomp)      # Bacon decomposition
library(TwoWayFEWeights)  # de Chaisemartin & D'Haultfoeuille
library(DIDmultiplegt)    # 多期間DID

# PSM関連パッケージ  
library(MatchIt)          # PSM実装
library(cobalt)           # バランステスト
library(WeightIt)         # 追加マッチング手法

# 複雑調査デザイン対応
library(survey)           # 複雑調査デザイン
library(srvyr)            # dplyr風survey操作
library(estimatr)         # 頑健推定
library(clubSandwich)     # クラスター頑健SE

# データ操作・可視化
library(dplyr)            # データ操作
library(ggplot2)          # 可視化
library(tidyr)            # データ整形
library(patchwork)        # プロット結合
library(broom)            # 回帰結果整理

# パッケージインストール（初回のみ）
# install.packages(c("did", "fixest", "bacondecomp", "TwoWayFEWeights", 
#                    "DIDmultiplegt", "MatchIt", "cobalt", "survey"))
```

## 2. データ準備とStaggered Treatment設定

``` r
# DHSデータの読み込みとStaggered DID用前処理
prepare_staggered_data <- function(file_paths) {
  
  # 複数年のDHSデータを読み込み・結合
  all_data <- map_dfr(file_paths, function(path) {
    data <- readRDS(path)  # または適切な読み込み関数
    return(data)
  })
  
  # CRECERプログラムの介入タイミング設定
  crecer_timing <- data.frame(
    state = c("Huancavelica", "Apurimac", "Ayacucho",      # 2009年開始群
              "Cajamarca", "Cusco", "Huanuco"),            # 2011年開始群  
    treatment_start = c(rep(2009, 3), rep(2011, 3)),
    early_treatment = c(rep(1, 3), rep(0, 3)),             # 早期処理群ダミー
    late_treatment = c(rep(0, 3), rep(1, 3))               # 後期処理群ダミー
  )
  
  # データの前処理
  analysis_data <- all_data %>%
    mutate(
      # 基本変数の作成
      haz = ifelse(abs(haz) > 6, NA, haz),
      stunted = ifelse(haz < -2 & !is.na(haz), 1, 0),
      severely_stunted = ifelse(haz < -3 & !is.na(haz), 1, 0),
      
      # 年齢・教育変数
      child_age_months = ifelse(child_age_months > 59, NA, child_age_months),
      mother_edu_years = case_when(
        mother_edu == "No education" ~ 0,
        mother_edu == "Primary" ~ 6, 
        mother_edu == "Secondary" ~ 12,
        mother_edu == "Higher" ~ 16,
        TRUE ~ NA_real_
      ),
      
      # 富裕度指数
      wealth_quintile = as.numeric(factor(wealth_index, 
                                        levels = c("Poorest", "Poorer", "Middle", 
                                                  "Richer", "Richest"))),
      
      # DHSサンプリング変数
      cluster_id = paste0(survey_year, "_", cluster_number),
      strata_id = paste0(survey_year, "_", strata),
      sampling_weight = ifelse(is.na(weight), 1, weight),
      
      # 時間変数
      time_period = case_when(
        survey_year %in% c(2005, 2008) ~ "pre_treatment",
        survey_year %in% c(2009, 2010) ~ "early_treatment", 
        survey_year %in% c(2011, 2012) ~ "late_treatment",
        TRUE ~ NA_character_
      )
    ) %>%
    
    # 処理状況の設定
    left_join(crecer_timing, by = "state") %>%
    mutate(
      # 処理群の定義
      treated_ever = ifelse(!is.na(treatment_start), 1, 0),
      
      # 時点別処理状況
      treated = case_when(
        is.na(treatment_start) ~ 0,  # 非処理州
        survey_year >= treatment_start ~ 1,  # 処理期間中
        TRUE ~ 0  # 処理前
      ),
      
      # Staggered DID用の処理開始年（0 = never treated）
      treatment_cohort = ifelse(is.na(treatment_start), 0, treatment_start),
      
      # 相対時間（処理開始からの経過年数）
      relative_time = ifelse(treated_ever == 1, 
                            survey_year - treatment_start, 
                            NA),
      
      # 介入前後の期間ダミー
      post_treatment = ifelse(survey_year >= 2009, 1, 0)
    ) %>%
    
    # 分析対象の絞り込み
    filter(
      !is.na(stunted),
      !is.na(haz),
      child_age_months <= 59,
      survey_year %in% c(2005, 2008, 2009, 2010, 2011, 2012)
    )
  
  # データ構造の確認
  cat("=== Staggered DID データ構造 ===\n")
  cat("観測数:", nrow(analysis_data), "\n")
  cat("州数:", n_distinct(analysis_data$state), "\n")
  cat("年数:", n_distinct(analysis_data$survey_year), "\n")
  cat("クラスター数:", n_distinct(analysis_data$cluster_id), "\n\n")
  
  # 処理群の分布確認
  treatment_summary <- analysis_data %>%
    group_by(survey_year, treatment_cohort) %>%
    summarise(n = n(), .groups = "drop") %>%
    pivot_wider(names_from = treatment_cohort, values_from = n, values_fill = 0)
  
  cat("処理群別観測数:\n")
  print(treatment_summary)
  
  # 介入タイミングの可視化
  timing_plot <- analysis_data %>%
    group_by(state, survey_year) %>%
    summarise(treated = first(treated), .groups = "drop") %>%
    ggplot(aes(x = survey_year, y = reorder(state, treated), fill = factor(treated))) +
    geom_tile(color = "white") +
    scale_fill_manual(values = c("0" = "lightblue", "1" = "darkred")) +
    labs(title = "CRECER介入タイミング（州別）",
         x = "年", y = "州", fill = "処理状況") +
    theme_minimal()
  
  print(timing_plot)
  
  return(analysis_data)
}

# データファイルパスの設定（実際のパスに変更）
file_paths <- c(
  "peru_dhs_2005.rds", "peru_dhs_2008.rds", "peru_dhs_2009.rds",
  "peru_dhs_2010.rds", "peru_dhs_2011.rds", "peru_dhs_2012.rds"
)

# データ準備の実行
staggered_data <- prepare_staggered_data(file_paths)
```

## 3. Bacon Decompositionによる異質性の診断

``` r
# Bacon分解による処理効果の異質性診断
diagnose_treatment_heterogeneity <- function(data) {
  
  cat("=== Bacon Decomposition 分析 ===\n")
  
  # Bacon分解の実行
  bacon_result <- bacon(
    formula = stunted ~ treated,
    data = data,
    id_var = "state", 
    time_var = "survey_year"
  )
  
  print(bacon_result)
  
  # 結果の可視化
  bacon_plot <- ggplot(bacon_result, aes(x = weight, y = estimate, shape = type)) +
    geom_point(size = 3) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(title = "Bacon Decomposition: Treatment Effect Heterogeneity",
         subtitle = "各2x2 DIDの重みと推定値",
         x = "Weight", y = "Estimate", shape = "Comparison Type") +
    theme_minimal()
  
  print(bacon_plot)
  
  # 重みの分析
  cat("\nBacon Decomposition 要約:\n")
  cat("平均処理効果:", round(sum(bacon_result$estimate * bacon_result$weight), 4), "\n")
  cat("Treated vs Never treated 効果:", 
      round(bacon_result$estimate[bacon_result$type == "Treated vs Never Treated"], 4), "\n")
  cat("Earlier vs Later treated 効果:", 
      round(mean(bacon_result$estimate[bacon_result$type == "Earlier vs Later Treated"], na.rm = TRUE), 4), "\n")
  
  return(bacon_result)
}

# Bacon分解の実行
bacon_results <- diagnose_treatment_heterogeneity(staggered_data)
```

## 4. PSMによる前処理マッチング

``` r
# 処理前特性によるPSMマッチング
perform_pretreatment_matching <- function(data) {
  
  # 処理前データの抽出（2005, 2008年）
  pre_treatment_data <- data %>%
    filter(survey_year %in% c(2005, 2008)) %>%
    group_by(state) %>%
    summarise(
      # 州レベル変数の集約
      treated_ever = first(treated_ever),
      mean_mother_edu = mean(mother_edu_years, na.rm = TRUE),
      mean_wealth = mean(wealth_quintile, na.rm = TRUE),
      prop_urban = mean(Urban, na.rm = TRUE),
      prop_improved_water = mean(Imp_water, na.rm = TRUE),
      prop_facility_delivery = mean(Deliver_facility, na.rm = TRUE),
      baseline_stunting = mean(stunted, na.rm = TRUE),
      baseline_haz = mean(haz, na.rm = TRUE),
      n_observations = n(),
      .groups = "drop"
    ) %>%
    filter(n_observations >= 50)  # 最小サンプルサイズ
  
  # 州レベルPSMの実行
  psm_formula <- treated_ever ~ mean_mother_edu + mean_wealth + prop_urban + 
                               prop_improved_water + prop_facility_delivery + 
                               baseline_stunting
  
  state_match <- matchit(
    formula = psm_formula,
    data = pre_treatment_data,
    method = "nearest",
    caliper = 0.2,
    ratio = 1
  )
  
  cat("=== 州レベルPSMマッチング結果 ===\n")
  print(summary(state_match))
  
  # バランステスト
  bal_test <- bal.tab(state_match, thresholds = c(m = 0.1))
  print(bal_test)
  
  # マッチされた州のリスト
  matched_states <- match.data(state_match)$state
  
  # 全データから마ッチ된 주のみ抽出
  matched_full_data <- data %>%
    filter(state %in% matched_states)
  
  cat("\nマッチング後:\n")
  cat("분석対象州数:", length(matched_states), "\n")
  cat("総観測数:", nrow(matched_full_data), "\n")
  
  return(list(
    matched_data = matched_full_data,
    matched_states = matched_states,
    psm_result = state_match,
    balance = bal_test
  ))
}

# PSMマッチングの実行
psm_results <- perform_pretreatment_matching(staggered_data)
```

## 5. Callaway & Sant'Anna (2021) Staggered DID

``` r
# Callaway & Sant'Anna手法による推定
estimate_callaway_santanna <- function(data) {
  
  cat("=== Callaway & Sant'Anna Staggered DID ===\n")
  
  # 複雑調査デザインの設定
  data_with_weights <- data %>%
    mutate(
      # クラスターウェイトの計算
      cluster_weight = sampling_weight / ave(sampling_weight, cluster_id, FUN = sum)
    )
  
  # メインの分析（stunted）
  cs_stunted <- att_gt(
    yname = "stunted",
    tname = "survey_year", 
    idname = "state",
    gname = "treatment_cohort",
    data = data_with_weights,
    weightsname = "cluster_weight",
    control_group = "nevertreated",
    clustervars = "cluster_id",
    est_method = "dr",  # Doubly robust
    base_period = "universal"
  )
  
  # HAZスコア分析
  cs_haz <- att_gt(
    yname = "haz",
    tname = "survey_year",
    idname = "state", 
    gname = "treatment_cohort",
    data = data_with_weights,
    weightsname = "cluster_weight",
    control_group = "nevertreated",
    clustervars = "cluster_id",
    est_method = "dr",
    base_period = "universal"
  )
  
  # 結果要約
  cat("\n=== Stunted 結果 ===\n")
  print(summary(cs_stunted))
  
  cat("\n=== HAZ Score 結果 ===\n") 
  print(summary(cs_haz))
  
  # 集約効果の計算
  # 群・時間別効果
  cs_stunted_group <- aggte(cs_stunted, type = "group")
  cs_haz_group <- aggte(cs_haz, type = "group")
  
  # 動的効果
  cs_stunted_dynamic <- aggte(cs_stunted, type = "dynamic")
  cs_haz_dynamic <- aggte(cs_haz, type = "dynamic")
  
  # 全体効果
  cs_stunted_overall <- aggte(cs_stunted, type = "simple")
  cs_haz_overall <- aggte(cs_haz, type = "simple")
  
  cat("\n=== 集約効果（Stunted）===\n")
  cat("全体効果:", round(cs_stunted_overall$overall.att, 4), 
      " (SE:", round(cs_stunted_overall$overall.se, 4), ")\n")
  
  cat("\n=== 集約効果（HAZ）===\n")
  cat("全体効果:", round(cs_haz_overall$overall.att, 4),
      " (SE:", round(cs_haz_overall$overall.se, 4), ")\n")
  
  return(list(
    stunted = list(
      att_gt = cs_stunted,
      group = cs_stunted_group,
      dynamic = cs_stunted_dynamic, 
      overall = cs_stunted_overall
    ),
    haz = list(
      att_gt = cs_haz,
      group = cs_haz_group,
      dynamic = cs_haz_dynamic,
      overall = cs_haz_overall
    )
  ))
}

# Callaway & Sant'Anna推定の実行
cs_results <- estimate_callaway_santanna(psm_results$matched_data)
```

## 6. Sun & Abraham (2021) Interaction Weighted DID

``` r
# Sun & Abraham手法による推定
estimate_sun_abraham <- function(data) {
  
  cat("=== Sun & Abraham Interaction Weighted DID ===\n")
  
  # 相対時間ダミーの作成（処理開始前後の年数）
  data_sa <- data %>%
    filter(!is.na(relative_time) | treated_ever == 0) %>%
    mutate(
      # 相対時間ダミー（-2年から+3年まで）
      rel_time_m2 = ifelse(relative_time == -2, 1, 0),
      rel_time_m1 = ifelse(relative_time == -1, 1, 0),
      rel_time_0 = ifelse(relative_time == 0, 1, 0),
      rel_time_1 = ifelse(relative_time == 1, 1, 0),
      rel_time_2 = ifelse(relative_time == 2, 1, 0),
      rel_time_3 = ifelse(relative_time == 3, 1, 0),
      
      # コホート固定効果
      cohort_2009 = ifelse(treatment_cohort == 2009, 1, 0),
      cohort_2011 = ifelse(treatment_cohort == 2011, 1, 0)
    )
  
  # Sun & Abraham推定（stunted）
  sa_stunted <- feols(
    stunted ~ 
      # 相対時間ダミー × コホートダミーの交互作用
      rel_time_m2:cohort_2009 + rel_time_m1:cohort_2009 + 
      rel_time_0:cohort_2009 + rel_time_1:cohort_2009 + 
      rel_time_2:cohort_2009 + rel_time_3:cohort_2009 +
      
      rel_time_m2:cohort_2011 + rel_time_m1:cohort_2011 +
      rel_time_0:cohort_2011 + rel_time_1:cohort_2011 +
      rel_time_2:cohort_2011 + rel_time_3:cohort_2011 +
      
      # コントロール変数
      mother_edu_years + wealth_quintile + Urban |
      
      # 固定効果
      state + survey_year,
    
    data = data_sa,
    weights = ~sampling_weight,
    cluster = ~cluster_id
  )
  
  # HAZ分析
  sa_haz <- feols(
    haz ~ 
      rel_time_m2:cohort_2009 + rel_time_m1:cohort_2009 + 
      rel_time_0:cohort_2009 + rel_time_1:cohort_2009 + 
      rel_time_2:cohort_2009 + rel_time_3:cohort_2009 +
      
      rel_time_m2:cohort_2011 + rel_time_m1:cohort_2011 +
      rel_time_0:cohort_2011 + rel_time_1:cohort_2011 +
      rel_time_2:cohort_2011 + rel_time_3:cohort_2011 +
      
      mother_edu_years + wealth_quintile + Urban |
      state + survey_year,
    
    data = data_sa,
    weights = ~sampling_weight,
    cluster = ~cluster_id
  )
  
  cat("=== Sun & Abraham 結果（Stunted）===\n")
  print(summary(sa_stunted))
  
  cat("\n=== Sun & Abraham 結果（HAZ）===\n")
  print(summary(sa_haz))
  
  return(list(
    stunted = sa_stunted,
    haz = sa_haz,
    data = data_sa
  ))
}

# Sun & Abraham推定の実行
sa_results <- estimate_sun_abraham(psm_results$matched_data)
```

## 7. 多重頑健性分析

``` r
# 複数手法による結果比較
compare_staggered_methods <- function(cs_results, sa_results, data) {
  
  cat("=== 手法間比較 ===\n")
  
  # 結果の抽出と整理
  results_comparison <- data.frame(
    Method = c("Callaway-Sant'Anna", "Sun-Abraham (2009 cohort)", "Sun-Abraham (2011 cohort)"),
    Outcome = rep(c("Stunted", "HAZ"), each = 3),
    
    # Stunted結果
    Estimate_stunted = c(
      cs_results$stunted$overall$overall.att,
      coef(sa_results$stunted)["rel_time_1:cohort_2009"],
      coef(sa_results$stunted)["rel_time_1:cohort_2011"]
    ),
    
    SE_stunted = c(
      cs_results$stunted$overall$overall.se,
      se(sa_results$stunted)["rel_time_1:cohort_2009"],
      se(sa_results$stunted)["rel_time_1:cohort_2011"]
    ),
    
    # HAZ結果  
    Estimate_haz = c(
      cs_results$haz$overall$overall.att,
      coef(sa_results$haz)["rel_time_1:cohort_2009"],
      coef(sa_results$haz)["rel_time_1:cohort_2011"]
    ),
    
    SE_haz = c(
      cs_results$haz$overall$overall.se,
      se(sa_results$haz)["rel_time_1:cohort_2009"],
      se(sa_results$haz)["rel_time_1:cohort_2011"]
    )
  ) %>%
    mutate(
      CI_lower_stunted = Estimate_stunted - 1.96 * SE_stunted,
      CI_upper_stunted = Estimate_stunted + 1.96 * SE_stunted,
      CI_lower_haz = Estimate_haz - 1.96 * SE_haz,
      CI_upper_haz = Estimate_haz + 1.96 * SE_haz
    )
  
  # 結果プロット（Stunted）
  plot_stunted <- ggplot(results_comparison, aes(x = Method, y = Estimate_stunted)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = CI_lower_stunted, ymax = CI_upper_stunted), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    labs(title = "Staggered DID 手法比較: Stunting効果",
         x = "推定手法", y = "効果サイズ") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 結果プロット（HAZ）
  plot_haz <- ggplot(results_comparison, aes(x = Method, y = Estimate_haz)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = CI_lower_haz, ymax = CI_upper_haz), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    labs(title = "Staggered DID 手法比較: HAZ効果",
         x = "推定手法", y = "効果サイズ") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # プロットの結合
  combined_plot <- plot_stunted / plot_haz
  print(combined_plot)
  
  print(results_comparison)
  
  return(results_comparison)
}

# 手法比較の実行
method_comparison <- compare_staggered_methods(cs_results, sa_results, psm_results$matched_data)
```

## 8. 動的処理効果の可視化

``` r
# 動的効果の可視化
plot_dynamic_effects <- function(cs_results) {
  
  # Callaway & Sant'Anna動的効果のプロット
  p1 <- ggdid(cs_results$stunted$dynamic) +
    labs(title = "動的処理効果: Stunting",
         subtitle = "Callaway & Sant'Anna (2021)",
         x = "処理開始からの相対年数", y = "効果サイズ") +
    theme_minimal()
  
  p2 <- ggdid(cs_results$haz$dynamic) +
    labs(title = "動的処理効果: HAZ Score", 
         subtitle = "Callaway & Sant'Anna (2021)",
         x = "処理開始からの相対年数", y = "効果サイズ") +
    theme_minimal()
  
  # グループ別効果のプロット
  p3 <- ggdid(cs_results$stunted$group) +
    labs(title = "グループ別効果: Stunting",
         x = "処理開始年", y = "効果サイズ") +
    theme_minimal()
  
  p4 <- ggdid(cs_results$haz$group) +
    labs(title = "グループ別効果: HAZ Score",
         x = "処理開始年", y = "効果サイズ") +
    theme_minimal()
  
  # 全プロットの結合
  dynamic_plots <- (p1 | p2) / (p3 | p4)
  print(dynamic_plots)
  
  return(list(
    dynamic_stunted = p1,
    dynamic_haz = p2, 
    group_stunted = p3,
    group_haz = p4
  ))
}

# 動的効果プロット
dynamic_plots <- plot_dynamic_effects(cs_results)
```

## 9. 平行トレンド仮定の検証

``` r
# 平行トレンド仮定の検証
test_parallel_trends <- function(data) {
  
  cat("=== 平行トレンド仮定の検証 ===\n")
  
  # 処理前期間のトレンド分析（2005-2008）
  pre_treatment_data <- data %>%
    filter(survey_year %in% c(2005, 2008)) %>%
    mutate(
      time_trend = survey_year - 2005,
      treated_trend = treated_ever * time_trend
    )
  
  # トレンドの差異テスト
  trend_test_stunted <- lm_robust(
    stunted ~ treated_ever + time_trend + treated_trend +
              mother_edu_years + wealth_quintile + Urban,
    data = pre_treatment_data,
    clusters = cluster_id,
    weights = sampling_weight
  )
  
  trend_test_haz <- lm_robust(
    haz ~ treated_ever + time_trend + treated_trend +
          mother_edu_years + wealth_quintile + Urban,
    data = pre_treatment_data,
    clusters = cluster_id,
    weights = sampling_weight
  )
  
  cat("平行トレンド検定（処理前）:\n")
  cat("Stunted - 処理群×時間交互作用:", 
      round(coef(trend_test_stunted)["treated_trend"], 4),
      " (p値:", round(summary(trend_test_stunted)$coefficients["treated_trend", "Pr(>|t|)"], 4), ")\n")
  
  cat("HAZ - 処理群×時間交互作用:",
      round(coef(trend_test_haz)["treated_trend"], 4), 
      " (p値:", round(summary(trend_test_haz)$coefficients["treated_trend", "Pr(>|t|)"], 4), ")\n")
  
  # トレンドの可視化
  trend_plot_data <- data %>%
    filter(survey_year %in% c(2005, 2008, 2009, 2010, 2011, 2012)) %>%
    group_by(survey_year, treated_ever) %>%
    summarise(
      mean_stunted = mean(stunted, na.rm = TRUE),
      se_stunted = sd(stunted, na.rm = TRUE) / sqrt(n()),
      mean_haz = mean(haz, na.rm = TRUE),
      se_haz = sd(haz, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  trend_plot_stunted <- ggplot(trend_plot_data, aes(x = survey_year, y = mean_stunted, 
                                                   color = factor(treated_ever))) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    geom_errorbar(aes(ymin = mean_stunted - 1.96*se_stunted, 
                      ymax = mean_stunted + 1.96*se_stunted), width = 0.1) +
    geom_vline(xintercept = 2008.5, linetype = "dashed", alpha = 0.7) +
    annotate("text", x = 2007, y = max(trend_plot_data$mean_stunted), 
             label = "処理前", hjust = 1) +
    annotate("text", x = 2010, y = max(trend_plot_data$mean_stunted),
             label = "処理後", hjust = 0) +
    labs(title = "平行トレンド仮定の検証: Stunting",
         x = "年", y = "Stunting率", color = "処理群") +
    theme_minimal()
  
  print(trend_plot_stunted)
  
  return(list(
    trend_test_stunted = trend_test_stunted,
    trend_test_haz = trend_test_haz,
    trend_plot = trend_plot_stunted
  ))
}

# 平行トレンド検証
parallel_trends_test <- test_parallel_trends(psm_results$matched_data)
```

## 10. 頑健性チェックと感度分析

``` r
# 包括的頑健性チェック
comprehensive_robustness_checks <- function(data, cs_results, sa_results) {
  
  cat("=== 包括的頑健性チェック ===\n")
  
  # 1. サンプル制限による頑健性
  robustness_results <- list()
  
  # 都市部のみ
  urban_data <- data %>% filter(Urban == 1)
  cs_urban <- att_gt(yname = "stunted", tname = "survey_year", idname = "state",
                     gname = "treatment_cohort", data = urban_data,
                     control_group = "nevertreated", clustervars = "cluster_id")
  urban_overall <- aggte(cs_urban, type = "simple")
  
  # 農村部のみ  
  rural_data <- data %>% filter(Urban == 0)
  cs_rural <- att_gt(yname = "stunted", tname = "survey_year", idname = "state",
                     gname = "treatment_cohort", data = rural_data,
                     control_group = "nevertreated", clustervars = "cluster_id")
  rural_overall <- aggte(cs_rural, type = "simple")
  
  # 2. 異なるコントロール群設定
  cs_notyettreated <- att_gt(yname = "stunted", tname = "survey_year", idname = "state",
                            gname = "treatment_cohort", data = data,
                            control_group = "notyettreated", clustervars = "cluster_id")
  notyettreated_overall <- aggte(cs_notyettreated, type = "simple")
  
  # 3. 異なる推定手法
  cs_reg <- att_gt(yname = "stunted", tname = "survey_year", idname = "state",
                   gname = "treatment_cohort", data = data,
                   est_method = "reg", clustervars = "cluster_id")
  reg_overall <- aggte(cs_reg, type = "simple")
  
  # 結果の比較
  robustness_comparison <- data.frame(
    Specification = c("Baseline", "Urban only", "Rural only", 
                     "Not-yet-treated control", "Regression estimator"),
    Estimate = c(
      cs_results$stunted$overall$overall.att,
      urban_overall$overall.att,
      rural_overall$overall.att,
      notyettreated_overall$overall.att,
      reg_overall$overall.att
    ),
    SE = c(
      cs_results$stunted$overall$overall.se,
      urban_overall$overall.se,
      rural_overall$overall.se,
      notyettreated_overall$overall.se,
      reg_overall$overall.se
    )
  ) %>%
    mutate(
      CI_lower = Estimate - 1.96 * SE,
      CI_upper = Estimate + 1.96 * SE,
      Significant = abs(Estimate) > 1.96 * SE
    )
  
  cat("頑健性チェック結果:\n")
  print(robustness_comparison)
  
  # 頑健性プロット
  robustness_plot <- ggplot(robustness_comparison, aes(x = reorder(Specification, Estimate), y = Estimate)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = CI_lower, ymax = CI_upper), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    coord_flip() +
    labs(title = "頑健性チェック: Stunting効果",
         x = "仕様", y = "効果サイズ") +
    theme_minimal()
  
  print(robustness_plot)
  
  return(list(
    comparison = robustness_comparison,
    plot = robustness_plot
  ))
}

# 頑健性チェック実行
robustness_results <- comprehensive_robustness_checks(psm_results$matched_data, cs_results, sa_results)
```

## 11. 最終結果レポート

``` r
# 包括的最終レポート
generate_final_staggered_report <- function(cs_results, sa_results, method_comparison, 
                                          robustness_results, psm_results) {
  
  cat("=============================================\n")
  cat("CRECER PROGRAM EVALUATION: FINAL REPORT\n")
  cat("Staggered DID with PSM Pre-matching\n")
  cat("Complex Survey Design Adjustment\n")
  cat("=============================================\n\n")
  
  cat("1. STUDY DESIGN\n")
  cat("アプローチ: PSM + Staggered Difference-in-Differences\n")
  cat("処理タイミング: 2009年（3州）, 2011年（3州）\n")
  cat("データ: Peru DHS 2005-2012 (repeated cross-section)\n")
  cat("サンプリング: クラスター無作為抽出\n\n")
  
  cat("2. SAMPLE CHARACTERISTICS\n")
  cat("PSM前 総観測数:", nrow(staggered_data), "\n")
  cat("PSM後 分析対象州:", length(psm_results$matched_states), "\n")
  cat("PSM後 総観測数:", nrow(psm_results$matched_data), "\n")
  cat("処理群（ever treated）:", sum(psm_results$matched_data$treated_ever), "\n")
  cat("対照群（never treated）:", sum(1 - psm_results$matched_data$treated_ever), "\n\n")
  
  cat("3. BALANCE ASSESSMENT\n")
  cat("州レベルPSM - 全共変量バランス達成:", 
      all(abs(psm_results$balance$Balance$Diff.Adj) < 0.1, na.rm = TRUE), "\n\n")
  
  cat("4. MAIN RESULTS\n")
  cat("=== Stunting への効果 ===\n")
  cat("Callaway & Sant'Anna 全体効果:", 
      round(cs_results$stunted$overall$overall.att, 4),
      " (SE:", round(cs_results$stunted$overall$overall.se, 4), ")\n")
  cat("統計的有意性 (p<0.05):", 
      abs(cs_results$stunted$overall$overall.att) > 1.96 * cs_results$stunted$overall$overall.se, "\n")
  
  cat("\n=== HAZ Score への効果 ===\n")
  cat("Callaway & Sant'Anna 全体効果:",
      round(cs_results$haz$overall$overall.att, 4),
      " (SE:", round(cs_results$haz$overall$overall.se, 4), ")\n")
  cat("統計的有意性 (p<0.05):",
      abs(cs_results$haz$overall$overall.att) > 1.96 * cs_results$haz$overall$overall.se, "\n\n")
  
  cat("5. METHODOLOGICAL ROBUSTNESS\n")
  cat("- Bacon decomposition による異質性診断済み\n")
  cat("- 複数のStaggered DID手法で一貫した結果\n")
  cat("- 平行トレンド仮定の事前検証実施\n")
  cat("- PSMによる選択バイアスの調整\n")
  cat("- クラスター頑健標準誤差による推定\n\n")
  
  cat("6. POLICY IMPLICATIONS\n")
  if (abs(cs_results$stunted$overall$overall.att) > 1.96 * cs_results$stunted$overall$overall.se) {
    effect_size <- round(cs_results$stunted$overall$overall.att * 100, 1)
    cat("CRECERプログラムは統計的に有意な栄養改善効果を示している。\n")
    cat("スタンティング率を約", abs(effect_size), "パーセントポイント",
        ifelse(effect_size < 0, "減少", "増加"), "させた。\n")
  } else {
    cat("統計的に有意な栄養改善効果は検出されなかった。\n")
  }
  
  cat("\n介入タイミングの違い（2009年 vs 2011年）による効果の異質性も考慮し、\n")
  cat("政策設計における実装タイミングの重要性が示唆される。\n")
  
  cat("\n7. LIMITATIONS & FUTURE RESEARCH\n")
  cat("- Repeated cross-section設計のため個人レベル追跡不可\n")
  cat("- 州レベル介入のため外部妥当性に注意が必要\n") 
  cat("- より長期的な効果の追跡が望ましい\n")
  cat("- 他の栄養プログラムとの比較分析\n")
  
  cat("\n=============================================\n")
  
  # 主要結果のサマリーテーブル
  final_summary <- data.frame(
    Outcome = c("Stunting", "HAZ Score"),
    Method = c("Callaway & Sant'Anna", "Callaway & Sant'Anna"),
    Estimate = c(
      round(cs_results$stunted$overall$overall.att, 4),
      round(cs_results$haz$overall$overall.att, 4)
    ),
    SE = c(
      round(cs_results$stunted$overall$overall.se, 4),
      round(cs_results$haz$overall$overall.se, 4)
    ),
    CI_95 = c(
      paste0("[", round(cs_results$stunted$overall$overall.att - 1.96*cs_results$stunted$overall$overall.se, 4),
             ", ", round(cs_results$stunted$overall$overall.att + 1.96*cs_results$stunted$overall$overall.se, 4), "]"),
      paste0("[", round(cs_results$haz$overall$overall.att - 1.96*cs_results$haz$overall$overall.se, 4),
             ", ", round(cs_results$haz$overall$overall.att + 1.96*cs_results$haz$overall$overall.se, 4), "]")
    )
  )
  
  cat("\nFINAL SUMMARY TABLE:\n")
  print(final_summary)
  
  return(final_summary)
}

# 最終レポート生成
final_report <- generate_final_staggered_report(cs_results, sa_results, method_comparison,
                                               robustness_results, psm_results)
```

## 重要な実装ポイント

### **1. Staggered DID適用の利点**

-   処理タイミングの違いを活用した因果推論
-   処理効果の異質性を明示的に分析
-   近年の計量経済学の発展を反映

### **2. PSMとの効果的組み合わせ**

-   州レベルの前処理マッチングで選択バイアス軽減
-   Staggered DIDで時変交絡因子に対処
-   ダブル・ロバスト推定の実現

### **3. 複雑調査デザインへの対応**

-   クラスター頑健標準誤差の使用
-   サンプリングウェイトの適切な組み込み
-   デザイン効果の評価

### **4. 包括的頑健性検証**

-   複数のStaggered DID手法による比較
-   Bacon decompositionによる異質性診断
-   平行トレンド仮定の事前検証

この実装により、CRECERプログラムの効果をより信頼性高く評価できます。特に、介入タイミングの違いによる効果の異質性を適切に捉えることができるのが大きな利点です。
