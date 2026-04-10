library(dplyr)
library(purrr)
library(tidyr)
library(writexl)
library(readxl)
library(haven)


### 関数名一覧 ##############
#' @title make_label_dict
#' @description
#' データフレームから、変数名、変数ラベル、値ラベルを抽出して、dataset-varname-varlabel-value-valuelabel 形式のデータフレームを作成する関数。
#' @title merge_label_dicts
#' @description
#' 既存のラベル辞書と新規のラベル辞書をマージする関数。上書きポリシーを指定して、どちらのラベルを優先するかを制御できます。
#' @title export_labels_to_excel
#' @description
#' データフレームから抽出したラベル辞書を、指定されたExcelファイルの label_extract シートに書き出す関数。既存のシートがある場合は、上書きポリシーに従ってマージします。
#' @title strip_all_labels
#' @description
#' データフレームから、変数ラベル、値ラベル、ユーザー定義の欠損値をすべて削除する関数。haven_labelled 形式のラベルも対応。
#' @title strip_value_labels_only
#' @description
#' データフレームから、値ラベルとユーザー定義の欠損値を削除し、変数ラベルは保持する関数。haven_labelled 形式のラベルも対応。
#' @title apply_labels_from_excel
#' @description
#' 指定されたExcelファイルの label_extract シートから、データフレームに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。
#' @title apply_labels_from_label_final
#' @description
#' 指定されたExcelファイルの label_final シートから、データフレームに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。label_final シートは、dataset 列がない前提で、var_name と var_label のみを含む形式であることを想定しています。
#' ----------------------------------------------------------------------------

# df から dataset-varname-varlabel-value-valuelabel 形式の辞書を作る（SPSSラベル対応版）
#########################################################################
#' @title make_label_dict
#' @description
#' データフレームから、変数名、変数ラベル、値
#' ラベルを抽出して、以下の形式のデータフレームを作成する関数。
#' dataset | var_name | var_label | value | value_label | is_logical | is_character | is_numeric | is_factor | factor_levels | yes_value | no_value
#' @param df データフレーム
#' @param dataset_name データセット名（文字列）
#' @param vars 変数名のベクトル（NULLの場合は全変
#' 数を対象）
#' @return dataset-varname-varlabel-value-valuelabel 形式のデータフ
#' ーム
#' @details
#' - SPSSのラベル（haven_labelled）に対応するため、変
#' 数ラベルは var_label() から、値ラベルは val_labels() から抽出します。
#' - 変数ラベルは変数ごとに1行、値ラベルは変数ごとに値の数だけ行が追加されます。
#' - 既存の辞書とマージする際の上書きポリシーは、merge_label_dicts() 関数で制御します。
#' ------------------------------------------------------------------------
#########################################################################
make_label_dict <- function(df, dataset_name, vars = NULL) {
  if (is.null(vars)) vars <- names(df)
  
  yesno_level <- function(v){
    yes_vars <- c("Yes", "yes", "Sí", "si")
    no_vars  <- c("No", "no")
    res <- list(yes_var = NA_character_, no_var = NA_character_)
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
    res
  }
  
  validate_labels <- function(x, label_name = deparse(substitute(x))) {
    if (all(is.na(unlist(x, use.names = FALSE)))) {
      stop(sprintf("ラベル '%s' が全て NA です。処理を中止します。", label_name))
    }
    invisible(x)
  }
  
  # haven::var_label は named list を返す
  vlab_list <- haven::var_label(df)
  vlab_chr  <- vapply(vlab_list, function(x) if (is.null(x)) NA_character_ else as.character(x),
                      FUN.VALUE = character(1))
  
  validate_labels(vlab_chr, "変数ラベル")
  
  var_part <- tibble(
    dataset      = dataset_name,
    var_name     = vars,
    var_label    = unname(vlab_chr[vars]),
    value        = NA_character_,
    value_label  = NA_character_,
    is_logical   = purrr::map_lgl(vars, ~ is.logical(df[[.x]])),
    is_character = purrr::map_lgl(vars, ~ is.character(df[[.x]])),
    is_numeric   = purrr::map_lgl(vars, ~ is.numeric(df[[.x]])),
    is_factor    = purrr::map_lgl(vars, ~ is.factor(df[[.x]])),
    factor_levels = purrr::map_int(vars, ~ {
      x <- df[[.x]]
      if (is.factor(x)) length(na.omit(unique(x))) else NA_integer_
    }),
    yes_value    = NA_character_,
    no_value     = NA_character_
  )
  
  value_part <- purrr::map_dfr(vars, function(v) {
    x <- df[[v]]
    lab_vals <- attr(x, "labels", exact = TRUE)
    
    if (is.null(lab_vals) || length(lab_vals) == 0) return(NULL)
    
    tibble(
      dataset      = dataset_name,
      var_name     = v,
      var_label    = vlab_chr[[v]] %||% NA_character_,
      value        = as.character(unname(lab_vals)),
      value_label  = names(lab_vals),
      is_logical   = is.logical(x),
      is_character = is.character(x),
      is_numeric   = is.numeric(x),
      is_factor    = is.factor(x),
      factor_levels = if (is.factor(x)) length(na.omit(unique(x))) else NA_integer_,
      yes_value    = if (is.factor(x) && length(na.omit(unique(x))) == 2)
        yesno_level(levels(x))$yes_var else NA_character_,
      no_value     = if (is.factor(x) && length(na.omit(unique(x))) == 2)
        yesno_level(levels(x))$no_var else NA_character_
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
  
  bind_rows(var_part, value_part) %>%
    arrange(dataset, var_name, value)
}
# ------関数ここまで------------------------------------------------------------

# 既存辞書と新規辞書をマージ（上書きポリシー付き）
#########################################################################
#' @title merge_label_dicts
#' @description
#' 既存のラベル辞書と新規のラベル辞書を
#' マージする関数。上書きポリシーを指定して、どちらのラベルを優先するかを制御できます。
#' @param old 既存のラベル辞書（データフレーム
#' dataset-var_name-var_label-value-value_label 形式）
#' @param new 新規のラベル辞書（同上）
#' @param overwrite_policy 上書きポリシー（"prefer_new" また
#' は "prefer_old"）
#' @return マージされたラベル辞書（同上）
#' @details
#' - 上書きポリシー "prefer_new" は、新規辞書
#' のラベルを優先し、既存辞書のラベルは新規にない場合のみ使用します。
#' - 上書きポリシー "prefer_old" は、既存辞
#' 書のラベルを優先し、新規辞書のラベルは既存にない場合のみ使用します。
#' - マージは dataset, var_name, value の組み合わせで行い
#' ます。両方の辞書に同じ組み合わせがある場合は、上書きポリシーに従ってラベルを選択します。
#' ------------------------------------------------------------------------
merge_label_dicts <- function(old, new, overwrite_policy = c("prefer_new", "prefer_old")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  key_cols <- c("dataset", "var_name", "value")
  
  full <- full_join(old, new,
                    by = key_cols,
                    suffix = c("_old", "_new"))

  # ★ 型をそろえる：必ず character にしてから coalesce
  full <- full %>%
    dplyr::mutate(
      var_label_old   = as.character(var_label_old),
      var_label_new   = as.character(var_label_new),
      value_label_old = as.character(value_label_old),
      value_label_new = as.character(value_label_new),
      is_logical_old  = as.logical(is_logical_old),
      is_logical_new  = as.logical(is_logical_new),
      is_character_old = as.logical(is_character_old),
      is_character_new = as.logical(is_character_new),
      is_numeric_old = as.logical(is_numeric_old),
      is_numeric_new = as.logical(is_numeric_new),
      is_factor_old = as.logical(is_factor_old),
      is_factor_new = as.logical(is_factor_new),
      factor_levels_old = as.numeric(factor_levels_old),
      factor_levels_new = as.numeric(factor_levels_new),
      yes_value_old = as.character(yes_value_old),
      yes_value_new = as.character(yes_value_new),
      no_value_old = as.character(no_value_old),
      no_value_new = as.character(no_value_new)
    )
    
  if (overwrite_policy == "prefer_new") {
    out <- full %>%
      transmute(
        dataset,
        var_name,
        value,
        var_label   = coalesce(var_label_new, var_label_old),
        value_label = coalesce(value_label_new, value_label_old),
        is_logical  = coalesce(is_logical_new, is_logical_old),
        is_character = coalesce(is_character_new, is_character_old),
        is_numeric = coalesce(is_numeric_new, is_numeric_old),
        is_factor = coalesce(is_factor_new, is_factor_old),
        factor_levels = coalesce(factor_levels_new, factor_levels_old),
        yes_value = coalesce(yes_value_new, yes_value_old),
        no_value = coalesce(no_value_new, no_value_old)
      )
  } else {
    out <- full %>%
      transmute(
        dataset,
        var_name,
        value,
        var_label   = coalesce(var_label_old, var_label_new),
        value_label = coalesce(value_label_old, value_label_new),
        is_logical  = coalesce(is_logical_old, is_logical_new),
        is_character = coalesce(is_character_old, is_character_new),
        is_numeric = coalesce(is_numeric_old, is_numeric_new),
        is_factor = coalesce(is_factor_old, is_factor_new),
        factor_levels = coalesce(factor_levels_old, factor_levels_new),
        yes_value = coalesce(yes_value_old, yes_value_new),
        no_value = coalesce(no_value_old, no_value_new)
      )
  }
  
  out %>%
    arrange(dataset, var_name, value)
}
# ----関数ここまで------------------------------------------------------------


# Excel の label_extract シートにラベル辞書を書き出す
#######################################################################
#' @title export_labels_to_excel
#' @description
#' データフレームから抽出したラベル辞書を、指定された
#' Excel ファイルの label_extract シートに書き出す関数。既存のシートがある場合は、上書きポリシーに従ってマージします。
#' @param df データフレーム
#' @param dataset_name データセット名（文字列）
#' @param path Excel ファイルのパス
#' @param sheet_name 書き出すシート名（デフォルトは
#' "label_extract"）
#' @param vars 変数名のベクトル（NULLの場合は全変
#' 数を対象）
#' @param overwrite_policy 上書きポリシー（"prefer_new" また
#' は "prefer_old"）
#' @return 書き出されたラベル辞書のデータフレーム
#' @details
#' - 既存の Excel ファイルが存在する場合、指定されたシート
#' があるかを確認します。シートがある場合は、既存の辞書を読み込み、新規の辞書とマージします。シートがない場合は、新規の辞書をそのまま使用します。
#' - 既存の他のシートは保持され、label_extract シート
#' のみが上書きまたは追加されます。
#' - Excel ファイルが存在しない場合は、新規にファイルを作
#' 成し、label_extract シートに新規の辞書を書き出します。
#' ------------------------------------------------------------------------
#' # 基本的な使い方（全変数を抽出、既存データがあれば新規優先で上書き）
# export_labels_to_excel(
#   df = endes2012_raw,
#   dataset_name = "ENDES12",
#   path = "metadata/data_dictionary.xlsx"
# )
# 
# # 一部の変数だけ更新（既存ラベルを優先）
# export_labels_to_excel(
#   df = endes2012_raw,
#   dataset_name = "ENDES12",
#   path = "metadata/data_dictionary.xlsx",
#   vars = c("state", "sex", "wealth_quint"),
#   overwrite_policy = "prefer_old"
# )
# 
# # 別のデータセットを同じExcelファイルに追加
# export_labels_to_excel(
#   df = endes2015_raw,
#   dataset_name = "ENDES15",
#   path = "metadata/data_dictionary.xlsx"
# )
#' 
export_labels_to_excel <- function(df,
                                   dataset_name,
                                   path,
                                   sheet_name = "label_extract",
                                   vars = NULL,
                                   overwrite_policy = c("prefer_new", "prefer_old")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  # 新規辞書を作成
    dict_new <- make_label_dict(df, dataset_name, vars)
  
  # 既存 Excel ファイルがある場合
  if (file.exists(path)) {
    # 既存シートを読み込み（エラー時は新規作成）
    existing_sheets <- excel_sheets(path)
    
    if (sheet_name %in% existing_sheets) {
      old <- read_excel(path, sheet = sheet_name)
      dict_out <- merge_label_dicts(old, dict_new, overwrite_policy)
    } else {
      # シートが存在しない場合は新規作成
      dict_out <- dict_new
    }
    
    # 既存の他シートを保持しつつ、label_extract シートを上書き
    all_sheets <- lapply(existing_sheets, function(s) {
      if (s == sheet_name) {
        dict_out
      } else {
        read_excel(path, sheet = s)
      }
    })
    names(all_sheets) <- existing_sheets
    
    # label_extract が新規の場合は追加
    if (!sheet_name %in% existing_sheets) {
      all_sheets[[sheet_name]] <- dict_out
    }
    
    write_xlsx(all_sheets, path)
    
  } else {
    # ファイル自体が存在しない場合は新規作成
    dict_out <- dict_new
    write_xlsx(setNames(list(dict_out), sheet_name), path)
  }
  
  invisible(dict_out)
}
# ----関数ここまで------------------------------------------------------------

# DHSデータのラベルを削除する関数セット
########################################################################
#' @title strip_all_labels
#' @description
#' データフレームから、変数ラベル、値ラベル、ユー
#' ザー定義の欠損値をすべて削除する関数。haven_labelled 形式のラベルも対応。
#' @param df データフレーム
#' @param user_na_to_na ユーザー定義の欠損値
#' をNAに変換するかどうか（デフォルトは TRUE）。TRUE の場合、ユーザー定義の欠損値は NA に置き換えられます。FALSE の場合、ユーザー定義の欠損値はそのまま残ります。
#' @return ラベルが削除されたデータフレーム
#' @details
#' - labelled::remove_labels() 関数を使用して、変数ラベル、値ラベル、ユーザー定義の欠損値をまとめて削除します。user_na_to_na 引数で、ユーザー定義の欠損値を NA に変換するかどうかを制御できます。
#' - この関数は、DHSデータのような haven_labelled
#' 形式のデータフレームに対して、ラベルを完全に削除するために使用されます。必要に応じて、ユーザー定義の欠損値を NA に変換するオプションも提供しています。
#' -----------------------------------------------------------------------
# 1. 変数ラベル・値ラベル・ユーザー欠損をすべて削除
strip_all_labels <- function(df, user_na_to_na = TRUE) {
  df[] <- lapply(df, function(x) {
    # 値ラベル・変数ラベル・ユーザーNAを haven で削除
    x <- haven::zap_labels(x)
    x <- haven::zap_label(x)
    if (user_na_to_na) {
      x <- haven::zap_missing(x)
    }
    # SPSS 由来の属性も念のため削除
    attr(x, "format.spss")   <- NULL
    attr(x, "display_width") <- NULL
    # クラスから haven_labelled 等を外す
    cl <- class(x)
    cl <- setdiff(cl, c("haven_labelled", "labelled", "vctrs_vctr"))
    class(x) <- cl
    x
  })
  df
}
# ------関数ここまで------------------------------------------------------------
########################################################################
#' @title strip_value_labels_only
#' @description
#' データフレームから、値ラベルとユーザー定義の欠
#' 損値を削除し、変数ラベルは保持する関数。haven_labelled 形式のラベルも対応。
#' @param df データフレーム
#' @param user_na_to_na ユーザー定義の欠損値
#' をNAに変換するかどうか（デフォルトは TRUE）。TRUE の場合、ユーザー定義の欠損値は NA に置き換えられます。FALSE の場合、ユーザー定義の欠損値はそのまま残ります。
#' @return 値ラベルとユーザー定義の欠損値が
#' 削除されたデータフレーム（変数ラベルは保持）
#' @details
#' - labelled::remove_val_labels() 関数を使用して、値ラベル
#' を削除し、labelled::remove_user_na() 関数を使用して、ユーザー定義の欠損値を削除します。user_na_to_na 引数で、ユーザー定義の欠損値を NA に変換するかどうかを制御できます。
#' - この関数は、変数ラベルを保持しつつ、値
#' ラベルとユーザー定義の欠損値を削除したい場合に使用されます。DHSデータのような haven_labelled 形式のデータフレームに対して、必要なラベルだけを削除するために便利です。
#' -----------------------------------------------------------------------
# 2. 「変数ラベルだけ残して、値ラベルとユーザー欠損だけ削除」版
strip_value_labels_only <- function(df, user_na_to_na = TRUE) {
  df[] <- lapply(df, function(x) {
    x <- haven::zap_labels(x)   # 値ラベルだけ削除
    if (user_na_to_na) {
      x <- haven::zap_missing(x)
    }
    x
  })
  df
}

# -----関数ここまで------------------------------------------------------------

# Excel (label_extract) からラベルを df に適用
#######################################################################
#' @title apply_labels_from_excel
#' @description
#' 指定された Excel ファイルの label_extract シートから、データフレ
#' ムに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。
#' @param df データフレーム
#' @param dataset_name データセット名（文字列）
#' @param path Excel ファイルのパス
#' @param sheet_name 読み込むシート名（デフォルトは
#' "label_extract"）
#' @param overwrite_policy 上書きポリシー（"prefer_excel" また
#' は "prefer_df"）
#' @return ラベルが適用されたデータフレーム
#' @details
#' - Excel ファイルの label_extract シートから、指定されたデータセット名
#' に対応する行をフィルタリングして、変数ラベルと値ラベルの情報を抽出します。
#' - 変数ラベルは、value が NA の行から抽出され
#' ます。値ラベルは、value が NA でない行から抽出されます。
#' - 上書きポリシー "prefer_excel" は、Excel のラ
#' ベルを優先して、データフレームの既存のラベルを上書きします。上書きポリシー "prefer_df" は、データフレームの既存のラベルを優先し、Excel のラベルは既存にない場合のみ適用します。
#' - 変数ラベルと値ラベルの適用は、データ
#' フレームの変数名と Excel の var_name を照合して行います。Excel に存在しない変数や、データフレームに存在しない変数は無視されます。
#' ------------------------------------------------------------------------
apply_labels_from_excel <- function(df,
                                    dataset_name,
                                    path,
                                    sheet_name = "label_extract",
                                    overwrite_policy = c("prefer_excel", "prefer_df")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  dict <- readxl::read_excel(path, sheet = sheet_name) %>%
    mutate(
      dataset    = as.character(dataset),
      var_name   = as.character(var_name),
      var_label  = as.character(var_label),
      value      = as.character(value),
      value_label = as.character(value_label)
    ) %>%
    filter(dataset == dataset_name)
  
  var_info <- dict %>%
    filter(is.na(value) | value %in% c("NA", "")) %>%
    select(var_name, var_label) %>%
    distinct()
  
  value_info <- dict %>%
    filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    select(var_name, value, value_label)
  
  # 1) 変数ラベル
  if (nrow(var_info) > 0) {
    existing_vlab_list <- haven::var_label(df)
    existing_vlab <- vapply(existing_vlab_list,
                            function(x) if (is.null(x)) NA_character_ else as.character(x),
                            FUN.VALUE = character(1))
    
    for (i in seq_len(nrow(var_info))) {
      v   <- var_info$var_name[i]
      lab <- var_info$var_label[i]
      
      if (!v %in% names(df) || is.na(lab) || lab == "") next
      
      if (overwrite_policy == "prefer_excel") {
        haven::var_label(df[[v]]) <- lab
      } else {
        if (is.na(existing_vlab[[v]]) || existing_vlab[[v]] == "") {
          haven::var_label(df[[v]]) <- lab
        }
      }
    }
  }
  
  # 2) 値ラベル
  if (nrow(value_info) > 0) {
    for (v in unique(value_info$var_name)) {
      if (!v %in% names(df)) next
      
      sub <- value_info %>% filter(var_name == v)
      x <- df[[v]]
      
      new_vals_num <- suppressWarnings(as.numeric(sub$value))
      if (any(is.na(new_vals_num) & !is.na(sub$value))) {
        new_vals <- sub$value             # 文字列コード
      } else {
        new_vals <- new_vals_num          # 数値コード
      }
      
      new_labs <- sub$value_label
      names(new_labs) <- new_vals        # names: コード, 値: ラベル文字列でもよいが、here: names=コード
      
      old_labs <- attr(x, "labels", exact = TRUE)
      
      if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
        attr(df[[v]], "labels") <- new_labs
        if (!inherits(df[[v]], "haven_labelled")) {
          class(df[[v]]) <- c("haven_labelled", class(df[[v]]))
        }
      } else {
        add_codes <- setdiff(names(new_labs), names(old_labs))
        merged <- c(old_labs, new_labs[add_codes])
        attr(df[[v]], "labels") <- merged
        if (!inherits(df[[v]], "haven_labelled")) {
          class(df[[v]]) <- c("haven_labelled", class(df[[v]]))
        }
      }
    }
  }
  
  df
}
# -----関数ここまで------------------------------------------------------------
###############################################################################
#' @title apply_labels_from_label_final
#' @description
#' 指定された Excel ファイルの label_final シートから、データフレームに
#' 変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、
#' 既存のラベルとExcelのラベルのどちらを優先するかを制御できます。
#' label_final シートは、dataset 列がない前提で、var_name, 
#' var_label, value, value_label の列を持つ形式である必要があります。
#' @param df データフレーム
#' @param path Excel ファイルのパス
#' @param sheet_name 読み込むシート名（デフォルトは
#' "label_final"）
#' @param overwrite_policy 上書きポリシー（"prefer_excel" また
#' は "prefer_df"）
#' @return ラベルが適用されたデータフレーム
#' @details
#' - Excel ファイルの label_final シートから、変数ラベルと値
#' ラベルの情報を抽出します。label_final シートは、dataset 列がない前提で、var_name, var_label, value, value_label の列を持つ形式である必要があります。
#' - 変数ラベルは、value が NA / "NA" / 空
#' の行から抽出されます。値ラベルは、value が NA でない行から抽出されます。
#' - 上書きポリシー "prefer_excel" は、Excel のラ
#' ベルを優先して、データフレームの既存のラベルを上書きします。上書きポリシー "prefer_df" は、データフレームの既存のラベルを優先し、Excel のラベルは既存にない場合のみ適用します。
#' - 変数ラベルと値ラベルの適用は、データ
#' フレームの変数名と Excel の var_name を照合して行います。Excel に存在しない変数や、データフレームに存在しない変数は無視されます。
#' ------------------------------------------------------------------------
apply_labels_from_label_final <- function(df,
                                          path,
                                          sheet_name = "label_final",
                                          overwrite_policy = c("prefer_excel", "prefer_df")) {
  overwrite_policy <- match.arg(overwrite_policy)
  
  dict <- readxl::read_excel(path, sheet = sheet_name) %>%
    dplyr::mutate(
      var_name    = as.character(var_name),
      var_label   = as.character(var_label),
      value       = as.character(value),
      value_label = as.character(value_label)
    )
  
  var_info <- dict %>%
    dplyr::filter(is.na(value) | value %in% c("NA", "")) %>%
    dplyr::select(var_name, var_label) %>%
    dplyr::distinct()
  
  value_info <- dict %>%
    dplyr::filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    dplyr::select(var_name, value, value_label)
  
  # 1) 変数ラベル
  if (nrow(var_info) > 0) {
    existing_vlab_list <- haven::var_label(df)
    existing_vlab <- vapply(existing_vlab_list,
                            function(x) if (is.null(x)) NA_character_ else as.character(x),
                            FUN.VALUE = character(1))
    
    for (i in seq_len(nrow(var_info))) {
      v   <- var_info$var_name[i]
      lab <- var_info$var_label[i]
      
      if (!v %in% names(df) || is.na(lab) || lab == "") next
      
      if (overwrite_policy == "prefer_excel") {
        haven::var_label(df[[v]]) <- lab
      } else {
        if (is.na(existing_vlab[[v]]) || existing_vlab[[v]] == "") {
          haven::var_label(df[[v]]) <- lab
        }
      }
    }
  }
  
  # 2) 値ラベル
  if (nrow(value_info) > 0) {
    for (v in unique(value_info$var_name)) {
      if (!v %in% names(df)) next
      
      x <- df[[v]]
      if (is.logical(x)) next        # logical はスキップ
      
      if (is.factor(x)) {
        x <- as.character(x)
        df[[v]] <- x
      }
      
      sub <- value_info %>% dplyr::filter(var_name == v)
      
      if (is.numeric(x) || is.integer(x)) {
        new_vals <- suppressWarnings(as.numeric(sub$value))
      } else {
        new_vals <- as.character(sub$value)
      }
      
      keep <- !is.na(new_vals)
      if (!any(keep)) next
      
      new_vals <- new_vals[keep]
      new_labs_chr <- sub$value_label[keep]
      
      new_labs <- setNames(new_vals, new_labs_chr)
      
      old_labs <- attr(df[[v]], "labels", exact = TRUE)
      
      if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
        attr(df[[v]], "labels") <- new_labs
      } else {
        add_codes <- setdiff(names(new_labs), names(old_labs))
        merged <- c(old_labs, new_labs[add_codes])
        attr(df[[v]], "labels") <- merged
      }
      
      if (!inherits(df[[v]], "haven_labelled")) {
        class(df[[v]]) <- c("haven_labelled", class(df[[v]]))
      }
    }
  }
  
  df
}
# -----関数ここまで------------------------------------------------------------
