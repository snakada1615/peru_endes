library(labelled)
library(dplyr)
library(haven)
library(papeR)

# --------------------------------------------------------------------------
#' @title convert_lbl_to_paper
#' @description SPSSのデータラベルをpapeRのラベル形式に変換する関数。
#' @param df 変換するデータフレーム
#' @return SPSSのラベル属性が削除され、papeR形式に変換されたもの
#'------------------------------------------------------------------------ 
convert_lbl_to_paper <- function(df) {
  # 1. papeRラベル + ldf/lv クラス付与
  df <- papeR::as.ldf(df)
  
  # 2. SPSS/haven 由来の属性だけ削除（ldf クラスは触らない）
  for (nm in names(df)) {
    x <- df[[nm]]
    if (!is.factor(x)) {
      attr(x, "label")         <- NULL
      attr(x, "labels")        <- NULL
      attr(x, "format.spss")   <- NULL
      attr(x, "display_width") <- NULL
      # クラスから haven_labelled と vctrs_vctr を除去
      class(x) <- setdiff(class(x), c("haven_labelled", "vctrs_vctr"))
    }
    df[[nm]] <- x
  }
  
  return(df)  # クラスに "ldf" が残った data.frame
}
# ---関数終わり-------------------------------------------------------------

# ------------------------------------------------------------------------------
#' @title read_spss_and_paper
#' 
# ------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
#' @title mutate_papeR
#' @description
#' papeRのラベルを維持したまま、dplyr::mutateを行う関数。mutateの後で、
#' 共通の列についてpapeRのラベルを復元する。
#' @param .data データフレーム（papeRのラベルが付与されていることが前提）
#' @param ... dplyr::mutateに渡す引数
#' @return mutate後のデータフレーム（papeRのラベルが復元されている）
#' -----------------------------------------------------------------------------
mutate_papeR <- function(.data, ...) {
  # 事前にラベルを退避
  labs_before <- labels(.data)
  
  out <- dplyr::mutate(.data, ...)
  
  # 共通の列についてラベルを戻す
  common <- intersect(names(out), names(labs_before))
  if (length(common) > 0) {
    labels(out, which = common) <- labs_before[common]
  }
  out
}
# ----関数ここまで--------------------------------------------------------------

left_join_ldf <- function(df1, df2, by){
  # 1. papeRラベル + ldf/lv クラス付与
  ldf1 <- papeR::as.ldf(df1)
  ldf2 <- papeR::as.ldf(df2)
  
  # 2. left_join実行
  df_joined <- dplyr::left_join(df1, df2, by = by)
  
  # 3. ldfの統合
  lab_all <- c(ldf1, ldf2)
  # 万一、同じ名前のラベルが複数あれば、後勝ち or 前勝ちをルール化
  lab_all <- lab_all[!duplicated(names(lab_all), fromLast = TRUE)]
  
  # 4. 共通の列についてラベルを戻す 
  vars_in_both <- intersect(names(df_joined), names(lab_all))
  labels(df_joined, which = vars_in_both) <- unname(lab_all[vars_in_both])
  
  
  return(df_joined)  # クラスに "ldf" が残った data.frame
}
