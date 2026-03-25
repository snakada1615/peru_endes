library(dplyr)
library(purrr)
library(tidyr)
library(writexl)
library(readxl)
library(labelled)


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
#' | dataset | var_name | var_label | value | value_label |
#' |---------|----------|-----------|-------|-------------|
#' | ...     | ...      | ...       | ...   | ...         |
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
  
  # 変数ラベル: var_label(df) は named list なので、unlist して named chr に
  vlab <- labelled::var_label(df, unlist = TRUE)  # named character ベクトル
  
  var_part <- tibble(
    dataset    = dataset_name,
    var_name   = vars,
    var_label  = unname(vlab[vars]),
    value      = NA_character_,
    value_label = NA_character_
  )
  
  # 値ラベル: val_labels() は haven_labelled に対して named vector を返す
  value_part <- purrr::map_dfr(vars, function(v) {
    x <- df[[v]]
    lab_vals <- labelled::val_labels(x)
    if (is.null(lab_vals) || length(lab_vals) == 0) return(NULL)
    
    tibble(
      dataset     = dataset_name,
      var_name    = v,
      var_label   = unname(vlab[[v]] %||% NA_character_),
      value       = as.character(unname(lab_vals)),
      value_label = names(lab_vals)
    )
  })
  
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
      value_label_new = as.character(value_label_new)
    )
    
  if (overwrite_policy == "prefer_new") {
    out <- full %>%
      transmute(
        dataset,
        var_name,
        value,
        var_label   = coalesce(var_label_new, var_label_old),
        value_label = coalesce(value_label_new, value_label_old)
      )
  } else {
    out <- full %>%
      transmute(
        dataset,
        var_name,
        value,
        var_label   = coalesce(var_label_old, var_label_new),
        value_label = coalesce(value_label_old, value_label_new)
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
strip_all_labels <- function(df,
                             user_na_to_na = TRUE) {
  df %>%
    # labelled::remove_labels() は df 全体に対して、
    # 変数ラベル・値ラベル・ユーザー定義欠損をまとめて削除できる [web:70][web:80]
    labelled::remove_labels(user_na_to_na = user_na_to_na)
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
strip_value_labels_only <- function(df,
                                    user_na_to_na = TRUE) {
  df %>%
    # 値ラベルとユーザー欠損だけ削除し、変数ラベルは保持 [web:70][web:61]
    labelled::remove_val_labels() %>%
    labelled::remove_user_na(user_na_to_na = user_na_to_na)
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
  
  # 辞書を読み込み
  dict <- readxl::read_excel(path, sheet = sheet_name) %>%
    mutate(
      dataset    = as.character(dataset),
      var_name   = as.character(var_name),
      var_label  = as.character(var_label),
      value      = as.character(value),
      value_label = as.character(value_label)
    ) %>%
    filter(dataset == dataset_name)
  
  # 変数ラベル部分（value が NA の行）
  var_info <- dict %>%
    filter(is.na(value) | value %in% c("NA", "")) %>%
    select(var_name, var_label) %>%
    distinct()
  
  # 値ラベル部分（value が NA でない行）
  value_info <- dict %>%
    filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    select(var_name, value, value_label)
  
  # 1) 変数ラベルの適用
  if (nrow(var_info) > 0) {
    # 既存の変数ラベルを取得
    existing_vlab <- labelled::var_label(df, unlist = TRUE)
    
    for (i in seq_len(nrow(var_info))) {
      v   <- var_info$var_name[i]
      lab <- var_info$var_label[i]
      
      if (!v %in% names(df) || is.na(lab) || lab == "") next
      
      if (overwrite_policy == "prefer_excel") {
        # Excel のラベルを優先
        labelled::var_label(df[[v]]) <- lab
      } else {
        # 既存ラベルが無い場合のみ Excel のラベルを適用
        if (is.null(existing_vlab[[v]]) || is.na(existing_vlab[[v]]) || existing_vlab[[v]] == "") {
          labelled::var_label(df[[v]]) <- lab
        }
      }
    }
  }
  
  # 2) 値ラベルの適用
  if (nrow(value_info) > 0) {
    for (v in unique(value_info$var_name)) {
      if (!v %in% names(df)) next
      
      sub <- value_info %>%
        filter(var_name == v)
      
      # Excel からの新しいラベル定義
      new_vals  <- suppressWarnings(as.numeric(sub$value))
      # 数値に変換できなければ、そのまま文字列として扱う（文字列コード対応）
      if (any(is.na(new_vals) & !is.na(sub$value))) {
        # 文字列コード
        new_vals <- sub$value
      }
      
      new_labs <- sub$value_label
      names(new_labs) <- new_vals
      
      # 既存ラベルを取得
      old_labs <- labelled::val_labels(df[[v]])
      
      if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
        # Excel 側を優先して全面上書き
        labelled::val_labels(df[[v]]) <- new_labs
      } else {
        # 既存を優先しつつ、Excel にしかないコードを追加
        add_codes <- setdiff(names(new_labs), names(old_labs))
        merged <- c(old_labs, new_labs[add_codes])
        labelled::val_labels(df[[v]]) <- merged
      }
    }
  }
  
  df
}
# -----関数ここまで------------------------------------------------------------
###############################################################################
#' @title apply_labels_from_label_final
#' @description
#' 指定された Excel ファイルの label_final シートから、データフレ
#' ームに変数ラベルと値ラベルを適用する関数。上書きポリシーを指定して、既存のラベルとExcelのラベルのどちらを優先するかを制御できます。label_final シートは、dataset 列がない前提で、var_name, var_label, value, value_label の列を持つ形式である必要があります。
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
  
  # 辞書を読み込み（dataset 列は無い前提）
  dict <- readxl::read_excel(path, sheet = sheet_name) %>%
    dplyr::mutate(
      var_name    = as.character(var_name),
      var_label   = as.character(var_label),
      value       = as.character(value),
      value_label = as.character(value_label)
    )
  
  # 変数ラベル部分（value が NA / "NA" / 空 の行）
  var_info <- dict %>%
    dplyr::filter(is.na(value) | value %in% c("NA", "")) %>%
    dplyr::select(var_name, var_label) %>%
    dplyr::distinct()
  
  # 値ラベル部分（value が有効な行）
  value_info <- dict %>%
    dplyr::filter(!(is.na(value) | value %in% c("NA", ""))) %>%
    dplyr::select(var_name, value, value_label)
  
  # 1) 変数ラベルの適用
  if (nrow(var_info) > 0) {
    existing_vlab <- labelled::var_label(df, unlist = TRUE)
    
    for (i in seq_len(nrow(var_info))) {
      v   <- var_info$var_name[i]
      lab <- var_info$var_label[i]
      
      if (!v %in% names(df) || is.na(lab) || lab == "") next
      
      if (overwrite_policy == "prefer_excel") {
        labelled::var_label(df[[v]]) <- lab
      } else {
        if (is.null(existing_vlab[[v]]) || is.na(existing_vlab[[v]]) || existing_vlab[[v]] == "") {
          labelled::var_label(df[[v]]) <- lab
        }
      }
    }
  }
  
  # 2) 値ラベルの適用
  if (nrow(value_info) > 0) {
    for (v in unique(value_info$var_name)) {
      if (!v %in% names(df)) next
      
      x <- df[[v]]
      
      # ★ logical は値ラベル不要なのでスキップ
      if (is.logical(x)) next
      
      # factor の処理
      if (is.factor(x)) {
        x <- as.character(x)
        df[[v]] <- x
      }
      
      sub <- value_info %>%
        dplyr::filter(var_name == v)
      
      if (is.numeric(x) || is.integer(x)) {
        new_vals <- suppressWarnings(as.numeric(sub$value))
      } else {
        new_vals <- as.character(sub$value)
      }
      
      keep <- !is.na(new_vals)
      if (!any(keep)) next
      
      new_vals  <- new_vals[keep]           # numeric vector
      new_labs  <- sub$value_label[keep]    # character vector（ラベル文字列）
      # val_labels は c(ラベル名 = コード値) の形式が期待される
      # → setNames(コード値ベクタ, ラベル文字列) で作る
      new_labs <- setNames(new_vals, new_labs)
      
      old_labs <- labelled::val_labels(df[[v]])
      
      if (overwrite_policy == "prefer_excel" || is.null(old_labs) || length(old_labs) == 0) {
        labelled::val_labels(df[[v]]) <- new_labs
      } else {
        add_codes <- setdiff(names(new_labs), names(old_labs))
        merged <- c(old_labs, new_labs[add_codes])
        labelled::val_labels(df[[v]]) <- merged
      }
    }
  }
  df
}
# -----関数ここまで------------------------------------------------------------

