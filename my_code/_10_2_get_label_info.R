#' ------------------------------------------------------------
#' 目的：変数の型とfactorレベル情報を整理し、あとでfactorのダミー化に利用する
#' - 変数の型や水準を確認し、分析に利用する変数の概要を把握する
#' - 変数の型や水準をExcelファイルにまとめる
#' - 変数の型や水準を確認することで、分析に利用する変数の特徴を把握し、適切な分析手法を選択するための基礎情報を得る
#' - 変数の型や水準を確認することで、データの品質や欠損値の状況を把握し、データクリーニングや前処理の必要性を判断するための基礎情報を得る
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
source("my_code/_tool_labels.R")
source("my_code/_tool_df_structure.R")

# ステップ1: 元データの読み込み
df_org <- readRDS(
  file.path(gdrive_dir, 
            "output","all_data_merged_temp1.rds")) %>% 
  filter(!is.na(v021) & !is.na(v022) & !is.na(sampling_weight_trimmed))

# 分析に利用する変数名の抽出
variable_for_analysis <- names(df_org)
variable_for_analysis <- variable_for_analysis[grepl("^[a-zA-Z]{2}_|^enaho_|^juntos_", variable_for_analysis)]

df_vars <- df_org %>%
  select(
    all_of(c("year", "state", "treatment_group", "treated_status", "year_treated", "treatment_group", "analysis_grp", "group_treated")),
    all_of(variable_for_analysis)
  )

df_vars <- apply_labels_from_label_final(
  df = df_vars,
  overwrite_policy = "prefer_excel",
  path = file.path(gdrive_dir, "output", "labels", "data_dictionary.xlsx"),
)

var_summary <- variable_summary(df_vars)


# var_summary <- t(var_summary) %>% as.data.frame()

write.xlsx(
  var_summary,
  file = file.path(save_path, "labels", "label_all_data_merged.xlsx"),
  sheetName = "main",
  rowNames = FALSE,
  na.string = "NA"
)
# csvで保存するとスペイン語が文字化けする


