
source("myTools.R")
# 指定したルートフォルダ以下に存在するすべてのDHSファイル名の取得（-> dhsFiles）
source("nt_getDHSfiles.R")
dhsFiles

years <- c("2005", "2008", "2009", "2010", "2011", "2012")
vars <- c("v463h","v463i", "v463l", "v463ab", "m74_1", "m76_1")

for (year in years){
  IRdatafile <- dhsFiles[[as.character(year)]]$IR
  temp <- read_dta(IRdatafile)
  print(year)
  check_vars(temp, vars)
}
