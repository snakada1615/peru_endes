library(dplyr)
library(haven)   # ← haven に統一
library(rlang)

# =========================================================
# 1. 全変数ラベルを保存 / 復元（variable label）
# =========================================================

# 全ての変数ラベルをリストに保存
save_all_labels <- function(data) {
  labs <- haven::var_label(data)   # named list: 変数名 → ラベル
  # NULL は落とす（不要ならこの行は外してもよい）
  labs[ vapply(labs, is.null, logical(1)) ] <- NULL
  labs
}

# 全ての変数ラベルをリストから復元
restore_all_labels <- function(data, labels) {
  if (length(labels) == 0) return(data)
  for (col in names(labels)) {
    if (col %in% names(data)) {
      haven::var_label(data[[col]]) <- labels[[col]]
    }
  }
  data
}

# 指定列だけの変数ラベルを保存
save_labels <- function(data, columns = NULL) {
  if (is.null(columns)) columns <- names(data)
  labs <- haven::var_label(data)
  labs[intersect(names(labs), columns)]
}

# 指定列だけの変数ラベルを復元
restore_labels_col <- function(data, labels, columns = NULL) {
  if (is.null(columns)) {
    columns <- names(labels)
  }
  for (col in columns) {
    if (col %in% names(data) && !is.null(labels[[col]])) {
      haven::var_label(data[[col]]) <- labels[[col]]
    }
  }
  data
}

# =========================================================
# 2. パイプ処理用バックアップ / 復元
# =========================================================

with_labels <- function(data) {
  attr(data, ".labels_backup") <- save_all_labels(data)
  data
}

restore_from_backup <- function(data) {
  labs <- attr(data, ".labels_backup", exact = TRUE)
  if (!is.null(labs)) {
    data <- restore_all_labels(data, labs)
    attr(data, ".labels_backup") <- NULL
  }
  data
}

# ラベルバックアップ付きクリーンデータ作成
# （value/variable ラベルと haven_labelled クラス等を削除）
with_labels_and_clean <- function(data, remove_factor = TRUE) {
  attr(data, ".labels_backup") <- save_all_labels(data)
  
  data[] <- lapply(data, function(x) {
    # haven のラベル関連を削除
    x <- haven::zap_labels(x)   # 値ラベル（val_labels）
    x <- haven::zap_label(x)    # 変数ラベル（var_label）
    
    # haven_labelled, labelled, vctrs_vctr をクラスから除去
    cl <- class(x)
    cl <- setdiff(cl, c("haven_labelled", "labelled", "vctrs_vctr"))
    
    # factor を落としたい場合は character に
    if (remove_factor && any(cl %in% c("factor", "ordered"))) {
      x <- as.character(x)
      cl <- setdiff(cl, c("factor", "ordered"))
    }
    class(x) <- cl
    x
  })
  
  data
}

# =========================================================
# 3. ラベル情報（変数ラベル + 値ラベル + factor情報）を保存
# =========================================================

save_labels_to_memory <- function(data, exist_label_only = TRUE) {
  # 変数ラベル（haven::var_label は named list を返す）
  var_labels <- haven::var_label(data)
  
  # 値ラベル（attr "labels"）
  val_labels <- lapply(data, function(x) attr(x, "labels", exact = TRUE))
  
  # factor 情報
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
  
  if (exist_label_only) {
    has_var_lab <- !vapply(var_labels, function(x) is.null(x) || (is.character(x) && x == ""), logical(1))
    has_val_lab <- !vapply(val_labels, is.null, logical(1))
    
    target_vars <- names(data)[has_var_lab | has_val_lab]
    var_labels  <- var_labels[target_vars]
    val_labels  <- val_labels[target_vars]
    factor_info <- factor_info[target_vars]
  }
  
  list(
    var_labels = var_labels,
    val_labels = val_labels,
    factor_info = factor_info
  )
}

# =========================================================
# 4. 複数データセットのラベル情報をマージ
# =========================================================

merge_labels_memory <- function(...) {
  labs_list <- list(...)
  labs_list <- labs_list[!vapply(labs_list, is.null, logical(1))]
  if (length(labs_list) == 0) {
    return(list(var_labels = NULL, val_labels = NULL, factor_info = NULL))
  }
  
  # var_labels
  all_vars <- unique(unlist(lapply(labs_list, function(x) names(x$var_labels))))
  merged_var <- setNames(vector("list", length(all_vars)), all_vars)
  for (v in all_vars) {
    vals <- lapply(labs_list, function(x) x$var_labels[[v]])
    for (lab in rev(vals)) {
      if (!is.null(lab) && !(length(lab) == 1 && (is.na(lab) || lab == ""))) {
        merged_var[[v]] <- lab
        break
      }
    }
  }
  
  # val_labels
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
  
  # factor_info
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

# =========================================================
# 5. ラベルの除去（haven ベース）
# =========================================================

remove_labels <- function(data, remove_factor = TRUE) {
  data[] <- lapply(data, function(x) {
    # haven のラベル関連を削除
    x <- haven::zap_labels(x)
    x <- haven::zap_label(x)
    
    # SPSS 由来の余計な属性があれば削除
    attr(x, "format.spss")   <- NULL
    attr(x, "display_width") <- NULL
    
    # クラスから haven_labelled, labelled, vctrs_vctr を削除
    cl <- class(x)
    cl <- setdiff(cl, c("haven_labelled", "labelled", "vctrs_vctr"))
    
    if (remove_factor && any(cl %in% c("factor", "ordered"))) {
      x <- as.character(x)
      cl <- setdiff(cl, c("factor", "ordered"))
    }
    
    class(x) <- cl
    x
  })
  data
}

# =========================================================
# 6. ラベルの復元（haven ベース）
# =========================================================

restore_labels <- function(data, labels_memory) {
  if (!all(c("var_labels", "val_labels") %in% names(labels_memory))) {
    stop("labels_memory must contain 'var_labels' and 'val_labels'")
  }
  
  var_labels  <- labels_memory$var_labels
  val_labels  <- labels_memory$val_labels
  factor_info <- labels_memory$factor_info
  
  # 変数ラベル
  for (var in names(var_labels)) {
    if (var %in% names(data)) {
      haven::var_label(data[[var]]) <- var_labels[[var]]
    }
  }
  
  # 値ラベル（haven::labelled を想定）
  for (var in names(val_labels)) {
    if (var %in% names(data) && !is.null(val_labels[[var]])) {
      labs <- val_labels[[var]]   # named numeric: 値 → ラベル名 or その逆にしてもよい
      attr(data[[var]], "labels") <- labs
      # 必要なら haven_labelled クラスを付与
      if (!inherits(data[[var]], "haven_labelled")) {
        class(data[[var]]) <- c("haven_labelled", class(data[[var]]))
      }
    }
  }
  
  # factor の復元
  if (!is.null(factor_info)) {
    for (var in names(factor_info)) {
      if (var %in% names(data)) {
        info <- factor_info[[var]]
        data[[var]] <- if (isTRUE(info$ordered)) {
          factor(data[[var]], levels = info$levels, ordered = TRUE)
        } else {
          factor(data[[var]], levels = info$levels)
        }
      }
    }
  }
  
  # ラベル欠損の警告（任意）
  missing_var_labels <- setdiff(names(data), names(var_labels))
  if (length(missing_var_labels) > 0) {
    warning("The following variables are missing variable labels:")
    for (var in missing_var_labels) message("  - ", var)
  }
  
  data
}