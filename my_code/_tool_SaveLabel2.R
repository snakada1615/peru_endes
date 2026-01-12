library(haven)
library(labelled)
library(dplyr)
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
# ============================================

# ============================================
# ステップ2: データフレームからラベル属性を除去
# ============================================
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
    attr(x, "class") <- setdiff(attr(x, "class"), 
          c("haven_labelled", "labelled", "vctrs_vctr"))
    x
  })
  
  return(data)
}

# ============================================

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
# ============================================

