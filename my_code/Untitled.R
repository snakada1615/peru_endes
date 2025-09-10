library(here)

source(here("myTools.R"), local = environment())
source("getDHSfiles.R", local = environment())

# file_list <- get_dhs_file(
#   yearlist = c("2005", "2008", "2009", "2010", "2011", "2012"),
#   root_folder = normalizePath(here("..", ".."))
# )

year <- c("2005", "2008", "2009", "2010", "2011", "2012")
# year <- c("2005")

# HRdatafile <- file_list[[year[1]]]$HR
# HRdata <- read_dta(HRdatafile)
# 
# dup_list <- HRdata %>%
#   as_tibble() %>%
#   group_by(hv001, hv002) %>%
#   summarise(
#     dup_count = n(),
#     .groups = "drop"
#   )
# 
# 
# summary(dup_list)
# 
# label_list <- list()
# for (yr in year) {
#   print(paste("Processing year:", yr))
#   dmData <- read_dta(normalizePath(here("..", "output", yr, "DMdata_dm.dta")))
#   
#   label_list[[yr]] <- dmData %>%
#     get_label_list()
# 
# }
#*************************************************************************************************************************************
file_path <- normalizePath(here("..", "..", "2005", "IR", "PEIR51FL.DTA"))
IRtemp_df <- read_dta(file_path)

my_label <- get_label_list(IRtemp_df) %>%
  as_tibble()

print("done!")