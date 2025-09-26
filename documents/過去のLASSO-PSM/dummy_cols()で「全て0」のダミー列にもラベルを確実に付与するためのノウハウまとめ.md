<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## dummy_cols()で「全て0」のダミー列にもラベルを確実に付与するためのノウハウまとめ


***

### 問題点の整理

- **dummy_cols()によるダミー変数作成時、元データに存在しないカテゴリ（水準）は全て0のダミー列となり、変数名末尾が`_`で終わる（例: `ch_pneumo1_either_`）**
- 通常は`_1`等のサフィックスがつく（例: `ch_polio1_either_1`）
- ラベルをforループで付与しようとしたとき、この全て0の列が条件からすり抜けてしまい、ラベルが付与されない問題が発生

***

### 原因

- 通常、ラベル付与対象ループは `label_df` の varname/val をもとに「想定される列名」を生成して突き合わせていたが、
dummy_cols() の仕様（全て0の列はsuffixがつかず"_"で終わる）にマッチせず、処理対象外になっていた

***

### 解決策

1. **実際に生成された全てのダミー列を列挙し、それぞれを正規表現等でパースして、label_df内と突き合わせてラベル付与する**
2. **末尾が"_"の列については、最後の"_"より前をvarname、その後をvalとして復元する処理を明示的に記述**

***

### サンプルコード

```r
library(haven)

# label_df…「varname」「val」「varlabel」「vallabel」列を持つデータフレーム
# df_dummies…dummy_cols()で生成したデータフレーム

# 末尾が"_"（全て0のダミー列）と通常の"_数値"を一括処理
zero_dummy_cols <- names(df_dummies)[grepl("_$", names(df_dummies))]
normal_dummy_cols <- names(df_dummies)[grepl("_\\d+$", names(df_dummies))]
all_dummy_cols <- c(zero_dummy_cols, normal_dummy_cols)

for (dummy_col in all_dummy_cols) {
  
  # 末尾が"_"の場合の処理（全て0のダミー列）
  if (grepl("_$", dummy_col)) {
    base_name <- sub("_$", "", dummy_col)
    last_underscore <- max(gregexpr("_", base_name)[[^1]])
    if (last_underscore > 0) {
      varname <- substr(base_name, 1, last_underscore - 1)
      val <- substr(base_name, last_underscore + 1, nchar(base_name))
    } else {
      next
    }
  } else {
    base_name <- sub("_\\d+$", "", dummy_col)
    val <- sub(".*_", "", dummy_col)
    last_underscore <- max(gregexpr("_", base_name)[[^1]])
    if (last_underscore > 0) {
      varname <- substr(base_name, 1, last_underscore - 1) 
      val <- paste0(substr(base_name, last_underscore + 1, nchar(base_name)), "_", val)
    } else {
      varname <- base_name
    }
  }
  
  row_idx <- which(label_df$varname == varname & as.character(label_df$val) == val)
  
  if (length(row_idx) > 0) {
    vallabel <- label_df$vallabel[row_idx[^1]]
    varlabel <- label_df$varlabel[row_idx[^1]]
    if (is.na(vallabel) || vallabel == "") {
      lab_txt <- paste0(varlabel, ": ", val, " (=1)")
    } else {
      lab_txt <- paste0(varlabel, ": ", vallabel, " (=1)")
    }
  } else {
    lab_txt <- paste0(varname, ": ", val, " (=1)")
  }
  
  message(sprintf("%s → ラベル付与: '%s'", dummy_col, lab_txt))
  
  df_dummies[[dummy_col]] <- haven::labelled(
    df_dummies[[dummy_col]],
    label = lab_txt
  )
}
```


***

### ポイント要約

- **dummy_cols()で「全て0」のカテゴリは列名末尾が"_"になる仕様→特別扱いが必要**
- **実際の列名から逆算してvarnameとカテゴリ値(val)を抽出し、label_dfでラベルと突き合わせる設計にする**
- **forループは生成済み列名を主導に回すことで「全て0を含むすべての列」に確実にラベル付与可能**
- **ラベル付与にはhaven::labelled()が最適（Stataエクスポートでも保持）**

***

これにより、高い再現性でどんなdummy列にもラベルが付与できます。

<div style="text-align: center">⁂</div>

[^1]: https://smart-hint.com/python/dummies/

