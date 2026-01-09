
# DHS年リスト
default_yearList <- c("2005", "2008", "2009", "2010", "2011", "2012")  # vector型でOK

# ******************************************************************************

# 複数年のDHSファイルを取得してリストに格納する関数
get_dhs_file <- function(yearlist = default_yearList, root_folder) {
  dhsFiles <- list()
  
  # DHSフォルダを取得する関数
  helper_data_root <- function(year, root_folder) {
    return(
      file.path(root_folder, year) %>%
        normalizePath() %>%
        trimws()
    ) 
  }
  # DHSファイルを取得するヘルパー関数
  # 単年のDHSファイルを取得する関数
  helper_getDHSfile <- function(year, root_folder) {
    
    dfDhsFiles <- getFilesByType(
      root_folder = root_folder,
      filetype = "dta"
    )
    
    KRFile <- filter(dfDhsFiles, str_detect(relative_path, "KR"))$filename
    PRFile <- filter(dfDhsFiles, str_detect(relative_path, "PR"))$filename
    IRFile <- filter(dfDhsFiles, str_detect(relative_path, "IR"))$filename
    HRFile <- filter(dfDhsFiles, str_detect(relative_path, "HR"))$filename
    BRFile <- filter(dfDhsFiles, str_detect(relative_path, "BR"))$filename
    
    return(list(
      KR = file.path(root_folder, "KR", KRFile),
      PR = file.path(root_folder, "PR", PRFile),
      IR = file.path(root_folder, "IR", IRFile),
      HR = file.path(root_folder, "HR", HRFile),
      BR = file.path(root_folder, "BR", BRFile)
    ))
  }
  
  
  for (year in yearlist) {  # for文は ( ) を使います
    # dhsFilesはリスト型で、年ごとにKR, PR, IR, HRのファイルパスを格納
    dhsFiles[[year]] <- helper_getDHSfile(
      year, 
      helper_data_root(year, root_folder)
      )
  }
  return(dhsFiles)
}
