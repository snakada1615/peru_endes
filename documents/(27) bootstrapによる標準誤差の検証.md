<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# **2段階推定（Two-Stage）における標準誤差の補正をブートストラップ法で行う**実装について、Step by stepで解説します。

## 1. ブートストラップ関数の定義

```{r}
iv_boot_function <- function(data, indices)
```

### 1.1 リサンプリング

```{r}
d <- data[indices, ]
```

-   `boot()`パッケージが生成した`indices`（行番号）に基づいて元データからリサンプリング
-   ブートストラップでは**復元抽出**で同じサイズのデータセットを作成

### 1.2 Survey designオブジェクトの作成

```{r}
svy_boot <- svydesign(
  ids = ~v021,           # クラスターID（1次抽出単位）
  strata = ~v022,        # 層別変数
  weights = ~sampling_weight_trimmed,  # サンプリングウェイト
  data = d, 
  nest = TRUE            # 入れ子構造を許容
)
```

-   リサンプリングされたデータで複雑標本デザインを再構築
-   **重要**: ブートストラップの各反復で標本設計を再現

### 1.3 第1段階（1st Stage）

```{r}
fit1 <- svyglm(formula_1st, design = svy_boot, family = gaussian())
d$pred_dairy <- (predict(fit1, type = "response") - pred_dairy_mean) / pred_dairy_sd
```

-   操作変数（IV）回帰：内生変数を操作変数で予測
-   `pred_dairy`を予測し、**標準化**（平均を引いて標準偏差で割る）
-   この予測値が第2段階で使用される

### 1.4 Survey designの更新

```{r}
svy_boot <- svydesign(...)  # 再度作成
```

-   `pred_dairy`が追加されたデータで再度survey designを作成
-   `svyglm`は元のデータフレームを参照するため更新が必要

### 1.5 第2段階（2nd Stage）

```{r}
fit2 <- svyglm(formula_2nd, design = svy_boot, family = quasibinomial())
return(coef(fit2)["pred_dairy"])
```

-   アウトカム変数を`pred_dairy`（第1段階の予測値）で回帰
-   `quasibinomial()`: 二値アウトカム（おそらく栄養不良の有無）
-   **返り値**: `pred_dairy`の係数のみ

### 1.6 エラーハンドリング

```{r}
tryCatch({...}, error = function(e) { return(NA) })
```

-   ブートストラップの一部の反復で収束しない場合に`NA`を返す

------------------------------------------------------------------------

## 2. ブートストラップの実行

```{r}
set.seed(12345)  # 再現性の確保
boot_results <- boot(
  data = df_lasso, 
  statistic = iv_boot_function, 
  R = 1000,                    # 1000回反復
  parallel = "multicore",      # macOS/Linuxで並列処理
  ncpus = 8                    # 8コア使用
)
```

-   `boot()`パッケージの関数で1000回のブートストラップを実行
-   各反復で2段階推定を行い、`pred_dairy`の係数を保存
-   **並列処理**で高速化（M4 MacBook Airなら有効）

------------------------------------------------------------------------

## 3. 結果の保存と確認

```{r}
print(boot_results)
saveRDS(coef_importance, file.path(save_path,"boot_result.rds"))
```

⚠️ **注意**: `coef_importance`は定義されていないようです。おそらく`boot_results`の誤記

------------------------------------------------------------------------

## 4. 信頼区間の計算

```{r}
boot.ci(boot_results, type = c("norm", "basic", "perc"))
```

3種類の信頼区間を計算:

-   **norm**: 正規近似（係数 ± 1.96 × ブートストラップ標準誤差）
-   **basic**: 基本ブートストラップ法
-   **perc**: パーセンタイル法（推奨：分布の歪みに対応）

------------------------------------------------------------------------

## 5. 標準誤差の比較

```{r}
boot_se <- sd(boot_results$t, na.rm = TRUE)
original_se <- summary(fit2_svy)$coefficients["pred_dairy", "Std. Error"]
```

### なぜこれが重要か？

2段階推定では**第1段階の不確実性が無視される**ため、通常の標準誤差（`original_se`）は**過小推定**されます。

```{r}
cat("増加率:", round((boot_se / original_se - 1) * 100, 1), "%\n")
```

-   ブートストラップ標準誤差は通常20-50%大きくなる
-   この増加分が第1段階の不確実性を反映

------------------------------------------------------------------------

## 6. 修正後の統計的推論

```{r}
z_boot <- original_coef / boot_se
p_boot <- 2 * pnorm(-abs(z_boot))
ci_boot <- original_coef + c(-1.96, 1.96) * boot_se
```

-   **修正後のp値**: ブートストラップ標準誤差でZ検定
-   **修正後の95%信頼区間**: 正規近似を使用
-   これらが**正しい統計的推論**の基礎となる

------------------------------------------------------------------------

## 全体の流れ（まとめ）

1.  **問題認識**: 2段階推定の標準誤差が過小推定される
2.  **解決策**: ブートストラップで両段階の不確実性を同時に考慮
3.  **実装**: 各ブートストラップ標本で1st→2nd stageを完全に再実行
4.  **結果**: 1000個の係数推定値の分布から正しい標準誤差を計算
5.  **推論**: 修正後の標準誤差で信頼区間とp値を再計算

------------------------------------------------------------------------

## 推奨事項

**コード修正**:

```{r}
# 保存部分を修正
saveRDS(boot_results, file.path(save_path, "boot_result.rds"))
```

**実行時間の見積もり**:

-   M4チップ8コア並列で30-60分は妥当
-   まずは`R = 100`でテスト実行を推奨

**結果の解釈**:

-   `boot.ci()`の**percentile信頼区間**を主要な結果として報告
-   標準誤差の増加率を論文のロバストネスチェックとして記述

このコードは計量経済学の**操作変数法の標準的なブートストラップ実装**として適切です。
