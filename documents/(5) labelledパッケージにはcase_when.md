<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# `case_when`と`ifelse`の違いによるエラーの解説

あなたのコードでエラーが発生する理由は、**`ifelse`と`case_when`が返すデータ型の違い**にあります。

## 問題の詳細

### `case_when`の場合（エラーなし）

```r
case_when(
  v744d==1  ~ 1, 
  v744d %in% c(0,8,9)  ~ 0
)
```

`case_when`は右側の値（`1`、`0`）の型を保持し、**数値型（numeric）**のベクトルを返します[^1][^2][^3]。

### `ifelse`の場合（エラー発生）

```r
ifelse(v744a==1 | v744b==1 | v744c==1 | v744d==1 | v744e==1, 1, 0)
```

`ifelse`は条件式に**論理値（logical）**のベクトルを渡されると、**論理型のベクトルを返す**ことがあります[^1][^4][^5]。これは`ifelse`の内部動作によるもので、特に複数の論理条件を`|`（OR）で結合した場合に発生しやすくなります。

## `labelled`パッケージのエラー

`set_value_labels()`関数は**数値型（numeric）または文字型（character）**のベクトルのみを受け付けます[^6][^7]。論理型のベクトルが渡されると以下のエラーが発生します：

```
Error in `new_labelled()`:
! `x` must be a numeric or a character vector.
```


## 解決方法

### 1. `as.numeric()`で明示的に変換

```r
WEdata <- WEdata %>%
  mutate(dm_dvjustify_onereas =
           as.numeric(ifelse(v744a==1 | v744b==1 | v744c==1 | v744d==1 | v744e==1, 1, 0))) %>%
  set_value_labels(dm_dvjustify_onereas = c("Yes" = 1, "No"=0)) %>%
  set_variable_labels(dm_dvjustify_onereas = "Agree that husband is justified in hitting or beating his wife for at least one of the reasons")
```


### 2. `case_when`を使用（推奨）

```r
WEdata <- WEdata %>%
  mutate(dm_dvjustify_onereas =
           case_when(
             v744a==1 | v744b==1 | v744c==1 | v744d==1 | v744e==1 ~ 1,
             TRUE ~ 0
           )) %>%
  set_value_labels(dm_dvjustify_onereas = c("Yes" = 1, "No"=0)) %>%
  set_variable_labels(dm_dvjustify_onereas = "Agree that husband is justified in hitting or beating his wife for at least one of the reasons")
```


### 3. `dplyr::if_else`を使用

```r
WEdata <- WEdata %>%
  mutate(dm_dvjustify_onereas =
           if_else(v744a==1 | v744b==1 | v744c==1 | v744d==1 | v744e==1, 1, 0)) %>%
  set_value_labels(dm_dvjustify_onereas = c("Yes" = 1, "No"=0)) %>%
  set_variable_labels(dm_dvjustify_onereas = "Agree that husband is justified in hitting or beating his wife for at least one of the reasons")
```


## まとめ

**`case_when`の使用を推奨**します。理由は以下の通りです：

- **データ型の一貫性**：右側の値の型を確実に保持します[^3][^8]
- **可読性**：条件が複雑になっても読みやすいコードが書けます[^2][^9]
- **拡張性**：将来的に条件を追加する際も容易です[^3]

`ifelse`を使用する場合は、`labelled`パッケージと組み合わせる際に必ず`as.numeric()`で明示的に型変換することが重要です[^6][^7]。
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36]</span>

<div style="text-align: center">⁂</div>

[^1]: https://www.geeksforgeeks.org/r-language/why-cant-rs-ifelse-statements-return-vectors/

[^2]: https://www.stephenskalicky.com/if-else-and-case-when.html

[^3]: https://www.rdocumentation.org/packages/dplyr/versions/1.0.10/topics/case_when

[^4]: https://rdrr.io/r/base/ifelse.html

[^5]: https://advanced-r-solutions.rbind.io/control-flow

[^6]: https://stackoverflow.com/questions/63924910/preparing-data-for-tbl-summary-convert-to-numeric-without-losing-label-attribut

[^7]: https://ropercenter.cornell.edu/ascii-conversion-r

[^8]: https://dplyr.tidyverse.org/reference/case_when.html

[^9]: https://bookdown.org/ansellbr/WEHI_tidyR_course_book/manipulating-data-with-dplyr.html

[^10]: https://www.datamentor.io/r-programming/ifelse-function

[^11]: https://rdrr.io/cran/labelled/src/R/val_labels.R

[^12]: https://stackoverflow.com/questions/76820570/if-else-ifelse-and-case-when-returning-different-results

[^13]: https://www.codingem.com/r-ifelse-function/

[^14]: https://stackoverflow.com/questions/43225937/does-r-ifelse-work-correctly-with-empty-vectors

[^15]: https://cran.r-project.org/web/packages/labelled/labelled.pdf

[^16]: https://doubtpad.hatenablog.com/entry/2020/02/14/004013

[^17]: https://stackoverflow.com/questions/43927755/using-if-ifelse-statement-with-vector-conditions-in-r

[^18]: https://github.com/ddsjoberg/gtsummary/issues/488

[^19]: https://www.jaysong.net/RBook/datahandling3.html

[^20]: https://r4ds.hadley.nz/logicals.html

[^21]: https://cran.r-project.org/web/packages/labelled/vignettes/labelled.html

[^22]: https://stackoverflow.com/questions/67661534

[^23]: https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/ifelse

[^24]: https://www.reddit.com/r/RStudio/comments/1fqknwu/issue_with_haven_labelled_data_dhs/

[^25]: https://cran.r-project.org/web/packages/lest/lest.pdf

[^26]: https://stackoverflow.com/questions/76580755/turn-a-character-vector-into-numeric-vector-with-labels

[^27]: https://exploratory.io/reference/

[^28]: https://stackoverflow.com/questions/71442196/dplyr-mutate-with-ifelse-or-case-when-not-working-as-expected

[^29]: https://stackoverflow.com/questions/67291199/r-inconsistent-class-returned-by-median-when-vector-labelled-with-hmisc

[^30]: https://stackoverflow.com/questions/65109818/ifelse-returns-logical0-when-trying-to-change-values

[^31]: https://larmarange.github.io/labelled/articles/labelled.html

[^32]: https://forum.posit.co/t/data-table-ifelse-type-mismatch-error/16853

[^33]: https://debruine.github.io/post/case_functions/

[^34]: https://forum.posit.co/t/error-in-r-markdown-data-must-be-a-character-vector/100444

[^35]: https://stackoverflow.com/questions/70383944/ifelse-behavior-and-related-error-incompatible-types-in-subassignment-type-fi

[^36]: https://www.reddit.com/r/RStudio/comments/1gzl4wn/trying_to_create_a_new_vector_using_if_statements/

