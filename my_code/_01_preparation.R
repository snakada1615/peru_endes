library(openxlsx)
library(dplyr)          # For %>%, mutate(), case_when()
library(readr)
library(here)          # For here() function

rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss" 

# 対象とする年のリスト
yearlist <- c("2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012",
             "2013", "2014", "2015", "2016")
# yearlist <- c("2015")

endes_list <- NULL   # 空のリストまたはデータフレームとして初期化
for (yr in yearlist) {
  root_folder <- file.path(gdrive_dir, yr) %>%
    normalizePath() %>%
    trimws()
  sav_files <- getFilesByType(
    root_folder = root_folder,   # root_folderを渡す
    filetype = "sav"
  ) %>%
    mutate(
      year = yr,        # yrを新しい列として追加
      relative_path =  file.path(yr, relative_path) # 相対パスを計算して更新
      )            
  
  endes_list <- bind_rows(endes_list, sav_files) %>%
    as_tibble()
}
outputfile <- file.path(gdrive_dir, "output", "endes_data_list.rds") %>%
  normalizePath() %>%
  trimws()

# ファイルをRDSで保存
saveRDS(endes_list, file = outputfile)

endes_vaeiable_list <- NULL
endes_keys <- NULL
for (yr in yearlist) {
  print(paste("Processing year:", yr))
  # 変数ラベルの取得
  df_result <- NULL
  df_result2 <- NULL
  year_df <- endes_list %>% filter(year == yr) # sliceで抜く
  for (i in 1:nrow(year_df)) {
    row <- year_df[i,]
    print(row[["filename"]])
    filepath <- file.path(gdrive_dir, row[["relative_path"]], row[["filename"]]) %>%
      normalizePath() %>%
      trimws()
    df <- read_sav(filepath, encoding = "latin1")
    df_label <- getLabelfromDF(df) %>%
      mutate(
        year = row[["year"]],
        filename = row[["filename"]]
      )
    df_result <- bind_rows(df_result, df_label)
  }
  df_result <- df_result %>%
    mutate(label_english = "") # 空の列を追加
  
  print(paste0("number of rows =", as.character(nrow(df_result))))
  
  endes_vaeiable_list <- bind_rows(endes_vaeiable_list, df_result) %>%
    as_tibble()
  
  # 家庭データのキー情報を取得
  df_result2 <-open_endes_file(yr, "RECH0.sav") %>%
    rename_with(~ tolower(.x)) %>%
    select(v001 = hv001, v002 = hv002, v003 = hv003, v005 = hv005, hhid = hhid,
           v021 = hv021, v022 = hv022, v024 = hv024, v025 = hv025, 
           v026 = hv026) %>%
    mutate(year = yr)
  endes_keys <- bind_rows(endes_keys, df_result2) %>% as_tibble()
  
}

# CRECERプログラムの介入期間の取得
crecer_timing <- read_csv(normalizePath(here("my_code", "state_list.csv"))) %>%
  mutate(
    treatment_start = as.numeric(year_treated) # treatment_startを数値に変換
  ) 

# 家庭データにCRECERの介入情報を結合
endes_keys <- endes_keys %>%
  left_join(crecer_timing, by = c("v024" = "state_id")) %>%
  mutate(
    treated_status = case_when(
      year_treated == 2009 & as.numeric(year) >= 2009 ~ "early_treated",  # 早期開始州かつ2009年以降
      year_treated == 2011 & as.numeric(year) >= 2011 ~ "late_treated",   # 後期開始州かつ2011年以降
      !is.na(year_treated) ~ "not_yet_treated",                           # 将来的にtreatedになるが年が到達していない
      is.na(year_treated) ~ "never_treated",                              # どれにも該当しない
      TRUE ~ "other"                                                       # その他（念のため）
    ),
    group_treated = case_when(
      year_treated == 2009 ~ "treat1_grp",
      year_treated == 2011 ~ "treat2_grp",
      TRUE ~ "control_grp"
    )
  )

# save the variable list to an RDS file
outputfile <- file.path(gdrive_dir, "output", paste0("endes_var_labels", ".rds")) %>%
  normalizePath() %>%
  trimws()
saveRDS(endes_vaeiable_list, file = outputfile)
write.xlsx(endes_vaeiable_list, file = gsub(".rds", ".xlsx", outputfile))
saveRDS(endes_keys, file = file.path(gdrive_dir, "output", "endes_keys.rds"))

print("complete")
