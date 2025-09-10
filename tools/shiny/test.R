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


# source(paste0(here(),"/myTools.R"))


stop("ok")

shinyApp(ui = ui, server = server)