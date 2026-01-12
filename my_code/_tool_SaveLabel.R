library(dplyr)
library(labelled)  # またはhaven
library(rlang)


# すべてのラベルをリストとして保存
save_all_labels <- function(data) {
  labels <- list()
  for (col in names(data)) {
    labels[[col]] <- attr(data[[col]], "label", exact = TRUE)
  }
  return(labels)
}

# 保存されたラベルをすべて復元
restore_all_labels <- function(data, labels) {
  for (col in names(data)) {
    if (!is.null(labels[[col]])) {
      attr(data[[col]], "label") <- labels[[col]]
    }
  }
  return(data)
}


# 指定した列のラベルのみを保存
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

# 指定した列のラベルのみを復元
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

# パイプ処理に組み込める簡潔版
pipe_with_labels <- function(data) {
  structure(
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
  )
}

# より実用的な実装版
with_labels <- function(data) {
  attr(data, ".labels_backup") <- save_all_labels(data)
  return(data)
}

restore_from_backup <- function(data) {
  labels <- attr(data, ".labels_backup", exact = TRUE)
  if (!is.null(labels)) {
    data <- restore_all_labels(data, labels)
    attr(data, ".labels_backup") <- NULL
  }
  return(data)
}

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

# ラベルをバックアップしながらラベル属性を削除
with_labels_and_clean <- function(data) {
  # ステップ1: ラベル情報をバックアップ
  attr(data, ".labels_backup") <- save_all_labels(data)
  
  # ステップ2: ラベル属性を削除
  data <- data %>%
    mutate(across(everything(), ~{
      attr(., "label") <- NULL
      attr(., "labels") <- NULL
      class(.) <- setdiff(class(.), c("labelled", "haven_labelled"))
      .
    }))
  
  return(data)
}

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

