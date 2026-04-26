library(dplyr)
library(haven)   # ← haven に統一
library(rlang)
library(purrr)
library(tidyr)
library(writexl)
library(readxl)

#' 関数一覧1 ------------------------------------------------------------
#' save_all_labels(data) : データフレーム全体の変数ラベルをリストに保存
#' restore_all_labels(data, labels) : データフレーム全体の変数ラベルをリストから復元
#' save_labels(data, columns) : 指定列の変数ラベルをリストに保存
#' restore_labels_col(data, labels, columns) : 指定列の変数ラベルをリストから復元
#' with_labels(data) : データフレーム全体の変数ラベルをバックアップ用の属性に保存
#' restore_from_backup(data) : with_labels() で保存したバックアップから変数ラベルを復元
#' with_labels_and_clean(data, remove_factor) : 変数ラベルをバックアップしつつ、データフレームからラベル関連の属性とクラスを削除（必要に応じて factor を character に変換）
#' save_labels_to_memory(data, exist_label_only) : データフレームから変数ラベル、値ラベル、factor情報をリスト形式で保存
#' merge_labels_memory(...) : 複数のラベル情報リストをマージして、変数ラベル、値ラベル、factor情報を統合
#' remove_labels(data, remove_factor) : データフレームから変数ラベル、値ラベル、ユーザー定義の欠損値を削除（必要に応じて factor を character に変換）
#' restore_labels(data, labels_memory) : データフレームに変数ラベル、値ラベル、factor情報を復元
#' update_label_dict_in_excel：Excel ファイルの label_extract シートに、dataset-varname-varlabel-value-valuelabel 形式のラベル辞書を更新・マージする関数。上書きポリシーを指定して、既存のラベルと新規のラベルのどちらを優先するかを制御できます。
#' ------------------------------------------------------------
######### part 2: ラベル辞書の作成・マージ・Excel 書き出し・Excel からの適用 ############

#' 関数一覧2 ------------------------------------------------------------
#' make_label_dict：データフレームから、変数名、変数ラベル、値ラベルを抽出して、dataset-varname-varlabel-value-valuelabel 形式のデータフレームを作成する関数。
#' merge_label_dicts：既存のラベル辞書と新規のラベル辞書をマージする関数。上書きポリシーを指定して、どちらのラベルを優先するかを制御できます。
#' export_labels_to_excel：データフレームから抽出したラベル辞書を、指定されたExcelファイルの label_extract シートに書き出す関数。既存のシートがある場合は、上書きポリシーに従ってマージします。
#' strip_all_labels：データフレームから、変数ラベル、値ラベル、ユーザー定義の欠損値をすべて削除する関数。haven_labelled 形式のラベルも対応。
#' strip_value_labels_only：データフレームから、値ラベルとユーザー定義の欠損値を削除し、変数ラベルは保持する関数。haven_labelled 形式のラベルも対応。
#' apply_labels_from_excel：指定されたExcelファイルの label_extract シートから、データフレームに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。
#' apply_labels_from_label_final：指定されたExcelファイルの label_final シートから、データフレームに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。label_final シートは、dataset 列がない前提で、var_name と var_label のみを含む形式であることを想定しています。
#' update_labels_dict_in_excel：Excel ファイルの label_extract シートに、dataset-varname-varlabel-value-valuelabel 形式のラベル辞書を更新・マージする関数。上書きポリシーを指定して、既存のラベルと新規のラベルのどちらを優先するかを制御できます。
#' ----------------------------------------------------------------------------
#' 

# =========================================================
# 1. 全変数ラベルを保存 / 復元（variable label）
# =========================================================

# 全ての変数ラベルをリストに保存（list: 変数名 → ラベル文字列 or NULL）
save_all_labels <- function(data) {
  labs <- lapply(data, function(x) attr(x, "label", exact = TRUE))
  labs
}
# 全ての変数ラベルをリストから復元
restore_all_labels <- function(data, labels) {
  if (length(labels) == 0) return(data)
  
  for (col in names(labels)) {
    if (!col %in% names(data)) next
    
    x        <- data[[col]]
    old_labs <- attr(x, "labels", exact = TRUE)  # 既存の値ラベル（あれば）
    lab      <- labels[[col]]
    
    if (is.null(lab) || is.na(lab) || lab == "") {
      # ラベルが無い場合はそのまま
      data[[col]] <- x
    } else {
      # 変数ラベル + 既存の値ラベルをまとめて付与
      data[[col]] <- haven::labelled(
        x      = x,
        labels = old_labs,
        label  = lab
      )
    }
  }
  
  data
}

# 指定列だけの変数ラベルを保存
save_labels <- function(data, columns = NULL) {
  if (is.null(columns)) columns <- names(data)
  labs <- lapply(data, function(x) attr(x, "label", exact = TRUE))
  labs[intersect(names(labs), columns)]
}
# 指定列だけの変数ラベルを復元
# 指定列だけの変数ラベルを復元
restore_labels_col <- function(data, labels, columns = NULL) {
  if (is.null(columns)) {
    columns <- names(labels)
  }
  
  for (col in columns) {
    if (!col %in% names(data) || is.null(labels[[col]])) next
    
    x        <- data[[col]]
    old_labs <- attr(x, "labels", exact = TRUE)  # 既存の値ラベル
    lab      <- labels[[col]]
    
    if (is.null(lab) || is.na(lab) || lab == "") {
      data[[col]] <- x
    } else {
      data[[col]] <- haven::labelled(
        x      = x,
        labels = old_labs,
        label  = lab
      )
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

save_labels_to_memory <- function(data, exist_label_only = TRUE) {
  var_labels <- lapply(data, function(x) attr(x, "label", exact = TRUE))
  val_labels <- lapply(data, function(x) attr(x, "labels", exact = TRUE))
  
  factor_info <- lapply(names(data), function(nm) {
    x <- data[[nm]]
    if (is.factor(x)) {
      list(levels = levels(x), ordered = is.ordered(x))
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
    var_labels  = var_labels,
    val_labels  = val_labels,
    factor_info = factor_info
  )
}

merge_labels_memory <- function(...) {
  labs_list <- list(...)
  labs_list <- labs_list[!vapply(labs_list, is.null, logical(1))]
  if (length(labs_list) == 0) {
    return(list(var_labels = NULL, val_labels = NULL, factor_info = NULL))
  }
  
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

remove_labels <- function(data, remove_factor = TRUE) {
  data[] <- lapply(data, function(x) {
    x <- haven::zap_labels(x)
    x <- haven::zap_label(x)
    
    attr(x, "format.spss")   <- NULL
    attr(x, "display_width") <- NULL
    
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

restore_labels <- function(data, labels_memory) {
  stopifnot(all(c("var_labels", "val_labels") %in% names(labels_memory)))
  
  var_labels  <- labels_memory$var_labels
  val_labels  <- labels_memory$val_labels
  factor_info <- labels_memory$factor_info
  
  for (var in names(data)) {
    x <- data[[var]]
    
    old_var_label  <- attr(x, "label", exact = TRUE)
    old_val_labels <- attr(x, "labels", exact = TRUE)
    
    new_var_label  <- var_labels[[var]]
    new_val_labels <- val_labels[[var]]
    
    final_var_label <- if (!is.null(new_var_label) && !is.na(new_var_label) && new_var_label != "") {
      new_var_label
    } else {
      old_var_label
    }
    
    final_val_labels <- if (!is.null(new_val_labels) && length(new_val_labels) > 0) {
      new_val_labels
    } else {
      old_val_labels
    }
    
    if (!is.null(final_var_label) || (!is.null(final_val_labels) && length(final_val_labels) > 0)) {
      x <- haven::labelled(
        x      = x,
        labels = final_val_labels,
        label  = final_var_label
      )
    }
    
    data[[var]] <- x
  }
  
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
  
  missing_var_labels <- setdiff(names(data), names(var_labels))
  if (length(missing_var_labels) > 0) {
    warning("The following variables are missing variable labels:")
    for (var in missing_var_labels) message("  - ", var)
  }
  
  data
}

make_label_dict <- function(df, vars = NULL) {
  if (is.null(vars)) vars <- names(df)
  
  yesno_level <- function(v) {
    yes_vars <- c("Yes", "yes", "Sí", "si")
    no_vars  <- c("No", "no")
    res <- list(yes_var = NA_character_, no_var = NA_character_)
    if (!is.vector(v) || length(v) != 2) {
      stop("Input must be a vector of length 2.")
    }
    for (x in v) {
      if (x %in% yes_vars) {
        res$yes_var <- x
      } else if (x %in% no_vars) {
        res$no_var <- x
      }
    }
    res
  }
  
  validate_labels <- function(x, label_name = deparse(substitute(x))) {
    if (all(is.na(unlist(x, use.names = FALSE)))) {
      stop(sprintf("ラベル '%s' が全て NA です。処理を中止します。", label_name))
    }
    invisible(x)
  }
  
  vlab_list <- lapply(df, function(x) attr(x, "label", exact = TRUE))
  vlab_chr  <- vapply(
    vlab_list,
    function(x) if (is.null(x)) NA_character_ else as.character(x),
    FUN.VALUE = character(1)
  )
  
  validate_labels(vlab_chr, "変数ラベル")
  
  var_part <- tibble(
    var_name      = vars,
    var_label     = unname(vlab_chr[vars]),
    value         = NA_character_,
    value_label   = NA_character_,
    is_logical    = purrr::map_lgl(vars, ~ is.logical(df[[.x]])),
    is_character  = purrr::map_lgl(vars, ~ is.character(df[[.x]])),
    is_numeric    = purrr::map_lgl(vars, ~ is.numeric(df[[.x]])),
    is_factor     = purrr::map_lgl(vars, ~ is.factor(df[[.x]])),
    factor_levels = purrr::map_int(vars, ~ length(unique(na.omit(df[[.x]])))),
    yes_value     = NA_character_,
    no_value      = NA_character_
  )
  
  value_part <- purrr::map_dfr(vars, function(v) {
    x <- df[[v]]
    lab_vals <- attr(x, "labels", exact = TRUE)
    
    if (is.null(lab_vals) || length(lab_vals) == 0) return(NULL)
    
    tibble(
      var_name      = v,
      var_label     = unname(vlab_chr[v]),
      value         = as.character(unname(lab_vals)),
      value_label   = names(lab_vals),
      is_logical    = is.logical(x),
      is_character  = is.character(x),
      is_numeric    = is.numeric(x),
      is_factor     = is.factor(x),
      factor_levels = if (is.factor(x)) length(na.omit(unique(x))) else NA_integer_,
      yes_value     = if (is.factor(x) && length(na.omit(unique(x))) == 2) yesno_level(levels(x))$yes_var else NA_character_,
      no_value      = if (is.factor(x) && length(na.omit(unique(x))) == 2) yesno_level(levels(x))$no_var else NA_character_
    )
  })
  
  if (!is.null(value_part) && nrow(value_part) > 0) {
    if ("value_label" %in% names(value_part)) {
      value_part$value_label[value_part$value_label == ""] <- NA_character_
      if (all(is.na(value_part$value_label))) {
        warning("値ラベルがすべて NA です。")
      }
    }
    if ("is_factor" %in% names(value_part)) {
      if (all(value_part$is_factor == FALSE | is.na(value_part$is_factor))) {
        warning("Factorが一つも存在しません。")
      }
    }
  } else {
    warning("値ラベルを持つ変数が一つもありません。")
  }
  
  bind_rows(var_part, value_part) %>% arrange(var_name, value)
}

merge_label_dicts <- function(old, new, overwrite_policy = c("prefer_new", "prefer_old")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  key_cols <- c("var_name", "value")
  
  full <- full_join(old, new, by = key_cols, suffix = c("_old", "_new"))
  
  full <- full %>%
    dplyr::mutate(
      var_label_old     = as.character(var_label_old),
      var_label_new     = as.character(var_label_new),
      value_label_old   = as.character(value_label_old),
      value_label_new   = as.character(value_label_new),
      is_logical_old    = as.logical(is_logical_old),
      is_logical_new    = as.logical(is_logical_new),
      is_character_old  = as.logical(is_character_old),
      is_character_new  = as.logical(is_character_new),
      is_numeric_old    = as.logical(is_numeric_old),
      is_numeric_new    = as.logical(is_numeric_new),
      is_factor_old     = as.logical(is_factor_old),
      is_factor_new     = as.logical(is_factor_new),
      factor_levels_old = as.numeric(factor_levels_old),
      factor_levels_new = as.numeric(factor_levels_new),
      yes_value_old     = as.character(yes_value_old),
      yes_value_new     = as.character(yes_value_new),
      no_value_old      = as.character(no_value_old),
      no_value_new      = as.character(no_value_new)
    )
  
  if (overwrite_policy == "prefer_new") {
    out <- full %>%
      transmute(
        var_name,
        value,
        var_label     = coalesce(var_label_new, var_label_old),
        value_label   = coalesce(value_label_new, value_label_old),
        is_logical    = coalesce(is_logical_new, is_logical_old),
        is_character  = coalesce(is_character_new, is_character_old),
        is_numeric    = coalesce(is_numeric_new, is_numeric_old),
        is_factor     = coalesce(is_factor_new, is_factor_old),
        factor_levels = coalesce(factor_levels_new, factor_levels_old),
        yes_value     = coalesce(yes_value_new, yes_value_old),
        no_value      = coalesce(no_value_new, no_value_old)
      )
  } else {
    out <- full %>%
      transmute(
        var_name,
        value,
        var_label     = coalesce(var_label_old, var_label_new),
        value_label   = coalesce(value_label_old, value_label_new),
        is_logical    = coalesce(is_logical_old, is_logical_new),
        is_character  = coalesce(is_character_old, is_character_new),
        is_numeric    = coalesce(is_numeric_old, is_numeric_new),
        is_factor     = coalesce(is_factor_old, is_factor_new),
        factor_levels = coalesce(factor_levels_old, factor_levels_new),
        yes_value     = coalesce(yes_value_old, yes_value_new),
        no_value      = coalesce(no_value_old, no_value_new)
      )
  }
  
  out %>% arrange(var_name, value)
}

export_labels_to_excel <- function(df,
                                   path,
                                   sheet_name = "label_raw_extract",
                                   vars = NULL,
                                   overwrite_policy = c("prefer_new", "prefer_old")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  dict_new <- make_label_dict(df, vars)
  
  if (file.exists(path)) {
    existing_sheets <- excel_sheets(path)
    
    if (sheet_name %in% existing_sheets) {
      old <- read_excel(path, sheet = sheet_name)
      if ("dataset" %in% names(old)) old <- dplyr::select(old, -dataset)
      dict_out <- merge_label_dicts(old, dict_new, overwrite_policy)
    } else {
      dict_out <- dict_new
    }
    
    all_sheets <- lapply(existing_sheets, function(s) {
      if (s == sheet_name) {
        dict_out
      } else {
        read_excel(path, sheet = s)
      }
    })
    names(all_sheets) <- existing_sheets
    
    if (!sheet_name %in% existing_sheets) {
      all_sheets[[sheet_name]] <- dict_out
    }
    
    write_xlsx(all_sheets, path)
  } else {
    dict_out <- dict_new
    write_xlsx(setNames(list(dict_out), sheet_name), path)
  }
  
  invisible(dict_out)
}

strip_all_labels <- function(df, user_na_to_na = TRUE) {
  df[] <- lapply(df, function(x) {
    x <- haven::zap_labels(x)
    x <- haven::zap_label(x)
    if (user_na_to_na) {
      x <- haven::zap_missing(x)
    }
    attr(x, "format.spss")   <- NULL
    attr(x, "display_width") <- NULL
    cl <- class(x)
    cl <- setdiff(cl, c("haven_labelled", "labelled", "vctrs_vctr"))
    class(x) <- cl
    x
  })
  df
}

strip_value_labels_only <- function(df, user_na_to_na = TRUE) {
  df[] <- lapply(df, function(x) {
    x <- haven::zap_labels(x)
    if (user_na_to_na) {
      x <- haven::zap_missing(x)
    }
    x
  })
  df
}

apply_labels_from_excel <- function(df,
                                    path,
                                    sheet_name = "label_extract",
                                    overwrite_policy = c("prefer_excel", "prefer_df")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  dict <- readxl::read_excel(path, sheet = sheet_name)
  if ("dataset" %in% names(dict)) dict <- dplyr::select(dict, -dataset)
  
  dict <- dict %>%
    dplyr::mutate(
      var_name     = as.character(var_name),
      var_label    = as.character(var_label),
      value        = as.character(value),
      value_label  = as.character(value_label),
      is_character = as.logical(is_character),
      is_numeric   = as.logical(is_numeric)
    )
  
  var_info <- dict %>%
    dplyr::filter(is.na(value) | value %in% c("NA", "")) %>%
    dplyr::select(var_name, var_label, is_character, is_numeric) %>%
    dplyr::distinct()
  
  value_info <- dict %>%
    dplyr::filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    dplyr::select(var_name, value, value_label)
  
  for (v in intersect(unique(dict$var_name), names(df))) {
    x <- df[[v]]
    vtype <- var_info %>% dplyr::filter(var_name == v) %>% dplyr::slice(1)
    force_char    <- isTRUE(vtype$is_character)
    force_numeric <- isTRUE(vtype$is_numeric)
    
    x_base <- if (inherits(x, "haven_labelled")) haven::zap_labels(x) else x
    
    if (force_char && !is.character(x_base)) {
      x_base <- as.character(x_base)
    } else if (force_numeric && !is.numeric(x_base)) {
      x_base <- suppressWarnings(as.numeric(x_base))
    }
    
    old_var_label <- attr(x, "label", exact = TRUE)
    
    new_var_label <- var_info %>%
      dplyr::filter(var_name == v) %>%
      dplyr::pull(var_label) %>%
      .[1]
    
    final_var_label <- dplyr::case_when(
      overwrite_policy == "prefer_excel" && !is.na(new_var_label) && new_var_label != "" ~ new_var_label,
      (is.null(old_var_label) || is.na(old_var_label) || old_var_label == "") && !is.na(new_var_label) && new_var_label != "" ~ new_var_label,
      TRUE ~ old_var_label
    )
    
    sub <- value_info %>% dplyr::filter(var_name == v)
    
    if (nrow(sub) > 0) {
      if (force_char) {
        new_vals <- as.character(sub$value)
      } else if (force_numeric) {
        new_vals <- suppressWarnings(as.numeric(sub$value))
      } else {
        new_vals_num <- suppressWarnings(as.numeric(sub$value))
        new_vals <- if (any(is.na(new_vals_num) & !is.na(sub$value))) as.character(sub$value) else new_vals_num
      }
      
      keep     <- !is.na(new_vals) & !is.na(sub$value_label) & sub$value_label != ""
      new_labs <- stats::setNames(new_vals[keep], sub$value_label[keep])
    } else {
      new_labs <- NULL
    }
    
    old_labs <- attr(x, "labels", exact = TRUE)
    
    if (!is.null(old_labs) && length(old_labs) > 0) {
      if (is.character(x_base)) {
        old_labs <- stats::setNames(as.character(old_labs), names(old_labs))
      } else if (is.numeric(x_base)) {
        old_labs <- stats::setNames(suppressWarnings(as.numeric(old_labs)), names(old_labs))
        old_labs <- old_labs[!is.na(old_labs)]
      }
    }
    
    final_labs <- if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
      new_labs
    } else if (is.null(new_labs) || length(new_labs) == 0) {
      old_labs
    } else {
      add_labs <- new_labs[setdiff(names(new_labs), names(old_labs))]
      c(old_labs, add_labs)
    }
    
    if (!is.null(final_labs) && length(final_labs) > 0) {
      df[[v]] <- haven::labelled(x = x_base, labels = final_labs, label = final_var_label)
    } else if (!is.null(final_var_label) && !is.na(final_var_label) && final_var_label != "") {
      attr(x_base, "label") <- final_var_label
      df[[v]] <- x_base
    } else {
      df[[v]] <- x_base
    }
  }
  
  df
}

apply_labels_from_label_final <- function(df,
                                          path,
                                          sheet_name = "label_final",
                                          overwrite_policy = c("prefer_excel", "prefer_df")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  dict <- readxl::read_excel(path, sheet = sheet_name) %>%
    dplyr::mutate(
      var_name     = as.character(var_name),
      var_label    = as.character(var_label),
      value        = as.character(value),
      value_label  = as.character(value_label),
      is_character = as.logical(if ("is_character" %in% names(.)) is_character else NA),
      is_character = as.logical(is_character),
      is_numeric   = as.logical(if ("is_numeric" %in% names(.)) is_numeric else NA)
    )
  
  var_info <- dict %>%
    dplyr::filter(is.na(value) | value %in% c("NA", "")) %>%
    dplyr::select(var_name, var_label, is_character, is_numeric) %>%
    dplyr::distinct()
  
  value_info <- dict %>%
    dplyr::filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    dplyr::select(var_name, value, value_label)
  
  for (v in intersect(unique(dict$var_name), names(df))) {
    x <- df[[v]]
    
    vtype <- var_info %>% dplyr::filter(var_name == v) %>% dplyr::slice(1)
    force_char    <- isTRUE(vtype$is_character)
    force_numeric <- isTRUE(vtype$is_numeric)
    
    x_base <- if (inherits(x, "haven_labelled")) haven::zap_labels(x) else x
    
    if (force_char && !is.character(x_base)) {
      x_base <- as.character(x_base)
    } else if (force_numeric && !is.numeric(x_base)) {
      x_base <- suppressWarnings(as.numeric(x_base))
    }
    
    old_var_label <- attr(x, "label", exact = TRUE)
    old_var_label <- if (is.null(old_var_label)) NA_character_ else as.character(old_var_label)
    
    new_var_label <- var_info %>%
      dplyr::filter(var_name == v) %>%
      dplyr::pull(var_label) %>%
      .[1]
    
    final_var_label <- dplyr::case_when(
      overwrite_policy == "prefer_excel" & !is.na(new_var_label) & new_var_label != "" ~ new_var_label,
      (is.na(old_var_label) | old_var_label == "") & !is.na(new_var_label) & new_var_label != "" ~ new_var_label,
      TRUE ~ old_var_label
    )
    
    sub <- value_info %>% dplyr::filter(var_name == v)
    
    if (nrow(sub) > 0) {
      if (force_char) {
        new_vals <- as.character(sub$value)
      } else if (force_numeric) {
        new_vals <- suppressWarnings(as.numeric(sub$value))
      } else if (is.numeric(x_base) || is.integer(x_base)) {
        new_vals <- suppressWarnings(as.numeric(sub$value))
      } else {
        new_vals <- as.character(sub$value)
      }
      
      keep     <- !is.na(new_vals) & !is.na(sub$value_label) & sub$value_label != ""
      new_labs <- stats::setNames(new_vals[keep], sub$value_label[keep])
    } else {
      new_labs <- NULL
    }
    
    old_labs <- attr(x, "labels", exact = TRUE)
    
    if (!is.null(old_labs) && length(old_labs) > 0) {
      if (is.character(x_base)) {
        old_labs <- stats::setNames(as.character(old_labs), names(old_labs))
      } else if (is.numeric(x_base)) {
        old_labs <- stats::setNames(suppressWarnings(as.numeric(old_labs)), names(old_labs))
        old_labs <- old_labs[!is.na(old_labs)]
      }
    }
    
    final_labs <- if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
      new_labs
    } else if (is.null(new_labs) || length(new_labs) == 0) {
      old_labs
    } else {
      add_labs <- new_labs[setdiff(names(new_labs), names(old_labs))]
      c(old_labs, add_labs)
    }
    
    if (!is.null(final_labs) && length(final_labs) > 0) {
      df[[v]] <- haven::labelled(x = x_base, labels = final_labs, label = final_var_label)
    } else if (!is.null(final_var_label) && !is.na(final_var_label) && final_var_label != "") {
      attr(x_base, "label") <- final_var_label
      df[[v]] <- x_base
    } else {
      df[[v]] <- x_base
    }
  }
  
  df
}

update_label_dict_in_excel <- function(df,
                                       path,
                                       sheet_name = "label_raw_extract",
                                       overwrite_policy = c("prefer_new", "prefer_old")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  normalize_key_value <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  }
  
  make_default_value <- function(proto_col, col_name = NULL) {
    if (inherits(proto_col, "Date")) return(as.Date(NA))
    if (inherits(proto_col, "POSIXct")) return(as.POSIXct(NA))
    if (is.integer(proto_col)) return(NA_integer_)
    if (is.numeric(proto_col)) return(NA_real_)
    if (is.logical(proto_col)) return(NA)
    if (is.character(proto_col)) return(NA_character_)
    if (is.factor(proto_col)) return(factor(NA, levels = levels(proto_col)))
    NA
  }
  
  same_r_type <- function(x, y) {
    cls_x <- class(x)[1]
    cls_y <- class(y)[1]
    identical(cls_x, cls_y)
  }
  
  add_missing_cols_from_prototype <- function(df, proto_df) {
    miss_cols <- setdiff(names(proto_df), names(df))
    if (length(miss_cols) == 0) return(df)
    
    for (cc in miss_cols) {
      default_val <- make_default_value(proto_df[[cc]], cc)
      df[[cc]] <- rep(default_val, nrow(df))
    }
    df
  }
  
  align_col_order <- function(df, ref_names) {
    extra_cols <- setdiff(names(df), ref_names)
    df[, c(ref_names, extra_cols), drop = FALSE]
  }
  
  if (!("var_name" %in% names(df)) || !("value" %in% names(df))) {
    stop("df には必須列 'var_name' と 'value' が必要です。")
  }
  if (!("var_label" %in% names(df)) || !("value_label" %in% names(df))) {
    stop("df には必須列 'var_label' と 'value_label' が必要です。")
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  df$var_name <- as.character(df$var_name)
  df$value <- normalize_key_value(df$value)
  if ("dataset" %in% names(df)) df$dataset <- NULL
  
  if (file.exists(path)) {
    existing_sheets <- readxl::excel_sheets(path)
    
    if (sheet_name %in% existing_sheets) {
      old <- readxl::read_excel(path, sheet = sheet_name)
      old <- as.data.frame(old, stringsAsFactors = FALSE)
      
      if (!("var_name" %in% names(old)) || !("value" %in% names(old))) {
        stop("既存シートに 'var_name' または 'value' 列がありません。")
      }
      
      old$var_name <- as.character(old$var_name)
      old$value <- normalize_key_value(old$value)
      if ("dataset" %in% names(old)) old$dataset <- NULL
      
      df <- add_missing_cols_from_prototype(df, old)
      
      all_cols <- union(names(old), names(df))
      
      for (cc in setdiff(all_cols, names(old))) {
        old[[cc]] <- rep(make_default_value(df[[cc]], cc), nrow(old))
      }
      for (cc in setdiff(all_cols, names(df))) {
        df[[cc]] <- rep(make_default_value(old[[cc]], cc), nrow(df))
      }
      
      old <- old[, all_cols, drop = FALSE]
      df  <- df[,  all_cols, drop = FALSE]
      
      common_cols <- intersect(names(df), names(old))
      common_cols <- setdiff(common_cols, c("var_name", "value"))
      
      keep_row <- rep(TRUE, nrow(df))
      
      for (i in seq_len(nrow(df))) {
        bad_cols <- character(0)
        
        for (cc in common_cols) {
          new_val <- df[[cc]][i]
          if (length(new_val) == 0 || is.na(new_val)) next
          
          if (!same_r_type(new_val, old[[cc]])) {
            bad_cols <- c(bad_cols, cc)
          }
        }
        
        if (length(bad_cols) > 0) {
          keep_row[i] <- FALSE
          warning(
            sprintf(
              "行 %d は既存シートと型不一致の列 (%s) があるためスキップしました。key = [%s / %s]",
              i,
              paste(bad_cols, collapse = ", "),
              df$var_name[i],
              df$value[i]
            )
          )
        }
      }
      
      df_valid <- df[keep_row, , drop = FALSE]
      
      key_old <- paste(old$var_name, old$value, sep = "\r")
      key_new <- paste(df_valid$var_name, df_valid$value, sep = "\r")
      
      if (overwrite_policy == "prefer_new") {
        old_keep <- old[!(key_old %in% key_new), , drop = FALSE]
        dict_out <- rbind(old_keep, df_valid)
      } else {
        new_keep <- df_valid[!(key_new %in% key_old), , drop = FALSE]
        dict_out <- rbind(old, new_keep)
      }
      
      dict_out <- align_col_order(dict_out, all_cols)
      
      all_sheets <- lapply(existing_sheets, function(s) {
        if (s == sheet_name) {
          dict_out
        } else {
          readxl::read_excel(path, sheet = s)
        }
      })
      names(all_sheets) <- existing_sheets
      
      writexl::write_xlsx(all_sheets, path)
    } else {
      dict_out <- df
      all_sheets <- lapply(existing_sheets, function(s) readxl::read_excel(path, sheet = s))
      names(all_sheets) <- existing_sheets
      all_sheets[[sheet_name]] <- dict_out
      writexl::write_xlsx(all_sheets, path)
    }
  } else {
    dict_out <- df
    writexl::write_xlsx(stats::setNames(list(dict_out), sheet_name), path)
  }
  
  invisible(dict_out)
}
