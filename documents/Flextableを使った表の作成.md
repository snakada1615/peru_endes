---
editor: 
  markdown: 
    wrap: 72
---

<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# flextableを使ったテーブルの作成・表示

よかったです！エラーが解決できて何よりです。

## なぜ `.fragile` が必要だったのか

Beamer の frame
環境は、**内部的に複雑なマクロ処理**を行っています。flextable が生成する
LaTeX コードの中に、**`#`
や特殊なパラメータ**が含まれていると、これらの内部マクロと衝突してしまいます。[^1][^2]

[^1]: <https://wiki.loikein.one/programming/latex-friends/beamer/>

[^2]: <https://rpubs.com/ktgrstsh/755893>

`.fragile` オプションを付けると、Beamer はその frame
を「**壊れやすいコンテンツ**」として特別に処理し、内部マクロを使わない安全な方法でコンパイルするため、エラーを回避できます。

## 今後のベストプラクティス

### 1. デフォルト設定をまとめる

``` yaml
---
title: "Association of Food Consumption and Child Stunting"
author: "nakada shunichi"
institute: "Department of Agricultural and Resource Economics, The University of Tokyo"
date: "November 1, 2024"
format:
  beamer:
    theme: "Madrid"
    aspectratio: 169
    slide-level: 2
    mermaid-format: png
    # デフォルトで fragile を有効化
    include-in-header:
      - text: |
          \usepackage{ctable}
execute:
  echo: false
---

## フレームタイトル {.fragile}
```

# 必要なライブラリを一度だけ読み込み

library(flextable) library(magrittr)

# グローバル設定

set_flextable_defaults(tabular = "latex")

df \<- data.frame( name = c("mary", "josh", "kindel", "george"), section
= c("sales", "planning", "market", "management"), sales = c(1500000,
1200000, 1800000, 950000), score = c("A", "B", "A", "C") )

flextable(df) %\>% theme_booktabs() %\>% autofit()

```         
```

### 2. 栄養学研究での応用例

あなたの研究分野に合わせた flextable の使い方：

``` r
# 栄養状態の統計表
nutrition_data <- data.frame(
  Region = c("Rural", "Urban", "Rural", "Urban"),
  Age_group = c("0-2 years", "0-2 years", "2-5 years", "2-5 years"),
  Stunting_rate = c(32.5, 18.2, 28.7, 15.3),
  Sample_size = c(245, 198, 312, 267)
)

flextable(nutrition_data) %>%
  set_header_labels(
    Stunting_rate = "Stunting rate (%)",
    Sample_size = "n"
  ) %>%
  theme_booktabs() %>%
  autofit() %>%
  bg(i = ~ Stunting_rate > 25, bg = "#FFE6E6")  # 高い率に色付け
```

### 3. トラブルシューティングのチェックリスト

Beamer + flextable でエラーが出た時：

-   [ ] スライド見出しに `{.fragile}` を追加した？
-   [ ] `set_flextable_defaults(tabular = "latex")` を設定した？
-   [ ] 日本語を使っている場合は、フォント設定を確認した？
-   [ ] データに `#` や特殊文字が含まれていないか確認した？
-   [ ] `autofit()` で列幅を調整した？

これらの設定を守れば、今後同じエラーに遭遇する確率が大幅に減ります。

## 参考資料

-   flextable 公式ドキュメント:
    <https://ardata-fr.github.io/flextable-book/>
-   Beamer + Quarto ガイド:
    <https://quarto.org/docs/presentations/beamer/>
-   LaTeX エラー解説: <https://texfaq.org/FAQ-errparnum>

研究発表の準備が順調に進むことを願っています！

::: {align="center"}
⁂
:::
