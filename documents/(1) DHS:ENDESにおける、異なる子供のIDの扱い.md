<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# DHS/ENDESにおける、異なる子供のID(bidx/hidx/midx/bord)に関する解説まとめ

以下に、DHS（ENDES含む）で使われる子供IDの主な種類と、その違いやマッチング時の注意点を**マークダウン形式**でまとめます。

------------------------------------------------------------------------

## DHSの子供IDとその使い分け

### 主要なID変数

| 変数 | 説明 |
|:---|:---|
| **bidx** | 母親の出生履歴で左から右への子供のインデックス。1が最も新しい（直近）出生。 |
| **hidx** | PR/HRファイルでの世帯内個人番号。BR/KRファイルのbidxと、母親・子供間でjoin可能。 |
| **idx95** | 出産履歴上の子供に付された番号。通常bidxと同じ意味合いで用いられる。 |
| **midx** | M（母子・授乳等）関連ファイルでの出産履歴インデックス。bidxやhidxと同様の使い方が可能。 |
| **bord** | 実際の出生順。BORD=1は第1子。「間に死亡児や兄弟がいる場合」にbidxとは異なる値になる。 |

### 各IDのマッチング

-   **bidx, idx95, midx, hidx**はいずれも、**「母親ID（例: caseid, v001+v002+v003など）」とセット**で使うことで、同一母親内の各子供を一意に識別できる。
-   **bord**は「家族全体での出生順」だが、間に死亡児などがあるとbidxと一致しないことがある。

### 使い分け・実務上の注意ポイント

-   **データ結合（merge）時は、必ず「母親ID＋子供ID（bidxやhidx、midxなど）」をjoinキーにする**。
-   「生存児のみ」分析の際は、b5==1（生存指標）で事前にフィルタリングし、max(bidx)などで一番若い生存児を特定するのが定石。
-   **bidx, hidx, idx95, midxは通常一致しているが、サンプル設計やファイルによる例外もあるため、事前に一致テストをすると安全**。
-   **bordは出生順のみに特化**しており、インデックスマッチ（ファイル間結合）には通常使わない。

------------------------------------------------------------------------

### 例：df1とdf2の子供データをマッチさせる場合

``` r
# 典型的なRマージ例
merged <- merge(df1, df2, by.x = c("caseid", "bidx"), by.y = c("caseid", "hidx"))
# または
merged <- merge(df1, df2, by.x = c("caseid", "bidx"), by.y = c("caseid", "midx"))
```

-   「母親ID＋子供ID」2変数をマージキーに設定するのが標準。

------------------------------------------------------------------------

## まとめ

-   **bidx/hidx/idx95/midx：母親IDとセットで「子供一意化」→ファイル横断のデータマッチングに利用**
-   **bord：出生順だがインデックスマッチ用ではない**
-   マージ時は「生存児フラグ」など前処理も重要

各IDの性質を理解して、DHSの複数テーブル・ファイルを安全にリンクできます。 [^(1-dhsendesにおける、異なる子供のidの扱い-1][^(1-dhsendesにおける、異なる子供のidの扱い-2][^(1-dhsendesにおける、異なる子供のidの扱い-3][^(1-dhsendesにおける、異なる子供のidの扱い-4][^(1-dhsendesにおける、異なる子供のidの扱い-5][^(1-dhsendesにおける、異なる子供のidの扱い-6][^(1-dhsendesにおける、異なる子供のidの扱い-7][^(1-dhsendesにおける、異なる子供のidの扱い-8][^(1-dhsendesにおける、異なる子供のidの扱い-9][^(1-dhsendesにおける、異なる子供のidの扱い-10]

[^(1-dhsendesにおける、異なる子供のidの扱い-1]: [<https://www.digital.go.jp/assets/contents/node/basic_page/field_ref_resources/82a1ea56-128f-4cf6-bbd5-9ef6d4b7bafc/dd5f2542/20231211_policies_budget_entrustment_deliverables_report_01.pdf>]{style="display:none"}

[^(1-dhsendesにおける、異なる子供のidの扱い-2]: <https://irid.or.jp/wp-content/uploads/2020/08/gensiryokuryakugosyuu202008.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-3]: <https://jpfhir.jp/fhir/clins/ighistory/igv1.4.1/StructureDefinition-JP-ResearchStudy-.profile.json.html>

[^(1-dhsendesにおける、異なる子供のidの扱い-4]: <https://www.cfa.go.jp/assets/contents/node/basic_page/field_ref_resources/6b2c8f31-578d-4268-a57e-94acd694439f/a94d5ce9/20240329_policies_youth-kankyou_internet_research_02.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-5]: <https://www.nisc.go.jp/pdf/policy/kihon-s/250627cs2025.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-6]: <https://jpfhir.jp/fhir/ccs/output/StructureDefinition-JP-Observation-LabResult-eCS.profile.json.html>

[^(1-dhsendesにおける、異なる子供のidの扱い-7]: <https://www.meti.go.jp/meti_lib/report/2022FY/000764.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-8]: <https://webdesk.jsa.or.jp/pdf/dev/jsa_report/jsareport_2024_international%20standardization%20trend_%E7%94%9F%E4%BD%93%E8%AA%8D%E8%A8%BC.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-9]: <https://www.rd.ntt/sil/overview/NTTannual2023_j_web.pdf>

[^(1-dhsendesにおける、異なる子供のidの扱い-10]: <https://marketing-cdn.production.worldly.io/guides/ja/FEM2022> How to Higg Guide - Japanese.pdf

::: {style="text-align: center"}
⁂
:::
