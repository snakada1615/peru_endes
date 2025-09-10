# Shinyアプリケーション：dtaファイルの選択と表示
# このコードは、Shinyアプリケーションを使用して、指定されたディレクトリ内のdtaファイルを選択し、その内容を表示するものです。
# コマンドラインからの立ち上げ
# R -e "shiny::runApp('/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/peru_DHS/R/code/tools/shiny/showVariableDescription.R', launch.browser = TRUE)"

# 必要なライブラリの読み込み
library(shiny)            # Shiny 本体
library(here)             # プロジェクトパス補助
library(DT)               # データテーブル表示
library(tibble)           # データ構造補助
library(dplyr)            # データ操作
library(tidyverse)        # データ操作統合
library(shinycssloaders)  # ローディングアイコン

# 環境変数クリア
rm(list = ls(all = TRUE))

# カスタム関数等の読み込み
source(do.call(here, as.list(c("myTools.R"))))
hello()

# ルートフォルダのパス作成
root_folder <- c("..", "output")
my_path <- normalizePath(do.call(here::here, as.list(root_folder)))

# 指定ディレクトリのdtaファイル情報を取得し、id列を付加
files_info <- getFilesByType(my_path, "dta") %>% rowid_to_column("id")

my_year_list <- unique(files_info$relative_path)

# --- UI定義 ---
ui <- fluidPage(
  tags$style(type="text/css",
             "#out {max-width: 450px; white-space: pre-wrap; word-break: break-all;}"),
  # 年を選ぶリストボックス（relative_pathごとに分割）
  selectInput(
    inputId = "year_list",
    label = "年を選択してください",
    choices = my_year_list,
    selected = NULL
  ),
  # ファイル選択リストボックス（初期値は空）
  selectInput(
    inputId = "file_list",
    label = "ファイルを選択してください",
    choices = c("not selected" = ""),
    selected = NULL
  ),
  # 選択内容の表示
  verbatimTextOutput("selectedValue"),
  # 読み込んだデータのテーブル表示（スピナー付き）
  withSpinner(DT::dataTableOutput("myTable"), hide.ui = FALSE)
)

# --- サーバー処理 ---
server <- function(input, output, session) {
  # 年の選択に応じてファイルリストの内容を動的に切り替える
  observeEvent(input$year_list, {
    # 選択されたyear_list（id）に対応するrelative_pathだけを抽出
    filtered_files <- files_info %>%
      filter(relative_path == input$year_list)
    # 対応するファイルに限定し、SelectInputの選択肢を更新
    updateSelectInput(session, "file_list",
                      choices = c("not selected" = "", setNames(filtered_files$id, filtered_files$filename)),
                      selected = NULL # 年を変更したらファイル選択はリセット
    )
  })
  
  # ファイルのパス取得・データ読み込みなどをラップしたreactive関数
  my_data <- reactive({
    # 選択必須チェック（未選択時はエラー表示）
    validate(need(input$file_list != "", "ファイルを選択してください"))
    # IDが一致する行を特定
    idx <- which(trimws(as.character(files_info$id)) == trimws(as.character(input$file_list)))
    if (length(idx) != 1) stop("ファイル選択が不正です")
    # ファイルのパスを構成
    my_folder <- files_info$relative_path[idx]
    path_parts <- c(root_folder, my_folder, files_info$filename[idx])
    file_full <- normalizePath(do.call(here::here, as.list(path_parts)))
    # ファイルの存在チェック
    if (!file.exists(file_full)) stop("ファイルが存在しません: ", file_full)
    # （ここでデータ読み込みなど：read_dta(file_full)）
    # 必要なら内容を返す
    return(list(file_full = file_full))
  })
  
  # ファイルパス等の表示
  output$selectedValue <- renderText({
    d <- my_data()
    paste("選択された値は:", d$file_full, "\n")
  })
  
  # ファイルを読み込んでテーブルで表示
  output$myTable <- DT::renderDataTable({
    d <- my_data()
    file_full <- d$file_full
    my_table <- read_dta(file_full) %>% getLabelfromDTA()
  }, options = list(pageLength = 20))
}

# アプリ起動
shinyApp(ui, server)
