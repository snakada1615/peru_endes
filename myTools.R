
# myTools.R

# required libraries for this script
library(haven)
library(openxlsx)
library(stringr)
library(dplyr)
library(psych) # for describe function


#' @title Hello World 関数
hello <- function() {
  message("Hello, World!")
}

# ******************************************************************************
#' データフレームから変数ラベルを抽出する関数
#'
#' Stataの .dta ファイルなどを haven::read_dta() で読み込んだ際に
#' 各変数に付与された "label" 属性を抽出し、
#' 変数名とラベル対応の一覧データフレームを返します。
#'
#' @title getLabelfromDTA：
#' @param df データフレーム形式のデータセット
#' @return 変数名 ("variable") と 変数ラベル ("label") の対応表（data.frame）
#'
#' @examples
#' # attr(sample_df$age, "label") <- "年齢" のようにラベルが設定されていれば、抽出されます。
#' getLabelfromDTA(sample_df)
# ******************************************************************************

getLabelfromDF <- function(df) {
  # 入力チェック: データフレームでない場合はエラーを出す
  if (!is.data.frame(df)) {
    stop("入力は data.frame クラスである必要があります。")
  }
  
  # 各変数（列）に対して "label" 属性を取得し、リストに格納
  label_vec <- sapply(seq_along(df), function(i) {
    x <- df[[i]]                 # 列を取り出す
    var_name <- names(df)[i]     # 列名
    
    lbl <- attr(x, "label")      # "label" 属性の取得
    
    if (is.null(lbl)) {
      # ラベルが存在しなければ NA
      return(NA_character_)
    } else if (length(lbl) > 1) {
      # 複数ラベル（想定外）の場合は警告し、最初のものだけ使う
      warning(sprintf("変数 '%s' に複数のラベルが存在します。最初の1つのみを使用します。", var_name))
      return(as.character(lbl[1]))
    } else {
      # 正常に1つのラベルがある場合
      return(as.character(lbl))
    }
  })
  
  # 名前（変数名）と結果ベクトルをデータフレームに整形
  label_df <- data.frame(
    variable = names(df),     # 列名（変数名）
    label = label_vec,        # 抽出されたラベル
    stringsAsFactors = FALSE  # 文字列を factor に変換しない
  )
  
  # 結果のデータフレームを返却
  return(label_df)
}
# --- 関数定義ここまで ---

# ******************************************************************************
#' @title draw_tree：ディレクトリツリーの描画 (内部補助関数)
#' @description 指定されたディレクトリ以下のファイルやサブディレクトリの階層構造を、
#'              ツリー形式でコンソールに再帰的に描画します。
#'              この関数は通常、直接呼び出すのではなく、より上位の関数 (`print_directory_tree`など)
#'              によって内部的に使用されることを想定しています。
#'
#' @param path (character) ツリーを描画する現在のディレクトリのパス。
#' @param prefix (character) ツリーの各行の前に付加されるインデントとツリーの線を表す文字列。
#'   再帰呼び出し時に内部的に使用されます。デフォルトは `""` (空文字列)。
#' @param is_last (logical) 現在のディレクトリが親ディレクトリの最後のエントリであるかどうかを示す論理値。
#'   ツリーの描画線 (`├──` または `└──`) を決定するために内部的に使用されます。デフォルトは `TRUE`。
#' @param show_hidden (logical) 隠しファイルや隠しディレクトリ (`.`で始まるファイル/ディレクトリ) を表示するかどうか。
#'   デフォルトは `FALSE`。
#' @return (NULL) ディレクトリツリーをコンソールに出力し、明示的な値は返しません。
#'
#' @details
#'   この関数は再帰的に呼び出され、指定されたディレクトリの内容を走査し、
#'   適切なインデントとツリーの線を使用してファイルやサブディレクトリを表示します。
#'   隠しファイルやディレクトリの表示は `show_hidden` パラメータで制御されます。
#'   ファイルのパーミッションやアクセス権によっては、一部のディレクトリにアクセスできない場合、
#'   エラーが発生する可能性があります。
#'
#' @examples
#' # この関数は通常、直接呼び出すのではなく、上位の関数によって使用されます。
#' # 例: `print_directory_tree(getwd(), show_hidden = TRUE)`
#' # もし単独でテストしたい場合は、以下のように一時ディレクトリを作成して試すことができます:
#' # temp_dir <- tempdir()
#' # dir.create(file.path(temp_dir, "test_dir", ".hidden_folder"), recursive = TRUE)
#' # file.create(file.path(temp_dir, "test_dir", "file1.txt"))
#' # file.create(file.path(temp_dir, "test_dir", ".hidden_file"))
#' # message("--- Test Tree ---")
#' # draw_tree(file.path(temp_dir, "test_dir"))
#' # message("--- Test Tree with hidden files ---")
#' # draw_tree(file.path(temp_dir, "test_dir"), show_hidden = TRUE)
#' # unlink(temp_dir, recursive = TRUE) # テストディレクトリをクリーンアップ
#'
#' @seealso \code{\link[base]{dir.exists}}, \code{\link[base]{list.files}}, \code{\link[base]{file.path}}
#' @noRd # この関数は内部補助関数であるため、外部にドキュメントを生成しないことを示します。
#'
draw_tree <- function(path, prefix = "", is_last = TRUE, show_hidden = FALSE, show_files = FALSE) {
  # パスが存在するかチェック
  if (!dir.exists(path)) {
    stop("指定されたディレクトリが存在しません: ", path)
  }
  
  # ディレクトリ内容を取得
  entries <- list.files(path, full.names = FALSE, all.files = show_hidden)
  
  # 隠しファイルを除外（show_hidden = FALSE の場合）
  if (!show_hidden) {
    entries <- entries[!grepl("^\\.", entries)]
  }
  
  # フルパス取得に使用
  full_paths <- file.path(path, entries)
  
  # show_files = FALSE の場合、ディレクトリのみ残す
  if (!show_files) {
    entries <- entries[dir.exists(full_paths)]
    full_paths <- full_paths[dir.exists(full_paths)]
  }
  
  # エントリをソート
  ordering <- order(entries)
  entries <- entries[ordering]
  full_paths <- full_paths[ordering]
  
  # ツリーの描画
  for (i in seq_along(entries)) {
    entry <- entries[i]
    full_path <- full_paths[i]
    is_last_entry <- (i == length(entries))
    
    # ツリー線とプレフィックスの決定
    tree_line <- if (is_last_entry) "└── " else "├── "
    next_prefix <- if (is_last_entry) paste0(prefix, "    ") else paste0(prefix, "│   ")
    
    cat(prefix, tree_line, entry, "\n", sep = "")
    
    # サブディレクトリがあれば再帰
    if (dir.exists(full_path)) {
      draw_tree(full_path, next_prefix, is_last_entry, show_hidden, show_files)
    }
  }
}

# --- 関数定義ここまで ---
# ******************************************************************************
#' @title check_vars：データフレーム内の変数の存在確認
#' 
#' @description 指定された変数名が、入力データフレーム（data.frame）内に
#' 存在するかどうかを順に確認し、結果を標準出力に表示します。
#'
#' @param data (data.frame) 対象のデータフレーム。確認対象となる変数が
#' 含まれているかどうかをチェックします。
#'
#' @param vars (character vector) 存在確認を行う変数名の文字ベクトル。
#' 各要素がデータフレーム内に存在するかどうかを個別に検査します。
#'
#' @return (なし) この関数は戻り値を返しません。確認結果を
#' 標準出力（console）に `print()` 文を用いて表示します。
#'
#' @details
#' 与えられた変数名ベクトルに対して、順に `%in% names(data)` を使用して
#' 対応する列（変数）がデータフレーム内に存在するかどうかを確認します。
#' 存在する場合は「Variable XXX exists in the dataset.」、
#' 存在しない場合は「Variable XXX does not exist in the dataset.」という
#' メッセージを出力します。
#' 
#' 単純な構造ですが、データの前処理やレポート作成時に、想定された変数が
#' 適切に読み込まれているかをチェックする場面で便利です。
#'
#' @examples
#' # データフレームを作成
#' df <- data.frame(
#'   id = 1:5,
#'   age = c(25, 30, 22, 28, 35),
#'   gender = c("M", "F", "M", "F", "M")
#' )
#'
#' # 変数名のリストを確認（"id", "income", "age"という3変数）
#' check_vars(df, c("id", "income", "age"))
#'
#' # 出力例:
#' # [1] "Variable id exists in the dataset."
#' # [1] "Variable income does not exist in the dataset."
#' # [1] "Variable age exists in the dataset."
#'
#' @seealso \code{\link[base]{names}}, \code{\link[base]{print}}, \code{\link[base]{exists}}
#' @export
# ******************************************************************************
check_vars <- function(data, vars) {
  for (var in vars) {
    if (var %in% names(data)) {
      print(paste("Variable", var, "exists in the dataset."))
    } else {
      print(paste("Variable", var, "does not exist in the dataset."))
    }
  }
}
# ******************************************************************************

# ******************************************************************************
#' @title getFilesByType：指定ディレクトリ以下の指定タイプのファイル一覧を取得
#'
#' @description 任意の拡張子（例：".dta" や ".csv"）にマッチするファイルを、指定された
#' ルートフォルダ以下（再帰的）から検索し、ファイル名とその属するサブフォルダの
#' 相対パス（ファイル名を除く）を含むデータフレームとして返します。
#'
#' @param root_folder (character) 検索対象のルートディレクトリのパス。
#' 
#' @param filetype (character) 検索対象とするファイル拡張子（例: "DTA", "csv" など）。
#' 大文字・小文字の区別はされません。
#'
#' @return (data.frame) `filename`（ファイル名）と `relative_path`
#' （フォルダ相対パス）を持つデータフレーム。
#'
#' @details
#' \itemize{
#'   \item 大文字・小文字を区別しないマッチを行うため、正規表現の `(?i)` フラグを使用。
#'   \item ルートフォルダ直下のファイルは `relative_path` が `""`（空文字列）になります。
#' }
#'
#' @examples
#' # 例: .dta ファイルを検索
#' getFilesByType("path/to/project", "dta")
#'
#' # 例: .csv ファイルを検索
#' getFilesByType("path/to/project", "csv")
#'
#' @seealso \code{\link[base]{list.files}}, \code{\link[base]{dirname}}, \code{\link[base]{basename}}, \code{\link[base]{tolower}}
#' @export
# ******************************************************************************

getFilesByType <- function(root_folder, filetype) {
  # 正規表現：大文字小文字を区別せず、拡張子に一致（例：".dta"）
  pattern <- paste0("(?i)\\.", filetype, "$")
  
  # ファイルの相対パス（再帰的検索・フルパスは不要）
  relative_file_paths <- list.files(
    path = root_folder,
    pattern = pattern,
    recursive = TRUE,
    full.names = FALSE
  )
  
  # 検出ファイルがない場合は空のデータフレームを返す
  if (length(relative_file_paths) == 0) {
    return(data.frame(filename = character(0), relative_path = character(0), stringsAsFactors = FALSE))
  }
  
  # ファイル名と相対ディレクトリパスを抽出
  filenames <- basename(relative_file_paths)
  relative_paths <- dirname(relative_file_paths)
  
  # "." を空文字に（ルート直下のファイル）
  relative_paths[relative_paths == "."] <- ""
  
  # データフレームにまとめて返す
  file_info <- data.frame(
    filename = filenames,
    relative_path = relative_paths,
    stringsAsFactors = FALSE
  )
  
  return(file_info)
}
# --- 関数定義ここまで ---


#' 指定したExcelファイルにシートを追加または上書き保存する関数
#' @title write_sheet_to_excel
#' @description
#' 指定したExcelファイル(`.xlsx`)に、データフレームを指定したシート名で書き込みます。
#' - ファイルが存在しない場合は新規作成します。
#' - 既存のファイルでシート名が重複している場合、該当シートのみ上書きされます（他のシートは維持されます）。
#' - 書き込みに成功すると`TRUE`、失敗時は警告を表示し`FALSE`を返します。
#'
#' @param file_path 文字列。書き込み対象のExcelファイルのパス（例: "result.xlsx"）
#' @param sheet_name 文字列。作成・書き込みを行うシート名（例: "Sheet1"）
#' @param data_to_write データフレーム。Excelシートに書き込むデータ
#'
#' @return 論理値。正常終了で`TRUE`、エラー発生時は`FALSE`を返します
#'
#' @examples
#' \dontrun{
#' df <- data.frame(x = 1:5, y = 6:10)
#' write_sheet_to_excel("book.xlsx", "data", df)
#' }
#' @importFrom openxlsx loadWorkbook createWorkbook addWorksheet writeData saveWorkbook removeWorksheet
#' @export
write_sheet_to_excel <- function(file_path, sheet_name, data_to_write) {
  tryCatch({
    # ファイルが存在するか確認
    if (file.exists(file_path)) {
      wb <- loadWorkbook(file_path)
      # 同名シートが存在する場合は削除
      if (sheet_name %in% names(wb)) {
        removeWorksheet(wb, sheet_name)
      }
    } else {
      wb <- createWorkbook()
    }
    
    # シートを追加してデータを書き込み
    addWorksheet(wb, sheet_name)
    writeData(wb, sheet_name, data_to_write)
    
    # ファイルを保存（上書き）
    saveWorkbook(wb, file_path, overwrite = TRUE)
    
    # 正常終了：TRUEを返す
    return(TRUE)
  }, error = function(e) {
    # エラーが起きた場合は警告を出してFALSEを返す
    warning(paste("Excel書き込みエラー:", e$message))
    return(FALSE)
  })
}
# --- 関数定義ここまで ---

# ******************************************************************************
#' @title get_label_list
#' @description
#' データフレームの各変数に設定されたラベルを抽出し、
#' 変数名とラベルの対応表をデータフレーム形式で返します。
#' この関数は、特にStataやHavenで読み込んだデータセットの
#' 変数ラベルを確認する際に便利です。
#' @param df データフレーム。変数ラベルを抽出する対象のデータセット。
#' @return 変数名とラベルの対応表を含むデータフレーム。
# ******************************************************************************

get_label_list <- function(df) {
  
  labels <- sapply(df, function(x) {
    lbl <- attr(x, "label")
    if (is.null(lbl)) NA else lbl
  })
  
  temp_label <- data.frame(
    variable = names(df),
    label = labels,
    stringsAsFactors = FALSE
  )
  
  return(temp_label)
}
# --- 関数定義ここまで ---

# ******************************************************************************
#' @title findVariables
#' @description 検索条件に合致した行をデータフレームから抽出する関数
#' @param df データフレーム。検索対象のデータセット。
#' @param word 文字列。検索するキーワード。
#' @param cols 文字列ベクトル。検索対象の列名。デフォルトは c("variable", "label")。
#' @return 検索条件に合致した行を含むデータフレーム。
#' @details
#' if_any(all_of(cols), ... ): colsで指定した複数列のうち“少なくとも
#'    1つの列”が条件（今回はワード一致）を満たす行をTRUEにする
#' ~ str_detect(.x, regex(word, ignore_case = TRUE)): 
#' 　 各列に対してwordが部分一致で含まれるかをチェック
#' 　 ignore_case = TRUE：大文字・小文字を区別しない
#' 
# ******************************************************************************
findVariables <- function(df, word, cols = c("variable", "label")) {
  if (missing(df) || missing(word)) {
    stop("df, cols, and word must be specified")
  }
  matched_rows <- df %>% 
    filter(if_any(all_of(cols), ~ str_detect(.x, stringr::regex(word, ignore_case = TRUE))))
  
  print(matched_rows)
  return(matched_rows)
}

# --- 関数定義ここまで ---

# ******************************************************************************
# これ以下はperu_endes用の関数群
# ******************************************************************************

# ******************************************************************************
#' @title findvariables_endes
#' @description endes_var_labelsデータフレームからキーワードで変数を検索し、
#' endes_listと結合して結果を返す関数
#' @param word 文字列。検索するキーワード。
#' @return 検索条件に合致した行を含むデータフレーム。
# ******************************************************************************

findvariables_endes <- function(word){
  if (!exists("endes_var_labels") || !exists("endes_list")) {
    stop("endes_var_labels and endes_list must be loaded in the global environment")
  }

  res <- endes_var_labels %>% findVariables(word) %>%
    left_join(endes_list, by = c("year", "filename"))
  
  print(res, n = nrow(res))
  return(res)
}
# --- 関数定義ここまで ---

# ******************************************************************************
#' @title open_endes_file
#' @description 指定した年とファイルタイプに基づき、endes_listから該当する
#' ファイルのパスを取得し、SPSS形式のデータを読み込んで返す関数
#' @param year 文字列。対象の年（例: "2005"）
#' @param fileType 文字列。対象のファイルタイプ（例: "RECH4.sav"）
#' @return 指定された年とファイルタイプに対応するデータフレーム
#' 
# ******************************************************************************

open_endes_file <- function(myyear, fileType) {
  if (!exists("endes_list")) {
    stop("endes_list must be loaded in the global environment")
  }
  
  relative_path <- endes_list %>% 
    filter(year == myyear, tolower(filename) == tolower(fileType))
  if (nrow(relative_path) == 0) {
    stop(paste("Year", myyear, ", or file", fileType, "not found in endes_list"))
  }
  
  print(paste("year=", myyear, "file=", fileType) )
  print(nrow(relative_path))

    relative_path <- file.path(gdrive_dir, relative_path$relative_path[1], 
       relative_path$filename[1]) %>%
       normalizePath() %>%
       trimws()

  if (is.na(relative_path) || relative_path == "") {
    stop(paste("File for year", myyear, "and type", fileType, "not found"))
  }
    
  print(relative_path)
  df <- read_sav(relative_path, user_na = FALSE)
  return(df)
}

# --- 関数定義ここまで ---
# ******************************************************************************
# '@title add_missing_columns
#' @description 指定した列名がデータフレームに存在しない場合、NA列を追加し、
#' 指定した列順に並び替えて返す関数
#' @param df データフレーム。対象のデータセット。
#' @param columns 文字列ベクトル。追加・並び替え対象の列名。
#' @return 指定した列名がすべて存在するデータフレーム。
#' ******************************************************************************
add_missing_columns <- function(df, columns) {
  for(col in columns) {
    if(!col %in% colnames(df)) {
      print(paste("Adding missing column:", col))
      df[[col]] <- NA
    }
  }
  return(df)
}

# --- 関数定義ここまで ---
# ******************************************************************************
#' @title duplicate_check
#' @description 指定したキー変数に基づき、データフレーム内の重複レコードをチェックし、
#' 結果を標準出力に表示する関数
#' @param df データフレーム。重複チェック対象のデータセット。
#' @param key_vars 文字列ベクトル。重複チェックに使用するキー変数名。
#' @param df_name 文字列。データフレームの名前（メッセージ表示用）。
#' @return 重複がない場合は1、重複がある場合は0を返す。
#' ******************************************************************************

duplicate_check <- function(df, key_vars, df_name) {
  print(paste("Checking duplicates in", df_name, "using keys:", paste(key_vars, collapse = ", ")))
  temp <- df %>%
    group_by(across(all_of(key_vars))) %>%
    summarise(n = n(), .groups = 'drop') %>%
    filter(n > 1)
  
  if (nrow(temp) > 0) {
    print(paste("重複レコードがあります in", df_name))
    print(temp)
    print(paste("レコード数：", nrow(df)))
    res <- 0
  } else {
    print(paste("重複レコードはありません in", df_name))
    print(paste("レコード数：", nrow(df)))
    res <- 1
  }
  return(res)
}
# --- 関数定義ここまで ---

# ******************************************************************************
#' @title duplicate_check_detail
#' @description 指定したキー変数に基づき、データフレーム内の重複レコードをチェックし、
#' 結果を標準出力に表示する関数
#' @param df データフレーム。重複チェック対象のデータセット。
#' @param key_vars 文字列ベクトル。重複チェックに使用するキー変数名。
#' @param df_name 文字列。データフレームの名前（メッセージ表示用）。
#' @return 重複がない場合は1、重複がある場合は0を返す。
#' ******************************************************************************

duplicate_check_detail <- function(df, key_vars, df_name) {
  print(paste("Checking duplicates in", df_name, "using keys:", paste(key_vars, collapse = ", ")))
  temp <- df %>%
    group_by(across(all_of(key_vars))) %>%
    summarise(n = n(), .groups = 'drop') %>%
    filter(n > 1)
  
  if (nrow(temp) > 0) {
    print(paste("重複レコードがあります in", df_name))
    print(temp)
    print(paste("レコード数：", nrow(df)))
    
    # 重複による問題が発生する列を特定
    problematic_cols <- df %>%
      group_by(across(all_of(key_vars))) %>%
      summarise(
        across(everything(), ~ n_distinct(.x, na.rm = TRUE)),
        .groups = 'drop'
      ) %>%
      filter(if_any(-all_of(key_vars), ~ .x > 1))
    
    if (nrow(problematic_cols) > 0) {
      print("\n同じグループ内で異なる値が存在する列がある重複レコード:")
      
      # 問題のある列のみを表示
      problem_detail <- df %>%
        semi_join(problematic_cols, by = key_vars) %>%
        group_by(across(all_of(key_vars))) %>%
        summarise(
          across(everything(), ~ paste(sort(unique(.x[!is.na(.x)])), collapse = ", ")),
          .groups = 'drop'
        )
      
      print(problem_detail)
      
      # どの列に問題があるかを明示
      cols_with_issues <- problematic_cols %>%
        select(-all_of(key_vars)) %>%
        select_if(~ any(.x > 1)) %>%
        names()
      
      if (length(cols_with_issues) > 0) {
        print("\n問題のある列:")
        print(cols_with_issues)
      }
    }
    
    res <- 0
  } else {
    print(paste("重複レコードはありません in", df_name))
    print(paste("レコード数：", nrow(df)))
    res <- 1
  }
  return(res)
}


# --- 関数定義ここまで ---
# ******************************************************************************
#' @title duplicate_check_detail_most
#' @description 指定したキー変数に基づき、データフレ
#' ーム内の重複レコードをチェックし、各重複グループで異なる値を持つ列を詳細に調べる関数
#' @param df データフレーム。重複チェック対象のデータセット。
#' @param key_vars 文字列ベクトル。重複チェックに使用するキー変数名。
#' @param df_name 文字列。データフレームの名前（メッセージ表示用）。
#' @return 重複がない場合は1、重複がある場合は0を返す。
#' ******************************************************************************
duplicate_check_detail_most <- function(df, key_vars, df_name) {
  temp <- df %>%
    group_by(across(all_of(key_vars))) %>%
    summarise(n = n(), .groups = 'drop') %>%
    filter(n > 1)
  
  if (nrow(temp) > 0) {
    print(paste("重複レコードがあります in", df_name))
    print(temp)
    print(paste("レコード数：", nrow(df)))
    
    # 各重複グループで異なる値を持つ列を詳細に調べる
    duplicate_groups <- temp %>% select(all_of(key_vars))
    
    # 重複レコードのみを取得
    duplicate_records <- df %>%
      semi_join(duplicate_groups, by = key_vars)
    
    # 各列について、重複グループ内での値の変動を調べる
    non_key_vars <- names(df)[!names(df) %in% key_vars]
    
    print("\n=== 重複による問題列の詳細診断 ===")
    
    for (col in non_key_vars) {
      col_issues <- duplicate_records %>%
        group_by(across(all_of(key_vars))) %>%
        summarise(
          distinct_values = n_distinct(!!sym(col), na.rm = TRUE),
          values = paste(sort(unique(!!sym(col)[!is.na(!!sym(col))])), collapse = ", "),
          .groups = 'drop'
        ) %>%
        filter(distinct_values > 1)
      
      if (nrow(col_issues) > 0) {
        cat("\n列:", col, "\n")
        print(col_issues)
      }
    }
    
    res <- 0
  } else {
    print(paste("重複レコードはありません in", df_name))
    print(paste("レコード数：", nrow(df)))
    res <- 1
  }
  return(res)
}
# --- 関数定義ここまで ---
# ******************************************************************************
#' @title left_join_safe
#' @description left_joinを実行する前に、結合キー以外の共通列で不一致がある場合に
#' 警告を表示する関数
#' @param x データフレーム。左側のデータセット。
#' @param y データフレーム。右側のデータセット。
#' @param by 文字列ベクトル。結合キーとして使用する列名。デフォルトはNULL（共通列名を使用）。
#' @param suffix 文字列ベクトル。結合後の共通列名に付加するサフィックス。デフォルトは c(".x", ".y")。
#' @param ... その他のleft_joinに渡す引数。
#' @return left_joinの結果のデータフレーム。
# ******************************************************************************

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
    by_x <- names(by)
    by_y <- unname(by)
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
  
  # 通常のleft_joinを実行
  result <- left_join(x, y, by = by, suffix = suffix, ...)
  return(result)
}

# --- 関数定義ここまで ---
# ******************************************************************************
#' @title inner_join_safe
#' @description inner_joinを実行する前に、結合キー以外の共通列で不一致がある場合に
#' 警告を表示する関数
#' @param x データフレーム。左側のデータセット。
#' @param y データフレーム。右側のデータセット。
#' @param by 文字列ベクトル。結合キーとして使用する列名。デフォルトはNULL（共通列名を使用）。
#' @param suffix 文字列ベクトル。結合後の共通列名に付加するサフィックス。デフォルトは c(".x", ".y")。
#' @param ... その他のinner_joinに渡す引数。
#' @return inner_joinの結果のデータフレーム。
# ******************************************************************************

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
    by_x <- names(by)
    by_y <- unname(by)
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
  
  # 通常のleft_joinを実行
  result <- inner_join(x, y, by = by, suffix = suffix, ...)
  return(result)
}

# --- 関数定義ここまで ---
# ******************************************************************************
#' @title diagnose_value_label_issues
#' @description データフレーム内の特定の変数について、値
#' ラベルを設定する前に、その変数のデータ型をチェックし、
#' ラベル設定に問題がある場合に警告を表示する関数
#' @param data データフレーム。値ラベルを設定する対象の
#' データセット。
#' @return なし。この関数は診断結果を標準出力に表示します。
# Function to check data types of all variables that will receive value labels
# and report any potential issues that would prevent label assignment.
# ******************************************************************************
diagnose_value_label_issues <- function(data) {
  message("=== Diagnostic Report for Value Label Assignment ===\\n\\n")
  
  # List of variables that will receive value labels
  value_label_vars <- c(
    "dm_cooking_fuel", "dm_cooking_fuel_traditional", "dm_rural", "dm_town", 
    "dm_city", "dm_capital", "dm_poorest", "dm_poorer", "dm_middle", 
    "dm_richer", "dm_richest", "dm_shared_toilet", "dm_cooking_house", 
    "dm_cooking_outdoor", "dm_cooking_separate", "dm_cattle_own", 
    "dm_goat_own", "dm_sheep_own", "dm_poultry_own", "dm_refrigerator", 
    "dm_female_headed", "dm_age_of_HH_head"
  )
  
  # Check each variable
  for (var in value_label_vars) {
    if (var %in% names(data)) {
      var_class <- class(data[[var]])
      var_type <- typeof(data[[var]])
      has_na <- any(is.na(data[[var]]))
      unique_vals <- length(unique(data[[var]], na.rm = TRUE))
      
      message("Variable:", var, "\\n")
      message("  - Class:", paste(var_class, collapse = ", "), "\\n")
      message("  - Type:", var_type, "\\n")
      message("  - Has NA:", has_na, "\\n")
      message("  - Unique values:", unique_vals, "\\n")
      
      # Check if its numeric or character (required by haven/labelled)
      is_valid <- is.numeric(data[[var]]) || is.character(data[[var]])
      message("  - Valid for labelling:", is_valid, "\\n")
      
      # Show sample values
      sample_vals <- head(unique(data[[var]], na.rm = TRUE), 5)
      message("  - Sample values:", paste(sample_vals, collapse = ", "), "\\n")
      message("\\n")
      
      if (!is_valid) {
        message("*** PROBLEM FOUND: Variable", var, "is not numeric or character! ***\\n")
        message("*** This variable cannot receive value labels ***\\n\\n")
      }
    } else {
      message("Variable:", var, "- NOT FOUND in dataset\\n\\n")
    }
  }
  
  message("=== End of Diagnostic Report ===\\n")
}

# --- 関数定義ここまで ---
# ******************************************************************************
#' @title set_all_value_labels_safe
#' @description データフレーム内の特定の変数に対して
#' 値ラベルを設定する関数。ただし、値ラベル設定に
#' 問題がある変数はスキップし、警告を表示します。
#' @param data データフレーム。値ラベルを設定する対象の
#' データセット。
#' @return 値ラベルが正常に設定された変数を含むデ
#' ータフレーム。
#' ******************************************************************************
# Modified function that skips problematic variables
set_all_value_labels_safe <- function(data) {
  message("Attempting to set value labels...\\n")
  
  # Check which variables exist and are valid
  valid_vars <- c()
  
  vars_to_check <- list(
    dm_cooking_fuel = c("electricity" = 1, "lpg" = 2, "natural gas" = 3, "biogas" = 4, 
                        "kerosene" = 5, "coal, lignite" = 6, "charcoal" = 7, "wood" = 8, 
                        "straw / shrubs / grass" = 9, "agricultural crop" = 10, 
                        "animal dung" = 11, "no food cooked in hh" = 95, "other" = 96, 
                        "not dejure resident" = 97),
    dm_cooking_fuel_traditional = c("Yes" = 1, "No" = 0),
    dm_rural = c("Yes" = 1, "No" = 0),
    dm_town = c("Yes" = 1, "No" = 0),
    dm_city = c("Yes" = 1, "No" = 0),
    dm_capital = c("Yes" = 1, "No" = 0),
    dm_poorest = c("Yes" = 1, "No" = 0),
    dm_poorer = c("Yes" = 1, "No" = 0),
    dm_middle = c("Yes" = 1, "No" = 0),
    dm_richer = c("Yes" = 1, "No" = 0),
    dm_richest = c("Yes" = 1, "No" = 0),
    dm_shared_toilet = c("Yes (10 or more households)" = 1, "No (less than 10 households)" = 0),
    dm_cooking_house = c("Yes (cooking inside house)" = 1, "No (cooking outside or in separate building)" = 0),
    dm_cooking_outdoor = c("Yes (cooking outdoor)" = 1, "No (cooking inside house or in separate building)" = 0),
    dm_cooking_separate = c("Yes (cooking in separate building)" = 1, "No (cooking inside house or outdoor)" = 0),
    dm_cattle_own = c("Yes (owns cattle)" = 1, "No (does not own cattle)" = 0),
    dm_goat_own = c("Yes (owns goats)" = 1, "No (does not own goats)" = 0),
    dm_sheep_own = c("Yes (owns sheep)" = 1, "No (does not own sheep)" = 0),
    dm_poultry_own = c("Yes (owns poultry)" = 1, "No (does not own poultry)" = 0),
    dm_refrigerator = c("Yes" = 1, "No" = 0),
    dm_female_headed = c("Yes" = 1, "No" = 0),
    dm_age_of_HH_head = c("10s" = 1, "20s" = 2, "30s" = 3, "40s" = 4, 
                          "50s" = 5, "60s" = 6, "70s" = 7, "80+" = 8)
  )
  
  for (var_name in names(vars_to_check)) {
    if (var_name %in% names(data)) {
      is_valid <- is.numeric(data[[var_name]]) || is.character(data[[var_name]])
      if (is_valid) {
        message("Setting labels for:", var_name, "\\n")
        tryCatch({
          data <- data %>% set_value_labels(!!var_name := vars_to_check[[var_name]])
        }, error = function(e) {
          message("ERROR setting labels for", var_name, ":", e$message, "\\n")
        })
      } else {
        message("SKIPPING", var_name, "- not numeric or character\\n")
      }
    } else {
      message("SKIPPING", var_name, "- variable not found\\n")
    }
  }
  
  return(data)
}

# cat("Diagnostic functions created. Use these in R:\\n")
# cat("1. diagnose_value_label_issues(your_data)\\n")
# cat("2. your_data <- set_all_value_labels_safe(your_data)\\n")
# 
# 
# print("R Diagnostic Script:")
# print("=" * 50)
# print(diagnostic_script)

# --- 関数定義ここまで ---

# ******************************************************************************
#' @title check_source_variables
#' @description 変数作成に使用する元データの変数の値分布を確認する関数
#' @param data データフレーム
#' @return なし。診断結果を標準出力に表示
# ******************************************************************************
check_source_variables <- function(data) {
  cat("=== Source Variable Check ===\n\n")
  
  source_vars <- c("hv026", "hv270", "hv238", "hv241", "hv246a", 
                   "hv246d", "hv246e", "hv246g", "hv209", "hv219", "hv220")
  
  for (var in source_vars) {
    if (var %in% names(data)) {
      cat("Variable:", var, "\n")
      cat("  - Class:", class(data[[var]]), "\n")
      cat("  - Type:", typeof(data[[var]]), "\n")
      
      # 値の分布を表示
      val_table <- table(data[[var]], useNA = "ifany")
      cat("  - Value distribution:\n")
      print(val_table)
      cat("\n")
    } else {
      cat("Variable:", var, "- NOT FOUND\n\n")
    }
  }
}


