library(qpdf)

# しおり情報のデータフレーム作成
bookmarks <- data.frame(
  level = c(
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    1, 2, 2, 2, 2, 2,
    1, 2, 2, 2,
    1, 2, 2, 2, 2, 2, 2
  ),
  title = c(
    # 01 Introduction
    "1. R for Empirical Economics Research 概要", 
    "1.1 OVERVIEW", "1.2 Google's R Style Guide", "1.3 RESEARCH WORKFLOW",
    "1.4 REPLICATION CRISIS", "1.5 P-HACKING / PUBLICATION BIAS",
    "1.6 FRAUD", "1.7 MISTAKES", "1.8 OPEN SCIENCE", "1.9 EXAMPLES",
    "1.10 SYLLABUS", "1.11 ASSESSMENT", "1.12 GETTING STARTED",
    "1.13 INSTALLING PACKAGES", "1.14 TIDYVERSE", "1.15 LIBRARY",
    "1.16 PACMAN", "1.17 HELP", "1.18 CAUTIONS ABOUT LLMS",
    "1.19 R BASICS", "1.20 VECTORS", "1.21 MODULARITY", "1.22 REFERENCES",
    
    # 02 Introduction
    "2. R の基本構文と関数",
    "2.1 SEQUENCES", "2.2 R FUNCTIONS", "2.3 IDENTICAL",
    "2.4 BASIC STATISTICS", "2.5 STATISTICS (ML vs Statistics)",
    "2.6 MACHINE LEARNING VS. STATISTICS", "2.7 SCRIPTING",
    "2.8 FUNCTIONS", "2.9 SCOPING", "2.10 CONTROL FLOW", "2.11 REFERENCES",
    
    # 03 Introduction
    "3. 日付・リスト・データフレーム",
    "3.1 DATES AND TIMES", "3.2 COMMENTING OUT", "3.3 IN-CLASS EXERCISE",
    "3.4 STANDARDIZE FUNCTION", "3.5 LISTS", "3.6 DATA FRAMES",
    "3.7 LM (線形回帰)", "3.8 QUARTO", "3.9 YAML HEADER",
    "3.10 PDFS", "3.11 PUBLISHING", "3.12 REFERENCES",
    
    # 04 dplyr
    "4. dplyr とデータ操作",
    "4.1 INSTALLING FROM GITHUB", "4.2 TIDYVERSE", "4.3 DATA FRAMES",
    "4.4 TIBBLE", "4.5 dplyr操作",
    
    # 05 joins/pivots
    "5. 結合と形の変換",
    "5.1 JOINS", "5.2 BINDING", "5.3 PIVOT_LONGER / PIVOT_WIDER",
    
    # 06 visualization
    "6. データ可視化",
    "6.1 COLOR", "6.2 SIZE", "6.3 FACETING", "6.4 STATISTICAL MODELS",
    "6.5 THE GOOD, THE BAD, AND THE UGLY", "6.6 AREA"
  ),
  page = c(
    # 01 Introduction
    1, 1, 3, 4, 5, 6, 15, 17, 18, 20, 21, 22, 23, 25, 27, 29, 30, 31, 33,
    34, 39, 47, 48,
    
    # 02 Introduction  
    49, 51, 57, 58, 61, 66, 67, 68, 70, 78, 85, 88,
    
    # 03 Introduction
    89, 89, 98, 101, 103, 104, 115, 118, 124, 127, 130, 132, 135,
    
    # 04 dplyr
    136, 136, 140, 141, 147, 149,
    
    # 05 joins/pivots
    239, 239, 258, 271,
    
    # 06 visualization
    287, 296, 297, 298, 299, 300, 301
  ),
  stringsAsFactors = FALSE
)

# しおりをPDFに埋め込む
pdf_add_bookmarks(
  input = here("documents", "R-basic-text.pdf"),
  output = here("documents", "R-basic-text-bookmark.pdf"),
  bookmarks = bookmarks
)
