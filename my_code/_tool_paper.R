library(haven)
library(labelled)
library(dplyr)
library(papeR)

read_spss_and_papeR <- function(path_sav) {
  # ここで:
  # 1. haven::read_sav(path_sav)
  # 2. labelsdf を作成
  # 3. df 内を factor / numeric / character に整理
  # 4. list(df = df, meta = labelsdf) を返す
}
