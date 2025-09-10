
source("myTools.R")
# 指定したルートフォルダ以下に存在するすべてのDHSファイル名の取得（-> dhsFiles）
source("nt_getDHSfiles.R")
dhsFiles

years <- c("2005", "2008", "2009", "2010", "2011", "2012")

for (year in years){
  HRdatafile <- dhsFiles[[as.character(year)]]$HR
  temp <- read_dta(HRdatafile)
  vars =c("hv252")
  check_vars(temp, vars)
}
