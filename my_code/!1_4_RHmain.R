# *******************************************************************************************************************************
# Program: 				!RHmain.R
# Purpose: 				Main file for the Reproductive Health Chapter. 
#						      The main file will call other do files that will produce the RH indicators and produce tables.
# Data outputs:		coded variables and table output in excel tables.
# Author: 				Shireen Assaf 
# Date last modified:		September 29, 2021 by Shireen Assaf
# Notes:					
# *******************************************************************************************************************************

rm(list = ls(all = TRUE))

# 以下のファイルを参照
# ー栄養			NT(Chap11)
# ーWASH関連データ　　HR(Chap16)
# ーワクチン関連　　	KR(Chap10)
# ー教育関連　		IR(Chap03)
# ー産前産後ケア　	IR(Chap09)
# ー家族計画関連　	  IR/MR(Chap04)
#

# libraries needed
library(tidyverse)  # most variable creation here uses tidyverse 
library(tidyselect) # used to select variables in FP_EVENTS.R
library(haven)      # used for Haven labeled DHS variables
library(labelled)   # used for Haven labeled variable creation
library(expss)    # for creating tables with Haven labeled data
library(xlsx)     # for exporting to excel
library(naniar)   # to use replace_with_na function
library(here)       # to get R project path
library(fs)

########################

#*******************************************************************************************************************************
#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap09_RH"


# 単一の年を指定する場合
# year <- c("2012")
# loopを回す場合
year <- c("2005", "2008", "2009", "2010", "2011", "2012")

# 指定したルートフォルダ以下に存在するすべてのDHSファイル名の取得（-> dhsFiles）
source("getDHSfiles.R")

dhsFiles <- get_dhs_file(
  yearlist = year,
  root_folder = source_folder
)
#*******************************************************************************************************************************
# 分析対象となる年を指定
# year <- c("2012")
# loopを回す場合
year <- c("2005", "2008", "2009", "2010", "2011", "2012")


#*******************************************************************************************************************************
goAnalysis <- function(year){
  # 設定した年に基づいて四種類のファイル名を取得します。
  IRdatafile <- dhsFiles[[as.character(year)]]$IR
  BRdatafile <- dhsFiles[[as.character(year)]]$BR
  
  # open dataset
  print(IRdatafile)
  IRdata <-  read_dta(IRdatafile)

  # do separate R scripts for each subtopic
  source(here(paste0(chap,"/RH_ANC.R")), local = environment())
  # Purpose: 	Code ANC indicators
  
  # PNCのデータは存在しないのでスキップ
  # source(here(paste0(chap,"/RH_PNC.R")))
  # Purpose: 	Code PNC indicators for mother and newborn
  
  source(here(paste0(chap,"/RH_Probs.R")), local = environment())
  # Purpose: 	Code indicators for problems accessing health care 
  
  # open dataset
  print(BRdatafile)
  BRdata <-  read_dta(BRdatafile)

  source(here(paste0(chap,"/RH_DEL.R")), local = environment())
  # Purpose: 	Code indicators for problems accessing health care 
  
  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }

  # IRdataとBRdataにyearを追加
  IRdata <- IRdata %>%
    mutate(year = year)
  
  BRdata <- BRdata %>%
    mutate(year = year)
  
  # IRdataから必要な変数を選択
  vars_to_keep <- IRdata %>%
    select(starts_with("rh")) %>%
    names() %>%
    append(c("year", "age", "v001", "v002", "v003", "v005", "v013", "v022", "v025", "v026")) # add the variables we need to keep
  
  # 順序を保って選択
  IRdata <- IRdata[, vars_to_keep]
  
  # IRdataをoutput folderにdta形式で保存
  write_dta(IRdata, paste0(outputDir, "/IRdata-rh.dta"))

  # BRdataから必要な変数を選択  
  vars_to_keep <- BRdata %>%
    select(starts_with("rh")) %>%
    names() %>%
    append(c("year", "age", "v001", "v002", "v003", "v005", "v013", "v022", "v025", "v026")) # add the variables we need to keep
  
  # 順序を保って選択
  BRdata <- BRdata[, vars_to_keep]
  
  # BRdataをoutput folderにdta形式で保存
  write_dta(BRdata, paste0(outputDir, "/BRdata-rh.dta"))
}

# *******************************************************************************************************************************
#** ここから実行
for (yr in year) {
  cat("Processing year:", yr, "\n")
  goAnalysis(yr)
}

# *******************************************************************************************************************************
stop('ここでまでくればOK🙆')
# *******************************************************************************************************************************

# ****************************

# BR file variables
 
source(here(paste0(chap,"/RH_DEL.R")))
# Purpose: Code delivery indicators

# ****************************

source(here(paste0(chap,"/RH_tables.R")))
# Purpose: 	Produce tables for indicators computed from above do files (both from IR and BR data)

# ******************************************************************************************************************************
