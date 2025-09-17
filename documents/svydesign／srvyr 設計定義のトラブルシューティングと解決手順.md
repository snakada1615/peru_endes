<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# svydesign／srvyr 設計定義のトラブルシューティングと解決手順

以下は、DHSデータ（10年分プール）を対象に `survey::svydesign()` および `srvyr::as_survey_design()` を正しく動作させるまでの手順とポイントです。

------------------------------------------------------------------------

## 1. 発生したエラー

```         
Error in terms.formula(formula, data = data) :  
  invalid model formula in ExtractVars  
Error: no more error handlers available (recursive errors?)  
```

-   主な原因は、**ラベル付き変数（haven/sjlabelledの `dbl+lbl`）** や **文字型変数** をそのまま `svydesign()` に渡していること。

------------------------------------------------------------------------

## 2. データ問題の整理

-   **`v021`（PSU）**: 数値型またはファクター型に
-   **`v022`（層化）**: ラベル付き数値 → 純粋な数値に
-   **`year`**: 文字型 → 数値型に
-   **`v005`（調査重み）**: 数値型（計算式は事前に実行）

------------------------------------------------------------------------

## 3. 解決のポイント

1.  **ラベルを完全に除去**（`zap_labels()`）
2.  **文字型 → 数値型** に明示的に変換
3.  **手動で層化変数** を作成
4.  **PSUを一意化**（年次込みで `psu_unique`）
5.  `survey` と `srvyr` それぞれの仕様に合わせる

------------------------------------------------------------------------

## 4. 修正コード例

### 4.1 データクリーニング＆変数準備

``` r
library(dplyr)
library(haven)
library(srvyr)   # srvyrを使う場合

ch_data_clean <- ch_data_anthropometric %>%
  # ① ラベルを除去
  zap_labels() %>%
  # ② 型変換
  mutate(
    v021 = as.numeric(as.character(v021)),
    v022 = as.numeric(as.character(v022)),
    year = as.numeric(as.character(year)),
    v005 = as.numeric(as.character(v005)),
    # ③ 調査重みを事前に計算
    survey_weights = v005 / 1000000
  ) %>%
  # ④ 層化・PSU変数を追加
  mutate(
    strata_combined = paste(v022, year, sep = "_"),
    psu_unique     = as.numeric(as.factor(paste(year, v021, sep = "_")))
  )
```

------------------------------------------------------------------------

### 4.2 surveyパッケージでの設計定義

``` r
library(survey)

design_pooled <- svydesign(
  ids     = ~psu_unique,
  strata  = ~strata_combined,
  weights = ~survey_weights,  # 事前に計算した変数
  data    = ch_data_clean,
  nest    = TRUE
)
```

------------------------------------------------------------------------

### 4.3 srvyrパッケージでの設計定義

``` r
design_pooled_srvyr <- ch_data_clean %>%
  as_survey_design(
    ids     = psu_unique,
    strata  = strata_combined,
    weights = survey_weights,
    nest    = TRUE
  )
```

------------------------------------------------------------------------

## 5. 注意点

-   **`zap_labels()`後は必ず型を確認** (`str()` で `v021`, `v022`, `year`, `survey_weights` が数値型になっていること)
-   `survey` では重みを式で指定可能だが、`srvyr` では **変数名しか指定できない**
-   複数年次データは **年次込みのPSU/層化変数** を作成すると安全

以上の手順を踏むことで、複数年次のDHSプールデータでも `svydesign()`／`as_survey_design()` が正常に動作します。
