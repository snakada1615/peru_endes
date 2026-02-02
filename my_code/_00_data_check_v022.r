# v022のユニーク値を各年で確認するコード
#'***********************************************************************
#'目的：v022（svydesign作成の重要変数）の値が特定年で全て0になっていたため
# 作成者: snakada
# 作成日: 2026-02-01
# 最終更新日: 2024-02-0
# ***********************************************************************/1

# Rの環境をクリア
rm(list = ls(all = TRUE))

# libraries needed
library(tidyverse)  # most variable creation here uses tidyverse 
library(tidyselect) # used to select variables in FP_EVENTS.R
library(haven)      # used for Haven labeled DHS variables
library(labelled)   # used for Haven labeled variable creation
library(expss)      # for creating tables with Haven labeled data
library(rJava)      # required for xlsx package
library(naniar)     # to use replace_with_na function
library(here)       # to get R project path
library(fs)         # for file path manipulation
library(openxlsx) 　# for exporting to excel
library(survey)       # for survey design


# 各種の関数セット読み込み
source("myTools.R")  # プロジェクトルートから読み込む（quarto限定の処理）

# 対象とする年のリスト
yearlist <- c("2005", "2006", "2007", "2008", "2009", "2010", "2011",
              "2012", "2013", "2014", "2015", "2016")
# yearlist <- c("2005")

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

# データベース一覧
endes_list <- readRDS(file.path(gdrive_dir, "output","endes_data_list.rds"))

# 変数ラベル一覧
endes_var_labels <- readRDS(file.path(gdrive_dir, "output", "endes_var_labels.rds"))

# ファイル名の設定
files <- c("BRdata-rh","IRdata-rh","IRdata-rc","IRdata-nt","KRvac","KRdata",
           "KRiycf-nt","WASHdata-ws","IRdata-ms","KRstool", "PRdata", "HRdata-dm")

# RDSファイルを読み込む関数
# year: 年
# filename: ファイル名（拡張子なし）
# select_col: 抽出する列名のベクトル（NULLの場合は全列を抽出）
open_processed_file <- function(year, filename, select_col = NULL) {
  p <- file.path(gdrive_dir, "output", year, paste0(filename, ".RDS"))
  print(paste0("Loading file: ", filename, " for year: ", year, " path: ", p))
  file_path <- file.path(gdrive_dir, "output", year, paste0(filename, ".RDS")) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  if (file_exists(file_path)) {
    df <- readRDS(file_path) %>%
      rename_with(~ tolower(.x))
    if (!is.null(select_col)) {
      df <- df %>% dplyr::select(all_of(select_col))
    }
    # merge_key設定：HRdata-dm/HRdata-dmのみ結合キーが"hhid"
    if (filename == "WASHdata-ws" | filename == "HRdata-dm") {
      merge_key <- c("hhid")
    } else {
      merge_key <- c("caseid")
    }
    
    print("重複チェック")
    if (duplicate_check(df, merge_key, filename) == 0) {
      duplicate_check_detail(df, merge_key, filename)
    }
    print("v021, v022チェック")
    v021_exist <- "v021" %in% names(df)
    v022_exist <- "v022" %in% names(df)
    if (v021_exist & v022_exist) {
      v021_unique <- n_distinct(df$v021)
      v022_unique <- n_distinct(df$v022)
      print(paste0("v021 unique values: ", v021_unique))
      print(paste0("v022 unique values: ", v022_unique))
    } else {
      print("v021 or v022 does not exist in the dataset.")
      print(paste0("v021 exist: ", v021_exist))
      print(paste0("v022 exist: ", v022_exist))
    }
    
    return(df)
  } else {
    stop("File does not exist: ", file_path)
  }
}

# open_processed_file関数内で、またはデータ読み込み直後に実施
open_processed_file_normalized <- function(year, filename) {
  data <- open_processed_file(year, filename)
  
  # データフレームとして確実に変換
  if (!is.data.frame(data)) {
    data <- as.data.frame(data)
  }
  
  # 列名の正規化
  names(data) <- names(data) %>%
    str_squish() %>%
    str_replace_all("[[:space:]]+", "_") %>%
    tolower()  # 小文字に統一（オプション）
  
  return(data)
}

# 各年のデータを格納するリスト
data_all <- list()
for (year in yearlist) {
  print(paste("Processing year:", year))
  df_rec0111 <- open_endes_file(year, "rec0111.sav") %>%
    rename_with(~ tolower(.x))
  df_rec0 <- open_endes_file(year, "rech0.sav") %>%
    rename_with(~ tolower(.x))
  print("check unique value of v022")
  if ("v022" %in% names(df_rec0111)) {
    v022_unique <- n_distinct(df_rec0111$v022)
    print(paste0("v022 unique values(rec0111): ", v022_unique))
  } else {
    print("v022 does not exist in the rec0111")
  }   
  if ("hv022" %in% names(df_rec0)) {
    v022_unique <- n_distinct(df_rec0$hv022)
    print(paste0("v022 unique values(rec0): ", v022_unique))
  } else {
    print("v022 does not exist in the rech0.")
  }   
}    