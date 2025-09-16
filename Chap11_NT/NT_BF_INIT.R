# /*****************************************************************************************************
# Program: 			NT_BF_INIT.R
# Purpose: 			Code to compute initial breastfeeding indicators
# Data inputs: 	KR dataset
# Data outputs:	coded variables
# Author:				Shireen Assaf
# Date last modified: Nov 24, 2021 by Shireen Assaf
# *****************************************************************************************************/
# 
# /*----------------------------------------------------------------------------
# Variables created in this file:
# nt_bf_ever			  "Ever breastfed - last-born in the past 2 years"
# nt_bf_start_1hr		"Started breastfeeding within one hour of birth - last-born in the past 2 years"
# nt_bf_start_1day	"Started breastfeeding within one day of birth - last-born in the past 2 years"
# nt_bf_prelac		  "Received a prelacteal feed - last-born in the past 2 years ever breast fed"
# 
# nt_bottle			    "Drank from a bottle with a nipple yesterday - under 2 years"
# ----------------------------------------------------------------------------*/

# # age of child. If b19 is not available in the data use v008 - b3
# if ("TRUE" %in% (!("b19" %in% names(KRdata))))
#   KRdata [[paste("b19")]] <- NA
# if ("TRUE" %in% all(is.na(KRdata$b19)))
# { b19_included <- 0} else { b19_included <- 1}
# 
# if (b19_included==1) {
#   KRdata <- KRdata %>%
#     mutate(age = b19)
# } else {
#   KRdata <- KRdata %>%
#     mutate(age = v008 - b3)
# }
# 
# 
# KRdata <- KRdata %>%
#   mutate(wt = v005/1000000)

# // INITIAL BREASTFEEDING

#//Ever breastfed
KRdata <- KRdata %>%
  mutate(nt_bf_ever =
           case_when(
             (midx==1 & age<24) & m4 %in% c(93,95)  ~ 1 ,
             (midx==1 & age<24) & m4 %in% c(94,98,99) ~ 0)) %>%
  set_value_labels(nt_bf_ever = c("Yes" = 1, "No"=0  )) %>%
  set_variable_labels(nt_bf_ever = "Ever breastfed - last-born in the past 2 years")

# //Start breastfeeding within 1 hr
KRdata <- KRdata %>%
  mutate(nt_bf_start_1hr =
           case_when(
             (midx==1 & age<24) &  m34<=100 ~ 1 ,
             (midx==1 & age<24)  ~ 0)) %>%
  set_value_labels(nt_bf_start_1hr = c("Yes" = 1, "No"=0  )) %>%
  set_variable_labels(nt_bf_start_1hr = "Started breastfeeding within one hour of birth - last-born in the past 2 years")

# //Start breastfeeding within 1 day
KRdata <- KRdata %>%
  mutate(nt_bf_start_1day =
           case_when(
             (midx==1 & age<24) &  m34<=123 ~ 1 ,
             (midx==1 & age<24)  ~ 0)) %>%
  set_value_labels(nt_bf_start_1day = c("Yes" = 1, "No"=0  )) %>%
  set_variable_labels(nt_bf_start_1day = "Started breastfeeding within one day of birth - last-born in the past 2 years")

# //Given prelacteal feed

# m55列が存在するかどうかの事前チェック
if ("m55A" %in% names(KRdata)) {
  # m55列が存在する場合の処理
  m55_cols <- c("M55A", "M55B", "M55C", "M55D", "M55E", "M55F", "M55G", "M55H", 
                "M55I", "M55J", "M55K", "M55L", "M55M", "M55N", "M55X", "M55Z")
  KRdata <- KRdata %>%
    mutate(m55 = ifelse(if_any(c(A, B, C), ~ .x == 1), 1, 0)) %>%
    mutate(
      nt_bf_prelac = case_when(
        (midx == 1 & age < 24) & m4 %in% c(93, 95) & m55 == 1 ~ 1,
        (midx == 1 & age < 24) & m55 == 0 ~ 0
      ),
      nt_bf_prelac_noBirthRecord = 0 # m55が存在する場合は、この変数は常に0
    ) %>%
    set_value_labels(nt_bf_prelac = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_bf_prelac = "Received a prelacteal feed - last-born in the past 2 years ever breast fed (with birth record)") %>%
    set_value_labels(nt_bf_prelac_noBirthRecord = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_bf_prelac_noBirthRecord = "Received a prelacteal feed - last-born in the past 2 years ever breast fed (without birth record data)")
  
} else {
  # m55列が存在しない場合の処理
  KRdata <- KRdata %>%
    mutate(
      nt_bf_prelac = NA_integer_, # m55がないため、nt_bf_prelacはNA
      nt_bf_prelac_noBirthRecord = case_when(
        (midx == 1 & age < 24) & m4 %in% c(93, 95) ~ 1, # m55がない場合、かつ条件を満たす
        (midx == 1 & age < 24) ~ 0 # それ以外の場合
      )
    ) %>%
    set_value_labels(nt_bf_prelac = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_bf_prelac = "Received a prelacteal feed - last-born in the past 2 years ever breast fed (with birth record)") %>%
    set_value_labels(nt_bf_prelac_noBirthRecord = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(nt_bf_prelac_noBirthRecord = "Received a prelacteal feed - last-born in the past 2 years ever breast fed (without birth record data)")
  
  # nt_bf_prelacのラベルも設定しておく（NAだが、将来的にm55列が追加される可能性を考慮）
  attr(KRdata$nt_bf_prelac, "label") <- "Received a prelacteal feed - last-born in the past 2 years ever breast fed (with birth record) - Not applicable (m55 missing)"
}# ----------------------------------------------------------------------------

# //Using bottle with nipple 
KRdata <- KRdata %>%
  mutate(nt_bottle =
           case_when(
             age<24 & m38==1 & b5==1  ~ 1 ,
             age<24 & b5==1  ~ 0)) %>%
  set_value_labels(nt_bottle = c("Yes" = 1, "No"=0  )) %>%
  set_variable_labels(nt_bottle = "Drank from a bottle with a nipple yesterday - under 2 years")

