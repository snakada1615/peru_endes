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

###############################################################################
# ----------------------------------------------------------------------------
#' @title variable_summary
#' @description
#' データフレームの各変数について、以下の情報をまとめた
#' データフレームを返す関数。
#' - variable: 変数名
#' - is_factor: factorかどうか
#' - num_factor_levels: factorの場合のレベル数（NA otherwise）
#' - is_binary: バイナリ変数かどうか（NA if not
#' factor）
#' - is_logical: logical型かどうか
#' - is_character: character型かどうか
#' - is_numeric: numeric型かどうか
#' - factor_levels: factorの場合のレベル名を"_"で結合した
#' 文字列（NA otherwise）
#' - var_label_base: papeRの変数ラベル（NA if not present
#' in papeR::labels(df)）
#' -------------------------------------------------------------------------- 
variable_summary <- function(df) {
  # バイナリ変数のyes/noレベルを判定するヘルパー関数------
  yesno_level <- function(v){
    # Yes/No 変数のレベル名の候補を定義
    yes_vars <- c("Yes", "yes", "Sí", "si")  # Yes 側のレベル名の候補
    no_vars <- c("No", "no")  # No 側のレベル名の候補
    
    res <- list(
      yes_var = NA_character_,
      no_var = NA_character_
    )
    
    if (!is.vector(v) | length(v) != 2) {
      stop("Input must be a vector of length 2.")
    }
    
    for (x in v) {
      if (x %in% yes_vars) {
        res$yes_var <- x
      } else if (x %in% no_vars) {
        res$no_var <- x
      }
    }
    return(res)
  }
  #------------------------------------
  
  
  # # papeRのラベル形式に変換
  # if (!papeR::is.ldf(df)) {
  #   df <- papeR::as.ldf(df)
  # }
  
  
  var_labs <- labels(df)
  
  var_summary <- lapply(names(df), function(x) {
    v <- df[[x]]
    
    res <- list(
      variable          = as.character(x),
      new_variable_name = as.character(x),  # フォールバック: 変数名をそのまま使用
      is_factor         = is.factor(v),
      num_factor_levels = if (is.factor(v)) length(na.omit(unique(v))) else NA_integer_,
      is_binary         = length(na.omit(unique(v))) == 2,
      is_logical        = is.logical(v),
      is_character      = is.character(v),
      is_numeric        = is.numeric(v),
      factor_levels     = if (is.factor(v)) paste(levels(v), collapse = "_") else NA_character_,
      var_label_base    = var_labs[[x]] %||% x,
      yes_value        = if (is.factor(v) && length(na.omit(unique(v))) == 2) 
        yesno_level(levels(v))$yes_var else NA_character_,
      no_value         = if (is.factor(v) && length(na.omit(unique(v))) == 2)
        yesno_level(levels(v))$no_var else NA_character_
    )
    res
  })
  
  var_summary <- do.call(rbind, lapply(var_summary, as.data.frame, 
                                       stringsAsFactors = FALSE))
  row.names(var_summary) <- NULL
  
  return(var_summary)
}
# ----関数ここまで--------------------------------------------------
###############################################################################

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

# 結果保存先
save_path <- file.path(gdrive_dir, "output")

source("myTools.R")
source("my_code/_tool_SaveLabel.R")
source("my_code/_tool_labels.R")

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
  path = file.path(gdrive_dir, "output", "data_dictionary.xlsx"),
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


