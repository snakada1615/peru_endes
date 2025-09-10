# /*******************************************************************************************************************************
# Program: 				MSmain.R
# Purpose: 				Main file for the Marriage and Sexual Activity Chapter. 
# The main file will call other source files that will produce the MS indicators and produce tables.
# Data outputs:		coded variables and table output on screen and in excel tables.  
# Author: 			        Courtney Allen
# Translated to R:      Courtney Allen 
# Date last modified:		September 1, 2022

# *******************************************************************************************************************************/
  
rm(list = ls(all = TRUE))

# 以下のファイルを参照
# ー栄養			NT(Chap11)
# ーWASH関連データ　　HR(Chap16)
# ーワクチン関連　　	KR(Chap10)
# ー教育関連　		    IR(Chap03)
# ー産前産後ケア　	  IR(Chap09)
# ー家族計画関連　	  IR/MR(Chap04)

library(tidyverse)  # most variable creation here uses tidyverse 
library(tidyselect) # used to select variables in FP_EVENTS.R
library(haven)      # used for Haven labeled DHS variables
library(labelled)   # used for Haven labeled variable creation
library(expss)      # for creating tables with Haven labeled data
library(openxlsx)   # for exporting to excel
library(naniar)     # to use replace_with_na function
library(here)       # to get R project path
library(survey)     # survey weight data to find median ages

#*******************************************************************************************************************************
#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap04_MS"


# 単一の年を指定する場合
year <- c("2008")
# loopを回す場合
# year <- c("2005", "2008", "2009", "2010", "2011", "2012")

# 指定したルートフォルダ以下に存在するすべてのDHSファイル名の取得（-> dhsFiles）
source("getDHSfiles.R")

dhsFiles <- get_dhs_file(
  yearlist = year,
  root_folder = source_folder
)
#*******************************************************************************************************************************
goAnalysis <- function(year){
  # 設定した年に基づいて四種類のファイル名を取得します。
  IRdatafile <- dhsFiles[[as.character(year)]]$IR

  #open dataset
  IRdata <-  read_dta(IRdatafile)

  source(here(paste0(chap,"/MS_MAR.R")), local = environment())
  #Purpose: 	Code marital status variables for men and women

  source(here(paste0(chap,"/MS_SEX.R")), local = environment())
  #Purpose: 	Code sexual activity variables for men and women
  
  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  
  
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }
  
  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  
  
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }
  
  # IRdataに年を追加
  IRdata <- IRdata %>%
    mutate(year = year)
  
  # IRdataから必要な変数を選択
  vars_to_keep <- IRdata %>%
    select(starts_with("ms")) %>%
    names() %>%
    append(c("year", "v001", "v002", "v003", "v005", "v013", "v025", "v026")) # add the variables we need to keep
  
  # 順序を保って選択
  IRdata <- IRdata[, vars_to_keep]
  
  # IRdataをoutput folderにdta形式で保存
  write_dta(IRdata, paste0(outputDir, "/IRdata-ms.dta"))
  
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

source(here(paste0(chap,"/MS_tables_WM.R")), local = environment())
#Purpose: 	Produce tables for indicators for women computed above. 


source(here(paste0(chap,"/MS_tables_MN.R")))
#Purpose: 	Produce tables for indicators for men computed above. 


