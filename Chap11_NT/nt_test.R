# myFile <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2012/PEKR6IDT/PEKR6IFL.DTA"
# temp <- read_dta(myFile)
# 
# vars = c("v412c", "v414v", "v414w", "m39a")

source("myTools.R")

myFile2005 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2005/PEKR51DT/PEKR51FL.DTA"
myFile2008 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2008/PEKR5ADT/PEKR51FL.DTA"
myFile2009 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2009/PEKR5IDT/PEKR5IFL.DTA"
myFile2010 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2010/PEKR61DT/PEKR61FL.DTA"
myFile2011 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2011/PEKR6ADT/PEKR6AFL.DTA"
myFile2012 <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/2012/PEKR6IDT/PEKR6IFL.DTA"
myFiles = c(myFile2005, myFile2008, myFile2009, myFile2010, myFile2011, myFile2012)
vars1 = c("v469e", "v469f", "v469x", "v414p", "m4", "v411", "v411a", "v412")
vars2 = c("v412c", "v414v", "v414w", "m39a")

for (myFile in myFiles) {
  temp <- read_dta(myFile)
  print(str_extract(myFile, "\\d{4}"))
  print("=== milk ===")
  check_vars(temp, vars1)
  print("=== solidfood ===")
  check_vars(temp, vars2)
}
