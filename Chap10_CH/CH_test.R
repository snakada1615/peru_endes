
source("myTools.R")
# 指定したルートフォルダ以下に存在するすべてのDHSファイル名の取得（-> dhsFiles）
source("nt_getDHSfiles.R")
dhsFiles

years <- c("2005", "2008", "2009", "2010", "2011", "2012")

for (year in years){
  KRdatafile <- dhsFiles[[as.character(year)]]$KR
  temp <- read_dta(KRdatafile)
  vars =c("ml13i", "h54", "h55", "h56", "h57", "h58", "h59")
  check_vars(temp, vars)
}
