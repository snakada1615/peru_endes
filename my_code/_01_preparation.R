library(openxlsx)

rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss" 

# 対象とする年のリスト
yearlist = c("2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012",
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
    mutate(year = yr)            # yrを新しい列として追加
  endes_list <- bind_rows(endes_list, sav_files)
}
outputfile <- file.path(gdrive_dir, "output", "endes_data_list.rds") %>%
  normalizePath() %>%
  trimws()

# ファイルをRDSで保存
saveRDS(endes_list, file = outputfile)

for (yr in yearlist) {
  print(paste("Processing year:", yr))
  df_result <- NULL
  year_df <- endes_list %>% filter(year == yr) # sliceで抜く
  for (i in 1:nrow(year_df)) {
    row <- year_df[i,]
    print(row[["filename"]])
    filepath <- file.path(gdrive_dir, row[["year"]], row[["relative_path"]], row[["filename"]]) %>%
      normalizePath() %>%
      trimws()
    df <- read_sav(filepath, encoding = "latin1")
    df_label <- getLabelfromDF(df) %>%
      mutate(
        year = row[["year"]],
        fileName = row[["filename"]]
      )
    df_result <- bind_rows(df_result, df_label)
  }
  df_result <- df_result %>%
    mutate(label_english = "") # 空の列を追加
  
  print(paste0("number of rows =", as.character(nrow(df_result))))
  outputfile <- file.path(gdrive_dir, "output", yr, paste0("endes_var_labels_", yr, ".rds")) %>%
    normalizePath() %>%
    trimws()
  # saveRDS(df_result, file = outputfile)
  write.xlsx(df_result, file = gsub(".rds", ".xlsx", outputfile))
}

