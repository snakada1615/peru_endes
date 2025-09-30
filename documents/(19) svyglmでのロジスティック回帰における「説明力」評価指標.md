<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# svyglmでのロジスティック回帰における「説明力」評価指標

調査データを扱う survey パッケージの `svyglm()` でロジスティック回帰を適用した場合、線形回帰のような決定係数 R² は直接得られません。代わりに以下のような**疑似 R²（Pseudo‐R²）**や**モデル適合度指標**を使うのが一般的です。

## 1. McFadden の疑似 R²

-   定義： \$ R\^2\_{McF} = 1 - \frac{\ell_{モデル}}{\ell_{切片のみ}} \$ ここで $\ell$ は対数尤度（log‐likelihood）です。
-   解釈：0.2～0.4 を良好とみなすことが多い。
-   計算例（擬似コード）：

``` r
# フルモデル
fit_full <- svyglm(Y ~ X1 + X2, design=svy_design, family=quasibinomial())
# 切片のみモデル
fit_null <- svyglm(Y ~ 1, design=svy_design, family=quasibinomial())
R2_McF <- 1 - as.numeric(logLik(fit_full) / logLik(fit_null))
```

## 2. Cox & Snell／Nagelkerke の疑似 R²

-   Cox & Snell： \$ R\^2\_{CS} = 1 - \left(\frac{L_0}{L_1}\right)\^{2/n} \$
-   Nagelkerke（最大化版）： \$ R\^2\_{N} = \frac{R^2_{CS}}{1 - L_0^{2/n}} \$
-   n は有効サンプルサイズ。
-   Nagelkerke は最大 1 となるため解釈しやすい。

## 3. Tjur の D 判別係数（Tjur’s R²）

-   定義： \$ D = \bar{\hat p}*{Y=1} -* \bar{\hat p}{Y=0} \$ すなわち、事象発生群と非発生群での平均予測確率の差。
-   解釈：0～1；大きいほど群間の識別力が高い。

## 4. ROC 曲線下面積（AUC）

-   説明力というより識別力指標だが、モデルの性能評価に広く用いられる。
-   survey デザイン対応には `survey` + `pROC` などを組み合わせて、重み付き AUC を計算可能。

## 5. 実装上の注意

-   `svyglm()` は対数尤度を補正して返すため、上記式にそのまま使えるか要確認。
-   サンプルサイズ n ではなく「有効サンプルサイズ（デザイン効果考慮後）」を用いるのが厳密。
-   R パッケージ例：
    -   **pscl::pR2()** で McFadden, Cox‐Snell, Nagelkerke を計算
    -   **DescTools::PseudoR2()**
    -   **performance::r2_nagelkerke()**（survey 対応要検討）

------------------------------------------------------------------------

**推奨フロー**

1.  切片のみモデルを作成
2.  Full モデルの対数尤度と比較し、McFadden R² を計算
3.  必要に応じて Cox‐Snell／Nagelkerke R²、Tjur R²、AUC も併用し、モデルの説明力・識別力を多角的に評価する。

# 以下のように擬似R2を求めました。結果に何か問題あるでしょうか？

``` r
# Survey-weighted GLM 

final_model_svy <- svyglm(
   final_formula,
   design = svy_design,
   family = binomial
   ) 

Warning in eval(family\$initialize) : non-integer #successes in a binomial glm!

# 説明力を評価するためのnull_model 

null_model_svy \<- svyglm(
   nt_ch_stunt \~ 1,
   design = svy_design,
   family = binomial
   ) 

Warning in eval(family\$initialize) : non-integer #successes in a binomial glm!

# 説明力の計算（擬似R2） 

pseudo_r2 <- 1 - as.numeric(logLik(final_model_svy) / logLik(null_model_svy)) 

Warning in logLik.svyglm(final_model_svy) : svyglm not fitted by maximum likelihood. 
Warning in logLik.svyglm(null_model_svy) : svyglm not fitted by maximum likelihood.

cat("擬似R²:", round(pseudo_r2, 4), "\n") 擬似R²: 0.0697
```

あなたのコードには**3つの問題**があります。これらの警告メッセージから問題を特定できます。[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-1], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-2], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-3], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-4]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-1]: <https://stackoverflow.com/questions/12953045/warning-non-integer-successes-in-a-binomial-glm-survey-packages>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-2]: <https://rdrr.io/rforge/survey/src/R/dAIC.R>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-3]: <https://rdrr.io/rforge/survey/man/psrsq.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-4]: <https://www.rdocumentation.org/packages/survey/versions/4.4-8/topics/svyglm>

## 問題点の詳細

### 1. 「non-integer #successes in a binomial glm!」警告

-   **原因**: `family = binomial` を使用している際、サンプリング重みが非整数であることが原因[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-5], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-6]
-   **解決法**: `family = quasibinomial()` を使用する[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-7], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-8], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-9]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-5]: <https://www.rdocumentation.org/packages/survey/versions/4.4-8/topics/svyglm>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-6]: <https://stackoverflow.com/questions/12953045/warning-non-integer-successes-in-a-binomial-glm-survey-packages>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-7]: <http://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svyglm.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-8]: <https://stackoverflow.com/questions/12953045/warning-non-integer-successes-in-a-binomial-glm-survey-packages>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-9]: <https://www.rdocumentation.org/packages/survey/versions/4.4-8/topics/svyglm>

``` r
final_model_svy <- svyglm(
  final_formula,
  design = svy_design,
  family = quasibinomial()  # binomial の代わりに
)
```

### 2. 「svyglm not fitted by maximum likelihood」警告

-   **原因**: `svyglm()` は最尤推定を使用せず、重み付き推定量を使用するため、`logLik()` 関数が正確な対数尤度を返さない[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-10], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-11], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-12]
-   **問題**: この警告により、擬似R²の計算が不正確になる可能性がある[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-13]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-10]: <https://rdrr.io/rforge/survey/src/R/dAIC.R>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-11]: <https://notstatschat.rbind.io/2024/08/27/the-missing-test-in-survey-regression-models/>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-12]: <https://stackoverflow.com/questions/15933836/fitting-model-in-svyglm>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-13]: <https://rdrr.io/rforge/survey/src/R/dAIC.R>

### 3. 擬似R²計算の不適切さ

-   あなたの計算方法は survey データに対しては**不適切**です[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-14], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-15]
-   survey パッケージには専用の `psrsq()` 関数が用意されています[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-16], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-17], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-18]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-14]: <https://www.stata.com/statalist/archive/2006-05/msg00953.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-15]: <https://www.statalist.org/forums/forum/general-stata-discussion/general/1423386-can-i-get-a-pseudo-r-squared-in-svy-logistic>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-16]: <https://rdrr.io/rforge/survey/man/psrsq.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-17]: <https://stats.oarc.ucla.edu/r/seminars/survey-data-analysis-with-r/>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-18]: <https://search.r-project.org/CRAN/refmans/survey/html/psrsq.html>

## 正しい解決方法

``` r
# 1. quasibinomial を使用
final_model_svy <- svyglm(
  final_formula,
  design = svy_design,
  family = quasibinomial()
)

null_model_svy <- svyglm(
  nt_ch_stunt ~ 1,
  design = svy_design,
  family = quasibinomial()
)

# 2. 専用の psrsq() 関数を使用
library(survey)
cox_snell_r2 <- psrsq(final_model_svy, method = "Cox-Snell")
nagelkerke_r2 <- psrsq(final_model_svy, method = "Nagelkerke")

cat("Cox-Snell R²:", round(cox_snell_r2, 4), "\n")
cat("Nagelkerke R²:", round(nagelkerke_r2, 4), "\n")
```

## なぜ psrsq() を使うべきか

-   `psrsq()` 関数は複雑な調査デザインに対応した**デザイン一貫性のある推定量**を提供します[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-19], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-20], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-21]
-   通常の対数尤度比に基づく計算は、調査重みがある場合には適切ではありません[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-22], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-23]
-   Thomas Lumley による論文で、複雑標本調査における擬似R²の適切な計算方法が示されています[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-24], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-25]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-19]: <https://arxiv.org/abs/1701.07745>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-20]: <https://onlinelibrary.wiley.com/doi/abs/10.1111/anzs.12187>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-21]: <https://rdrr.io/rforge/survey/man/psrsq.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-22]: <https://www.statalist.org/forums/forum/general-stata-discussion/general/1423386-can-i-get-a-pseudo-r-squared-in-svy-logistic>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-23]: <https://www.stata.com/statalist/archive/2006-05/msg00953.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-24]: <https://onlinelibrary.wiley.com/doi/abs/10.1111/anzs.12187>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-25]: <https://arxiv.org/abs/1701.07745>

あなたの現在の擬似R²値（0.0697）は、不正確な計算方法による結果の可能性が高いため、上記の修正を行うことを強く推奨します。[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-26], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-27], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-28] [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-29], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-30], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-31], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-32], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-33], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-34], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-35], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-36], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-37], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-38], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-39], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-40], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-41], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-42], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-43], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-44], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-45], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-46], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-47], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-48], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-49], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-50], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-51], [^(19-svyglmでのロジスティック回帰における「説明力」評価指標-52]

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-26]: <https://stats.oarc.ucla.edu/r/seminars/survey-data-analysis-with-r/>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-27]: <https://search.r-project.org/CRAN/refmans/survey/html/psrsq.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-28]: <https://rdrr.io/rforge/survey/man/psrsq.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-29]: [<https://epub.ub.uni-muenchen.de/1421/1/paper_18.pdf>]{style="display:none"}

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-30]: <https://stat.ethz.ch/pipermail/r-help/2008-August/170154.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-31]: <https://arxiv.org/pdf/1701.07745.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-32]: <https://www.reddit.com/r/rstats/comments/a6sg38/weight_argument_in_the_bestglm_function_is/>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-33]: <https://www.reddit.com/r/RStudio/comments/1hm71tb/how_to_deal_with_heteroscedasticity_when_using/>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-34]: <https://github.com/alan-turing-institute/PosteriorBootstrap/issues/16>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-35]: <https://github.com/tidymodels/broom/issues/572>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-36]: <https://stackoverflow.com/questions/73926485/survey-package-how-do-i-get-r-squared-from-a-svyglm-object>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-37]: <http://elearn.psgcas.ac.in/nptel/courses/video/109107190/lec25.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-38]: <https://rpubs.com/corey_sparks/58200>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-39]: <https://stackoverflow.com/questions/31022213/pseudo-r²-for-a-poisson-glm-with-offset>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-40]: <https://www.bookdown.org/rwnahhas/RMPH/survey-logistic.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-41]: <https://rdrr.io/cran/cregg/man/cj_tidy.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-42]: <https://discourse.mc-stan.org/t/survey-weights-in-brms-stan-simulation-based-on-design-effect-feedback-sought/28625>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-43]: <https://stackoverflow.com/questions/68787575/how-should-you-use-scaled-weights-with-the-svydesign-function-in-the-survey-pa>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-44]: <https://www.idescat.cat/sort/sort481/48.1.2.Iparragirre-etal.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-45]: <https://researchmethodscommunity.sagepub.com/blog/whats-the-best-r-squared-for-logistic-regression>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-46]: <https://cran.r-project.org/web/packages/survey/refman/survey.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-47]: <ftp://cran.r-project.org/pub/R/web/packages/survey/refman/survey.html>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-48]: <https://public.dhe.ibm.com/software/analytics/spss/documentation/statistics/20.0/en/client/Manuals/IBM_SPSS_Complex_Samples.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-49]: <https://cran.r-project.org/web/packages/survey/survey.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-50]: <http://r.meteo.uni.wroc.pl/web/packages/survey/survey.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-51]: <https://r.meteo.uni.wroc.pl/web/packages/survey/survey.pdf>

[^(19-svyglmでのロジスティック回帰における「説明力」評価指標-52]: <https://www.rdocumentation.org/packages/survey/versions/4.4-8>

::: {align="center"}
⁂
:::

# 疑似 R² の一般的 R² との解釈上の違いと留意点

擬似 R²（McFadden、Cox–Snell、Nagelkerke、Tjur など）は、線形回帰の決定係数 R² と同様に「モデルの説明力」を示唆する指標ですが、**厳密には異なる性質**をもつため、以下の点に留意して解釈してください。

## 1. 「分散説明率」ではない

-   線形回帰の R² は「応答変数の総変動に対して、モデルがどれだけ変動を説明したか」を百分率で示す。
-   擬似 R² は「尤度比」や「平均予測確率の差」などに基づく指標であり、**分散の説明率ではない**ため、R² のように「○○％説明できる」とは言えません。

## 2. 各指標ごとの解釈

-   **McFadden R²**：0.2～0.4 が「良いモデル」とされるが、値は線形 R² よりも小さく出る傾向があります。
-   **Cox–Snell R²**：最大値が 1 より小さくなるため、Nagelkerke R² でスケーリング補正した方が解釈しやすい場合があります。
-   **Nagelkerke R²**：Cox–Snell を 0–1 に拡張したもの。あくまで「McFadden R² より大きく出る傾向がある」程度の理解で十分です。
-   **Tjur R²**：二群の平均予測確率差。「大きいほどモデルの識別力が高い」と直感的に解釈できますが、線形回帰の R² とは異なり「変動説明率」ではありません。

## 3. 比較の注意点

-   **同一データ・同一目的変数内での比較**に用いるのが適切です。異なるモデル間やデータ間で数値を直接比較すると、指標の性質の違いによるバイアスが生じます。
-   線形回帰の R² と擬似 R² の値を並べて評価しないこと。種類の異なる指標同士の比較は無意味です。

## 4. 実務上の扱い

-   **モデル選択**：AIC や BIC、交差検証による予測精度など、他の評価指標と組み合わせて総合的に判断する。
-   **報告例**：擬似 R² を示しつつ、「線形回帰の R² とは異なる指標であり、モデル間比較に用いた」旨を明記すると良いでしょう。

------------------------------------------------------------------------

**まとめ** 擬似 R² は「モデルの適合度や識別力を示す目安」ですが、線形回帰の R² のように「説明率」として直接解釈してはいけません。あくまで同一データ・同一目的変数内でのモデル比較用指標として用い、AIC/BIC や交差検証など他の手法と組み合わせて評価するのが適切です。
