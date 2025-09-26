<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# これまでの結果を要約して、「DHSの複数年次でーたをpoolする際の変数ID設定法」として、マークダウンでまとめてください

**DHS複数年次データプール時の変数ID設定法要約**

------------------------------------------------------------------------

## 基本方針

-   DHSデータを複数年次でプール（結合）する場合、「各レコード（＝個人・子供・世帯）」が確実に一意となるIDキーを設計する必要がある。[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-1][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-2][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-3]
-   DHS標準変数（v001, v002, v003, caseid, bidx など）は単独・単純な組み合わせでは重複が生じやすい。

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-1]: output.csv

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-2]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-3]: <https://dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7.pdf>

------------------------------------------------------------------------

## 主なID構成要素

| 変数名 | 内容 |
|:---|:---|
| **year** | 調査年。必ず含めることで他年次との区別が可能[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-4] |
| **v001** | クラスター番号。地区・調査単位の識別[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-5] |
| **v002** | 世帯番号。同一クラスター内重複があり得るため、ほかと組み合わせる[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-6] |
| **v003** | 世帯内ライン番号（個人）。ただしファイルや年次で再利用される[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-7] |
| **caseid** | 多くのDHSファイルで一人の女性または母親を一意化する文字列[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-8] |
| **bidx** | 子供を識別する連番。子供レベルで一意化には必須[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-9] |
| **surveyid等** | 調査回・国コード等。データの出所を示しより頑健なID化に有用[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-10] |

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-4]: output.csv

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-5]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-6]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-7]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-8]: <https://dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-9]: <https://dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-10]: <https://dhsprogram.com/pubs/pdf/OP8/OP8.pdf>

------------------------------------------------------------------------

## 一意性確保の方法

-   単年度なら `caseid`（母親個票）や `v001/v002/v003` で一意化可能な場合も。
-   **複数年次または複数ファイルを統合する場合は以下を推奨：**
    -   必ず `year` を含める
    -   母親単位なら `caseid + year`
    -   子供単位なら `caseid + year + bidx` または `v001 + v002 + v003 + year + bidx`
    -   国際分析の場合、 `country code` や `surveyid` など追加
-   データに属性重複がある場合（イベント違い等）は、「代表値選択」や「集約変数の作成（max, any, first など）」で単一化する。[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-11]

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-11]: <https://dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7.pdf>

------------------------------------------------------------------------

## 実践的Rコード例

``` r
library(dplyr)
df %>%
  group_by(caseid, year, bidx) %>%
  slice_min(order_by = age, with_ties = FALSE) %>%
  ungroup()
```

-   「caseid・year・bidx」でグループ化し、age最小の1件を抽出。

------------------------------------------------------------------------

## 注意事項と推奨

-   DHS repeated cross-section設計では、「同じ家庭・同じ子供」が複数年サンプルされることがまれに存在する。その際は完全一意化のキー設計か、サンプリングの補足と属性集約による解決が重要。[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-12][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-13]
-   データセット間でkey構造が異なる場合もあるため、必ずマージ前にID設計を確認・テストし、重複や曖昧性がないか集計で確認を。

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-12]: <https://dhsprogram.com/pubs/pdf/OP8/OP8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-13]: <https://ysph.yale.edu/news-article/perus-continuous-demographic-and-health-survey/>

------------------------------------------------------------------------

**要点まとめ**

-   複数年・複数ファイルを統合する際は、`year`や`bidx`を活用し、イベントや属性違いレコードの重複も考慮したID設計によって、確実に「一意な個人／子供」だけを取り出すことが解析の基礎となる。[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-14][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-15][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-16][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-17][^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-18]

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-14]: <https://www.dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-8.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-15]: <https://ysph.yale.edu/news-article/perus-continuous-demographic-and-health-survey/>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-16]: output.csv

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-17]: <https://dhsprogram.com/pubs/pdf/DHSG1/Guide_to_DHS_Statistics_DHS-7.pdf>

[^(6-dhsの複数年次データをpoolする際のuniqueキー設定法-18]: <https://dhsprogram.com/pubs/pdf/OP8/OP8.pdf>

::: {style="text-align: center"}
⁂
:::
