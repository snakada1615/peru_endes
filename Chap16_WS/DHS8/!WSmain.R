# /*****************************************************************************
# Program: 				!PHmain.R
# Purpose: 				Main file for the Population and Housing Chapter. 
# 						    The main file will call other do files that will produce the PH indicators and produce tables.
# Data outputs:		Coded variables and table output on screen and in excel tables.  
# Author: 				Shireen Assaf
# Date last modified:		July 25, 2023 by Shireen Assaf to add srvyr library needed for PH.SCHOL file
# ******************************************************************************
rm(list = ls(all = TRUE))

# 以下のファイルを参照
# ー栄養			NT(Chap11)
# ーWASH関連データ　　HR(Chap16)
# ーワクチン関連　　	KR(Chap10)
# ー教育関連　		    IR(Chap03)
# ー産前産後ケア　	  IR(Chap09)
# ー家族計画関連　	  IR/MR(Chap04)

# libraries needed
library(tidyverse)  # most variable creation here uses tidyverse 
library(tidyselect) # used to select variables in FP_EVENTS.R
library(haven)      # used for Haven labeled DHS variables
library(labelled)   # used for Haven labeled variable creation
library(expss)    # for creating tables with Haven labeled data
library(xlsx)     # for exporting to excel
library(naniar)   # to use replace_with_na function
library(here)       # to get R project path
library(sjlabelled) # to set variables label
library(survey)  # to calculate weighted ratio for GAR
library(srvyr)

#*******************************************************************************************************************************
#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

# ソースコードのルートフォルダを指定
chap <- "Chap02_PH"


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
  HRdatafile <- dhsFiles[[as.character(year)]]$HR
  
  #open dataset
  HRdata <-  read_dta(HRdatafile)

  # HR file variables (use for indicators where households is the unit of measurement)
  WASHdata <- HRdata #same code can be used for PR or HR files, but must be specified here
  
  source(here(paste0(chap,"/PH_SANI.R")), local = environment())
  # Purpose: 	Code Sanitation indicators
  
  source(here(paste0(chap,"/PH_WATER.R")), local = environment())
  # Purpose: 	Code Water Source indicators
  
  HRWASHdata <- WASHdata # tables.R will refer to this dataset for tables on household characteristics
  
  source(here(paste0(chap,"/PH_HOUS.R")), local = environment())
  # Purpose:	Code housing indicators such as house material, assets, cooking fuel and place, and smoking in the home
  
  # 出力用のルートフォルダを指定
  outputDir <- here("..", "/output", year) %>%
    normalizePath() %>%
    trimws() # 正規化してトリムする

    
  # 出力用のルートフォルダが存在しない場合は作成
  if (!dir_exists(outputDir)) {
    dir_create(outputDir)
  }
  
  HRWASHdata <- HRWASHdata %>%
    mutate(year = year)
  
  # KRdataから必要な変数を選択
  vars_to_keep <- HRWASHdata %>%
    select(starts_with("ph")) %>%
    names() %>%
    append(c("year", "hv001", "hv002", "hv003", "hv005", "hv013", "hv025", "hv026")) # add the variables we need to keep
  
  # 順序を保って選択
  HRWASHdata <- HRWASHdata[, vars_to_keep]
  
  # KRdataをoutput folderにdta形式で保存
  write_dta(HRWASHdata, paste0(outputDir, "/HRWASHdata-ws.dta"))
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

# **********************************
# PR file variables (use for indicators where the population is the unit of measurement)

WASHdata <- PRdata #same code can be used for PR or HR files, but must be specified here

source(here(paste0(chap,"/PH_SANI.R")))
# Purpose: 	Code Sanitation indicators

source(here(paste0(chap,"/PH_WATER.R")))
# Purpose: 	Code Water Source indicators

PRWASHdata <- WASHdata # tables.R will refer to this dataset for tables on household characteristics

source(here(paste0(chap,"/PH_HNDWSH.R")))
# Purpose:	Code hand-washing indicators



# For the PH_SCHOL.R below you need to update the following inputs since they are country-specific
# To produce the net attendance ratios you need to provide country specific information on the year 
# and month of the school calendar and the age range for school attendance. See lines 63-73. 
# You can obtain this information for each country from the UNESCO webiste: http://data.uis.unesco.org/. 
# This would be under "Education" and then "Other policy relevant indicators".
# Scroll to the bottom of the list to obtain the school ages from "Offical entrance age to each ISCED level of education" and the school calendar from "Start and end of the academic year".

# To calculate the child's age at the start of the school year we have to specify the month and year of the start of the school year referred to in the survey. 
# For example, for Zimbabwe 2015 survey this was January 2015
school_start_yr = 2015
school_start_mo = 1
# also we need the age ranges for primary and secondary
# for example, for Zimbabwe 2015, the age range is 6-12 for primary school and 13-18 for secondary school
age_prim_min = 6
age_prim_max = 12
age_sec_min = 13
age_sec_max = 18

source(here(paste0(chap,"/PH_SCHOL.R")))
# Purpose:	Code education and schooling indicators. 
# Note: This code will merge BR and PR files and drop some cases. It will also produce the excel file Tables_schol 
# 
source(here(paste0(chap,"/PH_POP.R")))
# Purpose: 	Code to compute population characteristics, birth registration, education levels, household composition, orphanhood, and living arrangments
# Warning: This do file will collapse the data and therefore some indicators produced will be lost. However, they are saved in the file PR_temp_children.dta and this data file will be used to produce the tables for these indicators in the PH_table code. This do file will produce the Tables_hh_comps for household composition (usually Table 2.8 or 2.9 in the Final Report). 
# Note: The code will also produce the table Tables_PH.xlsx
 
source(here(paste0(chap,"/PH_GINI.R")))
# Purpose:	Code to produce Gini index table. 
# Note: This code will collapse the data and produce the table Table_gini.xls

source(here(paste0(chap,"/PH_tables.R")))
# Purpose: 	Produce tables for indicators computed from the above do files 