
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
library(dplyr)          # For %>%, mutate(), case_when()
library(naniar)         # For replace_with_na()


# 各種の関数セット読み込み
source("myTools.R")  # プロジェクトルートから読み込む（quarto限定の処理）

# 対象とする年のリスト
yearlist <- c("2007", "2008", "2009", "2010", "2011",
              "2012", "2013", "2014", "2015", "2016") 
# yearlist <- c("2015")
# my_year <- yearlist[8]

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

# データベース一覧

endes_list <- readRDS(file.path(gdrive_dir, "output","endes_data_list.rds"))

# 変数ラベル一覧

endes_var_labels <- readRDS(file.path(gdrive_dir, "output", "endes_var_labels.rds"))

go_analysis <- function(my_year){
  print(paste("Processing year:", my_year))
  # 出力用のルートフォルダを指定
  output_dir <- file.path(gdrive_dir, "output", my_year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(output_dir)) {
    dir_create(output_dir)
  }
  
  # 必要なデータセットの抽出
  print("必要なデータセットを抽出します")
  
  keep_RECH1 <- c("HV001", "HV002", "HV103", "HHID", "HVIDX")
  keep_RECH6 <- c("HC1", "hc27", "HC56", "HC70", "HC71", "HC72", "HHID", "HC0")
  
  df_REC1 <- open_endes_file(my_year, "RECH1.sav") %>%
    add_missing_columns(keep_RECH1) %>% select(all_of(keep_RECH1))
  df_REC6 <- open_endes_file(my_year, "RECH6.sav") %>%
    add_missing_columns(keep_RECH6) %>% select(all_of(keep_RECH6))
  
  print("レコードの重複チェックを行います")
  duplicate_check <- function(df, key_vars, df_name) {
    temp <- df %>%
      group_by(across(all_of(key_vars))) %>%
      summarise(n = n(), .groups = 'drop') %>%
      filter(n > 1)
    
    if (nrow(temp) > 0) {
      print(paste("重複レコードがあります in", df_name))
      print(temp)
      print(paste("レコード数：", nrow(df)))
    } else {
      print(paste("重複レコードはありません in", df_name))
      print(paste("レコード数：", nrow(df)))
    }
  }
  
  duplicate_check(df_REC1, c("HHID", "HVIDX"), "REC1.sav")
  duplicate_check(df_REC6, c("HHID", "HC0"), "REC6.SAV")
  
  # データセットの結合
  print("データセットを結合します")
  PRdata <- df_REC6 %>% 
    left_join(df_REC1, by = c("HHID" = "HHID",  "HC0" = "HVIDX"))
  
  # 列名の変更(大文字→小文字)
  PRdata <- PRdata %>%
    rename_with(tolower)
  
  # 再度重複チェック
  duplicate_check(PRdata, c("hhid", "hc0"), "KRdata")
  
  print("データセットの結合が完了しました")
  print(paste("レコード数:", nrow(PRdata)))
  
  # Peru ENDESにおける最年少児童抽出
  PRdata <- PRdata %>%
    # 24ヶ月未満 & 前夜在宅のみ
    filter(hc1 < 24, hv103 == 1) %>%
    # HHID単位で年齢順に並べる（最年少が上）
    arrange(hhid, hc1) %>%
    # 世帯ごとに最年少の1名だけ抽出
    group_by(hhid) %>%
    slice(1) %>%
    ungroup()
  
  print("月齢24ヶ月未満の子供に制限しました")
  print(paste("レコード数:", nrow(PRdata)))
  
  chap <- "Chap11_NT"
  
  source(here(paste0(chap,"/NT_CH_NUT.R")), local = environment())
  # Purpose: 	Code child's anthropometry indicators
  
  # 年をデータフレームに追加
  PRdata <- PRdata %>%
    mutate(year = my_year)
  print("add year variable")

  # 出力用の変数を指定
  vars_to_keep <- PRdata %>% 
    select(starts_with("nt")) %>%
    names() %>%
    append(c("year", "hhid", "hc0", "hc1", "hc27")) # add the variables we need to keep
  
  print(vars_to_keep)
  # 順序を保って選択
  
  PRdata <- PRdata[, vars_to_keep]
  print("select variables to keep")
  
  # PRdataをoutput folderにrds形式で保存
  print("save PRdata into output folder")
  saveRDS(PRdata, paste0(output_dir, "/PRData.rds"))
  print(paste("Data for year", my_year, "saved to", paste0(output_dir, "/PRData.rds")))
  
  return(PRdata)
}  

for (my_year in yearlist) {
  go_analysis(my_year)
}
print("All years processed.")

