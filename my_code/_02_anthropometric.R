
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
source("myTools.R")  # プロジェクトルートから読み込む

# 対象とする年のリスト
yearlist <- c("2007", "2008", "2009", "2010", "2011",
              "2012", "2013", "2014", "2015", "2016") 
# yearlist <- c("2015")

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
  
  keep_RECH1 <- c("hhid", "hvidx", "hv103") # hv103: 前夜在宅
  keep_RECH6 <- c("hc1", "hc27", "hc56", "hc70", "hc71", "hc72", "hhid", "hc0", 
                  "hc60")
  keep_REC0111 <- c("hhid", "v003", "caseid")
  keep_index <- c("year", "hhid", "hc27", "caseid")
  
  # 1. データ読み込み
  df_REC1 <- open_endes_file(my_year, "RECH1.sav") %>%
    rename_with(~ tolower(.x)) 
  df_REC6 <- open_endes_file(my_year, "RECH6.sav") %>%
    rename_with(~ tolower(.x))

  # 2. REC0111 から hhid と v003 を作成
  #    CASEID は文字列、V001=郡コード、V002=世帯番号、V003=行番号
  df_REC0111 <- process_endes_with_hhid(my_year, "REC0111.sav") %>%
    mutate(
      v003 = as.integer(v003)
    )  %>%
    select(all_of(keep_REC0111))

  # 3. RECH1 から hhid と hvidx を抽出
  df_REC1 <- df_REC1 %>%
    mutate(
      hhid  = as.character(hhid),
      hvidx = as.integer(hvidx)  # 世帯構成員行番号
    ) %>%
    select(all_of(keep_RECH1))
  
  # 4. RECH6 を整形
  df_REC6 <- df_REC6 %>%
    mutate(
      hhid  = as.character(hhid),
      hc60  = as.integer(hc60),   # 母親の行番号
    ) %>%
    select(all_of(keep_RECH6))
  
  # 5. 段階1: RECH6 と RECH1 の結合 (母親行番号と世帯構成員をマッチ)
  tmp <- df_REC6 %>%
    inner_join(df_REC1,
               by = c("hhid" = "hhid",
                      "hc60" = "hvidx"))
  
  # 6. 段階2: tmp と REC0111 の結合 (女性個人データからCASEIDを取得)
  result <- tmp %>%
    inner_join(df_REC0111,
               by = c("hhid" = "hhid",
                      "hc60" = "v003"))

  # 7. 不要な列を除外して最終データセット作成
  PRdata <- result
  
  duplicate_check(PRdata, c("caseid"), "PRdata")
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
  duplicate_check(PRdata, c("hhid"), "PRdata after filtering to youngest child under 24 months")
  
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
    append(keep_index) # add the variables we need to keep
  
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

