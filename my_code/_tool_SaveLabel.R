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

# *************************************************************************
#' ラベル一覧のリスト構造の例 
# *************************************************************************
#' labels_set <- list(
#' # まず変数ラベルは各変数を名前付きリストにする
#'  var_labels = list(
#'    sex = "sex of participant",
#'    edu = "education record"
#'    ),
#'    
#'  # 値ラベルは各変数ごとに名前付きベクトルを作成
#'  val_labels = list(
#'    sex = c(
#'      male = "M",
#'      female = "F"
#'      ) # edu は値ラベルなしなので入れない
#'    )
#'  )
#'  ************************************************************************* 
#'  以下、実際に作成する手順
#'  用意するもの
#'  ①変数名ベクトル、②変数ラベルベクトル、
#'  ③各変数ごとの値べクトル、④各変数ごとの値ラベルベクトル
#'  *************************************************************************  
# ## 変数ラベル（名前付きベクトル）
# var_names  <- c("sex", "edu")
# var_labs   <- c("sex of participant", "education record")
# var_label  <- setNames(var_labs, var_names)
# # names(var_label)  = c("sex","edu")
# # unname(var_label) = c("sex of participant","education record")
# 
# ## 値ラベル（各変数ごとの名前付きベクトル）
# sex_vals   <- c("M", "F")
# sex_labs   <- c("male", "female")
# sex_label  <- setNames(sex_vals, sex_labs)
# # c(male = "M", female = "F")
# 
# val_label  <- list(
#   sex = sex_label
#   # edu は値ラベルなしなので入れない
# )
# 
# ## save_labels_to_memory(df) と同じ構造にまとめる
# labels_memory_manual <- list(
#   var_labels = var_label,
#   val_labels = val_label
# )
#' *************************************************************************
#' ラベル情報を手動で作成する関数例
#' @title create_labels_memory_manual
#' @description 変数名、変数ラベル、値ラベルを手動で指定してラベル情報を作成します。
#' @param list_name リスト名（例: "labels_memory_manual"）
#' @param var_names 変数名ベクトル
#' @param var_labs 変数ラベルベクトル
#' @return ラベル情報を含むリスト
#' @examples
#' labels_memory_manual <- create_labels_memory_manual(
#'  list_name = "labels_memory_manual",  
#'  var_names = c(
#'   "sex", "edu"
#'   ),
#'  var_labs =c(
#'   "sex of participant", "education record"
#'    ))
#'  ***********************************************************************
# create_labels_memory_manual <- function(list_name, var_names, var_labs) {
#   # 変数ラベル（名前付きベクトル）
#   var_label <- setNames(var_labs, var_names)
#   
#   result <- list( list_name = var_label )
#   print(result)
#   return(result)
# }

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
#' @title save_labels_to_memory
#' @description データフレーム内のすべての変数の
#' 変数ラベルと値ラベルを保存します。
#' @param data データフレーム
#' @param exist_label_only 複数のデータセットを結合する際に、
#' ラベル付き変数のみを保存するかどうかの論理値。
#' デフォルトはTRUE。
#' @return 変数ラベルと値ラベルを含むリスト
#' @examples
#' labels_memory <- save_labels_to_memory(df)
#' ************************************************************************
save_labels_to_memory <- function(data, exist_label_only = TRUE) {
  # 変数ラベルを保存
  var_labels <- labelled::var_label(data)
  
  # 値ラベルを保存（各変数のattr "labels"を抽出）
  val_labels <- lapply(data, function(x) attr(x, "labels"))
  
  # factor情報を保存
  factor_info <- lapply(names(data), function(nm) {
    x <- data[[nm]]
    if (is.factor(x)) {
      list(
        levels  = levels(x),
        ordered = is.ordered(x)
      )
    } else {
      NULL
    }
  })
  names(factor_info) <- names(data)
  factor_info <- factor_info[!vapply(factor_info, is.null, logical(1))]
  
  # exist_label_only = TRUE のとき、ラベル付き変数だけに絞る
  if (exist_label_only) {
    has_var_lab <- !vapply(var_labels, function(x) is.null(x) || (is.character(x) && x == ""), logical(1))
    has_val_lab <- !vapply(val_labels, is.null, logical(1))
    
    target_vars <- names(data)[has_var_lab | has_val_lab]
    
    var_labels <- var_labels[target_vars]
    val_labels <- val_labels[target_vars]
    factor_info <- factor_info[target_vars]
  }
  
  # リストとして返す
  list(
    var_labels = var_labels,
    val_labels = val_labels,
    factor_info = factor_info
  )
}

#' ----------関数ここまで------------------------------------------------
# ============================================
# ステップ1-2: 複数のラベル情報を一つにまとめる
# ============================================
# 複数のlabels_memoryを結合
#' ************************************************************************
#' @title merge_labels_memory
#' @description 複数のラベル情報を一つにまとめます。
#' @param ... 複数のラベル情報リスト
#' @return 結合されたラベル情報リスト
#' @examples
#' merged_labels <- merge_labels_memory(labels1, labels2, labels3)
#' ************************************************************************
merge_labels_memory <- function(...) {
  labs_list <- list(...)
  labs_list <- labs_list[!vapply(labs_list, is.null, logical(1))]
  if (length(labs_list) == 0) {
    return(list(var_labels = NULL, val_labels = NULL, factor_info = NULL))
  }
  
  # すべての var_names の集合
  all_vars <- unique(unlist(lapply(labs_list, function(x) names(x$var_labels))))
  
  # var_labels のマージ（非欠損優先）
  merged_var <- setNames(vector("list", length(all_vars)), all_vars)
  for (v in all_vars) {
    vals <- lapply(labs_list, function(x) x$var_labels[[v]])
    # 後ろから見て、非NAかつ長さ>0のものを優先
    for (lab in rev(vals)) {
      if (!is.null(lab) && !(length(lab) == 1 && (is.na(lab) || lab == ""))) {
        merged_var[[v]] <- lab
        break
      }
    }
  }
  
  # val_labels も同様に（list なので NULL かどうかで判断）
  all_val_vars <- unique(unlist(lapply(labs_list, function(x) names(x$val_labels))))
  merged_val <- setNames(vector("list", length(all_val_vars)), all_val_vars)
  for (v in all_val_vars) {
    vals <- lapply(labs_list, function(x) x$val_labels[[v]])
    for (lab in rev(vals)) {
      if (!is.null(lab)) {
        merged_val[[v]] <- lab
        break
      }
    }
  }
  
  # factor_info を導入するなら同様に
  all_factor_vars <- unique(unlist(lapply(labs_list, function(x) names(x$factor_info))))
  merged_factor <- setNames(vector("list", length(all_factor_vars)), all_factor_vars)
  for (v in all_factor_vars) {
    vals <- lapply(labs_list, function(x) x$factor_info[[v]])
    for (info in rev(vals)) {
      if (!is.null(info)) {
        merged_factor[[v]] <- info
        break
      }
    }
  }
  
  list(
    var_labels  = merged_var,
    val_labels  = merged_val,
    factor_info = merged_factor
  )
}

#' ----------関数ここまで------------------------------------------------
# ============================================
# ステップ2: データフレームからラベル属性を除去
# ============================================
#' ************************************************************************
#' @title remove_labels
#' @description データフレーム内のすべての変数の
#' ラベル属性を削除します。
#' @param data データフレーム
#' @param remove_factor 論理値。TRUEの場合、factorクラスを削除します。デフォルトはTRUE。
#' @return ラベル属性が削除されたデータフレーム
#' @examples
#' df_clean <- remove_labels(df)
#' ************************************************************************
remove_labels <- function(data, remove_factor=TRUE) {
  data[] <- lapply(data, function(x) {
    # ラベル属性などを削除
    attr(x, "label")  <- NULL
    attr(x, "labels") <- NULL
    attr(x, "format.spss")     <- NULL
    attr(x, "display_width")   <- NULL
    
    # クラスから haven_labelled, labelled, vctrs_vctr を削除
    cl <- class(x)
    cl <- setdiff(cl, c("haven_labelled", "labelled", "vctrs_vctr"))
    
    # factor / ordered はここで character に落とす（option）
    if (remove_factor){
      if ("factor" %in% cl || "ordered" %in% cl) {
        x <- as.character(x)
        cl <- setdiff(cl, c("factor", "ordered"))
      }
    }
    
    class(x) <- cl
    x
  })
  return(data)
}

#' ----------関数ここまで------------------------------------------------

# ============================================
# ステップ3: 保存したラベルを復元
# ============================================
#' ************************************************************************
#' @title restore_labels
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
  
  # ============================================
  # factor情報の復元
  # factor の復元（必要な変数だけ）
  # ============================================
  if (!is.null(factor_info)) {
    for (var in names(factor_info)) {
      if (var %in% names(data)) {
        info <- factor_info[[var]]
        # いったん素のベクトルを取り出して factor にし直す
        data[[var]] <- if (isTRUE(info$ordered)) {
          factor(data[[var]], levels = info$levels, ordered = TRUE)
        } else {
          factor(data[[var]], levels = info$levels)
        }
      }
    }
  }
  
  #' =============================================
  #' ラベル情報（var_labels）が欠損している変数名の一覧を取得して表示
  #' =============================================
  missing_var_labels <- setdiff(names(data), names(var_labels))
  if (length(missing_var_labels) > 0) {
   warning("The following variables are missing variable labels: ", paste(missing_var_labels
   , collapse = ", "))
   }
  
  return(data)
}
#' ----------関数ここまで------------------------------------------------

