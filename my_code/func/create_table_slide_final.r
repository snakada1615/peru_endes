# ============================================================================
# Quarto Beamer スライド用テーブル画像埋め込み関数 (キャプション上部+フットノート版)
# ============================================================================
# Quartoの自動番号付けを完全に回避し、カスタム番号のみを表示
# キャプションを画像の上に配置
# フットノートで追加の注釈を管理
# 
# 重要: チャンク内で results: asis を指定してください
# 例:
# ```{r}
# #| results: asis
# source("create_table_slide.r")
# 
# create_table_slide(
#   image_path = "image/table_1_part1.png",
#   caption = "Nutritional composition by food group (part 1)",
#   table_number = "1-1",
#   slide_title = "食品グループ別栄養成分（前半）",
#   footnote = "Data source: National Survey 2024"
# )
# ```
# ============================================================================

create_table_slide <- function(
  image_path,
  caption,
  table_number,       # カスタム番号 (例: "1-1", "1-2", "2-1" など)
  slide_title = NULL,
  width = "100%",
  caption_position = "top",  # "top" または "bottom"
  footnote = NULL,    # フットノートテキスト
  enable_crossref = FALSE  # クロスリファレンスを有効にする場合はTRUE
) {
  
  # ========================================================================
  # パラメータ検証
  # ========================================================================
  if (!file.exists(image_path)) {
    warning(paste0("警告: ファイルが見つかりません: ", image_path))
  }
  
  # ========================================================================
  # キャプション作成
  # ========================================================================
  full_caption <- paste0(
    "**Table ", table_number, ".** ", caption
  )
  
  # ========================================================================
  # Beamer形式のマークダウンを構築
  # 注: #tbl- プレフィックスを使わないことでQuartoの自動番号付けを回避
  # ========================================================================
  
  # スライドタイトル
  if (!is.null(slide_title)) {
    cat("## ", slide_title, "\n\n", sep = "")
  }
  
  if (enable_crossref) {
    # クロスリファレンスを有効にする場合（Quartoの自動番号も表示される）
    fig_id <- paste0("tbl-", gsub("-", "", table_number))  # ハイフンを除去
    
    cat("::: {#", fig_id, "}\n", sep = "")
    cat("\n")
    
    # キャプションを上に配置
    if (caption_position == "top") {
      cat(full_caption, "\n\n")
    }
    
    # 画像埋め込み
    cat("![](", image_path, "){width=", width, "}\n", sep = "")
    cat("\n")
    
    # キャプションを下に配置
    if (caption_position == "bottom") {
      cat(full_caption, "\n\n")
    }
    
    # フットノート
    if (!is.null(footnote)) {
      cat("^[", footnote, "]\n\n", sep = "")
    }
    
    cat(":::\n")
    cat("\n")
    
  } else {
    # クロスリファレンスなし（カスタム番号のみ表示）
    # キャプションを上に配置
    if (caption_position == "top") {
      cat(full_caption, "\n\n")
    }
    
    # 画像埋め込み
    cat("![](", image_path, "){width=", width, "}\n", sep = "")
    cat("\n")
    
    # キャプションを下に配置
    if (caption_position == "bottom") {
      cat(full_caption, "\n\n")
    }
    
    # フットノート
    if (!is.null(footnote)) {
      cat("^[", footnote, "]\n\n", sep = "")
    }
  }
  
  invisible(NULL)
}


# ============================================================================
# 使用例
# ============================================================================
# ```{r}
# #| results: asis
# source("create_table_slide.r")
#
# # ========================================================================
# # 例1: キャプション上部、フットノート付き
# # ========================================================================
# create_table_slide(
#   image_path = "image/table_1_part1.png",
#   caption = "Nutritional composition by food group (part 1)",
#   table_number = "1-1",
#   slide_title = "食品グループ別栄養成分（前半）",
#   caption_position = "top",
#   footnote = "Data from National Survey 2024"
# )
#
# cat("\n")
#
# # ========================================================================
# # 例2: キャプション下部、複数の注釈
# # ========================================================================
# create_table_slide(
#   image_path = "image/table_1_part2.png",
#   caption = "Nutritional composition by food group (part 2)",
#   table_number = "1-2",
#   slide_title = "食品グループ別栄養成分（後半）",
#   caption_position = "bottom",
#   footnote = "Values shown as mean ± standard deviation; n=500"
# )
# ```
# ============================================================================


# ============================================================================
# 拡張版: より詳細なオプション対応
# ============================================================================
create_table_slide_extended <- function(
  image_path,
  caption,
  table_number,
  slide_title = NULL,
  width = "80%",
  caption_position = "top",
  note = NULL,          # 画像直下の注釈
  source = NULL,        # 出典
  footnote = NULL,      # ページ下部フットノート
  enable_crossref = FALSE
) {
  
  # パラメータ検証
  if (!file.exists(image_path)) {
    warning(paste0("警告: ファイルが見つかりません: ", image_path))
  }
  
  # キャプション作成
  full_caption <- paste0(
    "**Table ", table_number, ".** ", caption
  )
  
  # ========================================================================
  # スライドタイトル
  # ========================================================================
  if (!is.null(slide_title)) {
    cat("## ", slide_title, "\n\n", sep = "")
  }
  
  # ========================================================================
  # クロスリファレンス用Div開始
  # ========================================================================
  if (enable_crossref) {
    fig_id <- paste0("tbl-", gsub("-", "", table_number))
    cat("::: {#", fig_id, "}\n", sep = "")
    cat("\n")
  }
  
  # ========================================================================
  # キャプション（上部）
  # ========================================================================
  if (caption_position == "top") {
    cat(full_caption, "\n\n")
  }
  
  # ========================================================================
  # 画像埋め込み
  # ========================================================================
  cat("![](", image_path, "){width=", width, "}\n", sep = "")
  cat("\n")
  
  # ========================================================================
  # キャプション（下部）
  # ========================================================================
  if (caption_position == "bottom") {
    cat(full_caption, "\n")
    cat("\n")
  }
  
  # ========================================================================
  # 注釈（画像直下）
  # ========================================================================
  if (!is.null(note)) {
    cat("*Note: ", note, "*\n", sep = "")
    cat("\n")
  }
  
  # ========================================================================
  # 出典（画像直下）
  # ========================================================================
  if (!is.null(source)) {
    cat("*Source: ", source, "*\n", sep = "")
    cat("\n")
  }
  
  # ========================================================================
  # フットノート（ページ下部）
  # ========================================================================
  if (!is.null(footnote)) {
    cat("^[", footnote, "]\n\n", sep = "")
  }
  
  # ========================================================================
  # クロスリファレンス用Div終了
  # ========================================================================
  if (enable_crossref) {
    cat(":::\n")
    cat("\n")
  }
  
  invisible(NULL)
}


# ============================================================================
# ユーティリティ関数: 複数の分割テーブルを一括出力
# ============================================================================
create_multi_part_table <- function(
  images_list,        # リスト: c("path1.png", "path2.png", ...)
  captions_list,      # リスト: c("Part 1 caption", "Part 2 caption", ...)
  table_number,       # メインテーブル番号 (例: "1")
  slide_titles = NULL,# リスト（オプション）: スライドタイトル
  footnotes_list = NULL,  # リスト（オプション）: 各テーブルのフットノート
  width = "80%",
  caption_position = "top",
  enable_crossref = FALSE
) {
  
  # パラメータ検証
  if (length(images_list) != length(captions_list)) {
    stop("images_list と captions_list の要素数が一致していません")
  }
  
  num_parts <- length(images_list)
  
  # 各部分のテーブルを出力
  for (i in 1:num_parts) {
    # サブ番号 (1-1, 1-2, ..., 2-1, 2-2, ...)
    sub_table_number <- paste0(table_number, "-", i)
    
    # スライドタイトル（指定されている場合）
    current_slide_title <- if (!is.null(slide_titles) && i <= length(slide_titles)) {
      slide_titles[[i]]
    } else {
      NULL
    }
    
    # フットノート（指定されている場合）
    current_footnote <- if (!is.null(footnotes_list) && i <= length(footnotes_list)) {
      footnotes_list[[i]]
    } else {
      NULL
    }
    
    # 関数呼び出し
    create_table_slide(
      image_path = images_list[[i]],
      caption = captions_list[[i]],
      table_number = sub_table_number,
      slide_title = current_slide_title,
      width = width,
      caption_position = caption_position,
      footnote = current_footnote,
      enable_crossref = enable_crossref
    )
    
    # 各スライド間に空白を挿入（最後を除く）
    if (i < num_parts) {
      cat("\n")
    }
  }
  
  invisible(NULL)
}


# ============================================================================
# ユーティリティ関数の使用例
# ============================================================================
# ```{r}
# #| results: asis
# source("create_table_slide.r")
#
# # テーブル1（3部構成）を一括出力
# create_multi_part_table(
#   images_list = c(
#     "image/table_1_part1.png",
#     "image/table_1_part2.png",
#     "image/table_1_part3.png"
#   ),
#   captions_list = c(
#     "Nutritional composition by food group (part 1)",
#     "Nutritional composition by food group (part 2)",
#     "Nutritional composition by food group (part 3)"
#   ),
#   table_number = "1",
#   slide_titles = c(
#     "食品グループ別栄養成分（前半）",
#     "食品グループ別栄養成分（中盤）",
#     "食品グループ別栄養成分（後半）"
#   ),
#   footnotes_list = c(
#     "Data from wave 1 survey",
#     "Data from wave 1 survey",
#     "Data from wave 1 survey"
#   ),
#   caption_position = "top"
# )
# ```
# ============================================================================
