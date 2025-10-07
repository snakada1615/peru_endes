<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Survey-weighted線形回帰結果の解釈

この結果は、ペルーの栄養状況（おそらく身長年齢Zスコア等）に関するSurvey-weighted線形回帰分析の結果です。以下のように解釈できます：[^survey-weighted線形回帰結果の解釈-1], [^survey-weighted線形回帰結果の解釈-2]

[^survey-weighted線形回帰結果の解釈-1]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

[^survey-weighted線形回帰結果の解釈-2]: <https://www.nature.com/articles/s41366-020-00725-x>

### **全体的なモデル評価**

-   **観測数**: N = 22,858（大規模サンプル）
-   **統計的有意性**: ほとんどの変数が高い統計的有意性（\*\*\*p\<0.001）を示している
-   **年次効果**: 2007年を基準として、2014年のみ有意な正の効果（β=0.16\*）

### **主要な結果の解釈**

#### **正の関連要因（改善要因）**

1.  **出生時の子供のサイズ**（β=0.38\*\*\*）[^survey-weighted線形回帰結果の解釈-3], [^survey-weighted線形回帰結果の解釈-4]
    -   出生時のサイズが大きいほど、栄養状況が大幅に改善
    -   最も強い正の関連
2.  **首都居住**（β=0.20\*\*\*）[^survey-weighted線形回帰結果の解釈-5], [^survey-weighted線形回帰結果の解釈-6]
    -   都市部居住による栄養状況の改善効果
    -   都市と農村の栄養格差を反映
3.  **冷蔵庫所有**（β=0.16\*\*\*）
    -   食品保存環境の改善による栄養状況向上
4.  **母親の肥満BMI**（β=0.12***）、**過体重・肥満BMI**（β=0.09***）[^survey-weighted線形回帰結果の解釈-7]
    -   母親の栄養状況が子供に正の影響
    -   ペルーの栄養転換を反映

[^survey-weighted線形回帰結果の解釈-3]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC8546154/>

[^survey-weighted線形回帰結果の解釈-4]: <https://www.cambridge.org/core/journals/british-journal-of-nutrition/article/an-empirical-study-of-factors-associated-with-heightforage-zscores-of-children-aged-623-months-in-northwest-rwanda-the-role-of-care-practices-related-to-child-feeding-and-health/4ECAD3E3C2D47DFBFD6F18B1998BB8B9>

[^survey-weighted線形回帰結果の解釈-5]: <https://www.nature.com/articles/s41366-020-00725-x>

[^survey-weighted線形回帰結果の解釈-6]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

[^survey-weighted線形回帰結果の解釈-7]: <https://www.nature.com/articles/s41366-020-00725-x>

#### **負の関連要因（リスク要因）**

1.  **母親の低身長（145cm未満）**（β=-0.50\*\*\*）[^survey-weighted線形回帰結果の解釈-8]
    -   遺伝的・環境的要因による強い負の影響
2.  **低出生体重（2.5kg未満）**（β=-0.39\*\*\*）[^survey-weighted線形回帰結果の解釈-9]
    -   胎児期栄養不良の持続的影響
3.  **ANC期間の熟練した支援**（β=-0.34\*\*\*）
    -   意外な結果：高リスク妊娠への選択的支援を反映可能
4.  **伝統的調理燃料使用**（β=-0.13\*\*\*）[^survey-weighted線形回帰結果の解釈-10]
    -   社会経済的地位と屋内空気汚染の複合効果

[^survey-weighted線形回帰結果の解釈-8]: <https://www.cambridge.org/core/journals/british-journal-of-nutrition/article/an-empirical-study-of-factors-associated-with-heightforage-zscores-of-children-aged-623-months-in-northwest-rwanda-the-role-of-care-practices-related-to-child-feeding-and-health/4ECAD3E3C2D47DFBFD6F18B1998BB8B9>

[^survey-weighted線形回帰結果の解釈-9]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC8546154/>

[^survey-weighted線形回帰結果の解釈-10]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

### **社会経済的要因**

#### **教育の効果**（β=0.08\*\*\*）

-   教育水準向上による栄養改善効果[^survey-weighted線形回帰結果の解釈-11], [^survey-weighted線形回帰結果の解釈-12]

[^survey-weighted線形回帰結果の解釈-11]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

[^survey-weighted線形回帰結果の解釈-12]: <https://www.nature.com/articles/s41366-020-00725-x>

#### **住環境**

-   **床材**（β=0.00\*\*）: 効果は統計的に有意だがきわめて小さい
-   **水汲み往復時間**（β=-0.06\*\*）: インフラアクセスの影響

#### **畜産・農業**

-   **羊所有**（β=-0.18\***）、**家畜所有**（β=-0.06**）: 農村部の特徴を反映

### **栄養・育児実践**

#### **授乳・栄養実践**

-   **乳製品摂取**（β=0.10\*\*）: 補完食品の重要性
-   **哺乳瓶使用**（β=0.07\*\*）: 複合的な栄養実践効果
-   **1時間以内授乳開始**（β=-0.06\*\*）: 予想外の負の関連

### **時系列トレンド**

2007年を基準として、**2014年のみ有意な改善**（β=0.16\*）を示しており、これは：

-   ペルーの社会政策強化時期と一致[^survey-weighted線形回帰結果の解釈-13], [^survey-weighted線形回帰結果の解釈-14]
-   栄養改善プログラムの効果を反映可能

[^survey-weighted線形回帰結果の解釈-13]: <https://www.sciencedirect.com/science/article/pii/S2214109X16000851>

[^survey-weighted線形回帰結果の解釈-14]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

### **政策的示唆**

1.  **母子健康**: 妊娠期栄養と出生時体重改善の重要性[^survey-weighted線形回帰結果の解釈-15]
2.  **社会経済格差**: 都市農村格差、教育アクセス改善の必要性[^survey-weighted線形回帰結果の解釈-16], [^survey-weighted線形回帰結果の解釈-17]
3.  **統合的アプローチ**: 住環境、インフラ、栄養教育の包括的改善[^survey-weighted線形回帰結果の解釈-18]

[^survey-weighted線形回帰結果の解釈-15]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC8546154/>

[^survey-weighted線形回帰結果の解釈-16]: <https://www.nature.com/articles/s41366-020-00725-x>

[^survey-weighted線形回帰結果の解釈-17]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

[^survey-weighted線形回帰結果の解釈-18]: <https://www.sciencedirect.com/science/article/pii/S2214109X16000851>

この結果は、ペルーにおける栄養転換期の複雑な要因構造を示しており、多面的な政策介入の必要性を示唆しています。[^survey-weighted線形回帰結果の解釈-19], [^survey-weighted線形回帰結果の解釈-20], [^survey-weighted線形回帰結果の解釈-21] [^survey-weighted線形回帰結果の解釈-22], [^survey-weighted線形回帰結果の解釈-23], [^survey-weighted線形回帰結果の解釈-24], [^survey-weighted線形回帰結果の解釈-25], [^survey-weighted線形回帰結果の解釈-26], [^survey-weighted線形回帰結果の解釈-27], [^survey-weighted線形回帰結果の解釈-28], [^survey-weighted線形回帰結果の解釈-29], [^survey-weighted線形回帰結果の解釈-30], [^survey-weighted線形回帰結果の解釈-31], [^survey-weighted線形回帰結果の解釈-32], [^survey-weighted線形回帰結果の解釈-33], [^survey-weighted線形回帰結果の解釈-34], [^survey-weighted線形回帰結果の解釈-35], [^survey-weighted線形回帰結果の解釈-36]

[^survey-weighted線形回帰結果の解釈-19]: <https://www.sciencedirect.com/science/article/pii/S2214109X16000851>

[^survey-weighted線形回帰結果の解釈-20]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0092550>

[^survey-weighted線形回帰結果の解釈-21]: <https://www.nature.com/articles/s41366-020-00725-x>

[^survey-weighted線形回帰結果の解釈-22]: [<https://pmc.ncbi.nlm.nih.gov/articles/PMC11798800/>]{style="display:none"}

[^survey-weighted線形回帰結果の解釈-23]: <https://www.bookdown.org/rwnahhas/RMPH/weighted-linear-regression.html>

[^survey-weighted線形回帰結果の解釈-24]: <https://www.jstage.jst.go.jp/article/arfe/49/1/49_188/_pdf>

[^survey-weighted線形回帰結果の解釈-25]: <https://cdn.future.edu/wp-content/uploads/2018/06/altobelli-l-report-on-clas-dhs-analysis-abril-22-2009.pdf>

[^survey-weighted線形回帰結果の解釈-26]: <https://pubs.usgs.gov/tm/tm4a8/pdf/TM4-A8.pdf>

[^survey-weighted線形回帰結果の解釈-27]: <https://www.frontiersin.org/journals/pediatrics/articles/10.3389/fped.2020.00368/full>

[^survey-weighted線形回帰結果の解釈-28]: <https://dhsprogram.com/pubs/pdf/MR6/MR6.pdf>

[^survey-weighted線形回帰結果の解釈-29]: <https://onlinelibrary.wiley.com/doi/abs/10.1002/cjs.11155>

[^survey-weighted線形回帰結果の解釈-30]: <https://www.jstor.org/stable/2288115>

[^survey-weighted線形回帰結果の解釈-31]: <https://dhsprogram.com/pubs/pdf/CS12/CS12.pdf>

[^survey-weighted線形回帰結果の解釈-32]: <https://scikit-learn.org/stable/auto_examples/inspection/plot_linear_model_coefficient_interpretation.html>

[^survey-weighted線形回帰結果の解釈-33]: <https://sites.stat.columbia.edu/gelman/research/published/STS226.pdf>

[^survey-weighted線形回帰結果の解釈-34]: <https://projecteuclid.org/journals/statistical-science/volume-22/issue-2/Comment-Struggles-with-Survey-Weighting-and-Regression-Modeling/10.1214/088342307000000168.pdf>

[^survey-weighted線形回帰結果の解釈-35]: <https://www.pewresearch.org/decoded/2019/01/a-short-intro-to-linear-regression-analysis-using-survey-data/>

[^survey-weighted線形回帰結果の解釈-36]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC9566739/>

::: {align="center"}
⁂
:::
