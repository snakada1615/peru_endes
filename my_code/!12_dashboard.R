# install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "plotly", "readr"))
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(plotly)


ui <- dashboardPage(
  dashboardHeader(title = "記述統計ダッシュボード"),
  dashboardSidebar(
    selectInput("group", "グループを選択", choices = unique(df$group)),
    selectInput("variable", "変数を選択", choices = names(df)[-1]), # -1は群列を除外
    width = 250
  ),
  dashboardBody(
    fluidRow(
      box(title = "記述統計", width = 6, DTOutput("summary")),
      box(title = "ヒストグラム", width = 6, plotlyOutput("hist"))
    )
  )
)

server <- function(input, output, session) {
  filtered <- reactive({
    df %>% filter(group == input$group)
  })
  
  output$summary <- renderDT({
    data <- filtered()[[input$variable]]
    stat <- data.frame(
      平均=mean(data, na.rm=TRUE),
      中央値=median(data, na.rm=TRUE),
      最小値=min(data, na.rm=TRUE),
      最大値=max(data, na.rm=TRUE),
      標準偏差=sd(data, na.rm=TRUE)
    )
    datatable(stat, rownames=FALSE)
  })
  
  output$hist <- renderPlotly({
    data <- filtered()[[input$variable]]
    plot_ly(x = ~data, type = "histogram")
  })
}

shinyApp(ui, server)
