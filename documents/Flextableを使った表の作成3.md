<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# combine_flextables_cairo: flexTable縦結合関数

> ft_A$footer$dataset [1] Item Description Type Score \<0 rows\> (or 0-length row.names) ft_B$footer$dataset [1] Indicator Status \<0 rows\> (or 0-length row.names)

了解しました。フッターは空（0行）ですが、**headerも除外すべき**です。修正版です：

``` r
# ******************************************************************************
#' @description: 複数のflextableオブジェクトを隙間なく結合し、PNG画像として保存
#' @param ft_list flextableオブジェクトのリスト
#' @param output_file 保存先ファイルパス
#' @param width 出力画像の幅（インチ単位、デフォルト：7）
#' @param dpi 解像度（デフォルト：150）
#' @param row_height 1行あたりの高さ（インチ単位、デフォルト：0.3）
#' @return TRUE（成功時）
# ******************************************************************************
combine_flextables_cairo <- function(ft_list, output_file, width = 7, dpi = 150, row_height = 0.3) {
  library(flextable)
  library(gridExtra)
  library(grid)
  library(ragg)
  
  # 入力チェック
  if (!is.list(ft_list) || length(ft_list) == 0) {
    stop("ft_list は空でないリストである必要があります")
  }
  
  for (i in seq_along(ft_list)) {
    if (!inherits(ft_list[[i]], "flextable")) {
      stop(paste("ft_list[[", i, "]] はflextableオブジェクトではありません"))
    }
  }
  
  # grob化
  grob_list <- lapply(ft_list, function(ft) {
    gen_grob(ft, fit = "fixed")
  })
  
  # 各flextableの行数に基づいて高さを推定
  heights_in <- numeric(length(ft_list))
  
  for (i in seq_along(ft_list)) {
    ft <- ft_list[[i]]
    nrows <- 0
    
    # bodyデータの行数のみを取得（header/footerは除外）
    if (!is.null(ft$body$dataset)) {
      nrows <- nrow(ft$body$dataset)
    } else if (!is.null(ft$body$content)) {
      if (is.data.frame(ft$body$content)) {
        nrows <- nrow(ft$body$content)
      } else if (is.list(ft$body$content)) {
        nrows <- length(ft$body$content)
      }
    }
    
    # body行のみの高さを計算（マージンなし）
    heights_in[i] <- max(nrows * row_height, 0.3)
  }
  
  # PNG画像のサイズを計算
  png_width <- as.integer(width * dpi)
  png_height <- as.integer(sum(heights_in) * dpi)
  
  # PNG保存
  ragg::agg_png(
    output_file,
    width = png_width,
    height = png_height,
    res = dpi
  )
  
  # grid.arrange()で結合
  heights_unit <- unit(heights_in, "inches")
  
  do.call(
    grid.arrange,
    c(
      grob_list,
      list(
        nrow = length(grob_list),
        heights = heights_unit
      )
    )
  )
  
  dev.off()
  
  cat("✓ 画像を保存しました:", output_file, "\n")
  cat("✓ ピクセルサイズ:", png_width, "x", png_height, "\n")
  cat("✓ テーブル数:", length(ft_list), "\n")
  
  return(TRUE)
}

# ----関数ここまで--------------------------------------------------------------
```

**修正ポイント：**

1.  **マージンを削除** - `heights_in[i] <- max(nrows * row_height, 0.3)` に変更
2.  **footer判定を削除** - footerは常に0行なので不要
3.  **最小値を0.3に統一** - テーブルが小さすぎるのを防止

実行してみてください：

``` r
result <- combine_flextables_cairo(
  ft_list = list(ft_A_title, ft_A, ft_B),
  output_file = "tables_combined.png",
  width = 7,
  dpi = 150,
  row_height = 0.3
)
```

これでヘッダー・フッター行の余分な隙間がなくなるはずです。

この関数は今後、複数のflextableを隙間なく結合する際に何度も活用できます。必要に応じて以下のようにカスタマイズできることも覚えておいてください：

## 関数のカスタマイズ例

``` r
# テーブルを大きめに表示
result <- combine_flextables_cairo(
  ft_list = list(ft_A_title, ft_A, ft_B),
  output_file = "tables_combined_large.png",
  row_height = 0.4  # 行の高さを増加
)

# より高解像度で出力
result <- combine_flextables_cairo(
  ft_list = list(ft_A_title, ft_A, ft_B),
  output_file = "tables_combined_hires.png",
  dpi = 300  # 高解像度
)

# 幅を調整
result <- combine_flextables_cairo(
  ft_list = list(ft_A_title, ft_A, ft_B),
  output_file = "tables_combined_wide.png",
  width = 10  # 幅を10インチに拡張
)
```

Beamer出力でこのテーブル画像を使用する際は、以下のようにQuartoチャンクで指定できます：

``` markdown
```

#\| include: false result \<- combine_flextables_cairo(...)

```         

![](tables_combined.png){width=100%}
```

何か他にflextableやBeamer出力に関して質問があれば、お気軽にお問い合わせください。ご質問ありがとうございました！
