# path for R project

# 各種の関数セット読み込み
source("myTools.R")

# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss" 

endes_list <- get_endes_file(
    yearlist = c("2005", "2008", "2012", "2015"),
    root_folder = gdrive_dir
  )
