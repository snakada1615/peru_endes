<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Flextableを用いた表を作成することが目的です

添付の表のような**ヘッダー行をオレンジ色（背景色付き）にした2列表**をQuarto/R Markdownで作成する方法をいくつか紹介します。

------------------------------------------------------------------------

## 方法1：HTMLテーブルを直接書く（最もシンプル）

Quartoの `.qmd` ファイルに、以下をそのまま書きます。

``` html
<table style="width: 100%; border-collapse: collapse;">
  <thead>
    <tr style="background-color: #E89850; color: white; font-weight: bold;">
      <th style="padding: 10px; text-align: left;">Diversity</th>
      <th style="padding: 10px; text-align: left;">Diversity of <strong>food group</strong> (qualitative)</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color: #F5E6D3;">
      <td style="padding: 10px;">Balance</td>
      <td style="padding: 10px;">Consumed <strong>food group</strong> balance (semi-quantitative)</td>
    </tr>
    <tr style="background-color: #FFFFFF;">
      <td style="padding: 10px;">Adequacy</td>
      <td style="padding: 10px;">Adequacy of key <strong>nutrient intake</strong> from diet (quantitative)</td>
    </tr>
    <tr style="background-color: #F5E6D3;">
      <td style="padding: 10px;">Moderation</td>
      <td style="padding: 10px;">Refrain <strong>overconsumption</strong></td>
    </tr>
  </tbody>
</table>
```

**メリット：** 細かい制御（色、罫線、パディング）が自由自在

------------------------------------------------------------------------

## 方法2：Rコードで生成（`flextable` パッケージ）

より汎用的で、後から表の内容を簡単に変更できます。

```{r}
library(flextable)

# データフレームを作成
data <- data.frame(
  Item = c("Diversity", "Balance", "Adequacy", "Moderation"),
  Description = c(
    "Diversity of food group (qualitative)",
    "Consumed food group balance (semi-quantitative)",
    "Adequacy of key nutrient intake from diet (quantitative)",
    "Refrain overconsumption"
  )
)

# flextable で表を作成
ft <- flextable(data)

# ヘッダー行をオレンジ色に設定
ft <- bg(ft, part = "header", bg = "#E89850")
ft <- color(ft, part = "header", color = "white")

# フォントを太字に
ft <- bold(ft, part = "header")

# 交互に背景色を付ける（オプション）
ft <- bg(ft, i = c(1, 3), bg = "#F5E6D3", part = "body")

# パディングと列幅を調整
ft <- autofit(ft)

ft
```

**メリット：** Rで動的に表を作成・修正できる、論文の図表リスト自動生成に対応

------------------------------------------------------------------------

## 方法3：`kableExtra` パッケージ（最短コード）

```{r}
library(knitr)
library(kableExtra)

data <- data.frame(
  Item = c("Diversity", "Balance", "Adequacy", "Moderation"),
  Description = c(
    "Diversity of food group (qualitative)",
    "Consumed food group balance (semi-quantitative)",
    "Adequacy of key nutrient intake from diet (quantitative)",
    "Refrain overconsumption"
  )
)

kable(data, col.names = c("", "")) %>%
  kable_styling(full_width = FALSE) %>%
  row_spec(0, background = "#E89850", color = "white", bold = TRUE) %>%
  row_spec(c(2, 4), background = "#F5E6D3")
```

**メリット：** コードが短い、kable よりスタイリングに強い

------------------------------------------------------------------------

## 方法4：Markdown + CSS（CSS活用型）

Quarto の場合、`.qmd` ファイルの YAML に以下を追加しておくと、全体のスタイルを一元管理できます。

``` yaml
---
title: "Quality of Diet Evaluation"
format:
  html:
    css: custom.css
---
```

その後、`custom.css` で以下のように定義：

``` css
.diet-table {
  width: 100%;
  border-collapse: collapse;
}

.diet-table thead tr {
  background-color: #E89850;
  color: white;
  font-weight: bold;
}

.diet-table tbody tr:nth-child(odd) {
  background-color: #F5E6D3;
}

.diet-table th,
.diet-table td {
  padding: 10px;
  text-align: left;
  border: 1px solid #ddd;
}
```

本文で：

``` html
<table class="diet-table">
  <thead>
    <tr><th>Diversity</th><th>Diversity of food group (qualitative)</th></tr>
  </thead>
  <tbody>
    <tr><td>Balance</td><td>Consumed food group balance (semi-quantitative)</td></tr>
    <!-- ... -->
  </tbody>
</table>
```

------------------------------------------------------------------------

## おすすめの使い分け

| 用途 | おすすめ方法 |
|:---|:---|
| **プレゼン資料**（1回限り、細かく調整） | 方法1 HTML直書き |
| **論文・レポート**（複数表、統一スタイル） | 方法2 flextable または 方法3 kableExtra |
| **Rで動的に内容が変わる** | 方法2 flextable |
| **複数ドキュメントで同じスタイル共有** | 方法4 CSS |

------------------------------------------------------------------------

## 今のあなたの用途に最適な提案

Quarto で **講義資料用プレゼンスライド**を作成されているとのことなので、方法1（HTML直書き）か方法3（kableExtra）がシンプルで良いと思います。

`flextable` は PDF出力との相性が完璧で、論文・正式レポート向けです。

どの方法でやってみたいか、あるいは「PDF出力も必要」など要件があれば、カスタマイズ例をさらに詳しく提供できます。 [^flextableを使った表の作成2-1]

[^flextableを使った表の作成2-1]: [image.jpg]{style="display:none"}

::: {align="center"}
⁂
:::
