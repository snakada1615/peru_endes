# 部分的名前付きベクトルを完全名前付きベクトルに変換する補助関数
normalize_by_vector <- function(by, x_names, y_names) {
  # by引数がNULLまたは非namedの場合はそのまま返す
  if (is.null(by)) {
    return(NULL)
  }
  
  if (is.character(by) && is.null(names(by))) {
    # 非namedの場合（変換不要）
    return(by)
  }
  
  if (!is.character(by)) {
    return(by)
  }
  
  # namedベクトルの場合
  names_by <- names(by)
  
  # すべて名前が付いている場合（変換不要）
  if (!any(names_by == "" | is.na(names_by))) {
    return(by)
  }
  
  # 部分的に名前付きの場合 → 完全名前付きに変換
  warning("by引数に名前なしの要素が含まれています。完全名前付きベクトルに自動変換します。",
          "\n変換前: ", paste(
            ifelse(names_by == "" | is.na(names_by), 
                   paste0("\"", by, "\""), 
                   paste0(names_by, " = \"", by, "\"")),
            collapse = ", "))
  
  # 名前なしの要素に対して、by自身の値を名前として割り当てる
  # 例: c("a", b = "b_col") → c(a = "a", b = "b_col")
  new_names <- ifelse(names_by == "" | is.na(names_by), 
                      by, 
                      names_by)
  
  # 新しい完全名前付きベクトルを作成
  result <- by
  names(result) <- new_names
  
  warning("変換後: ", paste(
    paste0(names(result), " = \"", result, "\""),
    collapse = ", "))
  
  return(result)
}


left_join_safe <- function(x, y, by = NULL, suffix = c(".x", ".y"), ...) {
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
    # ここで部分的名前付きベクトルを完全名前付きに変換
    by <- normalize_by_vector(by, names(x), names(y))
    
    # 変換後は必ず完全名前付きになっているので処理
    names_by <- names(by)
    if (!any(names_by == "" | is.na(names_by))) {
      # 完全名前付き
      by_x <- names(by)
      by_y <- unname(by)
    } else {
      stop("by引数の形式が不正です。")
    }
  } else {
    stop("by引数の形式が不正です。")
  }
  
  # ***** キー列の一致チェックを追加 *****
  # キー列の値を取得
  if (length(by_x) == 1 && length(by_y) == 1) {
    x_keys <- x[[by_x[1]]]
    y_keys <- y[[by_y[1]]]
    
    # 共通するキー値をチェック
    common_keys <- intersect(x_keys, y_keys)
    
    if (length(common_keys) == 0) {
      stop(paste("キー列に共通する値がありません。結合を実行できません。",
                 paste0("\n左側データのキー列 '", by_x[1], "' の例: ", 
                        paste(head(unique(x_keys), 3), collapse = ", ")),
                 paste0("\n右側データのキー列 '", by_y[1], "' の例: ", 
                        paste(head(unique(y_keys), 3), collapse = ", ")),
                 "\nキー列の型やフォーマットを確認してください。"))
    }
    
    # マッチ率の情報を表示（オプション）
    match_rate <- length(common_keys) / length(unique(x_keys))
    if (match_rate < 0.5) {
      warning(paste0("キー列のマッチ率が低いです: ", 
                     round(match_rate * 100, 1), "% (", 
                     length(common_keys), "/", length(unique(x_keys)), ")"))
    }
  } else if (length(by_x) > 1) {
    # 複数キー列の場合の処理
    message("複数キー列の場合はキー一致チェックをスキップします")
  }
  # ***** キー列の一致チェック終了 *****
  
  # チェックのための共通列名取得
  # named vectorの場合は、左右で異なるキー名を許すため特別な処理
  # 2つのデータフレーム中の"by"で指定された列同士を対応させる
  common_cols_x <- intersect(names(x), names(y))
  if (is.null(by) || (is.character(by) && is.null(names(by)))) {
    cols_to_check <- setdiff(common_cols_x, by_x)
  } else {
    cols_to_check <- intersect(setdiff(names(x), by_x), setdiff(names(y), by_y))
  }
  
  if (length(cols_to_check) > 0) {
    warning("結合キー以外の共通列名があります: ", paste(cols_to_check, collapse = ", "))
    
    # inner_joinもbyそのまま渡して大丈夫
    temp_join <- inner_join(x, y, by = by, suffix = suffix)
    
    for (col in cols_to_check) {
      col_x <- paste0(col, suffix[1])
      col_y <- paste0(col, suffix[2])
      
      if (all(c(col_x, col_y) %in% names(temp_join))) {
        differences <- sum(temp_join[[col_x]] != temp_join[[col_y]], na.rm = TRUE)
        if (differences > 0) {
          warning(paste("列", col, "で", differences, "行の不一致があります"))
        }
      }
    }
  }
  
  # 通常のleft_joinを実行
  result <- left_join(x, y, by = by, suffix = suffix, ...)
  
  return(result)
}

right_join_safe <- function(x, y, by = NULL, suffix = c(".x", ".y"), ...) {
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
    # ここで部分的名前付きベクトルを完全名前付きに変換
    by <- normalize_by_vector(by, names(x), names(y))
    
    # 変換後は必ず完全名前付きになっているので処理
    names_by <- names(by)
    if (!any(names_by == "" | is.na(names_by))) {
      # 完全名前付き
      by_x <- names(by)
      by_y <- unname(by)
    } else {
      stop("by引数の形式が不正です。")
    }
  } else {
    stop("by引数の形式が不正です。")
  }
  
  # ***** キー列の一致チェックを追加 *****
  # キー列の値を取得
  if (length(by_x) == 1 && length(by_y) == 1) {
    x_keys <- x[[by_x[1]]]
    y_keys <- y[[by_y[1]]]
    
    # 共通するキー値をチェック
    common_keys <- intersect(x_keys, y_keys)
    
    if (length(common_keys) == 0) {
      stop(paste("キー列に共通する値がありません。結合を実行できません。",
                 paste0("\n左側データのキー列 '", by_x[1], "' の例: ", 
                        paste(head(unique(x_keys), 3), collapse = ", ")),
                 paste0("\n右側データのキー列 '", by_y[1], "' の例: ", 
                        paste(head(unique(y_keys), 3), collapse = ", ")),
                 "\nキー列の型やフォーマットを確認してください。"))
    }
    
    # マッチ率の情報を表示（オプション）
    match_rate <- length(common_keys

) / length(unique(y_keys))
    if (match_rate < 0.5) {
      warning(paste0("キー列のマッチ率が低いです: ",
                     round(match_rate * 100, 1), "% (", 
                     length(common_keys), "/", length(unique(y_keys)), ")"))
    }
  } else if (length(by_x) > 1) {
    # 複数キー列の場合の処理
    message("複数キー列の場合はキー一致チェックをスキップします")
  }
  # ***** キー列の一致チェック終了 *****
  # チェックのための共通列名取得
  # named vectorの場合は、左右で異なるキー名を許すため特別
  # 2つのデータフレーム中の"by"で指定された列同士を対応させる
  common_cols_x <- intersect(names(x), names(y))
  if (is.null(by) || (is.character(by) && is.null(names(by))))
  {
    cols_to_check <- setdiff(common_cols_x, by_x)
  } else {
    cols_to_check <- intersect(setdiff(names(x), by_x), setdiff(names(y), by_y))
  }
  if (length(cols_to_check) > 0) {
    warning("結合キー以外の共通列名があります: ", paste(cols_to_check, collapse = ", "))
    
    # inner_joinもbyそのまま渡して大丈夫
    temp_join <- inner_join(x, y, by = by, suffix = suffix)
    
    for (col in cols_to_check) {
      col_x <- paste0(col, suffix[1])
      col_y <- paste0(col, suffix[2])
      
      if (all(c(col_x, col_y) %in% names(temp_join))) {
        differences <- sum(temp_join[[col_x]] != temp_join[[col_y]], na.rm = TRUE)
        if (differences > 0) {
          warning(paste("列", col, "で", differences, "行の不一致があります"))
        }
      }
    }
  }
  # 通常のright_joinを実行
  result <- right_join(x, y, by = by, suffix = suffix, ...)
  return(result)
}


inner_join_safe <- function(x, y, by = NULL, suffix = c(".x", ".y"), ...) {
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
    # ここで部分的名前付きベクトルを完全名前付きに変換
    by <- normalize_by_vector(by, names(x), names(y))
    
    # 変換後は必ず完全名前付きになっているので処理
    names_by <- names(by)
    if (!any(names_by == "" | is.na(names_by))) {
      # 完全名前付き
      by_x <- names(by)
      by_y <- unname(by)
    } else {
      stop("by引数の形式が不正です。")
    }
  } else {
    stop("by引数の形式が不正です。")
  }
  # ***** キー列の一致チェックを追加 *****
  # キー列の値を取得
  if (length(by_x) == 1 && length(by_y) == 1)
  {
    x_keys <- x[[by_x[1]]]
    y_keys <- y[[by_y[1]]]
    
    # 共通するキー値をチェック
    common_keys <- intersect(x_keys, y_keys)
    
    if (length(common_keys) == 0) {
      stop(paste("キー列に共通する値がありません。結合を実行できません。",
                 paste0("\n左側データのキー列 '", by_x[1], "' の例: ", 
                        paste(head(unique(x_keys), 3), collapse = ", ")),
                 paste0("\n右側データのキー列 '", by_y[1], "' の例: ", 
                        paste(head(unique(y_keys), 3), collapse = ", ")),
                 "\nキー列の型やフォーマットを確認してください。"))
    }
    
    # マッチ率の情報を表示（オプション）
    match_rate <- length(common_keys) / min(length(unique(x_keys)), length(unique(y_keys)))
    if (match_rate < 0.5) {
      warning(paste0("キー列のマッチ率が低いです: ",
                     round(match_rate * 100, 1), "% (", 
                     length(common_keys), "/", 
                     min(length(unique(x_keys)), length(unique(y_keys))), ")"))
    }
  } else if (length(by_x) > 1) {
    # 複数キー列の場合の処理
    message("複数キー列の場合はキー一致チェックをスキップします")
  }
  # ***** キー列の一致チェック終了 *****
  # チェックのための共通列名取得
  # named vectorの場合は、左右で異なるキー名を許すため特別
  # 2つのデータフレーム中の"by"で指定された
  common_cols_x <- intersect(names(x), names(y))
  if (is.null(by) || (is.character(by) && is.null(names(by))))
  {
    cols_to_check <- setdiff(common_cols_x, by_x)
  } else {
    cols_to_check <- intersect(setdiff(names(x), by_x), setdiff(names(y),
                                                     by_y))
  }
  if (length(cols_to_check) > 0) {
    warning("結合キー以外の共通列名があります: ", paste(cols_to_check, collapse = ", "))
    # inner_joinもbyそのまま渡して大丈夫
    temp_join <- inner_join(x, y, by = by, suffix = suffix)
    
    for (col in cols_to_check) {
      col_x <- paste0(col, suffix[1])
      col_y <- paste0(col, suffix[2])
      
      if (all(c(col_x, col_y) %in% names(temp_join))) {
        differences <- sum(temp_join[[col_x]] != temp_join[[col_y]], na.rm = TRUE)
        if (differences > 0) {
          warning(paste("列", col, "で", differences, "行の不一致があります"))
        }
      }
    }
  }
  # 通常のinner_joinを実行
  result <- inner_join(x, y, by = by, suffix = suffix, ...)
  return(result)
}


full_join_safe <- function(x, y, by = NULL, suffix = c(".x", ".y"), ...) {
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
    # ここで部分的名前付きベクトルを完全名前付きに変換
    by <- normalize_by_vector(by, names(x), names(y))
    
    # 変換後は必ず完全名前付きになっているので処理
    names_by <- names(by)
    if (!any(names_by == "" | is.na(names_by))) {
      # 完全名前付き
      by_x <- names(by)
      by_y <- unname(by)
    } else {
      stop("by引数の形式が不正です。")
    }
  } else {
    stop("by引数の形式が不正です。")
  }
  
  # チェックのための共通列名取得
  # named vectorの場合は、左右で異なるキー名を許すため特別な処理
  # 2つのデータフレーム中の"by"で指定された列同士を対応させる
  common_cols_x <- intersect(names(x), names(y))
  if (is.null(by) || (is.character(by) && is.null(names(by)))) {
    cols_to_check <- setdiff(common_cols_x, by_x)
  } else {
    cols_to_check <- intersect(setdiff(names(x), by_x), setdiff(names(y), by_y))
  }
  
  if (length(cols_to_check) > 0) {
    warning("結合キー以外の共通列名があります: ", paste(cols_to_check, collapse = ", "))
    
    # inner_joinもbyそのまま渡して大丈夫
    temp_join <- inner_join(x, y, by = by, suffix = suffix)
    
    for (col in cols_to_check) {
      col_x <- paste0(col, suffix[1])
      col_y <- paste0(col, suffix[2])
      
      if (all(c(col_x, col_y) %in% names(temp_join))) {
        differences <- sum(temp_join[[col_x]] != temp_join[[col_y]], na.rm = TRUE)
        if (differences > 0) {
          warning(paste("列", col, "で", differences, "行の不一致があります"))
        }
      }
    }
  }
  # 通常のfull_joinを実行
  result <- full_join(x, y, by = by, suffix = suffix, ...)
  return(result)
}


 
    