<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## 問題だけのマークダウン

``` markdown
# 演習 2.1–2.5（iris を用いた演習）

## 演習 2-1：iris で SEQUENCES と型を確認する

1. `iris` データセットを読み込みなさい（`data(iris)` を使用してよい）。
2. `Species` 列のユニークな値の数を確認しなさい。
3. `Sepal.Length` の値が昇順に並んだベクトルを作成しなさい。
4. 「1 から `iris` の行数までの整数列」を、  
   - コロン演算子 `:`  
   - `seq()` 関数  
   の 2 通りの方法で作成しなさい。
5. 作成した 2 つのベクトルについて、`identical()` と `str()` を使って、  
   その違いがあるかどうかを確認し、結果を言葉で説明しなさい。

---

## 演習 2-2：iris を使った BASIC STATISTICS

1. `Sepal.Length` の  
   - 平均  
   - 分散  
   - 標準偏差  
   - 中央値  
   を求めなさい（ベース R 関数のみを使用してよい）。
2. `Sepal.Length` に `NA` を 1 つ追加した新しいベクトルを作り、  
   そのベクトルに対して `mean()` を  
   - `na.rm` を指定しない場合  
   - `na.rm = TRUE` を指定した場合  
   で比較しなさい。その違いを説明しなさい。
3. `Species` ごとに `Sepal.Length` の平均を計算しなさい。  
   ベース R のみを用い、少なくとも次のどちらか一方を使って解きなさい。  
   - `tapply()`  
   - `aggregate()`  

---

## 演習 2-3：SCRIPTING のための簡単スクリプト

1. ファイル名を `lecture2_iris.R` として、新しい R スクリプトファイルを作成しなさい。
2. スクリプト内で `iris` データセットを読み込み、`Petal.Length` について以下の統計量を計算し、`print()` あるいは `cat()` を使ってコンソールに出力しなさい。  
   - データ数 `n`  
   - 平均  
   - 標準偏差  
   - 最小値・最大値  
   - `NA` の個数
3. 作成したスクリプトを保存し、R コンソールから `source("lecture2_iris.R")` を実行して、期待どおりの結果が表示されるか確認しなさい。
4. 必要に応じてメッセージの整形（見出しの追加・改行など）を行い、可読性を高めなさい。

---

## 演習 2-4：FUNCTIONS – iris を引数にとる関数

1. 数値ベクトル `x` を引数にとり、  
   - 平均  
   - 標準偏差  
   を返す関数 `my_stats()` を作成しなさい。戻り値は長さ 2 の数値ベクトルや名前付きベクトルとしなさい。
2. データフレーム `df` と列名（文字列）`col_name` を引数にとり、  
   `df[[col_name]]` に対して `my_stats()` を適用して結果を返す関数 `iris_stats()` を作成しなさい。  
   `iris` データセットと `"Petal.Width"` を引数に与えて動作を確認しなさい。
3. `iris` データフレームと列名（文字列）を引数にとり、  
   `Species` ごとに指定列の `my_stats()` を計算して返す関数 `iris_stats_by_species()` を作成しなさい。  
   戻り値の形式は、`list` でも `data.frame` でもよいものとします。

---

## 演習 2-5：SCOPING と CONTROL FLOW – 型チェックと分岐

1. 入力ベクトル `x` が数値型 (`numeric`) でない場合にエラーを返す関数 `safe_mean()` を作成しなさい。  
   - 数値の場合は `mean(x, na.rm = TRUE)` を返すこと。  
   - 数値でない場合は `stop("x must be numeric")` のようなメッセージで停止すること。
2. データフレーム `df` と列名（文字列）`col_name` を引数にとる関数 `describe_col()` を作成しなさい。  
   - 列が数値 (`numeric`) の場合：その列の平均を返す。  
   - 列が因子 (`factor`) または文字列 (`character`) の場合：`table()` の結果を返す。  
   - それ以外の型の場合： `"Unsupported type"` のような文字列を返す。
3. 文字列 `sp`（`"setosa"`, `"versicolor"`, `"virginica"` など）を引数にとり、  
   種類に応じて異なるメッセージを返す関数 `species_message()` を作成しなさい。  
   - 例：  
     - `"setosa"` → `"Small flowers"`  
     - `"versicolor"` → `"Medium flowers"`  
     - `"virginica"` → `"Large flowers"`  
   `if` / `else if` / `else` あるいは `switch()` のどちらを使っても構いません。
```

------------------------------------------------------------------------
