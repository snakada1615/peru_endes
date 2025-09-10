library(here) # for file paths
library(haven) # for reading/writing .dta files
library(tidyr) # for data manipulation
library(ggplot2) # for plotting
library(tidyverse) # for data manipulation and visualization
library(labelled) # for variable labels)


# rmですべてのオブジェクトを削除
rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# 各種変数設定

# 年度の設定
# year <- c("2012")
# loopを回す場合
years <- c("2005", "2008", "2009", "2010", "2011", "2012")

# CRECERプログラムの介入期間
crecer_timing <- read_csv(normalizePath(here("my_code", "state_list.csv"))) %>%
  mutate(
    state_id = as.character(state_id), # state_idを文字列に変換
    treatment_start = as.numeric(year_treated) # treatment_startを数値に変換
  ) 


# ********************************************************************************************************************************
# DHSデータの読み込みとStaggered DID用介入期間設定
prepare_staggered_data <- function(my_data_frame, timing_crecer) {

  all_data <- my_data_frame %>%
    left_join(timing_crecer, by = "state_id") %>%
    mutate(
      treated_status = case_when(
        is.na(year_treated) ~ "never_treated",                            # どれにも該当しない
        year_treated == 2009 & as.numeric(year) >= 2009 ~ "early_treated",# 早期開始州かつ2009年以降
        year_treated == 2011 & as.numeric(year) >= 2011 ~ "late_treated", # 後期開始州かつ2011年以降
        TRUE ~ "not_yet_treated"                                             # 将来的にtreatedになるが年が到達していない
      )
  )
  
  print(names(all_data))
  # データの前処理
  analysis_data <- all_data %>%
    mutate(
      # 時間変数
      time_period = case_when(
        year %in% c(2005, 2008) ~ "pre_treatment",
        year %in% c(2009, 2010) ~ "early_treatment", 
        year %in% c(2011, 2012) ~ "late_treatment",
        TRUE ~ NA_character_
      )
    ) %>%
    
    # 処理状況の設定
    mutate(
      # 処理群の定義
      treated_ever = ifelse(!is.na(year_treated), 1, 0),
      
      # 時点別処理状況
      treated = case_when(
        is.na(year_treated) ~ 0,  # 非処理州
        year >= year_treated ~ 1,  # 処理期間中
        TRUE ~ 0  # 処理前
      ),
      
      # Staggered DID用の処理開始年（0 = never treated）
      treatment_cohort = ifelse(is.na(year_treated), 0, year_treated),
      
      # 相対時間（処理開始からの経過年数）
      relative_time = ifelse(treated_ever == 1, 
                            as.numeric(year) - year_treated, 
                             NA),
      
      # 介入前後の期間ダミー
      post_treatment = ifelse(year >= 2009, 1, 0)
    ) %>%
    
    # 分析対象の絞り込み
    filter(
      !is.na(nt_ch_stunt),
      !is.na(nt_ch_whz),
      age <= 59,
      year %in% c(2005, 2008, 2009, 2010, 2011, 2012)
    )
  
  # データ構造の確認
  cat("=== Staggered DID データ構造 ===\n")
  cat("観測数:", nrow(analysis_data), "\n")
  cat("州数:", n_distinct(analysis_data$state_id), "\n")
  cat("年数:", n_distinct(analysis_data$year), "\n")
  cat("クラスター数:", n_distinct(analysis_data$v001), "\n\n")
  
  # 処理群の分布確認
  treatment_summary <- analysis_data %>%
    group_by(year, treatment_cohort) %>%
    summarise(n = n(), .groups = "drop") %>%
    pivot_wider(names_from = treatment_cohort, values_from = n, values_fill = 0)
  
  cat("処理群別観測数:\n")
  print(treatment_summary)
  
  # 介入・非介入の６区分設定
  analysis_data <- analysis_data %>%
    mutate(
      group_summary = case_when(
        is.na(year_treated) & as.numeric(year) < 2009 ~ "control_0",
        is.na(year_treated) & as.numeric(year) >= 2009 & as.numeric(year) < 2011 ~ "control_1",
        is.na(year_treated) & as.numeric(year) >= 2011 ~ "control_2", 
        year_treated == 2009 & as.numeric(year) < 2009 ~ "treat1_0",
        year_treated == 2009 & as.numeric(year) >= 2009 ~ "treat1_1",
        year_treated == 2011 & as.numeric(year) < 2011 ~ "treat2_0",
        year_treated == 2011 & as.numeric(year) >= 2011 ~ "treat2_1",
        TRUE ~ "other"  # デバッグ用に変更
      )
    )
  
  # 介入タイミングの可視化
  timing_plot <- analysis_data %>%
    group_by(state_id, state, year) %>%
    summarise(treated = first(treated), .groups = "drop") %>%
    ggplot(aes(x = year, y = reorder(state, treated), fill = factor(treated))) +
    geom_tile(color = "gray") +
    scale_fill_manual(values = c("0" = "lightblue", "1" = "darkred")) +
    labs(
      title = "timing of CRECER introduction by department",
      x = "year",
      y = "state",  # 州の名称
      fill = "status of treatment"
    ) +
    theme_minimal()
  print(timing_plot)  
  
  ggsave(filename = here("..", "output", "image", "timing_crecer.png"), plot = timing_plot, width = 10, height = 6)
  
  return(analysis_data)
}
# ********************************************************************************************************************************

# ファイル名の設定
df <- list()
for (year in years) {
  print(sprintf("Processing year: %s", year))
  filename <- here("..", "output", year, paste0("merge_all_", year, ".dta"))
  df[[year]] <- read_dta(filename)
}

# データフレームの結合
merged_df <- do.call(rbind, df) %>%
  mutate(
    state_id = as.character(v024),        # stateを生成
    )

# データ準備の実行
merged_df <- prepare_staggered_data(merged_df, crecer_timing)

merged_df <- merged_df %>%
  set_variable_labels(
    year = "Year",
    treated_status = "Treated Status in four category",
    treatment_cohort = "Treatment Cohort in three category",
    time_period = "Treatment status at given year",
    relative_time = "Relative Time (years since treatment)",
    post_treatment = "Post Treatment Period",
    group_summary = "status of treatment at given year",
    state_id = "ID of State",
    state = "State Name",
    year_treated = "Year Treated (as text)",
    treated_ever = "Treated Group (1 = Yes, 0 = No)",
    treated = "Treated Status at given timing (1 = Treated, 0 = Not Treated)",
  )

# treated_statusの値を確認
table(merged_df$treated_status, useNA = "ifany")

# yearの値を確認
table(merged_df$year, useNA = "ifany")

# 両方の組み合わせを確認
table(merged_df$treated_status, merged_df$year, useNA = "ifany")

# 記述統計用の組み合わせを確認
table(merged_df$group_summary, merged_df$year, useNA = "ifany")

# caseid, year, bidxでデータが一意となるようフィルター適用
merged_df <- merged_df %>%
  group_by(caseid, year, bidx) %>%
  slice_min(order_by = age, with_ties = FALSE) %>%
  ungroup()

# 結合したデータフレームを保存
print(sprintf("saving all data"))
output_filename <- here("..", "output", "alldata", "merged_all_years.dta")
write_dta(merged_df, output_filename)
print(sprintf("Data merged and saved to: %s", output_filename))

# ラベルリストの取得
print("Preparing label list from merged data frame")
temp_label <- get_label_list(merged_df)

# ラベルリストにカテゴリを追加
temp_label_old <- read_csv(here("..", "output", "alldata", "variable_labels_org.csv"))
temp_label <- temp_label %>%
  left_join(temp_label_old, by = "variable")


# saving the variable labels
label_filename <- here("..", "output", "alldata", "variable_labels_new.csv")
write_csv(temp_label, label_filename)
print(sprintf("Data merged and saved to: %s", "variable_labels_new.csv"))
