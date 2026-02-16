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
  # file.path(gdrive_dir, "output","all_data_merged.rds")
  file.path(gdrive_dir, "output","all_data_merged.rds")
) %>%
  filter(!is.na(v021) & !is.na(v022) & !is.na(sampling_weight_trimmed))

# 変数ラベルをメモリに保存したうえでラベル消去
# labels_memory <- save_labels_to_memory(df_org)
# df_org <- remove_labels(df_org)

# 分析に利用する変数名の抽出
variable_for_analysis <- names(df_org)
variable_for_analysis <- variable_for_analysis[grepl("^[a-zA-Z]{2}_|^enaho_|^juntos_", variable_for_analysis)]


df_vars <- df_org %>%
  select(
    all_of(c("year", "state", "treatment_group", "treated_status", "year_treated", "treatment_start", "treatment_group", "analysis_grp", "group_treated")),
    all_of(variable_for_analysis)
  )
# df_vars <- restore_labels(df_vars, labels_memory)

var_summary <- lapply(names(df_vars), function(x) {
  v <- df_vars[[x]]
  
  res <- list(
    variable          = as.character(x),
    is_factor         = is.factor(v),
    num_factor_levels = if (is.factor(v)) length(na.omit(unique(v))) else NA_integer_,
    is_binary         = length(na.omit(unique(v))) == 2,
    is_logical        = is.logical(v),
    is_character      = is.character(v),
    is_numeric        = is.numeric(v),
    factor_levels     = if (is.factor(v)) paste(levels(v), collapse = "_") else NA_character_,
    value_labels      = {
      labs <- attr(v, "labels")
      if (!is.null(labs)) paste(names(labs), collapse = ":") else NA_character_
    },
    new_variable_name = x,
    Yes_value        = if (is.factor(v) && length(na.omit(unique(v))) == 2) 
                          levels(v)[1] 
                        else NA_character_,
    No_value         = if (is.factor(v) && length(na.omit(unique(v))) == 2) 
                          levels(v)[2] 
                        else NA_character_
  )
  res
})

var_summary <- do.call(rbind, lapply(var_summary, as.data.frame, 
                                     stringsAsFactors = FALSE))
row.names(var_summary) <- NULL


# var_summary <- t(var_summary) %>% as.data.frame()

write.xlsx(
  var_summary,
  file = file.path(save_path, "labels", "variable_type_summary.xlsx"),
  sheetName = "main",
  rowNames = FALSE,
  na.string = "NA"
)

# csvで保存するとスペイン語が文字化けする
# write.csv(
#   var_summary,
#   file = file.path(save_path, "variable_type_summary.csv"),
#   row.names = TRUE,
#   fileEncoding = "UTF-8"
# )

