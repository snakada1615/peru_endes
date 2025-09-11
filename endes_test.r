
# endes年リスト
default_yearList <- c("2005", "2008", "2009", "2010", "2011", "2012")  # vector型でOK

# ******************************************************************************

# 複数年のendesファイルを取得してリストに格納する関数
get_endes_file <- function(yearlist, root_folder) {
  endesFiles <- list()
  
  # endesフォルダを取得する関数
  helper_data_root <- function(year, root_folder) {
    return(
      file.path(root_folder, year) %>%
        normalizePath() %>%
        trimws()
    ) 
  }
  # endesファイルを取得するヘルパー関数
  # 単年のendesファイルを取得する関数
  helper_getendesfile <- function(year, root_folder) {
    
    dfEndesFiles <- getFilesByType(
      root_folder = root_folder,
      filetype = "sav"
    )
    
    RECH4File <- filter(dfEndesFiles, str_detect(relative_path, "RECH4"))$filename
    RECH23File <- filter(dfEndesFiles, str_detect(relative_path, "RECH23"))$filename
    # IRFile <- filter(dfEndesFiles, str_detect(relative_path, "IR"))$filename
    # HRFile <- filter(dfEndesFiles, str_detect(relative_path, "HR"))$filename
    # BRFile <- filter(dfEndesFiles, str_detect(relative_path, "BR"))$filename
    
    return(list(
      RECH4File = file.path(root_folder, "RECH4", RECH4File),
      RECH23File = file.path(root_folder, "RECH23", RECH23File),
      # IR = file.path(root_folder, "IR", IRFile),
      # HR = file.path(root_folder, "HR", HRFile),
      # BR = file.path(root_folder, "BR", BRFile)
    ))
  }
  
  
  for (year in yearlist) {  # for文は ( ) を使います
    # endesFilesはリスト型で、年ごとにKR, PR, IR, HRのファイルパスを格納
    endesFiles[[year]] <- helper_getendesfile(
      year, 
      helper_data_root(year, root_folder)
      )
  }
  return(endesFiles)
}
