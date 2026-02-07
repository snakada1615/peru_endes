#' ------------------------------------------------------------
#' 目的：
#' 主要変数にfactor, numeric, character, logicalのどれが含まれているかを確認し、変数タイプの一覧を作成する。
#' また、factor変数についてはレベル情報、value label情報も取得する
#' 作成日：2024/06/10
#' 作成者：仲田俊一
#' 更新履歴：
#' 2024/06/10	新規作成
#' ------------------------------------------------------------

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
# labels_memory <- save_labels_to_memory(df_org)
# df_org <- remove_labels(df_org)

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


df_vars <- df_org %>%
  select(
    all_of(c("year", "state", "treatment_group", "treated_status", "year_treated", "treatment_start", "treatment_group", "analysis_grp", "group_treated")),
    all_of(variable_for_analysis)
  )
# df_vars <- restore_labels(df_vars, labels_memory)

var_summary <- sapply(names(df_vars), function(x) {
  res <- list(
    variable = x,
    is_factor = is.factor(df_vars[[x]]),
    num_factor_levels = ifelse(is.factor(df_vars[[x]]), length(na.omit(unique(df_vars[[x]]))), NA),
    is_binary = length(na.omit(unique(df_vars[[x]]))) == 2,
    is_logical = is.logical(df_vars[[x]]),
    is_character = is.character(df_vars[[x]]),
    is_numeric = is.numeric(df_vars[[x]]),
    factor_levels = paste(levels(df_vars[[x]]), collapse = "_"),
    value_labels = paste(names(attr(df_vars[[x]], "labels")), collapse = ":"),
    var1 = df_vars[[x]][1],
    var2 = df_vars[[x]][2],
    var3 = df_vars[[x]][3],
    var4 = df_vars[[x]][4],
    var5 = df_vars[[x]][5]
  )
  return(res)
})

var_summary <- t(var_summary)
write.csv(
  var_summary,
  file = file.path(save_path, "variable_type_summary.csv"),
  row.names = TRUE,
  fileEncoding = "UTF-8"
)

