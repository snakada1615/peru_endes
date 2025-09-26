<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# LASSOとPSMを用いた多群介入効果評価のまとめ

## 基本設計と主な手順

### 1. 分析背景

-   対象は non-treated, early-treated, late-treated の3群。
-   early/late-treated群には「介入前」「介入後」データがある。
-   傾向スコアマッチング（PSM）で介入効果（例：child_stunted, 栄養指標）を検証する。

------------------------------------------------------------------------

### 2. マッチング変数選定の原則

-   **介入効果推定バイアス防止のため、介入前の変数だけで変数選定を行う**。
-   アウトカム（child_stunted）はマッチング時に目的変数として使わず、介入前指標としてのみ候補とする。
-   介入前child_stuntedもグループ特異的差の補正のため説明変数に組み込む。

------------------------------------------------------------------------

### 3. LASSO変数選定の操作論

#### （a）従来型の2群比較 ×2回

-   例）non-treated vs early-treated, non-treated vs late-treated で各々バイナリ分類のLASSOを行い、変数選択。
-   全てのバイナリ比較で「非ゼロ係数」となった変数の和集合をマッチングに使う。

#### （b）多クラス（3群）分類LASSO

-   glmnetパッケージの `family="multinomial"` を利用し、目的変数は "non-treated"・"early"・"late" の3値 factor。
-   各クラスへの割付けを判別するために重要な共変量を自動選択し、一括してマッチング変数として利用できる。
-   **本ケースではこの“多クラスLASSO”が手間と論理性の点で推奨される**。

------------------------------------------------------------------------

#### 例（R, glmnet/多クラスLASSO）

```{r}
aaa
library(glmnet) 
X <- model.matrix(~ . - group, data = df) # group: 3群factor 
fit <- cv.glmnet(X, df$group, family = "multinomial", alpha = 1) 
selected_vars <- coef(fit, s = "lambda.min")


```

------------------------------------------------------------------------

### 4. 固定効果・年次ダミーの扱い

-   固定効果や年次ダミー変数も **他の共変量と同時にダミー化しLASSOに投入**してOK。
-   ダミーがLASSOプロセスでゼロになれば「説明力が弱い」ことを意味するため、大きな問題はないが、
    -   政策的・疫学的に年次効果が必ず必要な場合は、「固定」として必ず投入する設計も可能。
-   基本は自動変数選択に任せ、「ゼロ＝年固定効果不要」とみなせる。

------------------------------------------------------------------------

### 5. 実際のPSMのフロー

1.  **介入前データでのみ**共変量候補（child_stunted含む）を抽出。
2.  （2群 or 多群LASSOで）目的変数を群ラベルとして変数選定。
3.  非ゼロ係数の変数を「マッチング変数」として傾向スコア推定に用いる。
4.  傾向スコアマッチング後、アウトカム（child_stunted 等）で効果検証。

------------------------------------------------------------------------

## 留意事項

-   サンプルサイズや研究状況に応じ（バイナリ or 多クラス）どちらの方法も可能だが、多群ならmultinomial LASSOが簡便かつ理論的。
-   LASSO選定後も、実務知見で追加/除外の調整を検討。
-   固定効果も選択対象にし、必要に応じて「必ず残す」処理も可能。

------------------------------------------------------------------------

## 参考

-   [傾向スコアのモデルに含める共変量選択のアプローチ][web:83]
-   [因果推論でコントロール変数の選択にLassoを使う：PDS Lasso][web:84]
-   [Propensity Score-Based Approaches in High Dimension...][web:108] \`\`\`

[^lassoとpsmを用いた多群介入効果評価のまとめ-1][^lassoとpsmを用いた多群介入効果評価のまとめ-2][^lassoとpsmを用いた多群介入効果評価のまとめ-3][^lassoとpsmを用いた多群介入効果評価のまとめ-4][^lassoとpsmを用いた多群介入効果評価のまとめ-5][^lassoとpsmを用いた多群介入効果評価のまとめ-6][^lassoとpsmを用いた多群介入効果評価のまとめ-7][^lassoとpsmを用いた多群介入効果評価のまとめ-8][^lassoとpsmを用いた多群介入効果評価のまとめ-9][^lassoとpsmを用いた多群介入効果評価のまとめ-10][^lassoとpsmを用いた多群介入効果評価のまとめ-11][^lassoとpsmを用いた多群介入効果評価のまとめ-12][^lassoとpsmを用いた多群介入効果評価のまとめ-13]

[^lassoとpsmを用いた多群介入効果評価のまとめ-1]: [<https://www.ibm.com/docs/ja/SS3RA7_18.6.0/nl/ja/pdf/ModelerScriptingAutomation.pdf>]{style="display:none"}

[^lassoとpsmを用いた多群介入効果評価のまとめ-2]: <https://www.trifields.jp/pypi-science-and-technology-2-6054>

[^lassoとpsmを用いた多群介入効果評価のまとめ-3]: <https://speakerdeck.com/tomoshige_n/qing-xiang-sukoanomoderunihan-merugong-bian-liang-xuan-ze-noapuroti>

[^lassoとpsmを用いた多群介入効果評価のまとめ-4]: <https://qiita.com/k_ryukius/items/df2526257ae0317c9379>

[^lassoとpsmを用いた多群介入効果評価のまとめ-5]: <https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2018.01010/pdf>

[^lassoとpsmを用いた多群介入効果評価のまとめ-6]: <https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/8/html-single/considerations_in_adopting_rhel_8/index>

[^lassoとpsmを用いた多群介入効果評価のまとめ-7]: <https://ides.hatenablog.com/entry/2024/05/26/224917>

[^lassoとpsmを用いた多群介入効果評価のまとめ-8]: <https://mhlw-grants.niph.go.jp/system/files/report_pdf/R4%E5%88%86%E6%8B%851_%E5%BA%B7%E6%B0%B8.pdf>

[^lassoとpsmを用いた多群介入効果評価のまとめ-9]: <https://www.docswell.com/s/6484025/KP27R7-2025-04-21-051814>

[^lassoとpsmを用いた多群介入効果評価のまとめ-10]: <https://files.solidworks.com/Supportfiles/Whats_new/2017/Japanese/whatsnew.pdf>

[^lassoとpsmを用いた多群介入効果評価のまとめ-11]: <https://evaluationjp.org/files/Vol20_No2.pdf>

[^lassoとpsmを用いた多群介入効果評価のまとめ-12]: <https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/7/html-single/7.2_release_notes/index>

[^lassoとpsmを用いた多群介入効果評価のまとめ-13]: <https://mhlw-grants.niph.go.jp/system/files/download_pdf/2022/202201012A.pdf>

::: {style="text-align: center"}
⁂
:::
