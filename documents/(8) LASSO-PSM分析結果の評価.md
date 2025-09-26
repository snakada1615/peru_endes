<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# LASSO-PSM分析結果の評価

## **主要な問題点**

あなたのLASSO-PSM分析には**重大な問題**が複数存在しており、結果の信頼性に深刻な懸念があります。[^1][^2]

### **1. 極端なIPTW重みの問題**

分析結果で最も深刻な問題は**極端に大きなIPTW重み**です：

- **最大重み**: 480.313（推奨閾値10-20を24倍超過）[^3][^4]
- **極端な重み**: 240個（全体の1.0%）が99パーセンタイル以上
- **平均重み**: 1.783（理想的には1.0に近い値）

これは**傾向スコアの重複不足**（poor overlap）を示しており、IPTWの基本的な仮定が破綻している可能性があります。[^5][^4]

![Treatment Group Distribution in LASSO-PSM Analysis](https://ppl-ai-code-interpreter-files.s3.amazonaws.com/web/direct-files/4c34f4df93533e417f63acc50c5f43d2/da50506a-5598-4c2c-968a-2792b6f168f9/c09c28fa.png)

Treatment Group Distribution in LASSO-PSM Analysis

### **2. 治療群の深刻な不均衡**

群分布の分析から明らかな不均衡が確認されます：

- **対照群**: 22,443名（93.7%）
- **介入群1**: 601名（2.5%）
- **介入群2**: 908名（3.8%）
- **不均衡比率**: 14.9:1

この極端な不均衡が極端な重みの主要原因となっています。[^6][^4]

![IPTW Weight Distribution showing Extreme Values](https://ppl-ai-code-interpreter-files.s3.amazonaws.com/web/direct-files/4c34f4df93533e417f63acc50c5f43d2/577f9cbe-9293-4114-9803-b858cedf4b7a/b651b801.png)

IPTW Weight Distribution showing Extreme Values

## **バランス診断の不備**

現在の分析では**標準化平均差（SMD）によるバランス診断**が実施されていません。これは致命的な欠陥です：[^7][^8]

- **SMD < 0.1**: 良好なバランス[^9][^10]
- **SMD < 0.05**: より厳格な基準[^11]
- **分散の比較**も必要[^7]


## **改善案**

### **1. 重み切断（Weight Trimming）**

```r
# 95パーセンタイル値での切断
weight_95th <- quantile(psm_data$iptw_weight, 0.95)
psm_data$iptw_weight_trimmed <- pmin(psm_data$iptw_weight, weight_95th)
```


### **2. 安定化重みの使用**

```r
# 安定化重み計算
marginal_prob <- table(psm_data$treatment_group) / nrow(psm_data)
psm_data$stabilized_weight <- psm_data$iptw_weight * marginal_prob[psm_data$treatment_group]
```


### **3. バランス診断の実装**

```r
# SMD計算
library(tableone)
CreateTableOne(vars = selected_vars, 
               strata = "treatment_group", 
               data = psm_data, 
               test = FALSE) %>%
  print(smd = TRUE)
```


### **4. オーバーラップ重み（Overlap Weighting）の検討**

極端な重みを自動的に抑制する代替手法です：[^5][^4]

```r
# オーバーラップ重み
pscore_min <- pmin(pscore_df$prob_0, pscore_df$prob_1, pscore_df$prob_2)
overlap_weight <- pscore_min
```


## **LASSO変数選択の評価**

**98個の変数選択**は適切ですが、以下を確認する必要があります：

- **コリニアリティの確認**: VIF値の計算
- **予測性能**: C統計量（AUC）の評価
- **クロスバリデーション**: より厳格な検証


## **推奨する対応順序**

1. **即座の対応**: 重み切断（95パーセンタイル）の実施
2. **バランス診断**: SMD計算による共変量バランスの確認
3. **代替手法**: オーバーラップ重みやマッチング手法の検討
4. **感度分析**: 複数の手法による結果の頑健性確認

現在の結果は**そのまま使用すべきではありません**。極端な重みによりバイアスと分散の増大が生じ、因果推論の妥当性が深刻に損なわれています。
<span style="display:none">[^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36]</span>

```
<div style="text-align: center">⁂</div>
```

[^1]: https://www.betterevaluation.org/methods-approaches/methods/propensity-scores

[^2]: https://cran.r-project.org/web/packages/riskdiff/vignettes/iptw-analysis.html

[^3]: https://becarispublishing.com/doi/10.2217/cer-2020-0013

[^4]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8327194/

[^5]: https://arxiv.org/pdf/2108.04394.pdf

[^6]: https://pmc.ncbi.nlm.nih.gov/articles/PMC3144483/

[^7]: https://pmc.ncbi.nlm.nih.gov/articles/PMC6351359/

[^8]: https://pubmed.ncbi.nlm.nih.gov/30788363/

[^9]: https://cran.r-project.org/web/packages/MatchIt/vignettes/assessing-balance.html

[^10]: https://www.elifecycle.org/archive/view_article?pid=lc-2-0-18

[^11]: https://pmc.ncbi.nlm.nih.gov/articles/PMC3472075/

[^12]: https://www.nature.com/articles/s41592-024-02405-4

[^13]: https://goltc.org/publications/propensity-score-matching-psm-methods/

[^14]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8757413/

[^15]: https://cdn.amegroups.cn/journals/amepc/files/journals/16/articles/22865/public/22865-PB1-4071-R2.pdf

[^16]: https://www.biomedicine.video/animated-videos/propensity-score-matching-methodology-why-and-how-it-is-used

[^17]: https://www.magnoliamarketaccess.com/what-is-inverse-probability-of-treatment-weighting-iptw/

[^18]: https://www.jstage.jst.go.jp/article/ace/2/2/2_33/_pdf

[^19]: https://www.jstage.jst.go.jp/article/ace/4/4/4_22013/_pdf

[^20]: https://www.statsig.com/perspectives/propensity-score-matching-balanced-groups

[^21]: https://en.wikipedia.org/wiki/Propensity_score_matching

[^22]: https://pmc.ncbi.nlm.nih.gov/articles/PMC4626409/

[^23]: https://pmc.ncbi.nlm.nih.gov/articles/PMC6039292/

[^24]: https://arxiv.org/html/2405.15740v1

[^25]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8189011/

[^26]: https://www.sciencedirect.com/science/article/pii/S2213624X25000264

[^27]: https://pmc.ncbi.nlm.nih.gov/articles/PMC3069059/

[^28]: https://academic.oup.com/biometrics/article/73/4/1111/7537777

[^29]: https://www.jstage.jst.go.jp/article/ace/4/4/4_22013/_html/-char/en

[^30]: https://arxiv.org/pdf/2101.07359.pdf

[^31]: https://necostat.hatenablog.jp/entry/2022/04/06/001353

[^32]: https://ww2.amstat.org/meetings/biop/2020/onlineprogram/handouts/SC4-Handouts.pdf

[^33]: https://www.e-jmis.org/journal/view.html?doi=10.7602%2Fjmis.2024.27.2.55

[^34]: https://becarispublishing.com/doi/10.2217/cer-2021-0069

[^35]: https://onlinelibrary.wiley.com/doi/10.1002/sim.10078

[^36]: https://sysengi.cjoe.ac.cn/EN/10.12011/SETP2020-0037

