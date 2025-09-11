
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

getLabelfromDTA <- function(df) {
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
#' @title get_endes_file
#' @description
#' 複数年のendesファイルを取得してリストに格納する関数
#' @param yearlist 年リスト（例: c("2005", "2008", "2009")）
#' @param root_folder ルートフォルダのパス
#' @return endesFiles リスト。各年ごとにKR, PR, IR, HRのファイルパスを格納
#' 
# ******************************************************************************

get_endes_file <- function(yearlist, root_folder) {
  endesFiles <- list()
  
  # endesフォルダを取得する関数
  helper_data_root <- function(year, root_folder) {
    return(
      file.path(root_folder, year) %>%
        normalizePath() %>%
        trimws()
    ) 
  }
  # endesファイルを取得するヘルパー関数
  # 単年のendesファイルを取得する関数
  helper_getendesfile <- function(year, root_folder) {
    
    dfEndesFiles <- getFilesByType(
      root_folder = root_folder,
      filetype = "sav"
    )
    
    dfEndesFiles <- dfEndesFiles %>%
      mutate(
        relative_path = file.path(root_folder, relative_path, filename),
        filename = gsub(".sav", "", dfEndesFiles$filename)
      )
    
    res <- setNames(dfEndesFiles$relative_path, dfEndesFiles$filename)
    return(res)
# 
#     RECH4File <- filter(dfEndesFiles, str_detect(filename, "RECH4"))$relative_path
#     RECH23File <- filter(dfEndesFiles, str_detect(filename, "RECH23"))$relative_path
    # IRFile <- filter(dfEndesFiles, str_detect(relative_path, "IR"))$filename
    # HRFile <- filter(dfEndesFiles, str_detect(relative_path, "HR"))$filename
    # BRFile <- filter(dfEndesFiles, str_detect(relative_path, "BR"))$filename
    
    # return(list(
    #   RECH4File = file.path(root_folder, RECH4File, "RECH4.sav"),
    #   RECH23File = file.path(root_folder, RECH23File, "RECH23.sav")
    #   # IR = file.path(root_folder, "IR", IRFile),
    #   # HR = file.path(root_folder, "HR", HRFile),
    #   # BR = file.path(root_folder, "BR", BRFile)
    # ))
  }
  
  
  for (year in yearlist) {  # for文は ( ) を使います
    # endesFilesはリスト型で、年ごとにKR, PR, IR, HRのファイルパスを格納
    endesFiles[[year]] <- helper_getendesfile(
      year, 
      helper_data_root(year, root_folder)
    )
  }
  return(endesFiles)
}
# --- 関数定義ここまで ---
