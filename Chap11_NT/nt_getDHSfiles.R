
#path for R project
here()

# DHSルートフォルダを取得する関数
dataRoot <- function(year) {
  return(
    here("..", "..", year) %>%
      normalizePath() %>%
      trimws()
  ) 
}

# DHS年リスト
yearList <- c("2005", "2008", "2009", "2010", "2011", "2012")  # vector型でOK

dhsFiles <- list()

for (year in yearList) {  # for文は ( ) を使います
  root_folder <- dataRoot(year)
  
  dfDhsFiles <- getFilesByType(
    root_folder = root_folder,
    filetype = "dta"
  )
  
  KRFile <- filter(dfDhsFiles, str_detect(relative_path, "KR"))$filename
  PRFile <- filter(dfDhsFiles, str_detect(relative_path, "PR"))$filename
  IRFile <- filter(dfDhsFiles, str_detect(relative_path, "IR"))$filename
  HRFile <- filter(dfDhsFiles, str_detect(relative_path, "HR"))$filename
  
  # file.pathに"/KR"のように先頭スラッシュ不要
  dhsFiles[[year]] <- list(
    KR = file.path(root_folder, "KR", KRFile),
    PR = file.path(root_folder, "PR", PRFile),
    IR = file.path(root_folder, "IR", IRFile),
    HR = file.path(root_folder, "HR", HRFile)
  )
}
