# path for R project

rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss" 

# 対象とする年のリスト
yearlist = c("2005", "2008", "2012", "2015")

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



# endes_list <- get_endes_file(
#     yearlist,
#     root_folder = gdrive_dir
#   )
# 
# fileName <- endes_list[["2005"]]$RECH4
# df <-  read_sav(fileName)
# df_label <- getLabelfromDF(df) %>%
#   mutate(year = "2005")
# 
# for (yr in yearlist) {
#   for (fileType in endes_list[[yr]][1]) {
#     fileName <- endes_list[[yr]][[fileType]]
#     print(fileName)
#   }
# }