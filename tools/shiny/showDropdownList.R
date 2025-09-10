library(shiny)
rm(list = ls(all = TRUE))


ui <- fluidPage(
  sliderInput("n", "サンプル数", 1, 100, 50),
  plotOutput("plot")
)

server <- function(input, output) {
  output$plot <- renderPlot({
    hist(rnorm(input$n))
  })
}


shinyApp(ui = ui, server = server)