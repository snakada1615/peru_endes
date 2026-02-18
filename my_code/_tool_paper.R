library(labelled)
library(dplyr)
library(haven)
library(papeR)

convert_lbl_to_paper <- function(df) {
  # 2. 変数ラベル（variable.label属性）を取り出す
  #    havenのlabelledは、attr(x, "label") に変数ラベルを持っているので、
  #    それをpapeR::labels() に渡す形に整える。
  var_labs <- sapply(df, function(x) attr(x, "label"))
  var_labs[sapply(var_labs, is.null)] <- NA_character_
  
  labelsdf <- data.frame(
    variable = names(var_labs),
    varlabel = as.character(var_labs),
    stringsAsFactors = FALSE
  )
  
  # 3. dfをdata.frameに変換しつつ、
  #    factor以外の列からは haven由来のラベル属性を削除
  df <- as.data.frame(df)
  
  df <- lapply(df, function(x) {
    if (!is.factor(x)) {
      attr(x, "label")        <- NULL
      attr(x, "labels")       <- NULL
      attr(x, "format.spss")  <- NULL
      attr(x, "display_width")<- NULL
      if ("labelled" %in% class(x)) {
        class(x) <- setdiff(class(x), "labelled")
      }
    }
    x
  }) |> as.data.frame()
  
  # 4. papeRの変数ラベルだけを付与
  papeR::labels(df) <- labelsdf$varlabel
  
  return(list(
    df   = df,       # factorはそのまま、その他はラベル属性除去済み
    meta = labelsdf  # 変数ラベルの一覧（papeR用）
  ))
}

read_spss_and_papeR <- function(path_sav) {
  # 1. SPSS読み込み（haven）
  if (endsWith(path_sav, ".sav")) {
    df_raw <- haven::read_sav(path_sav)
  } else if (endsWith(path_sav, ".dta")) {
    df_raw <- haven::read_dta(path_sav)
  } else if (endsWith(path_sav, ".rds")) {
    df_raw <- readRDS(path_sav)
  } else {
    stop("Unsupported file format. Please provide a .sav, .dta, or .csv file.")
  }

  
  res <- convert_lbl_to_paper(df_raw)
  return(res)

  }

