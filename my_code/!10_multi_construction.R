# library(stringr) 
library(labelled)

# rmですべてのオブジェクトを削除
rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# データの読み込み
path_data_file <- normalizePath(
  here("..", "output", "alldata", "merged_all_years.dta")
) # ソースコードのルートフォルダを正規化
org_data <- read_dta(path_data_file)

org_data <- org_data %>%
  mutate(
    food_adeq = nt_mad,
    caring_fac_delivery = ifelse(rh_del_place == 1, 1, 0),
    caring_adeq = ifelse(rh_anc_4vs == 1 & caring_fac_delivery == 1 & 
                          nt_bf_start_1hr == 1, 1, 0),
    tmp_sani = ifelse(ph_sani_improve == 1, 1, 0),
    tmp_water = ifelse(ph_wtr_improve == 1, 1, 0),
    healthenv_adeq = ifelse(tmp_sani == 1 & tmp_water == 1 & 
                            ch_allvac_either == 1, 1, 0)
  ) %>%
  select(-tmp_sani, -tmp_water)

set_variable_labels(
  org_data,
  food_adeq = "Food Adequacy",
  caring_fac_delivery = "Delivery at health facility",
  caring_adeq = "Caring Adequacy",
  healthenv_adeq = "Health Environment Adequacy"
)

# 結合したデータフレームを保存
print(sprintf("saving all data"))
write_dta(org_data, path_data_file)
print(sprintf("Data merged and saved to: %s", "merged_all_years.dta"))

