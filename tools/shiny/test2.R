library(shiny) # Shinyアプリケーションの作成
library(here) # Rプロジェクトのパスを取得
library(DT)        # データテーブル表示用
library(tibble)     # tibbleの使用
library(dplyr)      # データ操作用
library(tidyverse) # データ操作用

rm(list = ls(all = TRUE))


source(do.call(here, as.list(c("myTools.R"))))
hello()

root_folder <- c("..", "output")
my_path <- normalizePath(do.call(here::here, as.list(root_folder)))
cat(my_path, "\n")


temp <- getFilesByType(my_path, "dta") %>%
  rowid_to_column("id")
cat(temp$filename[1], "\n")


ui <- fluidPage(
  selectInput(
    inputId = "myList",
    label = "リストから選択してください",
    choices =setNames(temp$id, temp$filename),
    selected = NULL
  ),
  verbatimTextOutput("selectedValue"),
  DT::dataTableOutput("myTable")
)

server <- function(input, output, session) {
  my_data <- reactive({
    # 空選択または不正な場合は何もしない
    validate(
      need(input$myList != "", "ファイルを選択してください")
    )
    cat("input$myList:", input$myList, "\n")
    print(temp$filename)
    
    # 型・空白等を明示的に一致判定
    idx <- which(trimws(as.character(temp$id)) == trimws(as.character(input$myList)))
    cat("一致したインデックス:", idx, "\n")
    if (length(idx) != 1) {
      stop("ファイル選択が不正です")
    }
    my_folder <- temp$relative_path[idx]
    cat("Relative path:", my_folder, "\n")
    file_full <- normalizePath(do.call(here::here, as.list(root_folder, my_folder, temp$filename[idx])))
    cat("Before createPath:",root_folder, my_folder, temp$filename[idx], "\n")
    cat("Full file path:", file_full, "\n")
    cat("Final path:", file_full, "\n")
    if (!file.exists(file_full)) {
      stop("ファイルが存在しません: ", file_full)
    }
    read_dta(file_full)
    
    return(list(
      file_full = file_full,
      data = read_dta(file_full)
    ))
  })
  
  output$myTable <- DT::renderDataTable(
    my_data(), options = list(pageLength = 5)
    )
  output$selectedValue <- renderText({
    d <- my_data()
    paste(
      "選択された値は:", input$myList, 
      "\n", "file_full: ", d$file_full,
      )
  })
}

shinyApp(ui, server)
