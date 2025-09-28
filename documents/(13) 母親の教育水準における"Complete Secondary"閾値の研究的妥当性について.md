<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 母親の教育水準における"Complete Secondary"閾値の研究的妥当性について

DHSデータを用いた開発途上国の子供の栄養状態に関する研究において、母親の教育水準（DHS変数v149）を「中等教育修了（Complete Secondary）」を閾値としてダミー変数化することは、**既存の類似研究と十分に整合しており、研究的に妥当**と考えられます。

## 既存研究による閾値設定の支持

### 主要な研究結果

最も関連性の高い研究として、Makoka & Masibo（2015年）がDHSデータ（マラウイ、タンザニア、ジンバブエ）を用いて実施した研究では、母親の教育水準と子供の栄養状態（発育阻害、消耗症、低体重）の閾値効果を詳細に分析しています。この研究の主要な発見は以下の通りです：[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-1][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-2]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-1]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4546212/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-2]: <https://pubmed.ncbi.nlm.nih.gov/26297004/>

-   **発育阻害（stunting）**：統計的に有意な効果を示すためには10年以上の就学（上級中等教育以上）が必要
-   **消耗症（wasting）**と**低体重（underweight）**：より低い閾値レベルでも効果が認められる
-   研究の結論として、**初等教育だけでは不十分であり、女子を初等教育を超えて就学させる政策がより有望**と提言されています[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-3][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-4]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-3]: <https://pubmed.ncbi.nlm.nih.gov/26297004/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-4]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4546212/>

### 国際的な研究動向

複数の系統的レビューや大規模研究においても、中等教育修了レベルの重要性が示されています：

1.  **二分法的変数の使用**：Forshaw et al.（2017年）のメタ分析では、母親の教育を「初等教育以下/中等教育以上」で二分化した研究が多数採用されていることが報告されています[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-5]
2.  **教育の非線形効果**：Alderman & Headey（2017年）は、教育の栄養への影響には閾値効果が存在し、多くの低所得国では**中等教育レベルでの非線形効果**が重要であることを指摘しています[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-6][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-7]
3.  **地域特異性の考慮**：Paul et al.（2022年）のインドでの研究では、母親の教育が子供の栄養状態に与える影響は、中等教育以上で顕著になることが示されています[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-8]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-5]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC5745980/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-6]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC5384449/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-7]: <https://www.sciencedirect.com/science/article/pii/S0305750X17300451>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-8]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC9094570/>

## 方法論的考察

### 閾値設定の理論的根拠

母親の教育が子供の栄養に影響を与える経路として、以下のメカニズムが提唱されています：

1.  **知識習得効果**：中等教育修了により、栄養や健康に関する十分な知識が習得される
2.  **社会経済的地位の改善**：中等教育修了により雇用機会が拡大し、家計収入が向上する
3.  **意思決定力の向上**：教育水準の向上により、家庭内での発言力が強化される

### 統計的妥当性

Maïga（2015年）のブルキナファソでの自然実験研究では、母親の教育年数の閾値効果を推定し、子供の体重身長比（WHZ）で13年、身長年齢比（HAZ）で12年が最大の効果を示すことが確認されています。これは中等教育修了レベル（通常11-12年）とほぼ一致します。[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-9]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-9]: <https://archive.uneca.org/sites/default/files/uploaded-documents/AEC/2011/maiga_the_impact_of_mothers_education_on_child_health_and_nutrition_in_develping_countries_0.pdf>

## 実践的な推奨事項

### 変数作成における注意点

1.  **地域差の考慮**：研究対象国の教育制度を確認し、「Complete Secondary」が何年に相当するかを明確化する
2.  **欠損値の処理**：DHS v149変数には「Don't know」等の回答が含まれる場合があるため、適切な処理が必要
3.  **サンプルサイズの確認**：中等教育修了者の割合が極端に低い国では、統計的検出力に注意が必要

### 感度分析の実施

研究の頑健性を確保するため、以下の感度分析を推奨します：

1.  **異なる閾値での分析**：初等教育修了や上級中等教育修了を閾値とした比較分析
2.  **連続変数としての分析**：教育年数を連続変数として扱った場合との比較
3.  **交互作用項の検討**：地域や所得水準との交互作用効果の検証

## 結論

「Complete Secondary」を閾値とした母親の教育水準のダミー変数化は、既存の国際的な研究結果と十分に整合しており、**研究的に妥当な手法**です。特に、Makoka & Masibo（2015年）をはじめとする複数の高品質な研究が、中等教育修了レベルでの閾値効果を実証しており、あなたの研究アプローチを強力に支持しています。[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-10][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-11]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-10]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC4546212/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-11]: <https://pubmed.ncbi.nlm.nih.gov/26297004/>

この閾値設定により、開発途上国における家庭環境と子供の栄養状態の関係を適切に分析することが可能となり、政策的含意のある知見を得ることが期待されます。 [^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-12][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-13][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-14][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-15][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-16][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-17][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-18][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-19][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-20][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-21][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-22][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-23][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-24][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-25][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-26][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-27][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-28][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-29][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-30][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-31][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-32][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-33][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-34][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-35][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-36][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-37][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-38][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-39][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-40][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-41][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-42][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-43][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-44][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-45][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-46][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-47][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-48][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-49][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-50][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-51][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-52][^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-53]

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-12]: [<https://pmc.ncbi.nlm.nih.gov/articles/PMC11001623/>]{style="display:none"}

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-13]: <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0175216>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-14]: <https://heron-orb-mjmp.squarespace.com/s/FEX-66-Final-2.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-15]: <https://www.dhsprogram.com/pubs/pdf/WP84/WP84.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-16]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC12454179/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-17]: <https://onlinelibrary.wiley.com/doi/10.1002/app5.70044?af=R>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-18]: <https://onlinelibrary.wiley.com/doi/full/10.1002/pam.22404>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-19]: <https://dhsprogram.com/pubs/pdf/WP201/WP201.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-20]: <https://www.sciencedirect.com/science/article/abs/pii/S0738059325001981>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-21]: <https://www.sciencedirect.com/science/article/pii/S2405844022026913>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-22]: <https://dhsprogram.com/publications/publication-wp84-working-papers.cfm>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-23]: <https://afdb-scorecard.invenus.dev/en/indicators/school-completion/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-24]: <https://philarchive.org/archive/KHATLB>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-25]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC6860139/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-26]: <https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2024.1398236/full>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-27]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC5769091/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-28]: <https://www.nature.com/articles/s41598-021-83346-2>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-29]: <https://documents1.worldbank.org/curated/en/750491468774678418/pdf/327980ET0Deter1schooling0ARHD0no185.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-30]: <https://www.sciencedirect.com/science/article/pii/S2352827322000209>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-31]: <https://assets.publishing.service.gov.uk/media/5a81aa23ed915d74e62337d0/Step-change-window-full2.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-32]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7916293/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-33]: <https://www.sciencedirect.com/science/article/abs/pii/S0899900722002647>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-34]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7_v2.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-35]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-36]: <https://pure.mpg.de/rest/items/item_2574397_2/component/file_2609114/content>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-37]: [https://www.sciencedirect.com/science/article/pii/S1877050924008767/pdf?md5=25b19a67fb5f5da5202a10f972658794\\&pid=1-s2.0-S1877050924008767-main.pdf](https://www.sciencedirect.com/science/article/pii/S1877050924008767/pdf?md5=25b19a67fb5f5da5202a10f972658794\&pid=1-s2.0-S1877050924008767-main.pdf){.uri}

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-38]: <https://www.dhs.wisconsin.gov/badgercareplus/waiverext-app.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-39]: <https://iussp.org/sites/default/files/event_call_for_papers/ComparativeWealth-DRAFT-IUSSP.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-40]: <https://journals.sagepub.com/doi/abs/10.1177/02601060221146320>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-41]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC11192342/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-42]: <https://www.sciencedirect.com/science/article/pii/S294985622500008X>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-43]: <https://lup.lub.lu.se/student-papers/record/8972495/file/8972497.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-44]: <https://www.sciencedirect.com/science/article/pii/S1353829223000242>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-45]: <https://www.tandfonline.com/doi/full/10.1080/17441692.2023.2291703>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-46]: <https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2800722>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-47]: <https://ijsscfrtjournal.isrra.org/index.php/Social_Science_Journal/article/download/1513/189/1781>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-48]: <https://onlinelibrary.wiley.com/doi/10.1111/mcn.70049?af=R>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-49]: [https://www.thelancet.com/journals/lancet/article/piis0140-6736(21)00534-1/fulltext](https://www.thelancet.com/journals/lancet/article/piis0140-6736(21)00534-1/fulltext){.uri}

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-50]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC6519047/>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-51]: <https://dhsprogram.com/pubs/pdf/wp57/wp57.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-52]: <https://bmjopen.bmj.com/content/bmjopen/5/5/e006814.full.pdf>

[^母親の教育水準におけるcomplete-secondary閾値の研究的妥当性について-53]: <https://www.disei.unifi.it/upload/sub/pubblicazioni/repec/pdf/wp12_2024.pdf>

::: {align="center"}
⁂
:::
