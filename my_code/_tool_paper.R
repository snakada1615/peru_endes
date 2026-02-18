library(labelled)
library(dplyr)
library(haven)
library(papeR)

# --------------------------------------------------------------------------
#' @title convert_lbl_to_paper
#' @description
#' SPSSやStataのファイルを読み込むと、havenのlabelledクラスの変数ができることがあります。
#' これらの変数は、papeRのラベル形式とは異なるため、papeRで扱いやすい形式に変換する必要があります。
#' この関数は、havenのlabelledクラスの変数をpape
#' Rのラベル形式に変換するための関数です。
#' @param 
#' df havenのread_savやread_dtaで読み込んだデータフレーム
#' @return list(df = 変換後のデータフレーム, meta = 変数ラベルの一覧)
#'------------------------------------------------------------------------ 
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
# ---関数終わり-------------------------------------------------------------

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

# ----------------------------------------------------------------------------
#' @title variable_summary
#' @description
#' データフレームの各変数について、以下の情報をまとめた
#' データフレームを返す関数。
#' - variable: 変数名
#' - is_factor: factorかどうか
#' - num_factor_levels: factorの場合のレベル数（NA otherwise）
#' - is_binary: バイナリ変数かどうか（NA if not
#' factor）
#' - is_logical: logical型かどうか
#' - is_character: character型かどうか
#' - is_numeric: numeric型かどうか
#' - factor_levels: factorの場合のレベル名を"_"で結合した
#' 文字列（NA otherwise）
#' - var_label_base: papeRの変数ラベル（NA if not present
#' in papeR::labels(df)）
#' -------------------------------------------------------------------------- 
variable_summary <- function(df) {
  # バイナリ変数のyes/noレベルを判定するヘルパー関数------
  yesno_level <- function(v){
    # Yes/No 変数のレベル名の候補を定義
    yes_vars <- c("Yes", "yes", "Sí", "si")  # Yes 側のレベル名の候補
    no_vars <- c("No", "no")  # No 側のレベル名の候補
    
    res <- list(
      yes_var = NA_character_,
      no_var = NA_character_
    )
    
    if (!is.vector(v) | length(v) != 2) {
      stop("Input must be a vector of length 2.")
    }
    
    for (x in v) {
      if (x %in% yes_vars) {
        res$yes_var <- x
      } else if (x %in% no_vars) {
        res$no_var <- x
      }
    }
    return(res)
  }
  #------------------------------------
  
  
  # papeRのラベル形式に変換
  if (!papeR::is.ldf(df)) {
    df <- papeR::as.ldf(df)
  }
  
  var_labs <- labels(df)
  
  var_summary <- lapply(names(df), function(x) {
    v <- df[[x]]
    
    res <- list(
      variable          = as.character(x),
      new_variable_name = as.character(x),  # フォールバック: 変数名をそのまま使用
      is_factor         = is.factor(v),
      num_factor_levels = if (is.factor(v)) length(na.omit(unique(v))) else NA_integer_,
      is_binary         = length(na.omit(unique(v))) == 2,
      is_logical        = is.logical(v),
      is_character      = is.character(v),
      is_numeric        = is.numeric(v),
      factor_levels     = if (is.factor(v)) paste(levels(v), collapse = "_") else NA_character_,
      var_label_base    = var_labs[[x]] %||% x,
      yes_value        = if (is.factor(v) && length(na.omit(unique(v))) == 2) 
        yesno_level(levels(v))$yes_var else NA_character_,
      no_value         = if (is.factor(v) && length(na.omit(unique(v))) == 2)
        yesno_level(levels(v))$no_var else NA_character_
    )
    res
  })
  
  var_summary <- do.call(rbind, lapply(var_summary, as.data.frame, 
                                       stringsAsFactors = FALSE))
  row.names(var_summary) <- NULL
  
  return(var_summary)
}

