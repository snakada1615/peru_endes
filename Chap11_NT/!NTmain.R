# /*******************************************************************************************************************************
# Program: 				NTmain.R
# Purpose: 				Main file for the Nutrition Chapter. 
# 						    The main file will call other do files that will produce the NT indicators and produce tables.
# Data outputs:		coded variables and table output in excel tables.  
# Author: 				Shireen Assaf 
# Date last modified:		February 4, 2021
# 
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

#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap11_NT"


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
  PRdatafile <- dhsFiles[[as.character(year)]]$PR
  IRdatafile <- dhsFiles[[as.character(year)]]$IR
  HRdatafile <- dhsFiles[[as.character(year)]]$HR

  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }
  
  # Note: For the NT_MICRO do file, you need to merge the KR with the HR file. 
  # The merge will be performed before running any of the do files below. 
  #open HR file
  
  # ファイルのパスとして結合
  print(HRdatafile)
  HRdata <-  read_dta(HRdatafile)
  print("ok")
  
  # rename IDs
  HRdata <- HRdata %>%
    mutate(v001=hv001) %>%
    mutate(v002=hv002) 
  
  # 対象の列名
  vars_to_keep <- c("v001", "v002", "hv234a")
  # 存在する列だけ抽出
  existing_vars <- vars_to_keep[vars_to_keep %in% names(HRdata)]
  # 存在しない列をNAで作成
  missing_vars <- setdiff(vars_to_keep, existing_vars)
  for (var in missing_vars) {
    HRdata[[var]] <- NA  # NAを代入（必要ならどのNAかも指定可能：NA_character_など）
  }
  # 順序を保って選択
  HRtemp <- HRdata[, vars_to_keep]
  
  # * open IR dataset
  print(KRdatafile)
  KRdata <-  read_dta(KRdatafile)

    #perform merge
  KRdata <- merge(KRdata,HRtemp,by=c("v001", "v002"))
  rm(HRtemp)

  # Calculate age of child. If b19 is not available in the data use v008 - b3
  if ("TRUE" %in% (!("b19" %in% names(KRdata))))
    KRdata [[paste("b19")]] <- NA
  if ("TRUE" %in% all(is.na(KRdata$b19)))
  { b19_included <- 0} else { b19_included <- 1}
  
  if (b19_included==1) {
    KRdata <- KRdata %>%
      mutate(age = b19)
  } else {
    KRdata <- KRdata %>%
      mutate(age = v008 - b3)
  }

  
  source(here(paste0(chap,"/NT_CH_MICRO.R")), local = environment())
  # Purpose: 	Code micronutrient indicators
  
  source(here(paste0(chap,"/NT_BF_INIT.R")), local = environment())
  # Purpose:   Code initial breastfeeding indicators
  
  #source(here(paste0(chap,"/NT_BF_MED.do")), local = environment())
  # Purpose: 	Code breastfeeding indicators
  
  
  #############
  # Note: The following files select for the youngest child under 2 years living with the mother. 
  # Therefore a subset of the KR file (KRiycf)  will be produced to select for these children. 
  # Open KR file - if not open from code above
  # KRdata <-  read_dta(here(chap,KRdatafile))
  
  
  #create subset of KRfile to select for children for IYCF indicators
  KRiycf <- KRdata %>%
    subset(age < 24 & b9==0) %>% # children under 24 months living at home
    arrange(caseid, bidx) %>% # make sure the data is sorted
    subset(is.na(lag(caseid)) | caseid!=lag(caseid)) # select just the youngest
  
  source(here(paste0(chap,"/NT_IYCF.R")), local = environment())
  # Purpose: 			Code to compute infant and child feeding indicators
  # 
  
  KRiycf <- KRiycf %>%
    mutate(year = year)
  
  vars_to_keep <- KRiycf %>%
    select(starts_with("nt")) %>%
    names() %>%
    append(c("year", "age", "v001", "v002", "v003", "v005", "v013", "v025", "v026", "b4", "v024", "v106", "v190")) # add the variables we need to keep
  
  print(vars_to_keep)
  # 順序を保って選択
  
  KRiycf <- KRiycf[, vars_to_keep]

  # KRiycfをoutput folderにdta形式で保存
  print("save KRiycf into output folder")
  write_dta(KRiycf, paste0(outputDir, "/KRiycf-nt.dta"))
  print("complete KRiycf into output folder")
  

  source(here(paste0(chap,"/NT_tables_KR.R")), local = environment())
  # Purpose: 	Produce tables for indicators computed from KR file. This includes the KRiycf data. 
  print("complete KRiycf-table into output folder")
  
  # *******************************************************************************************************************************
  # *******************************************************************************************************************************
  # PR file variables
  
  # open dataset
  PRdata <-  read_dta(PRdatafile)
  
  source(here(paste0(chap,"/NT_CH_NUT.R")), local = environment())
  # Purpose: 	Code child's anthropometry indicators
  
  PRdata <- PRdata %>%
    mutate(year = year)
  #   mutate(v001 = hv001) %>%
  #   mutate(v002 = hv002) %>%
  #   mutate(v003 = hv003) %>%
  #   mutate(v005 = hv005) %>%
  #   mutate(v013 = hv013) %>%
  #   mutate(v024 = hv024) %>%
  #   mutate(v025 = hv025) %>%
  #   mutate(v026 = hv026)
  
  vars_to_keep <- PRdata %>% 
    select(starts_with("nt")) %>%
    names() %>%
    append(c("year", "hv001", "hv002", "hv003", "hv005", "hv013", "hv024", "hv025", "hv026", "hc1", "hc27", "hv270", "hv103")) # add the variables we need to keep
  
  print(vars_to_keep)
  # 順序を保って選択
  
  PRdata <- PRdata[, vars_to_keep]
  
  # ****************************************************************************
  # // 各家庭で同居、２歳未満、一番若い児童のみ抽出
  PRdata <- PRdata %>%
    # 24ヶ月未満 & 前夜在宅のみ
    filter(hc1 < 24, hv103 == 1) %>%
    # 世帯ID単位で年齢順に並べる（最年少が上）
    arrange(hv001, hv002, hc1) %>%
    # 世帯ごとに最年少の1名だけ抽出
    group_by(hv001, hv002) %>%
    slice(1) %>%
    ungroup()
  # ****************************************************************************
  
  # PRdataをoutput folderにdta形式で保存
  print("save PRdata into output folder")
  write_dta(PRdata, paste0(outputDir, "/PRdata-nt.dta"))
  
  source(here(paste0(chap,"/NT_tables_PR.R")), local = environment())
  # Purpose: 	Produce tables for indicators computed from the PR file 
  
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


# *******************************************************************************************************************************
# *******************************************************************************************************************************
# HR file variables
 
# open dataset
HRdata <-  read_dta(HRdatafile)

source(here(paste0(chap,"/NT_SALT.R")))
# Purpose: 	Code salt indicators  

source(here(paste0(chap,"/NT_tables_HR.R")))
# Purpose: 	Produce tables for indicators computed from HR file. 
# *******************************************************************************************************************************
# *******************************************************************************************************************************
# IR file variables

# A merge with the HR file is required to compute one of the indicators. 
# open HR file
HRdata <-  read_dta(HRdatafile)
# rename IDs
HRdata <- HRdata %>%
  mutate(v001=hv001) %>%
  mutate(v002=hv002) 
# keep relevant vars
HRtemp =subset(HRdata, select=c(v001, v002, hv234a))
# * open IR dataset
IRdata <-  read_dta(IRdatafile)
#perform merge
IRdata <- merge(IRdata,HRtemp,by=c("v001", "v002"))
rm(HRtemp)

source(here(paste0(chap,"/NT_WM_NUT.R")))
# Purpose: 	Code women's anthropometric indicators

source(here(paste0(chap,"/NT_tables_adults.R")))
# Purpose: 	Produce tables for indicators computed from IR file. 
# Note:		  The indicators are filtered for age 15-49. This can be changed if required for all women/men. 

# *******************************************************************************************************************************
# *******************************************************************************************************************************
# MR file variables

# A merge with the PR file is required to compute the indicators below.
# open PR file
PRdata <-  read_dta(PRdatafile)
# rename IDs
PRdata <- PRdata %>%
  mutate(mv001=hv001) %>%
  mutate(mv002=hv002) %>%
  mutate(mv003=hvidx) 
# keep relevant vars
PRtemp =subset(PRdata, select=c(mv001, mv002, mv003, hv042, hb55, hb56, hb57, hb40, hv103))

if (MRdatafile == "usePR") {
  # If using the PR file as MR file, then we need to rename the variables
  # 男性（例：15～59歳）を抽出し MRdata に格納
  MRdata <- PRdata %>%
    filter(hv104 == 1, hv105 >= 15, hv105 <= 59) %>%
    mutate(mv001 = hv001,
           mv002 = hv002,
           mv003 = hvidx)
} else {
  # If using the MR file, then we keep the variable names as is.
  #open MR dataset
  MRdata <-  read_dta(MRdatafile)
  #perform merge
  MRdata <- merge(MRdata,PRtemp,by=c("mv001", "mv002", "mv003"))
  rm(PRtemp)
}

source(here(paste0(chap,"/NT_MN_NUT.R")))
# Purpose: 	Code men's anthropometric indicators

source(here(paste0(chap,"/NT_tables_adults.R")))
# Purpose: 	Produce tables for indicators computed from MR file. 
# Note:	 The indicators are filtered for age 15-49. This can be changed if required for all women/men. 

# *******************************************************************************************************************************
# *******************************************************************************************************************************