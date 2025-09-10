# /*******************************************************************************************************************************
# Program: 			!RCmain.R
# Purpose: 			Main file for the Respondents' Characteristics Chapter. 
#               The main file will call other R files that will produce the RC indicators and produce tables.
# Data outputs:	coded variables and table output on screen and in excel tables.  
# Author: 			Mahmoud Elkasabi 
# Date last modified:	Sept 29, 2021 by Shireen Assaf
# *******************************************************************************************************************************/
rm(list = ls(all = TRUE))

# 以下のファイルを参照
# ー栄養			NT(Chap11)
# ーWASH関連データ　　HR(Chap16)
# ーワクチン関連　　	KR(Chap10)
# ー教育関連　		IR(Chap03)
# ー産前産後ケア　	IR(Chap09)
# ー家族計画関連　	  IR/MR(Chap04)
#

# install the following library if needed.
library(haven) # used for Haven labeled DHS variables
library(naniar) #to replace values with NA
library(dplyr) # for data manipulation
library(sjlabelled) # used for Haven labeled variable creation
library(matrixStats) # for weightedMedian function
library(expss) # for creating tables with Haven labeled data
library(xlsx) # for exporting to excel
library(here)       # to get R project path
library(fs)         # for file system operations
library(dplyr) # for data manipulation
library(labelled) # for setting variable labels

#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap03_RC"

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
goAnalysis <- function(year){
  # 設定した年に基づいて四種類のファイル名を取得します。
  IRdatafile <- dhsFiles[[as.character(year)]]$IR
  
  # Respondent characteristic indicators for women
  IRdata <-  read_dta(IRdatafile)
  
  # create analytic variables
  source(here(paste0(chap,"/RC_CHAR_WM.R")), local = environment())

  # run the chapter tables
  # source(here(paste0(chap,"/RC_tables_WM.R")), local = environment())

  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }

  IRdata <- IRdata %>%
    mutate(year = year)
  
  vars_to_keep <- IRdata %>%
    select(starts_with("rc")) %>%
    names() %>%
    append(c("year", "v001", "v002", "v003", "v005", "v013", "v022", "v025", "v026", 
             "v024")) # add the variables we need to keep
  
  # print(vars_to_keep)
  # 順序を保って選択
  
  IRdata <- IRdata[, vars_to_keep]
  
  # IRdata folderにdta形式で保存
  print(sprintf("save IRdata into output folder for %s", year))
  write_dta(IRdata, paste0(outputDir, "/IRdata-rc.dta"))
  print("complete IRdata into output folder")
}

#*******************************************************************************************************************************
#** ここから実行
for (yr in year) {
  goAnalysis(yr)
}

# *******************************************************************************************************************************
stop('ここでまでくればOK🙆')
# *******************************************************************************************************************************

#####################################################################################

# Respondent characteristic indicators for men
MRdata <-  read_dta(here(chap,MRdatafile))

# create analytic variables
source(here(paste0(chap,"/RC_CHAR_MN.R")))
# run the chapter tables
source(here(paste0(chap,"/RC_tables_MN.R")))

#####################################################################################
