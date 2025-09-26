<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Repeated Cross Sectionデータを用いたPSM分析の進め方まとめ

------------------------------------------------------------------------

## 1. データの特徴と前提

-   **反復横断面（Repeated Cross Section）データ**は、同一個体を追跡しない複数時点の横断調査の集積であり、パネル追跡ができない。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-1][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-2]
-   個票レベルで時点を跨いだマッチングは不可能。

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-1]: <https://www.opml.co.uk/sites/default/files/migrated_bolt_files/wp-matching-differencing-repeat.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-2]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

------------------------------------------------------------------------

## 2. 基本手順

### ① ベースラインでPSM実施

-   **介入前データ（実施前の各州等）で傾向スコア（propensity score）を推定し、マッチング・重み付けを行う**。
-   共変量には、介入によって変化しうる変数（例：栄養状態）は含めず、施策決定要因やベースライン関連変数のみ用いる。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-3][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-4]

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-3]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC11788469/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-4]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC1513192/>

### ② 得られたマッチング・重み付けを介入後に適用

-   **介入後データも同じ傾向スコア重み（IPTWなど）を用いて集団間比較分析**を行う。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-5][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-6]
-   擬似パネル構築は必要なく、対象州・サンプル数が少なくても推定可能。

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-5]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-6]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC3710547/>

### ③ 結果変数として「変化量」「差分」を用いる

-   **stunted率などの変化量（介入後−介入前）または介入効果の差分を主要アウトカムとする**。
-   DID（差分の差分）やstaggered DIDと組み合わせて、複数施策導入・タイミングの違いも評価できる。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-7][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-8][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-9]

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-7]: <https://psantanna.com/files/Callaway_SantAnna_2020.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-8]: <https://www.nber.org/system/files/working_papers/w31842/w31842.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-9]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

### ④ バランス診断・感度分析

-   **マッチング後のバランス性・選択バイアス残存の検証**（標準化差、Rubin’s B/R等）。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-10][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-11]
-   平行トレンド仮定・共変量バランス仮定の検証なども重点的に行う。

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-10]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC3472075/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-11]: <https://www.opml.co.uk/sites/default/files/migrated_bolt_files/wp-matching-differencing-repeat.pdf>

------------------------------------------------------------------------

## 3. 推奨解析手法

-   傾向スコア重み付け（PSM/IPTW）＋DID/staggered DIDの組み合わせが可能。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-12][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-13][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-14]
-   サンプル数に応じて集団平均又は州ごとの個別ATTを推定。
-   擬似パネルや個票時系列比較は回避。

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-12]: <https://www.nber.org/system/files/working_papers/w31842/w31842.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-13]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-14]: <https://psantanna.com/files/Callaway_SantAnna_2020.pdf>

------------------------------------------------------------------------

## 4. 注意点

-   州数やサンプル数が少ない場合は推定分散が大きくなる為、信頼区間や堅牢性への配慮が重要。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-15]
-   平行トレンド仮定を満たすよう事前に変数・地域を吟味すること。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-16]
-   変化量分析やDID分析はベースライン差や観測不可能な交絡にも対応可能。[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-17][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-18]

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-15]: <https://www.nber.org/system/files/working_papers/w31842/w31842.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-16]: <https://soichiroy.github.io/files/papers/double_did.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-17]: <https://www.opml.co.uk/sites/default/files/migrated_bolt_files/wp-matching-differencing-repeat.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-18]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

------------------------------------------------------------------------

## 参考文献

-   Matching, differencing on repeat - Oxford Policy Management[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-19]
-   Callaway & Sant’Anna (2020), Difference-in-Differences with Multiple Time Periods[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-20]
-   Propensity Score Analysis With Baseline and Follow‐Up[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-21]
-   Variable selection for propensity score models[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-22]
-   Using propensity scores in difference-in-differences models to estimate treatment effects[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-23]
-   Propensity Score Estimation for Multiple Treatments[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-24]
-   Designing Difference-in-Difference Studies with Staggered Implementation[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-25]

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-19]: <https://www.opml.co.uk/sites/default/files/migrated_bolt_files/wp-matching-differencing-repeat.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-20]: <https://psantanna.com/files/Callaway_SantAnna_2020.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-21]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC11788469/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-22]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC1513192/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-23]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4267761/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-24]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC3710547/>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-25]: <https://www.nber.org/system/files/working_papers/w31842/w31842.pdf>

------------------------------------------------------------------------

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-26][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-27][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-28][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-29][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-30][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-31][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-32][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-33][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-34][^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-35]

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-26]: [<https://www.e.okayama-u.ac.jp/economic_association/paper/pdf/%E2%85%A1_89.pdf>]{style="display:none"}

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-27]: <https://www.struers.com/ja-JP/Knowledge/Image-analysis>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-28]: <https://ipss.repo.nii.ac.jp/record/2000463/files/sh34090301.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-29]: <https://www.mitutoyo.co.jp/public/cms-assets/FAQ/FAQID-262_%E7%B7%8F%E5%90%88%E3%82%AB%E3%82%BF%E3%83%AD%E3%82%B0No13%E3%80%80_%E3%80%80%E7%B2%BE%E5%AF%86%E6%B8%AC%E5%AE%9A%E6%A9%9F%E5%99%A8%E3%81%AE%E8%B1%86%E7%9F%A5%E8%AD%98%E8%A1%A8%E9%9D%A2%E7%B2%97%E3%81%95%E6%B8%AC%E5%AE%9A%E6%A9%9F%E7%B7%A8%E3%80%80%E6%8A%9C%E7%B2%8B.pdf>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-30]: <https://rpubs.com/makota/stat301-fall-lec06>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-31]: <https://www.jstage.jst.go.jp/article/pscjspe/2018S/0/2018S_147/_pdf/-char/ja>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-32]: <https://www.struers.com/ja-JP/Products/Materialographic-analysis/Materialographic-analysis-equipment/PSM>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-33]: <https://www.mieruka-engine.com/media/cross-sectional-data>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-34]: <https://www.nstec.nipponsteel.com/technology/mechanical-test/tribology/tribology_02.html>

[^(4-repeated-cross-sectionデータを用いたpsm分析の進め方まとめ-35]: <https://www.soumu.go.jp/main_content/000935597.pdf>

::: {style="text-align: center"}
⁂
:::
