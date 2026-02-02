library(dplyr)
library(labelled)  # またはhaven
library(rlang)

#' 関数一覧
#' ============================================
#' 1. save_all_labels(data): データフレーム内のすべ
#' ての変数のラベル属性をリストとして保存
#' 2. restore_all_labels(data, labels): データフレーム
#' 内のすべての変数のラベル属性をリストから復
#' 元
#' 3. save_labels(data, columns = NULL): データフレーム
#' 内の指定した変数のラベル属性をリストとして保存
#' 4. restore_labels(data, labels, columns = NULL): デー
#' タフレーム内の指定した変数のラベル属性をリスト
#' から復元
#' 5. pipe_with_labels(data): パイプ処理に組み込
#' める簡潔版ラベルバックアップ
#' 6. with_labels(data): ラベルバックアップ付きデー
#' タフレーム作成
#' 7. restore_from_backup(data): ラベルバックアップか
#' ら復元
#' 8. with_labels_and_clean(data): ラベルバックアップ
#' 付きクリーンデータフレーム作成
#' 9. save_labels_to_memory(data): ラベル情報を保存
#' 10. merge_labels_memory(...): 複数のラベル情報を
#' 一つにまとめる
#' 11. remove_labels(data): ラベル属性を削除
#' 12. restore_labels(data, labels_memory): ラベルを復元
#' 
#' ============================================


#' ************************************************************************
#' @title 全てのラベルをリストとして保存
#' @description データフレーム内のすべての変数のラベル属性をリストとして保存します。
#' @param data データフレーム
#' @return 変数名をキー、ラベル属性を値とするリスト
#' @examples
#' labels <- save_all_labels(df)
#' ************************************************************************
save_all_labels <- function(data) {
  labels <- list()
  for (col in names(data)) {
    labels[[col]] <- attr(data[[col]], "label", exact = TRUE)
  }
  return(labels)
}
#' ----------関数ここまで------------------------------------------------


# 保存されたラベルをすべて復元
#' ************************************************************************
#' @title 全て復元
#' @description データフレーム内のすべての変数のラ
#' ベル属性をリストから復元します。
#' @param data データフレーム
#' @param labels 変数名をキー、ラベル属性を値とする
#' リスト
#' @return ラベル属性が復元されたデータフレーム
#' @examples
#' df <- restore_all_labels(df, labels)
#' ************************************************************************
restore_all_labels <- function(data, labels) {
  for (col in names(data)) {
    if (!is.null(labels[[col]])) {
      attr(data[[col]], "label") <- labels[[col]]
    }
  }
  return(data)
}
#' ----------関数ここまで------------------------------------------------

#' ************************************************************************
#' @title 指定列のみ保存
#' @description データフレーム内の指定した変数のラベル属性
#' をリストとして保存します。
#' @param data データフレーム
#' @param columns ラベルを保存する列名のベクトル。NULLの場合
#' はすべての列を対象とします。
#' @return 変数名をキー、ラベル属性を値とするリ
#' スト
#' @examples
#' labels <- save_labels(df, columns = c("var1", "var2"))
#' ************************************************************************
save_labels <- function(data, columns = NULL) {
  if (is.null(columns)) {
    columns <- names(data)
  }

  labels <- list()
  for (col in columns) {
    if (col %in% names(data)) {
      labels[[col]] <- attr(data[[col]], "label", exact = TRUE)
    }
  }
  return(labels)
}
#' ----------関数ここまで------------------------------------------------

#' ************************************************************************
#' @title 指定した列のラベルのみを復元
#' @description データフレーム内の指定した変数のラベル属性
#' をリストから復元します。
#' @param data データフレーム
#' @param labels 変数名をキー、ラベル属性を値とする
#' リスト
#' @param columns ラベルを復元する列名のベクトル。NULL
#' の場合はすべての列を対象とします。
#' @return ラベル属性が復元されたデータフレーム
#' @examples
#' df <- restore_labels(df, labels, columns = c("var1", "var
#' 2"))
#' ************************************************************************
restore_labels <- function(data, labels, columns = NULL) {
  if (is.null(columns)) {
    columns <- names(labels)
  }

  for (col in columns) {
    if (!is.null(labels[[col]]) && col %in% names(data)) {
      attr(data[[col]], "label") <- labels[[col]]
    }
  }
  return(data)
}
#' ----------関数ここまで------------------------------------------------

#' ************************************************************************
#' @title パイプ処理に組み込める簡潔版ラベルバックアップ
#' @description データフレームのラベル属性をバックアップし、
#' パイプ処理内で復元できるようにします。
#' @param data データフレーム
#' @return ラベルバックアップと復元関数を含むリスト
#' @examples
#' df_backup <- pipe_with_labels(df)
#' df_processed <- df_backup$data %>%
#'  mutate(new_var = existing_var * 2)
#' df_final <- df_backup$restore(df_processed)
#' ***********************************************************************
pipe_with_labels <- function(data) {
  return(structure(
    list(
      data = data,
      labels = save_all_labels(data),
      restore = function(result, columns = NULL) {
        if (is.null(columns)) {
          columns <- intersect(names(data), names(result))
        }
        restore_labels(result, structure(list(data = data, labels = save_all_labels(data)), class = "label_backup")$labels, columns)
      }
    ),
    class = "label_backup"
  ))
}
#' ----------関数ここまで------------------------------------------------

# より実用的な実装版
#' ************************************************************************
#' @title ラベルバックアップ付きデータフレーム作成
#' @description データフレームにラベルバックアップを
#' 属性として付加します。
#' @param data データフレーム
#' @return ラベルバックアップ属性を持つデータフレーム
#' @examples
#' df_with_backup <- with_labels(df)
#' df_processed <- df_with_backup %>%
#'  mutate(new_var = existing_var * 2)
#'  df_final <- restore_from_backup(df_processed)
#'  ***********************************************************************
with_labels <- function(data) {
  attr(data, ".labels_backup") <- save_all_labels(data)
  return(data)
}
#' ----------関数ここまで------------------------------------------------

#' ************************************************************************
#' @title ラベルバックアップから復元
#' @description ラベルバックアップ属性からラベルを
#' 復元します。
#' @param data データフレーム
#' @return ラベルが復元されたデータフレーム
#' @examples
#' df_final <- restore_from_backup(df_processed)
#' ***********************************************************************
# # 使用例:
# # ラベルバックアップを付加
# df_with_backup <- with_labels(df)
# 
# # 処理を実施
# df_processed <- df_with_backup %>%
#   mutate(across(everything(), ~{
#     attr(., "label") <- NULL
#     attr(., "labels") <- NULL
#     class(.) <- setdiff(class(.), c("labelled", "haven_labelled"))
#     .
#   })) %>%
#   mutate(
#     age_group = cut(age, breaks = c(0, 30, 100)),
#     log_income = log(income)
#   ) %>%
#   select(-id)
# 
# # ラベルを復元
# df_final <- restore_from_backup(df_processed)
#' ************************************************************************
restore_from_backup <- function(data) {
  labels <- attr(data, ".labels_backup", exact = TRUE)
  if (!is.null(labels)) {
    data <- restore_all_labels(data, labels)
    attr(data, ".labels_backup") <- NULL
  }
  return(data)
}

#' ----------関数ここまで------------------------------------------------

# ラベルをバックアップしながらラベル属性を削除
#' ************************************************************************
#' @title ラベルバックアップ付きクリーンデータフレーム作成
#' @description データフレームのラベル属性をバックアップし、
#' ラベル属性を削除したデータフレームを返します。
#' @param data データフレーム
#' @return ラベル属性が削除されたデータフレーム
#' @examples
#' df_clean <- with_labels_and_clean(df)
#' ***********************************************************************
# # 使用例:
# # Step 1: バックアップを埋め込む
# df_backup <- with_labels(df)
# 
# # Step 2: ラベル属性を削除して通常の処理をする
# df_result <- df_backup %>%
#   mutate(across(everything(), ~{
#     attr(., "label") <- NULL
#     class(.) <- setdiff(class(.), "labelled")
#     .
#   })) %>%
#   mutate(新変数 = 既存変数 + 別の変数) %>%
#   filter(条件)
# 
# # Step 3: ラベルを復元
# df_final <- restore_from_backup(df_result)
#' ************************************************************************
with_labels_and_clean <- function(data) {
  # ステップ1: ラベル情報をバックアップ
  attr(data, ".labels_backup") <- save_all_labels(data)

  # ステップ2: ラベル属性を削除
  data <- data %>%
    mutate(across(everything(), ~ {
      attr(., "label") <- NULL
      attr(., "labels") <- NULL
      class(.) <- setdiff(class(.), c("labelled", "haven_labelled"))
      .
    }))

  return(data)
}
#' ----------関数ここまで------------------------------------------------

library(haven)
library(labelled)
library(dplyr)
# ============================================
# ステップ1: ラベル情報を変数に保存
# ============================================

#' ************************************************************************
#' @title ラベル情報を保存
#' @description データフレーム内のすべての変数の
#' ラベル情報を保存します。
#' @param data データフレーム
#' @return 変数ラベルと値ラベルを含むリスト
#' @examples
#' labels_memory <- save_labels_to_memory(df)
#' ************************************************************************
save_labels_to_memory <- function(data) {
  
  # 変数ラベルを保存
  var_labels <- labelled::var_label(data)
  
  # 値ラベルを保存（各変数のattr "labels"を抽出）
  val_labels <- lapply(data, function(x) attr(x, "labels"))
  
  # リストとして返す
  list(
    var_labels = var_labels,
    val_labels = val_labels
  )
}

#' ----------関数ここまで------------------------------------------------
# ============================================
# ステップ1-2: 複数のラベル情報を一つにまとめる
# ============================================
# 複数のlabels_memoryを結合
merge_labels_memory <- function(...) {
  labs_list <- list(...)
  
  # 空チェック
  labs_list <- labs_list[!vapply(labs_list, is.null, logical(1))]
  if (length(labs_list) == 0) {
    return(list(var_labels = NULL, val_labels = NULL))
  }
  
  # var_labelsのマージ（後勝ち）
  merged_var <- do.call(c, lapply(labs_list, function(x) x$var_labels))
  merged_var <- merged_var[!duplicated(names(merged_var), fromLast = TRUE)]
  
  # val_labelsのマージ（後勝ち）
  merged_val <- do.call(c, lapply(labs_list, function(x) x$val_labels))
  merged_val <- merged_val[!duplicated(names(merged_val), fromLast = TRUE)]
  
  list(
    var_labels = merged_var,
    val_labels = merged_val
  )
}
#' ----------関数ここまで------------------------------------------------
# ============================================
# ステップ2: データフレームからラベル属性を除去
# ============================================
#' ************************************************************************
#' @title ラベル属性を削除
#' @description データフレーム内のすべての変数の
#' ラベル属性を削除します。
#' @param data データフレーム
#' @return ラベル属性が削除されたデータフレーム
#' @examples
#' df_clean <- remove_labels(df)
#' ************************************************************************
remove_labels <- function(data) {
  # すべてのラベル属性を削除
  data[] <- lapply(data, function(x) {
    # haven 関連のラベル属性を削除
    attr(x, "label") <- NULL
    attr(x, "labels") <- NULL

    # SPSS フォーマット属性を削除
    attr(x, "format.spss") <- NULL
    attr(x, "display_width") <- NULL

    # haven_labelled, labelled, vctrs_vctr クラスを削除
    attr(x, "class") <- setdiff(
      attr(x, "class"),
      c("haven_labelled", "labelled", "vctrs_vctr")
    )
    x
  })

  return(data)
}
#' ----------関数ここまで------------------------------------------------

# ============================================
# ステップ3: 保存したラベルを復元
# ============================================
#' ************************************************************************
#' @title ラベルを復元
#' @description 保存したラベル情報をデータフレームに復元します
#' @param data データフレーム
#' @param labels_memory 変数ラベルと値ラベルを含むリ
#' スト
#' @return ラベルが復元されたデータフレーム
#' @examples
#' df_restored <- restore_labels(df, labels_memory)
#' ************************************************************************
restore_labels <- function(data, labels_memory) {
  # labels_memoryの構造確認
  if (!("var_labels" %in% names(labels_memory) &
    "val_labels" %in% names(labels_memory))) {
    stop("labels_memory must contain 'var_labels' and 'val_labels'")
  }

  var_labels <- labels_memory$var_labels
  val_labels <- labels_memory$val_labels

  # ============================================
  # 変数ラベルの復元
  # ============================================
  for (var in names(var_labels)) {
    if (var %in% names(data)) {
      attr(data[[var]], "label") <- var_labels[[var]]
    }
  }

  # ============================================
  # 値ラベルの復元
  # ============================================
  for (var in names(val_labels)) {
    if (var %in% names(data) && !is.null(val_labels[[var]])) {
      # 既存の値ラベル（名前付きベクトル）を取得
      labels_to_set <- val_labels[[var]]

      # attr "labels" を設定
      attr(data[[var]], "labels") <- labels_to_set

      # haven_labelledクラスを付与
      if (!"labelled" %in% class(data[[var]])) {
        class(data[[var]]) <- c("haven_labelled", "labelled", class(data[[var]]))
      }
    }
  }

  return(data)
}
#' ----------関数ここまで------------------------------------------------

