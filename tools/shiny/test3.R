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


temp <- getFilesByType(my_path, "dta") %>%
  rowid_to_column("id")


ui <- fluidPage(
  tags$style(type="text/css",
             "#out {max-width: 450px; white-space: pre-wrap; word-break: break-all;}"),  
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

    # 型・空白等を明示的に一致判定
    idx <- which(trimws(as.character(temp$id)) == trimws(as.character(input$myList)))
    if (length(idx) != 1) {
      stop("ファイル選択が不正です")
    }
    my_folder <- temp$relative_path[idx]
    path_parts <- c(root_folder, my_folder, temp$filename[idx])
    file_full <- normalizePath(do.call(here::here, as.list(path_parts)))
    cat("Full file path:", file_full, "\n")
    if (!file.exists(file_full)) {
      stop("ファイルが存在しません: ", file_full)
    }
    read_dta(file_full)
    cat("file read complete")
    
    return(list(
      file_full = file_full
    ))
  })
  
  output$selectedValue <- renderText({
    d <- my_data()
    paste(
      "選択された値は:", d$file_full, "\n"
    )
  })
  
  output$myTable <- DT::renderDataTable({
    d <- my_data()
    file_full <- d$file_full
    my_table <- read_dta(file_full) %>%
      as_tibble() %>%
      select(1:5)  # 最初の5列を表示
    my_table
  }, options = list(pageLength = 5)
  )
}

shinyApp(ui, server)
