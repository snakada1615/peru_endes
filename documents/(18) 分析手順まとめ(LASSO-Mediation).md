<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 分析手順まとめ

## 1. LASSOによる予測因子選択

-   介入前後データを統合し、年固定効果を制御

```         
- `glmnet`でλ<sub>min</sub>のLASSOを実行し、**上位20変数**を抽出  
```

## 2. 変数の時間不変性評価

-   各変数の年別平均値を計算
-   変動係数（CV = 標準偏差÷平均値）を算出し、**CV\<0.10**の変数を高安定性と判定

## 3. コア予測因子の絞り込み

-   LASSO係数絶対値上位20変数の中から、

1.  **理論的根拠**（栄養・保健サービス・社会経済条件）
2.  **時間不変性** を両立する変数を選定

## 4. GLMによる妥当性検証

-   上位20変数＋年ダミーで**survey設計対応GLM**を実行
    -   `svydesign(ids=~v021,strata=~v022,weights=~sampling_weight_trimmed)`
    -   `svyglm(..., family=binomial)`
-   主要因子のオッズ比・p値・年次トレンドを確認

## 5. メディエーション分析準備

-   **メディエーター候補**（有意かつ理論的妥当性の高い変数）を選定：
    -   母親識字率（rc_litr）
    -   ミルク摂食（nt_fed_milk）
    -   産前ケア（rh_anc_4mo）
    -   早期授乳開始（nt_bf_start_1day）
    -   果物野菜摂取（nt_frtveg）
-   介入変数を二値化 (`treatment_binary`)、必要変数を`data.frame`に変換

## 6. メディエーション分析実行

-   各Mediatorについて：

1.  **モデルM**：`glm(M ~ X + covariates + as.factor(year))`
2.  **モデルY**：`glm(Y ~ X + M + covariates + as.factor(year))`
3.  `mediate(..., treat="treatment_binary", mediator=mediator, boot=FALSE)`

-   成功後に`boot=TRUE`でブートストラップを試行

## 7. 結果の解釈

-   **母親識字率**: 間接効果0.0074（p\<0.001）、媒介比率6.49%
-   **早期授乳開始**: 間接効果0.0008（p=0.004）
-   **産前ケア**: 間接効果0.0004（p=0.03）
-   **ミルク摂食**と**果物野菜摂取**: 媒介効果非有意

## 8. 次ステップ

-   複数メディエーター同時モデル化
-   地域・所得別の異質性分析
-   政策提言：教育支援・母子ケア強化によるstunting削減戦略
