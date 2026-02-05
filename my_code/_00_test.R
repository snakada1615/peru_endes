library(survey)
library(srvyr)
library(ggplot2)
library(dplyr)
library(haven)
library(tidyr)

# オブジェクトクリア
rm(list = ls(all = TRUE))

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

# 結果保存先
save_path <- file.path(gdrive_dir, "output")

source("myTools.R")
source("my_code/_tool_SaveLabel.R")

# ステップ1: 元データの読み込み
df_org <- readRDS(
  file.path(gdrive_dir, "output","all_data_merged.rds")
) %>%
  filter(!is.na(v021) & !is.na(v022) & !is.na(sampling_weight_trimmed))

# 変数ラベルをメモリに保存したうえでラベル消去
labels_memory <- save_labels_to_memory(df_org)
df_org <- remove_labels(df_org)

# キーテーブルの作成
key_table <- distinct(
  df_org,
  year,
  state,
  treatment_group,
  treated_status,
  year_treated,
  treatment_start,
  treatment_group,
  analysis_grp,
  group_treated
)

# 分析に利用する変数名の抽出
variable_for_analysis <- names(df_org)
variable_for_analysis <- variable_for_analysis[grepl("^[a-zA-Z]{2}_|^enaho_|^juntos_", variable_for_analysis)]

# === ファクター型を数値に変換 + NaN/Inf対策 ===
# df_org <- df_org %>%
#   mutate(
#     across(
#       all_of(variable_for_analysis),
#       ~ {
#         result <- if (is.factor(.)) {
#           as.numeric(.) - 1
#         } else if (is.numeric(.)) {
#           .
#         } else if (is.character(.)) {
#           as.numeric(.)
#         } else if (is.logical(.)) {
#           as.numeric(.)
#         } else {
#           as.numeric(as.character(.))
#         }
#         
#         # NaN と Inf を NA に変換
#         result[is.nan(result) | is.infinite(result)] <- NA
#         result
#       }
#     )
#   )

df_vars <- df_org %>%
  select(
    all_of(c("year", "state", "treatment_group", "treated_status", "year_treated", "treatment_start", "treatment_group", "analysis_grp", "group_treated")),
    all_of(variable_for_analysis)
  ) %>% slice_head()
df_vars <- restore_labels(df_vars, labels_memory)

var_summary <- sapply(names(df_vars), function(x) {
  res <- list(
    is_factor = is.factor(df_vars[[x]]),
    is_character = is.character(df_vars[[x]]),
    is_logical = is.logical(df_vars[[x]]),
    is_numeric = is.numeric(df_vars[[x]]),
    factor_levels = levels(df_vars[[x]]),
    value_labels = paste(attr(df_vars[[x]], "labels"), "_")
  )
  return(res)
})


