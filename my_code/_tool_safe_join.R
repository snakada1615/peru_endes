# ******************************************************************************
#' @title left_join_safe (改良版)
#' @description left_joinを実行する前に、結合キー以外の共通列で不一致がある場合に
#' 警告を表示し、キー列が一つもマッチしない場合は実行を停止する関数
#' 
#' 改良点：
#' (1) 結合キー以外に共通の列が存在する場合、右側の共通列を削除
#' (2) 残った列にはsuffix不要(.xは付かない)
#' (3) suffixのオプション指定も不要
#' (4) 右側の共通列を削除したことをwarningとして出力
#'
#' @param x データフレーム。左側のデータセット。
#' @param y データフレーム。右側のデータセット。
#' @param by 文字列ベクトル。結合キーとして使用する列名。デフォルトはNULL（共通列名を使用）。
#' @param ... その他のleft_joinに渡す引数。
#' @return left_joinの結果のデータフレーム。
# ******************************************************************************
# Example usage:
# df1 <- data.frame(ID = c(1, 2, 3), Value
# df2 <- data.frame(ID = c(2, 3, 4), Value = c("A", "B", "C"), Extra = c(10, 20, 30))
# result <- left_join_safe(df1, df2, by = "ID")
# print(result)
#    ID Value Extra
# 1  1  <NA>    NA
# 2  2     A    10
# 3  3     B    20
# Warning messages:
# 1: 結合キー以外の共通列を右側から削
# 除: Value
# 2: キー列のマッチ率が低いです: 66.7% (2/3)
# ******************************************************************************
left_join_safe <- function(x, y, by = NULL, ...) {
  
  # byがNULLの場合は共通列名をセット
  if (is.null(by)) {
    common_cols <- intersect(names(x), names(y))
    by <- common_cols
    by_x <- by_y <- common_cols
  } else if (is.character(by) && is.null(names(by))) {
    # 非namedの場合
    by_x <- by_y <- by
  } else if (is.character(by) && !is.null(names(by))) {
    # namedの場合（ex: by = c("A" = "B")）
    by_x <- names(by)
    by_y <- unname(by)
  } else {
    stop("by引数の形式が不正です。")
  }
  
  # ***** キー列の一致チェック *****
  if (length(by_x) == 1 && length(by_y) == 1) {
    x_keys <- x[[by_x[1]]]
    y_keys <- y[[by_y[1]]]
    common_keys <- intersect(x_keys, y_keys)
    
    if (length(common_keys) == 0) {
      stop(paste("キー列に共通する値がありません。結合を実行できません。",
                 paste0("\n左側データのキー列 '", by_x[1], "' の例: ",
                        paste(head(unique(x_keys), 3), collapse = ", ")),
                 paste0("\n右側データのキー列 '", by_y[1], "' の例: ",
                        paste(head(unique(y_keys), 3), collapse = ", ")),
                 "\nキー列の型やフォーマットを確認してください。"))
    }
    
    # マッチ率の情報を表示
    match_rate <- length(common_keys) / length(unique(x_keys))
    if (match_rate < 0.5) {
      warning(paste0("キー列のマッチ率が低いです: ",
                     round(match_rate * 100, 1), "% (",
                     length(common_keys), "/", length(unique(x_keys)), ")"))
    }
  } else if (length(by_x) > 1) {
    warning("複数キー列の場合はキー一致チェックをスキップします")
  }
  
  # ***** 結合キー以外の共通列を特定 *****
  cols_to_remove <- setdiff(intersect(names(x), names(y)), by_x)
  
  if (length(cols_to_remove) > 0) {
    # 右側の共通列を削除したことを警告
    warning(paste0("結合キー以外の共通列を右側から削除: ", 
                   paste(cols_to_remove, collapse = ", ")))
    
    # yから共通列（by_y除外）を削除
    y <- y[, !(names(y) %in% cols_to_remove), drop = FALSE]
  }
  
  # ***** left_joinを実行（suffixなし） *****
  result <- left_join(x, y, by = by, ...)
  
  return(result)
}
# --- 関数定義ここまで ------------------------------------------------
