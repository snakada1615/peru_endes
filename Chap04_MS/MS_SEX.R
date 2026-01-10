# ******************************************************************************
# Program: 			  MS_MAR.do
# Purpose: 			  Code to create marital indicators
# Data inputs: 		IR and MR survey list
# Data outputs:		coded variables and scalars
# Author:				  Courtney Allen for code share project
# Date last modified: August 2022 by Courtney Allen 
# ******************************************************************************

# Variables created in this file ------------------------------------------------
#   
# ms_afs_15		"First sexual intercourse by age 15"
# ms_afs_18		"First sexual intercourse by age 18"
# ms_afs_20		"First sexual intercourse by age 20"
# ms_afs_22		"First sexual intercourse by age 22"
# ms_afs_25		"First sexual intercourse by age 25"
# ms_mafs_25		 Median age at first sexual intercourse among age 25-49" (scalar, not a variable)
# ms_sex_never	"Never had intercourse"
# ms_sex_4wks   "Sexually active in last four weeks"
# ms_sex_1yr    "Sexually active in last year"
# ms_sex_1yrplus "Sexually active in one or more years ago"

# Datafiles created
#
# median_sex              datafile with median age at first sex (MAFS) by 5-year age groups among women
# median_sex_subgroup     datafile with median age at first sex (MAFS) by subgroup characteristics among women 20-49 and 25-49
# median_sex_men          datafile with median age at first sex (MAFS) by 5-year age groups among men
# median_sex_subgroup_men datafile with median age at first sex (MAFS) by subgroup characteristics among men 25-59 and 30-59 (age range may vary in survey)




# AGE AT FIRST SEX (AFS) (WOMEN)------------------------------------------------------
  
# Create yes and no category labels
yesno = c("Yes" = 1, "No" = 0)

				
# Never had sex
IRdata <- IRdata %>%
  mutate(ms_sex_never = case_when(
    v531==0 ~ 1,
    TRUE ~ 0
    )) %>%
  set_value_labels(ms_sex_never = yesno) %>%
  set_variable_labels(ms_sex_never = "Never had sex")


# Had sex by age 15
IRdata <- IRdata %>%
  mutate(ms_afs_15 = case_when(
    v531>=1 & v531<15 ~ 1,
    TRUE ~ 0)) %>%
  set_value_labels(ms_afs_15 = yesno) %>%
  set_variable_labels(ms_afs_15 = "First sex by age 15")

# Had sex by age 18
IRdata <- IRdata %>%
  mutate(ms_afs_18 = case_when(
    v531>=1 & v531<18 ~ 1,
    TRUE ~ 0)) %>%
  set_value_labels(ms_afs_18 = yesno) %>%
  set_variable_labels(ms_afs_18 = "First sex by age 18")

# Had sex by age 20
IRdata <- IRdata %>%
  mutate(ms_afs_20 = case_when(
    v531>=1 & v531<20 ~ 1,
    TRUE ~ 0)) %>%
  set_value_labels(ms_afs_20 = yesno) %>%
  set_variable_labels(ms_afs_20 = "First sex by age 20")

# Had sex by age 22
IRdata <- IRdata %>%
  mutate(ms_afs_22 = case_when(
    v531>=1 & v531<22 ~ 1,
    TRUE ~ 0)) %>%
  set_value_labels(ms_afs_22 = yesno) %>%
  set_variable_labels(ms_afs_22 = "First sex by age 22")

# Had sex by age 25
IRdata <- IRdata %>%
  mutate(ms_afs_25 = case_when(
    v531>=1 & v531<25 ~ 1,
    TRUE ~ 0)) %>%
  set_value_labels(ms_afs_25 = yesno) %>%
  set_variable_labels(ms_afs_25 = "First sex by age 25")



# RECENT SEXUAL ACTIVITY (WOMEN) -----------------------------------------------


# Recent sexual activity
IRdata <- IRdata %>%
  mutate(ms_sex_recent = case_when(
    v528 <= 28 ~ 1,
    v527 > 128 & v527 < 312 ~ 2,
    v527 >= 401 & v527 < 997 ~ 3,
    v531 == 0 ~ 4)) %>%
  set_value_labels(ms_sex_recent = c("Sex in last 4 wks" = 1, 
                                     "Sex in last yr" = 2, 
                                     "Sex in 1 or more yrs" = 3,
                                     "Never had sex" = 4)) %>%
  set_variable_labels(ms_sex_recent = "Recent sexual activity")


# # 男性は省略
# AGE AT FIRST SEX (AFS) (MEN) ------------------------------------------------------
	
# # Never had sex
# MRdata <- MRdata %>%
#   mutate(ms_sex_never = case_when(
#     mv531==0 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_sex_never = yesno) %>%
#   set_variable_labels(ms_sex_never = "Never had sex")
# 
# 
# # Had sex by age 15
# MRdata <- MRdata %>%
#   mutate(ms_afs_15 = case_when(
#     mv531>=1 & mv531<15 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_afs_15 = yesno) %>%
#   set_variable_labels(ms_afs_15 = "First sex by age 15")
# 
# # Had sex by age 18
# MRdata <- MRdata %>%
#   mutate(ms_afs_18 = case_when(
#     mv531>=1 & mv531<18 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_afs_18 = yesno) %>%
#   set_variable_labels(ms_afs_18 = "First sex by age 18")
# 
# # Had sex by age 20
# MRdata <- MRdata %>%
#   mutate(ms_afs_20 = case_when(
#     mv531>=1 & mv531<20 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_afs_20 = yesno) %>%
#   set_variable_labels(ms_afs_20 = "First sex by age 20")
# 
# # Had sex by age 22
# MRdata <- MRdata %>%
#   mutate(ms_afs_22 = case_when(
#     mv531>=1 & mv531<22 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_afs_22 = yesno) %>%
#   set_variable_labels(ms_afs_22 = "First sex by age 22")
# 
# # Had sex by age 25
# MRdata <- MRdata %>%
#   mutate(ms_afs_25 = case_when(
#     mv531>=1 & mv531<25 ~ 1,
#     TRUE ~ 0)) %>%
#   set_value_labels(ms_afs_25 = yesno) %>%
#   set_variable_labels(ms_afs_25 = "First sex by age 25")

# 男性は省略
# RECENT SEXUAL ACTIVITY (MEN) -----------------------------------------------
# 
# 
# # Recent sexual activity
# MRdata <- MRdata %>%
#   mutate(ms_sex_recent = case_when(
#     mv528 <= 28 ~ 1,
#     mv527 > 128 & mv527 < 312 ~ 2,
#     mv527 >= 401 & mv527 < 997 ~ 3,
#     mv531 == 0 ~ 4)) %>%
#   set_value_labels(ms_sex_recent = c("Sex in last 4 wks" = 1, 
#                                      "Sex in last yr" = 2, 
#                                      "Sex in 1 or more yrs" = 3,
#                                      "Never had sex" = 4)) %>%
#   set_variable_labels(ms_sex_recent = "Recent sexual activity")
# 




# MEDIAN AGES ---------------------------------------------------


# NOTES
#  Medians are calculated based on completed time periods using program defined
#  at beginning of this R script: calc_median_age()
#  See https://www.dhsprogram.com/data/Guide-to-DHS-Statistics.cfm for full details.
#  
#  Some age groups do not have medians because 50% of the respondents had not had sex by
#  the beginning of the age group. Each median is calculated and saved as a vector. 
#
#  Medians can found for subgroups by adding to the variable list below in 
#  the same manner


# MEDIAN AGE FUNCTION ----------------------------------------------------------
calc_median_age <- function(dhssvy2, beg_age) {
  # 年齢別の加重頻度表を作成
  age_table <- svytable(~ms_age, design = dhssvy2)
  
  # 観測値がない場合は早期リターン
  if (sum(age_table) == 0) {
    return(NA_real_)
  }
  
  # 累積割合を計算
  median_df <- data.frame(
    prop_cumulative = unclass(round(cumsum(prop.table(age_table)), 4))
  )
  median_df$age <- as.numeric(row.names(median_df))
  
  # 0.5を跨ぐ年齢群を特定
  median_df <- median_df %>%
    mutate(
      age_before50 = case_when(
        prop_cumulative < 0.5 & lead(prop_cumulative) > 0.5 ~ 1, 
        TRUE ~ 0
      ),
      age_after50 = case_when(
        prop_cumulative >= 0.5 & lag(prop_cumulative) < 0.5 ~ 1, 
        TRUE ~ 0
      )
    )
  
  # 0.5に到達しない場合はNAを返す
  if (max(median_df$prop_cumulative, na.rm = TRUE) < 0.5) {
    return(NA_real_)
  }
  
  # 年齢群の抽出（安全なインデックス操作）
  m1 <- median_df$age[median_df$age_before50 == 1]
  p1 <- median_df$prop_cumulative[median_df$age_before50 == 1]
  p2 <- median_df$prop_cumulative[median_df$age_after50 == 1]
  
  # 長さチェック
  if (length(m1) == 0 || length(p1) == 0 || length(p2) == 0) {
    return(NA_real_)
  }
  
  # 中央値の計算（DHS式に従う）
  median_age <- round((m1 + ((0.5 - p1) / (p2 - p1)) + 1), 1)
  
  # 開始年齢より大きい場合はNA
  median_age <- ifelse(median_age > beg_age, NA_real_, median_age)
  
  return(median_age)
}

# MEDIAN AGE AT FIRST  (MAFS) BY AGE GROUP  (WOMEN)---------------------------------
# if respondent has not had sex (v531==0) then replace with 99 to put these at the tail end of distribution for median
IRdata <- IRdata %>% mutate(ms_age =case_when(v531==0 ~ 99, TRUE ~ as.numeric(v531)))

# list of the beginning age groups
beg_age_list <- c(15, 20, 25, 30, 35, 40, 45)

# create empty dataframe to fill in with results
median_sex <- data.frame("age group"=NA, "median afs"=NA)


# create loop for each age group
for (a in beg_age_list) {
  beg_age <- a
  end_age <- a+4
  
  cat("finding median for ages", beg_age, "to", end_age)
  cat("here 01")
  #subset the age group using a beginning and ending age and subgroup
  temp_df <- IRdata %>% filter(v012>= beg_age & v012<= end_age) %>%
    select(ms_age, v021, v022, v005)
  
  if (nrow(temp_df) == 0) {
    cat("No data available for ages", beg_age, "to", end_age, "\n")
    median_age <- NA_real_
  } else {
    cat("Data available: nrow =", nrow(temp_df), "\n")
    
    # Create NEW survey design object for each subset
    sub_design <- svydesign(
      id = ~v021,
      strata = temp_df$v022, 
      weights = temp_df$v005 / 1000000,
      data = temp_df,
      nest = TRUE
    )
    
    median_age <- calc_median_age(sub_design, beg_age)
    
    # Safety check
    if (length(median_age) == 0) {
      median_age <- NA_real_
    }
  }

  # #save results
  # data_row <- data.frame(paste0(beg_age,"-",end_age), median_age)
  # median_sex <- rbind(median_sex, setnames(data_row, names(median_sex)))
  # cat("here 02")

  # save results to list
  results_list[[paste0(beg_age, "-", end_age)]] <- data.frame(
    age_group = paste0(beg_age, "-", end_age),
    median_age = median_age,
    stringsAsFactors = FALSE
  )
}

# combine all results
median_sex <- do.call(rbind, results_list)


# MEDIAN AGE AT FIRST SEX (MAFS) BY AGE GROUP AND SUBGROUP (WOMEN)----------------------


# mutate a dummy variable to loop through all women instead of subgroup
IRdata <- IRdata %>% mutate(all = 1) %>% 
  set_variable_labels(all = "total") %>% 
  set_value_labels(all = c("total"=1))

# list of subgroup characteristics (residence, education, wealth, total)
subgroup <- c("v025", "v106", "v190", "all")

# list of the beginning age groups (among subgroups only two age groups used: 20-49, 25-49)
beg_age_list <- c( 20, 25)
end_age <- max(IRdata$v012)   

# create empty dataframe to fill in with results
# median_sex_subgroup <- data.frame(
#   "age group"=NA, "subgroup"=NA, "level"=NA, "median afs"=NA)
# create empty list to store results
results_subgroup_list <- list()



# create loop for each age group and each level of each subgroup characteristic
for (a in beg_age_list) {
  beg_age <- a
  
  for(y in subgroup) {  
    
    # generate list of unique levels for each subgroup
    z <- as.vector(remove_val_labels(unique(IRdata[[y]])))
    
    # loop through each level of each subgroup
    for(x in z) {
      cat("finding median for ages", beg_age, "to", end_age, "subgroup:", y, "level=", x)
      
      # Subset data frame by age AND subgroup level
      temp_df <- IRdata %>% 
        filter(v012 >= beg_age & v012 <= end_age & .data[[y]] == x)
      
      if (nrow(temp_df) == 0) {
        cat("No data available for ages", beg_age, "to", end_age, 
            "subgroup:", y, "level=", x, "\n")
        median_age <- NA_real_
      } else {
        # Create NEW survey design object for each subset
        sub_design <- svydesign(
          id = ~v021,
          strata = ~v022,
          weights = temp_df$v005 / 1000000,
          data = temp_df,
          nest = TRUE
        )
        median_age <- calc_median_age(sub_design, beg_age)
        
        if (length(median_age) == 0) {
          median_age <- NA_real_
        }
      }
      
      # Get labels safely
      subgroup_label <- tryCatch(
        var_label(IRdata[[y]]), 
        error = function(e) y
      )
      level_label <- tryCatch(
        val_label(IRdata[[y]], x), 
        error = function(e) x
      )
      
      # Save results
      results_subgroup_list[[paste(beg_age, y, x, sep = "_")]] <- data.frame(
        "age group" = paste0(beg_age, "-", end_age),
        "subgroup" = subgroup_label,
        "level" = level_label,
        "median sex_age" = median_age,
        stringsAsFactors = FALSE
      )
      
      # #save results
      # data_row <- data.frame(
      #   paste0(beg_age,"-",end_age), 
      #   var_label(IRdata[,y]), 
      #   val_label(IRdata[,y],x), 
      #   median_age)
      # 
      # median_sex_subgroup <- rbind(median_sex_subgroup, setnames(data_row, names(median_sex_subgroup)))
      
    }
  }
}

# combine all results
median_sex_subgroup <- do.call(rbind, results_subgroup_list)



# 男性は省略
# MEDIAN AGE AT FIRST SEX (MAFS) BY AGE GROUP  (MEN)---------------------------------

# # if respondent has not had sex (v531==NA) then replace with 99 to put these at the tail end of distribution for median
# MRdata <- MRdata %>% mutate(ms_age =case_when(mv531==0 ~ 99, TRUE ~ as.numeric(mv531)))
# 
# # list of the beginning age groups
# beg_age_list <- c(15, 20, 25, 30, 35, 40, 45)
# 
# 
# # create empty dataframe to fill in with results
# median_sex_men <- data.frame("age group"=NA, "median afs"=NA)
# 
# 
# # create loop for each age group
# for (a in beg_age_list) {
#   beg_age <- a
#   end_age <- a+4
#   
#   cat("finding median for ages", beg_age, "to", end_age)
#   
#   #subset the age group using a beginning and ending age and subgroup
#   temp_df <- MRdata %>% filter(mv012>= beg_age & mv012<= end_age) %>%
#     select(ms_age, mv021, mv022, mv005)
#   
#   # weight data
#   dhssvy2 <- svydesign(id = temp_df$mv021, strata=temp_df$mv022, weights = temp_df$mv005/1000000, data=temp_df)
#   
#   median_age <- calc_median_age()
#   
#   
#   #save results
#   data_row <- data.frame(paste0(beg_age,"-",end_age), median_age)
#   median_sex_men <- rbind(median_sex_men, setnames(data_row, names(median_sex_men)))
#   
#   
# }
# 
# 
# # MEDIAN AGE AT FIRST SEX (MAFS) BY AGE GROUP AND SUBGROUP (MEN)----------------------
# 
# 
# # mutate a dummy variable to loop through all women instead of subgroup
# MRdata <- MRdata %>% mutate(all = 1) %>% set_variable_labels(all = "total") %>% set_value_labels(all = c("total" = 1))
# 
# # list of subgroup characteristics (residence, education, wealth, total)
# subgroup <- c("mv025", "mv106", "mv190", "all")
# 
# # list of the beginning age groups  (among subgroups only two age groups used: 20-49, 25-49)
# beg_age_list <- c( 20, 25)
# end_age <- max(MRdata$mv012)  
# 
# # create empty dataframe to fill in with results
# median_sex_subgroup_men <- data.frame("age group"=NA, "subgroup"=NA, "level"=NA, "median afs"=NA)
# 
# 
# 
# # create loop for each age group and each level of each subgroup characteristic
# for (a in beg_age_list) {
#   beg_age <- a
#   
#   for(y in subgroup) {  
#     
#     # generate list of unique levels for each subgroup
#     z <- as.vector(remove_val_labels(unique(MRdata[[y]])))
#     
#     # loop through each level of each subgroup
#     for(x in z) {
#       cat("finding median for ages", beg_age, "to", end_age, "subgroup:", y, "level=", x)
#       
#       #subset the age group using a beginning and ending age and subgroup
#       temp_df <- MRdata %>% filter(mv012>= beg_age & mv012<= end_age) %>%
#         select(ms_age, mv025, mv106, mv190, all, mv021, mv022, mv005)
#       temp_df <- temp_df[ temp_df[y]==x, ]
#       
#       # weight data
#       dhssvy2 <- svydesign(id = temp_df$mv021, strata=temp_df$mv022, weights = temp_df$mv005/1000000, data=temp_df)
#       
#       median_age <- calc_median_age()
#       
#       
#       #save results
#       data_row <- data.frame(paste0(beg_age,"-",end_age), var_label(MRdata[,y]), val_label(MRdata[,y],x), median_age)
#       median_sex_subgroup_men <- rbind(median_sex_subgroup_men, setnames(data_row, names(median_sex_subgroup_men)))
#       
#     }
#   }
#   
# }

