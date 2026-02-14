<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## 問題＋回答のマークダウン

``` markdown
# 演習 2.1–2.5（iris を用いた演習：問題＋解答例）

## 演習 2-1：iris で SEQUENCES と型を確認する

### 問題

1. `iris` データセットを読み込みなさい（`data(iris)` を使用してよい）。
2. `Species` 列のユニークな値の数を確認しなさい。
3. `Sepal.Length` の値が昇順に並んだベクトルを作成しなさい。
4. 「1 から `iris` の行数までの整数列」を、  
   - コロン演算子 `:`  
   - `seq()` 関数  
   の 2 通りの方法で作成しなさい。
5. 作成した 2 つのベクトルについて、`identical()` と `str()` を使って、  
   その違いがあるかどうかを確認し、結果を言葉で説明しなさい。

### 解答例

```r
# 1. データの読み込み
data(iris)

# 2. Species のユニークな値とその個数
unique(iris$Species)
length(unique(iris$Species))
# → 3 種類

# 3. Sepal.Length の昇順ソート
sepal_sorted <- sort(iris$Sepal.Length)
head(sepal_sorted)
tail(sepal_sorted)

# 4. 1 から行数までの整数列を 2 通りで作成
n <- nrow(iris)
x1 <- 1:n
x2 <- seq(1, n, 1)

# 5. identical() と str() でチェック
identical(x1, x2)
str(x1)
str(x2)
```

-   `identical(x1, x2)` は `TRUE` となり、
-   `str(x1)` と `str(x2)` を見ると、どちらも `"int"` 型で同じ構造になっていることが分かる。 したがって、この例では 2 通りの生成方法は結果として完全に同じオブジェクトを返している。

------------------------------------------------------------------------

## 演習 2-2：iris を使った BASIC STATISTICS

### 問題

1.  `Sepal.Length` の
    -   平均
    -   分散
    -   標準偏差
    -   中央値 を求めなさい（ベース R 関数のみを使用してよい）。
2.  `Sepal.Length` に `NA` を 1 つ追加した新しいベクトルを作り、 そのベクトルに対して `mean()` を
    -   `na.rm` を指定しない場合
    -   `na.rm = TRUE` を指定した場合 で比較しなさい。その違いを説明しなさい。
3.  `Species` ごとに `Sepal.Length` の平均を計算しなさい。 ベース R のみを用い、少なくとも次のどちらか一方を使って解きなさい。
    -   `tapply()`
    -   `aggregate()`

### 解答例

```{R}
data(iris)

x <- iris$Sepal.Length

# 1. 基本統計量
mean(x)
var(x)
sd(x)
median(x)

# 2. NA を追加して mean() の挙動を確認
x_na <- c(x, NA)

mean(x_na)                # NA が含まれるので結果は NA
mean(x_na, na.rm = TRUE)  # na.rm = TRUE で NA を無視して計算

# 3. Species ごとの Sepal.Length 平均

# tapply() を用いる例
tapply(iris$Sepal.Length, iris$Species, mean)

# aggregate() を用いる例
aggregate(Sepal.Length ~ Species, data = iris, FUN = mean)
```

-   `mean(x_na)` は 1 つでも `NA` が含まれると `NA` を返す。
-   `mean(x_na, na.rm = TRUE)` とすると、`NA` を除外して平均を計算する。
-   `tapply()` と `aggregate()` はどちらも `Species` ごとの平均値を計算するが、戻り値の形式が異なる（`tapply` は配列 / ベクトル、`aggregate` は `data.frame`）。

------------------------------------------------------------------------

## 演習 2-3：SCRIPTING のための簡単スクリプト

### 問題

1.  ファイル名を `lecture2_iris.R` として、新しい R スクリプトファイルを作成しなさい。
2.  スクリプト内で `iris` データセットを読み込み、`Petal.Length` について以下の統計量を計算し、`print()` あるいは `cat()` を使ってコンソールに出力しなさい。
    -   データ数 `n`
    -   平均
    -   標準偏差
    -   最小値・最大値
    -   `NA` の個数
3.  作成したスクリプトを保存し、R コンソールから `source("lecture2_iris.R")` を実行して、期待どおりの結果が表示されるか確認しなさい。
4.  必要に応じてメッセージの整形（見出しの追加・改行など）を行い、可読性を高めなさい。

### 解答例（`lecture2_iris.R` の中身の一例）

```{R}
# lecture2_iris.R

data(iris)

x <- iris$Petal.Length

cat("=== Petal.Length summary ===\n")
cat("n          :", length(x), "\n")
cat("mean       :", mean(x), "\n")
cat("sd         :", sd(x), "\n")
cat("min, max   :", min(x), max(x), "\n")
cat("NA count   :", sum(is.na(x)), "\n")
```

コンソール側では次のように実行する：

```{R}
source("lecture2_iris.R")
```

出力例：

``` text
=== Petal.Length summary ===
n          : 150 
mean       : 3.758 
sd         : 1.765298 
min, max   : 1 6.9 
NA count   : 0 
```

------------------------------------------------------------------------

## 演習 2-4：FUNCTIONS – iris を引数にとる関数

### 問題

1.  数値ベクトル `x` を引数にとり、
    -   平均
    -   標準偏差 を返す関数 `my_stats()` を作成しなさい。戻り値は長さ 2 の数値ベクトルや名前付きベクトルとしなさい。
2.  データフレーム `df` と列名（文字列）`col_name` を引数にとり、 `df[[col_name]]` に対して `my_stats()` を適用して結果を返す関数 `iris_stats()` を作成しなさい。 `iris` データセットと `"Petal.Width"` を引数に与えて動作を確認しなさい。
3.  `iris` データフレームと列名（文字列）を引数にとり、 `Species` ごとに指定列の `my_stats()` を計算して返す関数 `iris_stats_by_species()` を作成しなさい。 戻り値の形式は、`list` でも `data.frame` でもよいものとします。

### 解答例

```{R}
data(iris)

# 1. ベクトルの平均と標準偏差を返す関数
my_stats <- function(x) {
  m <- mean(x, na.rm = TRUE)
  s <- sd(x, na.rm = TRUE)
  c(mean = m, sd = s)
}

my_stats(iris$Sepal.Width)

# 2. データフレームと列名から統計量を返す関数
iris_stats <- function(df, col_name) {
  x <- df[[col_name]]
  my_stats(x)
}

iris_stats(iris, "Petal.Width")

# 3. Species ごとに my_stats を適用する関数
iris_stats_by_species <- function(df, col_name) {
  tapply(df[[col_name]], df$Species, my_stats)
}

iris_stats_by_species(iris, "Petal.Length")
```

-   `my_stats()` は NA を除外して平均・標準偏差を計算する。
-   `iris_stats()` は列名を文字列で指定できるようにしているため、スクリプトや関数内で柔軟に使える。
-   `iris_stats_by_species()` は `tapply()` を用いて `Species` ごとに `my_stats()` を適用している。

------------------------------------------------------------------------

## 演習 2-5：SCOPING と CONTROL FLOW – 型チェックと分岐

### 問題

1.  入力ベクトル `x` が数値型 (`numeric`) でない場合にエラーを返す関数 `safe_mean()` を作成しなさい。
    -   数値の場合は `mean(x, na.rm = TRUE)` を返すこと。
    -   数値でない場合は `stop("x must be numeric")` のようなメッセージで停止すること。
2.  データフレーム `df` と列名（文字列）`col_name` を引数にとる関数 `describe_col()` を作成しなさい。
    -   列が数値 (`numeric`) の場合：その列の平均を返す。
    -   列が因子 (`factor`) または文字列 (`character`) の場合：`table()` の結果を返す。
    -   それ以外の型の場合： `"Unsupported type"` のような文字列を返す。
3.  文字列 `sp`（`"setosa"`, `"versicolor"`, `"virginica"` など）を引数にとり、 種類に応じて異なるメッセージを返す関数 `species_message()` を作成しなさい。
    -   例：
        -   `"setosa"` → `"Small flowers"`
        -   `"versicolor"` → `"Medium flowers"`
        -   `"virginica"` → `"Large flowers"` `if` / `else if` / `else` あるいは `switch()` のどちらを使っても構いません。

### 解答例

```{R}
data(iris)

# 1. 型チェック付きの mean 関数
safe_mean <- function(x) {
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  mean(x, na.rm = TRUE)
}

safe_mean(iris$Sepal.Length)
# safe_mean(iris$Species)  # 実行するとエラーが出る

# 2. 列の型に応じて処理を変える関数
describe_col <- function(df, col_name) {
  x <- df[[col_name]]
  
  if (is.numeric(x)) {
    return(mean(x, na.rm = TRUE))
  } else if (is.factor(x) || is.character(x)) {
    return(table(x))
  } else {
    return("Unsupported type")
  }
}

describe_col(iris, "Sepal.Length")
describe_col(iris, "Species")

# 3. Species に応じてメッセージを返す関数
species_message <- function(sp) {
  if (sp == "setosa") {
    "Small flowers"
  } else if (sp == "versicolor") {
    "Medium flowers"
  } else if (sp == "virginica") {
    "Large flowers"
  } else {
    "Unknown species"
  }
}

species_message("setosa")
species_message(as.character(iris$Species))[^1]
species_message("unknown")
```

-   `safe_mean()` では `if (!is.numeric(x))` の条件で型をチェックしており、 スコーピングの観点では関数内部の `x` は関数呼び出しのたびに新しく評価されるローカル変数となる。
-   `describe_col()` は `df[[col_name]]` を使うことで、列名を動的に指定できる。
-   `species_message()` は `if` / `else if` チェーンで分岐しているが、`switch(sp, ...)` を使ってもよい。

\\\

::: {align="center"}
:::
