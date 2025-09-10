# /*******************************************************************************************************************************
# Program: 				  !CHmain.R
# Purpose: 				  Main file for the Child Health Chapter. 
# 						      The main file will call other syntax files that will produce the CH indicators and produce tables.
# Data outputs:			Coded variables and table output in excel tables.  
# Author: 				  Shireen Assaf	
# Date last modified:		August 17, 2022 by Shireen Assaf
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
# *******************************************************************************************************************************
# libraries needed
library(tidyverse)  # most variable creation here uses tidyverse 
library(tidyselect) # used to select variables in FP_EVENTS.R
library(haven)      # used for Haven labeled DHS variables
library(labelled)   # used for Haven labeled variable creation
library(expss)      # for creating tables with Haven labeled data
library(xlsx)       # for exporting to excel
library(naniar)     # to use replace_with_na function
library(here)       # to get R project path
library(sjlabelled) # to set variables label
library(survey)     # to calculate weighted ratio for GAR
library(fs)         # for file system operations


#*******************************************************************************************************************************
#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap10_CH"


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
  KRdatafile <- dhsFiles[[as.character(year)]]$KR
  
  #open dataset
  KRdata <-  read_dta(KRdatafile)
  
  source(here(paste0(chap,"/CH_SIZE.R")), local = environment())
  # Purpose: 	Code child size indicators
  
  source(here(paste0(chap,"/CH_ARI_FV.R")), local = environment())
  # Purpose:	Code ARI indicators
  
  source(here(paste0(chap,"/CH_DIAR.R")), local = environment())
  # Purpose:	Code diarrhea indicators
  
  source(here(paste0(chap,"/CH_VAC.R")), local = environment())
  # Purpose:	Code vaccination indicators
  # Note:     This code will create a data subset KRvac for children in the vaccination age group
  
  source(here(paste0(chap,"/CH_STOOL.R")), local = environment())
  # Purpose:	Safe disposal of stool
  # Note:     This code will create a data subset KRstool to selected for youngest child under age 2 living with the mother
  
  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }
  
  KRdata <- KRdata %>%
    mutate(year = year)
  
  # KRdataから必要な変数を選択
  vars_to_keep <- KRdata %>%
    select(starts_with("ch")) %>%
    names() %>%
    append(c("year", "age", "v001", "v002", "v003", "v005", "v013", "v025", "v026", "v008", "b3", "b9", "caseid", "bidx")) # add the variables we need to keep
  
  # 順序を保って選択
  KRdata <- KRdata[, vars_to_keep]

  # ****************************************************************************
  # // 各家庭で同居、２歳未満、一番若い児童のみ抽出
  KRdata <- KRdata %>%
    mutate(age_month = v008 - b3) %>% # 年齢（月）を計算
    # 24ヶ月未満かつ在宅児に絞る
    filter(age_month < 24, b9 == 0) %>%
    # caseid（母親・家庭単位）＆bidx（出生順）で並べ替え
    arrange(caseid, bidx) %>%
    # 各母親（家族）ごとに最年少（bidx==1）が最初に並ぶので、その1名だけ残す
    group_by(caseid) %>%
    slice(1) %>%
    ungroup()
  # ****************************************************************************
    
  # KRdataをoutput folderにdta形式で保存
  write_dta(KRdata, paste0(outputDir, "/KRdata-ch.dta"))
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

# do CH_tables.do
# *Purpose: 	Produce tables for indicators computed from above do files. 


# *******************************************************************************************************************************
# *******************************************************************************************************************************
 
# IR file variables
#open dataset
IRdata <-  read_dta(here(chap,IRdatafile))

source(here(paste0(chap,"/CH_KNOW_ORS.R")))
# Purpose: 	Code knowledge of ORS
# 
# *******************************************************************************************************************************

source(here(paste0(chap,"/CH_tables.R")))
# Purpose: 	Produce tables for indicators computed from above files. 


