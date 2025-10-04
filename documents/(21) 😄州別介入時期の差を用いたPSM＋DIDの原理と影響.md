<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 州別介入時期の差を用いたPSM＋DIDの原理と影響

**結論（要点）** 介入群と対照群を「傾向スコアマッチング（PSM）」で事前にバランス調整し、さらに「差分の差分法（DID）」で時系列的変化を推定することで、観測可能な交絡因子と時間変化を同時にコントロールし、より頑健な因果推論が可能となる。

------------------------------------------------------------------------

## 1. 手法の概要

**1.1 傾向スコアマッチング（PSM）**

-   観測された共変量（人口構造、経済指標、政策前水準など）に基づき、介入群と非介入群の各ユニットに「介入を受ける確率」（傾向スコア）を推定。
-   傾向スコアが近いユニット同士をマッチさせることで、観測可能な交絡バイアスを軽減する。

**1.2 差分の差分法（DID）**

-   介入前後のアウトカム差分を取り、さらに介入群と対照群の差分を引くことで、時間トレンドの影響を除去。
-   ただし、DIDは「介入群と対照群が介入前に同じトレンドをたどる（平行トレンド仮定）」が成立する必要がある。

------------------------------------------------------------------------

## 2. PSM＋DID 組み合わせの原理

1.  **マッチングによる共変量の調整**
    -   PSMでマッチングし、介入群・対照群の共変量分布を揃える
    -   これにより、DIDの「平行トレンド仮定」が成立しやすくなる
2.  **時系列差分による外的ショックの制御**
    -   DIDで介入以外の時間的変化（経済ショック、全州共通の外部要因など）を差し引く
    -   PSMで調整できない未観察の固定効果（州固有の定常的特徴）もある程度コントロール可能
3.  **二段階推定手順**
    -   ① 傾向スコアを推定し、Nearest‐NeighborやCaliperなどでマッチ
    -   ② マッチ後のサブサンプルでDID回帰モデル（例：$Y_{it} = \alpha + \beta\,\text{Post}_{t}\times \text{Treat}_{i} + \gamma_i + \delta_t + \varepsilon_{it}$）を推定

------------------------------------------------------------------------

## 3. 利点と注意点

**3.1 利点**

-   観測可能バイアスを低減しつつ、時系列の共通トレンドも制御できる
-   未観察の州固定効果および共通ショックに頑健
-   介入時期が州ごとに異なる多期DIDへの拡張も容易

**3.2 注意点**

-   マッチングによるサンプル削減：有意なサンプルサイズ減少で推定力低下の可能性
-   平行トレンド検証：マッチ後も介入群・対照群の事前トレンドの同一性を確認
-   異時点介入：Staggered DID のバイアス問題（最近の研究で注意喚起あり）
-   傾向スコアのモデル化誤差：共変量の漏れやモデル仕様ミスに注意

------------------------------------------------------------------------

## 4. 実装上のポイント

1.  **共変量選択**
    -   介入決定要因となり得る州レベルの指標を網羅的に入れる
2.  **マッチングの厳密度**
    -   Caliper幅の設定やマッチング比（1：1 vs. 1：k）を検討
3.  **平行トレンド検証**
    -   マッチ後に介入前数期のアウトカム推移をプロットして検証
4.  **標準誤差の補正**
    -   クラスタ化標準誤差（州単位）やブートストラップで信頼性検証

------------------------------------------------------------------------

## 5. まとめ

PSM＋DIDは、観測可能・非観測のバイアスを併せて制御し、介入効果をより正確に推定できる強力な手法である。ただし、マッチング後のトレンド検証や標準誤差補正など、実装上の慎重な配慮が不可欠である。

------------------------------------------------------------------------

# 平行トレンドが確認できれば基本的にはDIDの適用で政策効果を評価できると思いますが、PSMを加える意味はどこにありますか

PSMを加える意味は、DIDが前提とする「平行トレンド仮定」の成立をより現実的に補強し、観測された共変量の不均衡を事前に調整することである。具体的には以下の点に意味があります。

1.  DIDの「平行トレンド仮定」はグループ全体のトレンドが同一であることを要求するが、実際は介入群と対照群で共変量分布が異なるとこの仮定は破綻しやすい。PSMは同様の共変量を持つユニットでマッチングし、グループ間の共変量のバランスを整備するため、平行トレンドが成立しやすい（局所的な類似性の中で比較される）。[^州別介入時期の差を用いたpsm＋didの原理と影響-1], [^州別介入時期の差を用いたpsm＋didの原理と影響-2]
2.  観測可能な共変量の不均衡により、介入群と対照群の潜在的な異質性が推定にバイアスをもたらすことがあるため、PSMはこのバイアスを軽減し、より近似した条件でDIDを推定可能にする。[^州別介入時期の差を用いたpsm＋didの原理と影響-3], [^州別介入時期の差を用いたpsm＋didの原理と影響-4]
3.  また、PSMは介入群と非介入群の間で類型の異なるユニット（極端な傾向スコアを持つ個体）を除外するため、DIDの推定対象が実質的に「マッチしたサブサンプルにおける介入効果（平均処置効果 on the treated）」に限定されることから、より妥当な因果推論が期待できる。[^州別介入時期の差を用いたpsm＋didの原理と影響-5], [^州別介入時期の差を用いたpsm＋didの原理と影響-6]
4.  逆に、平行トレンドが完全に成り立ち、共変量の分布も非常にバランスが良い場合は、単純なDIDで十分であり、PSMを加えても推定の改善は限定的となることも指摘されている。[^州別介入時期の差を用いたpsm＋didの原理と影響-7]

[^州別介入時期の差を用いたpsm＋didの原理と影響-1]: <https://bcallaway11.github.io/files/DID-Covariates/Caetano_Callaway_2024.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-2]: <https://eu-cap-network.ec.europa.eu/training/evaluation-learning-portal/learning-portal-propensity-score-matching-difference-differences-psm-did-method_en>

[^州別介入時期の差を用いたpsm＋didの原理と影響-3]: <https://eu-cap-network.ec.europa.eu/training/evaluation-learning-portal/learning-portal-propensity-score-matching-difference-differences-psm-did-method_en>

[^州別介入時期の差を用いたpsm＋didの原理と影響-4]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0306393>

[^州別介入時期の差を用いたpsm＋didの原理と影響-5]: <https://www.jstage.jst.go.jp/article/jea/31/8/31_JE20210145/_pdf/-char/en>

[^州別介入時期の差を用いたpsm＋didの原理と影響-6]: <https://eu-cap-network.ec.europa.eu/training/evaluation-learning-portal/learning-portal-propensity-score-matching-difference-differences-psm-did-method_en>

[^州別介入時期の差を用いたpsm＋didの原理と影響-7]: <https://blogs.worldbank.org/en/impactevaluations/when-your-difference-differences-has-too-many-differences>

以上より、PSMはDIDの仮定を現実に適用可能にし、観察された選択バイアスの低減を通じて政策効果の推定を強固にするために加えられることが多いです。

まとめると、平行トレンドの確認は大前提ですが、PSMはその成立に不可欠な共変量バランスの強化および観測バイアスの軽減に役立つため、DID適用の前処理として有用となるのです.[^州別介入時期の差を用いたpsm＋didの原理と影響-8], [^州別介入時期の差を用いたpsm＋didの原理と影響-9], [^州別介入時期の差を用いたpsm＋didの原理と影響-10] [^州別介入時期の差を用いたpsm＋didの原理と影響-11], [^州別介入時期の差を用いたpsm＋didの原理と影響-12], [^州別介入時期の差を用いたpsm＋didの原理と影響-13], [^州別介入時期の差を用いたpsm＋didの原理と影響-14], [^州別介入時期の差を用いたpsm＋didの原理と影響-15], [^州別介入時期の差を用いたpsm＋didの原理と影響-16], [^州別介入時期の差を用いたpsm＋didの原理と影響-17], [^州別介入時期の差を用いたpsm＋didの原理と影響-18], [^州別介入時期の差を用いたpsm＋didの原理と影響-19], [^州別介入時期の差を用いたpsm＋didの原理と影響-20], [^州別介入時期の差を用いたpsm＋didの原理と影響-21], [^州別介入時期の差を用いたpsm＋didの原理と影響-22], [^州別介入時期の差を用いたpsm＋didの原理と影響-23], [^州別介入時期の差を用いたpsm＋didの原理と影響-24], [^州別介入時期の差を用いたpsm＋didの原理と影響-25]

[^州別介入時期の差を用いたpsm＋didの原理と影響-8]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0306393>

[^州別介入時期の差を用いたpsm＋didの原理と影響-9]: <https://bcallaway11.github.io/files/DID-Covariates/Caetano_Callaway_2024.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-10]: <https://eu-cap-network.ec.europa.eu/training/evaluation-learning-portal/learning-portal-propensity-score-matching-difference-differences-psm-did-method_en>

[^州別介入時期の差を用いたpsm＋didの原理と影響-11]: [<https://en.wikipedia.org/wiki/Propensity_score_matching>]{style="display:none"}

[^州別介入時期の差を用いたpsm＋didの原理と影響-12]: <https://pubmed.ncbi.nlm.nih.gov/30474484/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-13]: <https://journals.sagepub.com/doi/10.1177/1094428112447816>

[^州別介入時期の差を用いたpsm＋didの原理と影響-14]: <https://psantanna.com/files/Callaway_SantAnna_2020.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-15]: <https://www.sciencedirect.com/science/article/pii/S2213624X25002299>

[^州別介入時期の差を用いたpsm＋didの原理と影響-16]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC2943670/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-17]: <https://www.sciencedirect.com/science/article/pii/S2213624X25000264>

[^州別介入時期の差を用いたpsm＋didの原理と影響-18]: <https://mingze-gao.com/posts/difference-in-differences/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-19]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC8246231/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-20]: <https://www.publichealth.columbia.edu/research/population-health-methods/difference-difference-estimation>

[^州別介入時期の差を用いたpsm＋didの原理と影響-21]: <https://profcjgodlewski.files.wordpress.com/2016/09/2amatchinganddiffdiffhavari.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-22]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC8275441/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-23]: <https://www.sciencedirect.com/science/article/pii/S1048984323000048>

[^州別介入時期の差を用いたpsm＋didの原理と影響-24]: <https://towardsdatascience.com/causal-inference-with-python-a-guide-to-propensity-score-matching-b3470080c84f/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-25]: <https://gking.harvard.edu/files/gking/files/pan1900011_rev.pdf>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# 私のデータは、介入が州によって決まりますが、介入州と非介入州の間に共変量の分布が異なる場合、PSMの導入によって、各州の世帯をさらに均質なペア（介入州vs非介入州）に区分することで、より均質なグループ間比較が可能になると理解して良いでしょうか

はい、その理解は正しいです。介入州と非介入州の間で共変量分布が異なる場合、PSM（傾向スコアマッチング）を導入することで、各州の世帯を「共変量が類似したペア」に区分し、より均質なグループ間比較が可能になります。[^州別介入時期の差を用いたpsm＋didの原理と影響-26], [^州別介入時期の差を用いたpsm＋didの原理と影響-27]

[^州別介入時期の差を用いたpsm＋didの原理と影響-26]: <http://library.jsce.or.jp/jsce/open/00039/201811_no58/58-S1.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-27]: <https://repository.dl.itc.u-tokyo.ac.jp/record/2008848/files/A38871.pdf>

### PSM導入の意義

-   PSMは、介入州と非介入州の世帯が持つ共変量（例：所得、家族構成、教育水準など）が近いもの同士をマッチングします。[^州別介入時期の差を用いたpsm＋didの原理と影響-28]
-   これにより、政策介入の有無以外の要因によるバイアスを減らし、「介入の効果のみ」をより純粋に比較できるようになります。[^州別介入時期の差を用いたpsm＋didの原理と影響-29]
-   DID（差分の差分法）と組み合わせることで、時系列的な変化と観測可能な交絡因子の両方をコントロールでき、因果推論の信頼性が高まります。[^州別介入時期の差を用いたpsm＋didの原理と影響-30], [^州別介入時期の差を用いたpsm＋didの原理と影響-31]

[^州別介入時期の差を用いたpsm＋didの原理と影響-28]: <http://library.jsce.or.jp/jsce/open/00039/201811_no58/58-S1.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-29]: <https://repository.dl.itc.u-tokyo.ac.jp/record/2008848/files/A38871.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-30]: <https://repository.dl.itc.u-tokyo.ac.jp/record/2008848/files/A38871.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-31]: <http://library.jsce.or.jp/jsce/open/00039/201811_no58/58-S1.pdf>

### 実際の分析イメージ

-   まず、PSMで介入州と非介入州の世帯を「共変量が近いペア」に分ける。
-   その後、DIDで介入前後のアウトカムの差分を比較することで、より均質なグループ間で政策効果を推定できる。

このように、PSMの導入によって、州ごとの世帯を均質化し、グループ間比較の妥当性を高めることができます。[^州別介入時期の差を用いたpsm＋didの原理と影響-32], [^州別介入時期の差を用いたpsm＋didの原理と影響-33] [^州別介入時期の差を用いたpsm＋didの原理と影響-34], [^州別介入時期の差を用いたpsm＋didの原理と影響-35], [^州別介入時期の差を用いたpsm＋didの原理と影響-36], [^州別介入時期の差を用いたpsm＋didの原理と影響-37], [^州別介入時期の差を用いたpsm＋didの原理と影響-38], [^州別介入時期の差を用いたpsm＋didの原理と影響-39], [^州別介入時期の差を用いたpsm＋didの原理と影響-40]

[^州別介入時期の差を用いたpsm＋didの原理と影響-32]: <http://library.jsce.or.jp/jsce/open/00039/201811_no58/58-S1.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-33]: <https://repository.dl.itc.u-tokyo.ac.jp/record/2008848/files/A38871.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-34]: [<https://www.econ.kyoto-u.ac.jp/renewable_energy/stage2/pbfile/m000159/REEKU_DP002.pdf>]{style="display:none"}

[^州別介入時期の差を用いたpsm＋didの原理と影響-35]: <https://www.ier.hit-u.ac.jp/primced/documents/No47_dp_up_Pdf_2013j.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-36]: <https://hit-u.repo.nii.ac.jp/record/2054077/files/No47_dp.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-37]: <https://evaluationjp.org/files/Vol19_No1.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-38]: <https://toyo.repo.nii.ac.jp/record/8795/files/keizaironshu42-2_053-069.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-39]: <https://www.pref.osaka.lg.jp/documents/34120/introduction20to20causal20inference20for20policy20measures20analysis.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-40]: <https://hermes-ir.lib.hit-u.ac.jp/hermes/ir/re/27352/keizaikenkyu06502168.pdf>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# PSMにおけるマッチングは、具体的にどういう計算で、どういう変数で評価されるのでしょうか

PSM（傾向スコアマッチング）におけるマッチングは、主に以下の手順と計算で行われます。[^州別介入時期の差を用いたpsm＋didの原理と影響-41], [^州別介入時期の差を用いたpsm＋didの原理と影響-42], [^州別介入時期の差を用いたpsm＋didの原理と影響-43]

[^州別介入時期の差を用いたpsm＋didの原理と影響-41]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-42]: <https://robustwife.com/ezr_propensity_score_matching/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-43]: <https://academiclounge.jp/archives/3595>

### 1. 共変量の選択

-   介入の有無に影響しうる「事前の変数」（例：世帯所得、家族構成、教育水準、年齢、地域特性など）を選びます。
-   アウトカムや介入後に変化する変数は含めません。[^州別介入時期の差を用いたpsm＋didの原理と影響-44], [^州別介入時期の差を用いたpsm＋didの原理と影響-45]

[^州別介入時期の差を用いたpsm＋didの原理と影響-44]: <https://academiclounge.jp/archives/3595>

[^州別介入時期の差を用いたpsm＋didの原理と影響-45]: <https://best-biostatistics.com/summary/propensity-score.html>

### 2. 傾向スコアの推定

-   介入群（1）・非介入群（0）を目的変数、選んだ共変量を説明変数として「ロジスティック回帰分析」を行います。
-   得られた「介入を受ける確率（傾向スコア）」が各世帯ごとに算出されます。
-   機械学習（ランダムフォレスト等）でも推定可能ですが、ロジスティック回帰が一般的です。[^州別介入時期の差を用いたpsm＋didの原理と影響-46], [^州別介入時期の差を用いたpsm＋didの原理と影響-47], [^州別介入時期の差を用いたpsm＋didの原理と影響-48], [^州別介入時期の差を用いたpsm＋didの原理と影響-49]

[^州別介入時期の差を用いたpsm＋didの原理と影響-46]: <https://robustwife.com/ezr_propensity_score_matching/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-47]: <https://corvus-window.com/whats_propensity-score-matching/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-48]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-49]: <https://academiclounge.jp/archives/3595>

### 3. マッチングの方法

-   介入群の世帯と、非介入群の世帯で「傾向スコアが最も近いペア」を作ります（Nearest Neighbor法）。
-   キャリパー（許容範囲）を設定し、一定以上離れたペアは除外することもあります。[^州別介入時期の差を用いたpsm＋didの原理と影響-50], [^州別介入時期の差を用いたpsm＋didの原理と影響-51]
-   1対1、1対多（1:n）など、マッチングの比率も選択できます。

[^州別介入時期の差を用いたpsm＋didの原理と影響-50]: <https://www.stats-guild.com/analytics/6879>

[^州別介入時期の差を用いたpsm＋didの原理と影響-51]: <https://robustwife.com/ezr_propensity_score_matching/>

### 4. バランスの評価

-   マッチング後、各共変量の分布が介入群・非介入群で均質になっているか「標準化差」などで評価します。[^州別介入時期の差を用いたpsm＋didの原理と影響-52], [^州別介入時期の差を用いたpsm＋didの原理と影響-53]

[^州別介入時期の差を用いたpsm＋didの原理と影響-52]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-53]: <https://robustwife.com/ezr_propensity_score_matching/>

### 5. 効果の推定

-   マッチング済みデータで、介入の効果（平均因果効果など）を推定します。[^州別介入時期の差を用いたpsm＋didの原理と影響-54], [^州別介入時期の差を用いたpsm＋didの原理と影響-55]

[^州別介入時期の差を用いたpsm＋didの原理と影響-54]: <https://academiclounge.jp/archives/3595>

[^州別介入時期の差を用いたpsm＋didの原理と影響-55]: <https://best-biostatistics.com/summary/propensity-score.html>

**まとめ** PSMのマッチングは「ロジスティック回帰等で推定した傾向スコア」を基準に、事前に選んだ共変量で評価・ペアリングされます。これにより、介入群と非介入群の世帯が「共変量分布の近い均質なグループ」として比較可能になります。[^州別介入時期の差を用いたpsm＋didの原理と影響-56], [^州別介入時期の差を用いたpsm＋didの原理と影響-57], [^州別介入時期の差を用いたpsm＋didの原理と影響-58] [^州別介入時期の差を用いたpsm＋didの原理と影響-59], [^州別介入時期の差を用いたpsm＋didの原理と影響-60], [^州別介入時期の差を用いたpsm＋didの原理と影響-61], [^州別介入時期の差を用いたpsm＋didの原理と影響-62], [^州別介入時期の差を用いたpsm＋didの原理と影響-63]

[^州別介入時期の差を用いたpsm＋didの原理と影響-56]: <https://robustwife.com/ezr_propensity_score_matching/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-57]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-58]: <https://academiclounge.jp/archives/3595>

[^州別介入時期の差を用いたpsm＋didの原理と影響-59]: [<https://bellcurve.jp/ex/function/psmatching.html>]{style="display:none"}

[^州別介入時期の差を用いたpsm＋didの原理と影響-60]: <https://waidai-csc.jp/updata/2018/08/seminar-igaku-20180126.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-61]: <https://ai-biostat.com/2025/02/09/傾向スコアマッチング（2値アウトカム）/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-62]: <http://yukiyanai.github.io/jp/classes/econometrics2/contents/slides/metrics2_topic05_slides.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-63]: <https://www.emuyn.net/stats/extract_matched_controls>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# 非介入州には実際には介入を受けた世帯は存在しませんが、共変量の分布に基づいて、「介入を受ける可能性」を計算し、そのスコアが介入州のスコアに近いものとマッチングさせるという理解で良いですか

はい、その理解で正しいです。非介入州の世帯にも、共変量（例：所得、家族構成、教育水準など）に基づいて「介入を受ける可能性（傾向スコア）」を計算します。[^州別介入時期の差を用いたpsm＋didの原理と影響-64], [^州別介入時期の差を用いたpsm＋didの原理と影響-65]

[^州別介入時期の差を用いたpsm＋didの原理と影響-64]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-65]: <https://book.st-hakky.com/data-science/causal-analysis-ps>

-   具体的には、介入州・非介入州すべての世帯について、共変量を説明変数、介入の有無を目的変数としたロジスティック回帰などで「介入を受ける確率（傾向スコア）」を推定します。[^州別介入時期の差を用いたpsm＋didの原理と影響-66], [^州別介入時期の差を用いたpsm＋didの原理と影響-67]
-   その後、介入州の世帯と、非介入州の世帯で「傾向スコアが近い」もの同士をマッチングします。[^州別介入時期の差を用いたpsm＋didの原理と影響-68], [^州別介入時期の差を用いたpsm＋didの原理と影響-69]
-   これにより、実際には介入を受けていない非介入州の世帯でも、「もし介入州にいたら介入を受けていたかもしれない」ほど共変量が似ている世帯を比較対象として選ぶことができます。[^州別介入時期の差を用いたpsm＋didの原理と影響-70], [^州別介入時期の差を用いたpsm＋didの原理と影響-71]

[^州別介入時期の差を用いたpsm＋didの原理と影響-66]: <https://book.st-hakky.com/data-science/causal-analysis-ps>

[^州別介入時期の差を用いたpsm＋didの原理と影響-67]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-68]: <https://www.salesanalytics.co.jp/column/no00345/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-69]: <https://book.st-hakky.com/data-science/causal-analysis-ps>

[^州別介入時期の差を用いたpsm＋didの原理と影響-70]: <https://book.st-hakky.com/data-science/causal-analysis-ps>

[^州別介入時期の差を用いたpsm＋didの原理と影響-71]: <https://www.salesanalytics.co.jp/column/no00345/>

この方法により、介入の有無以外の要因によるバイアスを減らし、より妥当な比較が可能になります。[^州別介入時期の差を用いたpsm＋didの原理と影響-72], [^州別介入時期の差を用いたpsm＋didの原理と影響-73], [^州別介入時期の差を用いたpsm＋didの原理と影響-74] [^州別介入時期の差を用いたpsm＋didの原理と影響-75], [^州別介入時期の差を用いたpsm＋didの原理と影響-76], [^州別介入時期の差を用いたpsm＋didの原理と影響-77], [^州別介入時期の差を用いたpsm＋didの原理と影響-78], [^州別介入時期の差を用いたpsm＋didの原理と影響-79], [^州別介入時期の差を用いたpsm＋didの原理と影響-80], [^州別介入時期の差を用いたpsm＋didの原理と影響-81]

[^州別介入時期の差を用いたpsm＋didの原理と影響-72]: <https://best-biostatistics.com/summary/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-73]: <https://www.salesanalytics.co.jp/column/no00345/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-74]: <https://book.st-hakky.com/data-science/causal-analysis-ps>

[^州別介入時期の差を用いたpsm＋didの原理と影響-75]: [<https://www.stats-guild.com/analytics/6879>]{style="display:none"}

[^州別介入時期の差を用いたpsm＋didの原理と影響-76]: <https://waidai-csc.jp/updata/2019/05/7e3a9ea92b282ede82550e81a73c6b54.pdf>

[^州別介入時期の差を用いたpsm＋didの原理と影響-77]: <https://qiita.com/maskot1977/items/ed5ee05a85830bd5aa5a>

[^州別介入時期の差を用いたpsm＋didの原理と影響-78]: <https://blogs.sas.com/content/sasjapan/2023/11/09/psmatch_psmatchprocedure/>

[^州別介入時期の差を用いたpsm＋didの原理と影響-79]: <https://amn.astellas.jp/medical-information/analysis/analysis-2>

[^州別介入時期の差を用いたpsm＋didの原理と影響-80]: <https://yukiyanai.github.io/econometrics2/propensity-score.html>

[^州別介入時期の差を用いたpsm＋didの原理と影響-81]: <https://spss-statistics2020.com/2022/01/15/spssによる傾向スコア・マッチングの方法・手順は/>

::: {align="center"}
⁂
:::
