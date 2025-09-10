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
library(labelled) # for variable labels


#path for R project
here()

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
source_folder = normalizePath(here("..", "..")) # ソースコードのルートフォルダを正規化

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
  PRdatafile <- dhsFiles[[as.character(year)]]$PR
  IRdatafile <- dhsFiles[[as.character(year)]]$IR
  
  # データを読み込みます。
  HRdata <- read_dta(HRdatafile)
  PRdata <- read_dta(PRdatafile)
  IRdata <- read_dta(IRdatafile)
  
  # number of children under 12 years old per household
  child_count <- PRdata %>%
    filter(hv105 <= 12, hv102 == 1) %>%     # 年齢<=12かつde jureメンバー
    group_by(hv001, hv002) %>%              # クラスターIDと世帯IDで集計
    summarise(dm_children_under12 = n()) %>%   # 子供の数をカウント
    mutate(dm_children_under12 = ifelse(is.na(dm_children_under12), 0, dm_children_under12)) %>% # NAを0に置き換え
    ungroup()
  
  # type of cooking fuel per household  
  cooking_fuel <- IRdata %>%
    group_by(v001, v002) %>% # クラスターIDと世帯IDで集計
    summarise(dm_cooking_fuel = first(v161)) %>% # 最初の調理燃料を取得
    mutate(dm_cooking_fuel_traditional = ifelse(dm_cooking_fuel < 7, 0, 1)) %>% # 伝統的な調理燃料かどうか  
    mutate(dm_cooking_fuel_traditional = ifelse(
      is.na(dm_cooking_fuel_traditional), 0, dm_cooking_fuel_traditional)
      ) %>% # NAを0に置き換え
    ungroup()
  
  var_refrigerator <- if (yr < 2009) "sh2910f" else "hv209" # 冷蔵庫の変数名を年によって変更
  
  ##------------------------------------------------------------------------------------------------
  # women empowerment indicators
  source(here("Chap15_WE","WE_EMPW_update.R"), local = environment())  
  WEdata <- WEdata %>%
    mutate(year = yr)
  
  # WEdataから必要な変数を抽出
  vars_to_keep <- WEdata %>%
    select(starts_with("dm_")) %>%
    names() %>%
    append(c("year", "v001", "v002", "v003")) # add the variables we need to keep
  
  # 順序を保って選択
  WEdata <- WEdata[, vars_to_keep]
  ##------------------------------------------------------------------------------------------------
  
  HRdata <- HRdata %>%
    left_join(child_count, by = c("hv001", "hv002")) %>%
    left_join(cooking_fuel, join_by(hv001 == v001, hv002 == v002)) %>%
    left_join(WEdata, join_by(hv001 == v001, hv002 == v002, hv003 == v003)) %>%
    
    # 変数名を変更
    rename(
      v001 = hv001, # クラスターID
      v002 = hv002, # 世帯ID
      v005 = hv005, # 標準化されたウェイト
      v022 = hv022, # strutum-id
    ) %>%
  
    # コントロール変数の設定
    mutate(
      dm_rural = ifelse(hv026 == 3, 1, 0), # 農村ダミー
      dm_town = ifelse(hv026 == 2, 1, 0), # 小都市ダミー
      dm_city = ifelse(hv026 == 1, 1, 0), # 中都市ダミー
      dm_capital = ifelse(hv026 == 0, 1, 0), # 首都ダミー
      # dm_child_sex = ifelse(hc27 == 1, 1, 0), # 男児ダミー
      dm_poorest = ifelse(hv270 == 1, 1, 0), # 最も貧しいダミー
      dm_poorer = ifelse(hv270 == 2, 1, 0), # 貧しいダミー
      dm_middle = ifelse(hv270 == 3, 1, 0), # 中間層ダミー
      dm_richer = ifelse(hv270 == 4, 1, 0), # 裕福なダミー
      dm_richest = ifelse(hv270 == 5, 1, 0), # 最も裕福なダミー
      dm_weath_index = hv271/100000, # 資産保有状況のnormalized score (mean=0, sd=1)
      dm_shared_toilet = ifelse(hv238 == 95, 1, 0), # 共用トイレダミー
      dm_ag_land_ha = ifelse(hv244 == 0, 0, hv245), # 農地面積
      dm_cooking_house = ifelse(hv241 == 1, 1, 0), # 家庭内調理ダミー
      dm_cooking_outdoor = ifelse(hv241 == 3, 1, 0), # 屋外調理ダミー
      dm_cooking_separate = ifelse(hv241 == 2, 1, 0), # 別棟調理ダミー
      dm_cattle_own = ifelse(hv246a > 0 & hv246a < 98, 1, 0), # 牛飼育ダミー
      dm_goat_own = ifelse(hv246d > 0 & hv246d < 98, 1, 0), # ヤギ飼育ダミー
      dm_sheep_own = ifelse(hv246e > 0 & hv246e < 98, 1, 0), # 羊飼育ダミー
      dm_poultry_own = ifelse(hv246g > 0 & hv246g < 98, 1, 0), # 鶏飼育ダミー
      dm_refrigerator = ifelse(var_refrigerator == 1, 1, 0), # 冷蔵庫所有ダミー
      dm_female_headed = ifelse(hv219 == 2, 1, 0), # 女性世帯主ダミー
      dm_age_of_HH_head = ifelse(hv220 < 20, 1, 
                          ifelse(hv220 >= 20 & hv220 < 30, 2, 
                          ifelse(hv220 >= 30 & hv220 < 40, 3,
                          ifelse(hv220 >= 40 & hv220 < 50, 4,
                          ifelse(hv220 >= 50 & hv220 < 60, 5,
                          ifelse(hv220 >= 60 & hv220 < 70, 6,
                          ifelse(hv220 >= 70 & hv220 < 80, 7,
                          ifelse(hv220 >= 80, 8, NA)))))))), # 世帯主の年齢カテゴリ変数
    ) %>%
    mutate(year = year) # 年を追加
  
  vars_to_keep <- HRdata %>%
    select(starts_with("dm")) %>%
    names() %>%
    append(c("year", "v001", "v002", "v005", "v022")) # add the variables we need to keep
  
  # print(vars_to_keep)
  # 順序を保って選択
  
  # 重複行の排除（マージ用）
  HRdata <- HRdata[, vars_to_keep] %>%
    group_by(v001, v002) %>%
    summarise(across(everything(), first), .groups = "drop")
  
  
  # ラベルの設定
  HRdata <- HRdata %>%
    set_variable_labels(
      v001 = "Cluster number",
      v002 = "Household number",
      dm_children_under12 = "Number of children under 12 years old",
      dm_cooking_fuel = "type of cooking fuel",
      dm_cooking_fuel_traditional = "using traditional cooking fuel",
      dm_rural = "living in rural area",
      dm_town = "living in small town",
      dm_city = "living in medium city",
      dm_capital = "living in capital city",
      dm_poorest = "poorest wealth quintile",
      dm_poorer = "poorer wealth quintile",
      dm_middle = "middle wealth quintile",
      dm_richer = "richer wealth quintile",
      dm_richest = "richest wealth quintile",
      dm_weath_index = "wealth index (normalized score)",
      dm_shared_toilet = "shared toilet(10 or more HH)",
      dm_ag_land_ha = "agricultural land (hectare)",
      dm_cooking_house = "cooking inside house",
      dm_cooking_outdoor = "cooking outdoor",
      dm_cooking_separate = "cooking in separate building",
      dm_cattle_own = "owns cattle",
      dm_goat_own = "owns goats",
      dm_sheep_own = "owns sheep",
      dm_poultry_own = "owns poultry",
      dm_refrigerator = "owns refrigerator",
      dm_female_headed = "female headed household",
      dm_age_of_HH_head = "Age of head of household",
      year = "Survey year",
      v005 = "Sample weight",
      v022 = "Stratum"
    ) %>%
    set_value_labels(
      dm_cooking_fuel = c(
        "electricity" = 1, "lpg" = 2, "natural gas" = 3, "biogas" = 4, 
        "kerosene" = 5, "coal, lignite" = 6, "charcoal" = 7, "wood" = 8, 
        "straw / shrubs / grass" = 9, "agricultural crop" = 10, 
        "animal dung" = 11, "no food cooked in hh" = 95, "other" = 96, 
        "not dejure resident" = 97),
      dm_cooking_fuel_traditional = c("Yes" = 1, "No" = 0),
      dm_rural = c("Yes" = 1, "No" = 0),
      dm_town = c("Yes" = 1, "No" = 0),
      dm_city = c("Yes" = 1, "No" = 0),
      dm_capital = c("Yes" = 1, "No" = 0),
      dm_poorest = c("Yes" = 1, "No" = 0),
      dm_poorer = c("Yes" = 1, "No" = 0),
      dm_middle = c("Yes" = 1, "No" = 0),
      dm_richer = c("Yes" = 1, "No" = 0),
      dm_richest = c("Yes" = 1, "No" = 0),
      dm_shared_toilet = c("Yes (10 or more households)"=1, "No (less than 10 households)"=0),
      dm_cooking_house=c("Yes (cooking inside house)"=1,"No (cooking outside or in separate building)"=0),
      dm_cooking_outdoor=c("Yes (cooking outdoor)"=1,"No (cooking inside house or in separate building)"=0),
      dm_cooking_separate=c("Yes (cooking in separate building)"=1,"No (cooking inside house or outdoor)"=0),
      dm_cattle_own=c("Yes (owns cattle)"=1,"No (does not own cattle)"=0),
      dm_goat_own=c("Yes (owns goats)"=1,"No (does not own goats)"=0),
      dm_sheep_own=c("Yes (owns sheep)"=1,"No (does not own sheep)"=0),
      dm_poultry_own=c("Yes (owns poultry)"=1,"No (does not own poultry)"=0),
      dm_refrigerator=c("Yes" = 1, "No" = 0),
      dm_female_headed=c("Yes" = 1, "No" = 0),
      dm_age_of_HH_head = c(
        "10s"=1, "20s"=2, "30s"=3, "40s"=4, 
        "50s"=5, "60s"=6, "70s"=7, "80+"=8
      )
    )

  print(sprintf("%s年：ファイルを保存します", yr))
  output_file_name <- "DMdata_dm.dta"
  output_file <- normalizePath(here("..", "output", yr, output_file_name))
  write_dta(HRdata, output_file)
  print(sprintf("%s年：ファイルの保存が完了しました", yr))
}

#*******************************************************************************************************************************
#** ここから実行
for (yr in year) {
  goAnalysis(yr)
}

#*******************************************************************************************************************************