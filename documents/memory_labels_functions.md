# Rメモリ内ラベル管理：保存・除去・復元関数セット

栄養改善プログラムの分析ワークフローで、DHS/STEPSデータのラベル属性を一時的に除去してmutate処理を行い、その後ラベルを復元するパターンに対応した関数セットです。

------------------------------------------------------------------------

## 1. ラベルの保存（変数に格納）

``` r
# ============================================
# ステップ1: ラベル情報を変数に保存
# ============================================

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

# 使用例
data <- haven::read_dta("MWIR7HFL.DTA")
labels_memory <- save_labels_to_memory(data)
```

**保存されたオブジェクトの構造**:

``` r
# labels_memory$var_labels
# $age
# [1] "Age in years"
# 
# $sex
# [1] "Gender"

# labels_memory$val_labels
# $sex
# 1      2 
# "Male" "Female"
```

------------------------------------------------------------------------

## 2. ラベル属性の除去

``` r
# ============================================
# ステップ2: データフレームからラベル属性を除去
# ============================================

remove_labels <- function(data) {
  
  # すべてのラベル属性を削除
  data[] <- lapply(data, function(x) {
    # attr(x, "label") と attr(x, "labels") をNULLに設定
    attr(x, "label") <- NULL
    attr(x, "labels") <- NULL
    # その他のhaven関連属性も削除
    attr(x, "class") <- setdiff(attr(x, "class"), 
                                c("haven_labelled", "labelled"))
    x
  })
  
  return(data)
}

# 使用例
data_cleaned <- remove_labels(data)

# 確認
attr(data_cleaned$sex, "labels")  # NULL
```

------------------------------------------------------------------------

## 3. ラベル属性の復元

``` r
# ============================================
# ステップ3: 保存したラベルを復元
# ============================================

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

# 使用例
data_restored <- restore_labels(data_cleaned, labels_memory)

# 確認
attr(data_restored$sex, "labels")  # "Male" "Female"
```

------------------------------------------------------------------------

## 4. 完全なワークフロー例

``` r
# ============================================
# 完全なパイプライン
# ============================================

library(haven)
library(labelled)
library(dplyr)

# 1. データ読み込み
data <- haven::read_dta("MWIR7HFL.DTA")

# 2. ラベル保存
labels_memory <- save_labels_to_memory(data)

# 3. ラベル除去
data <- remove_labels(data)

# 4. 自由にmutate処理を実行
data <- data %>%
  mutate(
    age_group = case_when(
      age < 20 ~ "15-19",
      age < 30 ~ "20-29",
      age < 40 ~ "30-39",
      TRUE ~ "40+"
    ),
    bmi = weight / (height / 100)^2,
    log_income = log(income + 1)
  ) %>%
  filter(age >= 15)

# 5. ラベルを復元
data <- restore_labels(data, labels_memory)

# 確認
str(data)
```

------------------------------------------------------------------------

## 5. 便利なラッパー関数（ワンステップ処理）

### 5.1 ラベル除去 → 処理 → ラベル復元のパイプ

``` r
# ============================================
# パターンA: 処理後に自動的にラベルを復元
# ============================================

process_with_labels <- function(data, process_fn) {
  
  # 1. ラベル保存
  labels_memory <- save_labels_to_memory(data)
  
  # 2. ラベル除去
  data <- remove_labels(data)
  
  # 3. ユーザー定義の処理関数を実行
  data <- process_fn(data)
  
  # 4. ラベル復元
  data <- restore_labels(data, labels_memory)
  
  return(data)
}

# 使用例
data <- haven::read_dta("MWIR7HFL.DTA")

# 処理関数をインラインで定義
data_processed <- process_with_labels(data, function(df) {
  df %>%
    mutate(
      age_group = cut(age, breaks = c(0, 20, 30, 40, Inf),
                      labels = c("15-19", "20-29", "30-39", "40+")),
      bmi = weight / (height / 100)^2
    ) %>%
    filter(complete.cases(.))
})
```

### 5.2 パイプ対応版（より洗練されたパターン）

``` r
# ============================================
# パターンB: マグリットパイプとの統合
# ============================================

# labels_memoryをグローバル環境に保持する方法
# （注：実装上の注意が必要）

with_labels <- function(data) {
  # 属性として保存
  attr(data, "labels_memory") <- save_labels_to_memory(data)
  data
}

unset_labels <- function(data) {
  # ラベル除去（属性は保持）
  remove_labels(data)
}

reset_labels <- function(data) {
  # 属性から復元
  labels_mem <- attr(data, "labels_memory")
  if (!is.null(labels_mem)) {
    data <- restore_labels(data, labels_mem)
  }
  data
}

# 使用例（パイプ）
data <- haven::read_dta("MWIR7HFL.DTA") %>%
  with_labels() %>%
  unset_labels() %>%
  mutate(
    age_group = cut(age, breaks = c(0, 20, 30, 40, Inf),
                    labels = c("15-19", "20-29", "30-39", "40+"))
  ) %>%
  reset_labels()
```

------------------------------------------------------------------------

## 6. 高度な応用：複数変数セットの管理

新しい変数を追加した場合のラベル付与：

``` r
# ============================================
# 新規作成変数へのラベル付与
# ============================================

add_var_labels <- function(data, new_labels) {
  
  # new_labels: list(age_group = "Age group", bmi = "Body Mass Index")
  
  for (var_name in names(new_labels)) {
    if (var_name %in% names(data)) {
      attr(data[[var_name]], "label") <- new_labels[[var_name]]
    }
  }
  
  return(data)
}

# 使用例
data_processed <- data %>%
  mutate(
    age_group = cut(age, breaks = c(0, 20, 30, 40, Inf)),
    bmi = weight / (height / 100)^2
  ) %>%
  add_var_labels(list(
    age_group = "Age group (5-year)",
    bmi = "Body Mass Index (kg/m²)"
  ))
```

------------------------------------------------------------------------

## 7. トラブルシューティング

### Q: ラベル復元後、gtsummaryで表示されない

**A**: `haven_labelled`クラスが削除されている可能性。復元時に確認：

``` r
class(data$sex)  # "haven_labelled" "labelled" が含まれるか確認

# 手動で修正
class(data$sex) <- c("haven_labelled", "labelled", "numeric")
```

### Q: 新規作成変数にもラベルが必要

**A**: `restore_labels()`の後に`add_var_labels()`を使用：

``` r
data <- process_with_labels(data, function(df) {
  df %>% mutate(bmi = weight / (height / 100)^2)
}) %>%
add_var_labels(list(bmi = "Body Mass Index (kg/m²)"))
```

### Q: リスト変数の場合

**A**: `val_labels`の構造を確認：

``` r
# 値ラベルなし変数をフィルタ
val_labels_filtered <- labels_memory$val_labels[!sapply(labels_memory$val_labels, is.null)]
```

------------------------------------------------------------------------

## 8. 実装チェックリスト

``` r
# ============================================
# ワークフロー検証用スクリプト
# ============================================

verify_labels <- function(original_data, restored_data, labels_memory) {
  
  cat("=== ラベル復元検証 ===\n\n")
  
  # 1. 変数ラベルの確認
  cat("変数ラベル:\n")
  for (var in names(labels_memory$var_labels)) {
    orig_label <- labels_memory$var_labels[[var]]
    restored_label <- attr(restored_data[[var]], "label")
    match <- ifelse(identical(orig_label, restored_label), "✓", "✗")
    cat(sprintf("%s %s: %s\n", match, var, restored_label))
  }
  
  cat("\n値ラベル:\n")
  
  # 2. 値ラベルの確認
  for (var in names(labels_memory$val_labels)) {
    if (!is.null(labels_memory$val_labels[[var]])) {
      orig_labels <- labels_memory$val_labels[[var]]
      restored_labels <- attr(restored_data[[var]], "labels")
      match <- ifelse(identical(orig_labels, restored_labels), "✓", "✗")
      cat(sprintf("%s %s: %s\n", match, var, 
                  paste(restored_labels, collapse = ", ")))
    }
  }
}

# 使用例
data_orig <- haven::read_dta("MWIR7HFL.DTA")
labels_mem <- save_labels_to_memory(data_orig)
data_clean <- remove_labels(data_orig)
data_rest <- restore_labels(data_clean, labels_mem)

verify_labels(data_orig, data_rest, labels_mem)
```

------------------------------------------------------------------------

## 推奨ワークフロー

``` r
# Quarto/R Markdownでの標準ワークフロー

# setup chunk
data <- haven::read_dta("data/raw/MWIR7HFL.DTA")
labels_memory <- save_labels_to_memory(data)

# processing chunk
data <- data %>%
  remove_labels() %>%
  mutate(
    age_group = cut(age, breaks = c(0, 20, 30, 40, Inf)),
    bmi = weight / (height / 100)^2,
    diary_days_valid = rowSums(!is.na(.[paste0("day", 1:7)])) >= 4
  ) %>%
  filter(age >= 15, complete.cases(bmi)) %>%
  restore_labels(labels_memory)

# analysis chunk: このftsummary()がラベル付きで実行される
data %>%
  gtsummary::tbl_summary(
    by = sex,
    include = c(age_group, bmi, education)
  )
```

------------------------------------------------------------------------

## 参考：属性の詳細確認

``` r
# データフレーム全体の属性確認
check_all_attributes <- function(data) {
  
  cat("=== データフレーム全体の属性 ===\n")
  for (var in names(data)) {
    cat(sprintf("\n【%s】\n", var))
    cat("  class:", paste(class(data[[var]]), collapse = ", "), "\n")
    
    label <- attr(data[[var]], "label")
    if (!is.null(label)) {
      cat("  label:", label, "\n")
    }
    
    labels <- attr(data[[var]], "labels")
    if (!is.null(labels)) {
      cat("  values:", paste(names(labels), collapse = ", "), "\n")
    }
  }
}

check_all_attributes(data)
```
