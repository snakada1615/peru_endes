# /*****************************************************************************************************
# Program: 			NT_CH_MICRO.R
# Purpose: 			Code to compute micronutrient indicators in children
# Data inputs: 	KR dataset
# Data outputs:	coded variables
# Author:				Shireen Assaf
# Date last modified: Dec 3, 2021 by Shireen Assaf 
# *****************************************************************************************************/
# 
# /*----------------------------------------------------------------------------
# Variables created in this file:
# 
# nt_ch_micro_mp		"Children age 6-23 mos given multiple micronutrient powder"
# nt_ch_micro_iron	"Children age 6-59 mos given iron supplements"
# nt_ch_micro_vas		"Children age 6-59 mos given Vit. A supplements"
# nt_ch_micro_dwm		"Children age 6-59 mos given deworming medication"
# nt_ch_micro_iod		"Children age 6-59 mos live in hh with iodized salt"
# nt_ch_food_ther		"Children age 6-35 mos given therapeutic food"
# nt_ch_food_supp		"Children age 6-35 mos given supplemental food"
# 
# ----------------------------------------------------------------------------*/

# age of child. If b19 is not available in the data use v008 - b3
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


KRdata <- KRdata %>%
  mutate(wt = v005/1000000)

# h80a列が存在しない場合はNA列を追加
if (!"h80a" %in% names(KRdata)) {
  KRdata <- KRdata %>%
    mutate(h80a = NA_real_)
}

# h42列が存在しない場合はNA列を追加
if (!"h42" %in% names(KRdata)) {
  KRdata <- KRdata %>%
    mutate(h42 = NA_real_)
}

# // received multiple micronutrient powder
KRdata <- KRdata %>%
  mutate(nt_ch_micro_mp =
           case_when(
             age < 6 | age > 23 | b5 == 0 ~ 99, 
             h80a != 1 ~ 0,
             h80a == 1 ~ 1,
             TRUE ~ NA_real_  # catch-all to ensure no unexpected result
           )) %>%
  replace_with_na(replace = list(nt_ch_micro_mp = c(99))) %>%
  set_value_labels(nt_ch_micro_mp = c("Yes" = 1, "No" = 0)) %>%
  set_variable_labels(nt_ch_micro_mp = "Children age 6-23 mos given multiple micronutrient powder")


# //Received iron supplements
KRdata <- KRdata %>%
  mutate(nt_ch_micro_iron =
           case_when(
             age<6 | age>59 | b5==0 ~ 99, 
             h42!=1 ~ 0 ,
             h42==1 ~ 1, 
             TRUE ~ NA_real_  # catch-all to ensure no unexpected result
           )) %>%
  replace_with_na(replace = list(nt_ch_micro_iron = c(99))) %>%
  set_value_labels(nt_ch_micro_iron = c("Yes" = 1, "No"=0  )) %>%
  set_variable_labels(nt_ch_micro_iron = "Children age 6-59 mos given iron supplements")

# //Received Vit. A supplements
# 1. 最初に使用する 'v008系指標' を動的に決定：例えば temp_v008 に格納
if ("v008a" %in% names(KRdata)) {
  KRdata <- KRdata %>% mutate(temp_v008 = v008a)
} else if ("v008" %in% names(KRdata)) {
  KRdata <- KRdata %>% mutate(temp_v008 = v008)
} else {
  stop("Neither 'v008a' nor 'v008' exists in the dataset.")
}

# 2. 以降は temp_v008 を使って安全に処理
KRdata <- KRdata %>%
  mutate(
    # h33mがなければ一括で NA 設定（処理をここで止める）
    nt_ch_micro_vas = case_when(
      is.na(h33m) ~ NA_integer_,
      TRUE ~ -1L  # 仮置き
    )
  ) %>%
  mutate(
    h33m2 = if_else(nt_ch_micro_vas == -1L, h33m, NA_real_),
    h33d2 = if_else(h33d == 98, 15, as.numeric(h33d)),
    h33y2 = h33y
  ) %>%
  replace_with_na(replace = list(h33m2 = c(98))) %>%
  replace_with_na(replace = list(h33y2 = c(9998))) %>%
  mutate(
    Date = if_else(
      !is.na(h33m2) & !is.na(h33d2) & !is.na(h33y2),
      as.Date(paste(h33y2, h33m2, h33d2, sep = "-"), "%Y-%m-%d"),
      as.Date(NA)
    )
  ) %>%
  mutate(
    mdyc = if_else(
      !is.na(temp_v008) & !is.na(Date),
      as.integer((temp_v008 - (as.numeric(difftime(Date, as.Date("1960-01-01"), units = "days")) + 21916)) / 30.4375),
      NA_integer_
    )
  ) %>%
  mutate(
    nt_ch_micro_vas = case_when(
      is.na(h33m) ~ NA_integer_,  # 再確認
      (age >= 6 & age <= 59) & (h34 == 1 | (!is.na(mdyc) & mdyc <= 6)) ~ 1,
      !(age >= 6 & age <= 59) | b5 == 0 ~ 99,
      TRUE ~ 0
    )
  ) %>%
  replace_with_na(replace = list(nt_ch_micro_vas = c(99))) %>%
  set_value_labels(nt_ch_micro_vas = c("Yes" = 1, "No" = 0)) %>%
  set_variable_labels(nt_ch_micro_vas = "Children age 6-59 mos given Vit. A supplements")

library(dplyr)
library(labelled)
library(naniar)  # for replace_with_na()

# //Received deworming medication
if ("h43" %in% names(KRdata)) {
  KRdata <- KRdata %>%
    mutate(nt_ch_micro_dwm =
             case_when(
               age < 6 | age > 59 | b5 == 0 ~ 99,
               h43 != 1 ~ 0,
               h43 == 1 ~ 1
             )) %>%
    replace_with_na(replace = list(nt_ch_micro_dwm = c(99))) %>%
    set_value_labels(nt_ch_micro_dwm = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_ch_micro_dwm = "Children age 6-59 mos given deworming medication")
} else {
  KRdata <- KRdata %>%
    mutate(nt_ch_micro_dwm = NA_real_) %>%
    set_variable_labels(nt_ch_micro_dwm = "Children age 6-59 mos given deworming medication (var missing)")
}

# //Child living in household with iodized salt
if ("hv234a" %in% names(KRdata)) {
  KRdata <- KRdata %>%
    mutate(nt_ch_micro_iod =
             case_when(
               age < 6 | age > 59 | b5 == 0 | hv234a > 1 ~ 99,
               hv234a == 0 ~ 0,
               hv234a == 1 ~ 1
             )) %>%
    replace_with_na(replace = list(nt_ch_micro_iod = c(99))) %>%
    set_value_labels(nt_ch_micro_iod = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_ch_micro_iod = "Children age 6-59 mos live in hh with iodized salt")
} else {
  KRdata <- KRdata %>%
    mutate(nt_ch_micro_iod = NA_real_) %>%
    set_variable_labels(nt_ch_micro_iod = "Children age 6-59 mos live in hh with iodized salt (var missing)")
}

