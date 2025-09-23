<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# listで対応することにします

ところで、listで特定の値を参照する際に、なぜ二重カッコ[[]]を使うのでしょうか？

R言語でlistの要素を参照する際、「[[ ]]」の二重カッコを使う理由は、listから要素そのもの（元のデータ型）を直接取り出すためです。[^1][^3][^5]

### シングルカッコ「[ ]」との違い

- シングルカッコ「[ ]」は、listから部分集合（listの一部）を返します。[^3][^1]
- ダブルカッコ「[[ ]]」は、指定した要素そのものを返します。つまり、listの中に格納されたオブジェクトがそのまま返され、リスト構造は除外されます。[^5][^8][^1]


### 具体例

```r
lst <- list(a = 1:3, b = "foo")
lst[^1]     # 1番目の要素を持つ「list」を返す（list型のまま）[web:21][web:25]
lst[[^1]]   # 1番目の要素そのもの（ベクトル c(1,2,3)）を返す[web:21][web:23]
lst$b      # 名前「b」の要素そのものを返す（"foo"）[web:23]
```


### 解説

- ダブルカッコで取り出した場合は、listではなく、元のデータ型（ベクトル・データフレーム・関数など）がそのまま返ります。[^8][^1][^5]
- シングルカッコの場合、あくまでlist型が返るため、参照した部分がlistとして残ります。[^1][^3]


### 使い分け

- listの中身を直接操作・計算したい場合は「[[ ]]」が便利です。[^3][^5][^1]
- 複数要素をまとめて抜き出したい場合、シングルカッコ「[ ]」が有効です。[^5][^3]

***
二重カッコ「[[ ]]」は、listから中身そのものを“アンボックス”して使いたい場面で利用します。[^8][^1][^5]
<span style="display:none">[^10][^2][^4][^6][^7][^9]</span>

```
<div style="text-align: center">⁂</div>
```

[^1]: https://stackoverflow.com/questions/1169456/the-difference-between-bracket-and-double-bracket-for-accessing-the-el

[^2]: https://www.geeksforgeeks.org/r-language/difference-between-single-and-double-square-brackets-in-r/

[^3]: https://www.gastonsanchez.com/R-coding-basics/lists.html

[^4]: https://davetang.org/muse/2013/08/16/double-square-brackets-in-r/

[^5]: https://dataanalytics.org.uk/r-object-elements-brackets-double-brackets-and/

[^6]: https://faculty.washington.edu/otoomet/info201-book/lists.html

[^7]: https://biostats-r.github.io/biostats/workingInR/060_bestiary.html

[^8]: https://www.oreilly.com/library/view/r-in-a/9781449358204/ch06s05.html

[^9]: https://www.reddit.com/r/Rlanguage/comments/hdcci4/functionally_what_difference_does_using_a_single/

[^10]: https://www.rtutors.co.uk/basic-syntax-and-data-structures-lists

