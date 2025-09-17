<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# `svyby`で結果が全てNAになる問題の整理

## 背景

- プールした複数年のサーベイデザイン (`design_pooled`) 上で、年別に
`nt_ch_stunt` の平均と標準誤差を `svyby(~nt_ch_stunt, ~year, design_pooled, svymean)` で計算したところ、すべてNAになった。


## 原因

- **singleton strata（単一PSUの層）** の存在
プール前に共通化した `strata_combined` の下で、ある年だけを切り出すとPSU（一次標本集団）が1つしか含まれない層が生じる。
- Surveyパッケージは層内に最低2つのPSUがないと分散推定ができず、標準誤差と信頼区間をNAで返す。


## 解決策の手順

1. **データ確認**
    - 年次ごとの観測数、欠損数を確認

```r
table(design_pooled$variables$year, useNA="ifany")
table(design_pooled$variables$year, design_pooled$variables$nt_ch_stunt, useNA="ifany")
```

2. **方法A：NA除去してサブセット作成（推奨）**
    - 解析変数のNAを含む観測を先に取り除き、singleton strataを回避

```r
design_clean <- subset(design_pooled, !is.na(nt_ch_stunt))
annual_mean <- svyby(
  formula = ~nt_ch_stunt,
  by      = ~year,
  design  = design_clean,
  FUN     = svymean,
  vartype = c("se","ci")
)
print(annual_mean)
```

3. **方法B：`na.rm`オプション指定**
    - `svymean`呼び出し時にNA除去を強制

```r
annual_mean <- svyby(
  ~nt_ch_stunt, ~year, design_pooled,
  FUN         = function(x, d) svymean(x, d, na.rm=TRUE),
  vartype     = c("se","ci"),
  na.rm.all   = TRUE,
  na.rm.by    = TRUE
)
```

4. **方法C：singleton strata処理設定変更**
    - `options(survey.lonely.psu="remove")` または `"average"` に切り替え

```r
options(survey.lonely.psu="remove")
# 再度 svyby を実行
```


## 最終的な解決と理由

- **方法A（NA除去）** で無事に数値が得られた。
- NA除去により、**各層に少なくとも2つ以上の有効PSU**が残り、分散推定が可能になるため。

---

以上が、今回の問題発生から解決までの流れとその理由の整理です。

