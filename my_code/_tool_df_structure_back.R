###############################################################################
# ----------------------------------------------------------------------------
#' @title variable_summary
#' @description
#' データフレームの各変数について、以下の情報をまとめた
#' データフレームを返す関数。
#' - variable: 変数名
#' - is_factor: factorかどうか
#' - num_factor_levels: factorの場合のレベル数（NA otherwise）
#' - is_binary: バイナリ変数かどうか（NA if not factor）
#' - is_logical: logical型かどうか
#' - is_character: character型かどうか
#' - is_numeric: numeric型かどうか
#' - factor_levels: factorの場合のレベル名を"_"で結合した文字列（NA otherwise）
#' - var_label_base: papeRの変数ラベル（NA if not present in papeR::labels(df)）
#' -------------------------------------------------------------------------- 
variable_summary <- function(df) {
  
  # バイナリ変数のyes/noレベルを判定するヘルパー関数------
  #' @title yesno_level
  #' @description
  #' バイナリ変数のレベル名から、Yes/Noのどちらに該当するかを判定する関数。
  #' @param v バイナリ変数のレベル名のベクトル（長さ2）
  #' @return yes_var: Yes側のレベル名、no_var: No側のレベル名を含むリスト
  #' 
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
# ----関数ここまで--------------------------------------------------
