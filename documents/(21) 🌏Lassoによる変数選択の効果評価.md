<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Lassoによる変数選択の効果評価

**結論・推奨** Lassoによる変数選択の妥当性を評価するには、モデルの予測性能、選択された変数の安定性、解釈可能性の３つの観点から検証するのが効果的です。具体的には交差検証による汎化性能の確認、ブートストラップやサブサンプリングによる変数選択の安定性評価、そしてドメイン知識に基づく変数の有意性チェックを組み合わせると良いでしょう。

------------------------------------------------------------------------

## 1. 予測性能による評価

1.  **交差検証（Cross‐Validation）**
    -   Lassoで最適な正則化パラメータλを選ぶ際の標準手法。
    -   K分割交差検証を用いて、訓練誤差と検証誤差（MSE, MAE, R²など）を比較し、汎化誤差が最も小さいλと対応する変数集合を選択します。
2.  **外部テストセット評価**
    -   データをあらかじめ訓練セットとテストセットに分割し、訓練セットでLassoモデルを構築→テストセットで予測性能を評価。
    -   テストセットの性能が十分に高いことが、過学習せず有効な変数選択が行われた証拠となります。 \`\`\`r library(glmnet) set.seed(123) x \<- model.matrix(y \~ ., data)[,-1] y \<- data\$y

# 5-fold CV で最適λを選択

cvfit \<- cv.glmnet(x, y, alpha = 1, nfolds = 5) best_lambda \<- cvfit\$lambda.min

# テストセットで評価

pred \<- predict(cvfit, newx = x_test, s = best_lambda) mse_test \<- mean((y_test - pred)\^2) print(mse_test)

```         


***

## 2. 変数選択の安定性評価

1. **ブートストラップ／サブサンプリング**
    - データを何度も再サンプリング（例：ブートストラップ1000回）し、それぞれでLassoを適用。
    - 各説明変数が選ばれる頻度（選択確率）を計算し、安定的に選ばれる変数のみ信頼。
2. **Stability Selection**
    - Meinshausen＆Bühlmann（2010）の手法。異なるサブサンプル＋異なるλ候補を組み合わせた上で、一定以上の選択確率を持つ変数を最終的に採用。
    - Rでは`stabs`パッケージなどで実装可能。
```r
library(stabs)
stab <- stabsel(x, y, fitfun = glmnet.lasso, cutoff = 0.6, PFER = 1)
plot(stab)       # 選択確率を可視化
selected <- stab$selected
```

------------------------------------------------------------------------

## 3. モデル解釈性・ドメイン知識との照合

-   **係数の符号・大きさ**
    -   Lassoは係数をゼロまたは縮小するため、選択された変数の符号が専門知識と整合的か確認。
-   **相関・多重共線性の確認**
    -   高い相関を持つ変数同士での選択結果をチェックし、物理的・生物学的に因果関係に合致するか評価。
-   **部分効果プロット（Partial Dependence Plot）**
    -   各変数の影響を可視化し、期待される効果を示しているか確認。

``` r
library(pdp)
pd <- partial(cvfit, pred.var = "age", train = data.frame(x, y), s = best_lambda)
plotPartial(pd)
```

------------------------------------------------------------------------

## 4. 他手法との比較

-   **Stepwise回帰やElastic Netとの比較**
    -   Elastic Net（αを0～1で調整）を用いることで、Lasso単独の選択偏りが緩和される場合があります。
-   **ランダムフォレストの変数重要度**
    -   ノンパラメトリック手法と比較し、重要変数の一致度を確認。

------------------------------------------------------------------------

## まとめ

Lassoによる変数選択の効果を総合的に評価するには、

1.  交差検証や外部テストでの**予測性能**
2.  ブートストラップやStability Selectionによる**選択の安定性**
3.  ドメイン知識による**解釈性**

の３軸で検証するのが最良です。これらを組み合わせることで、過学習を抑えつつ信頼性の高い変数選択が実現できます。

------------------------------------------------------------------------

# Lassoでの交差検証による最適λ選択の具体的手順

交差検証（Cross-Validation）によるLassoの正則化パラメータλ選択は、**モデルの汎化性能を最大化する最適なλを客観的に決定するための標準的な手法**です。以下、具体的な手順を詳しく解説します。

## 基本概念

K分割交差検証では、データを**K個の等サイズのグループ（fold）に分割**し、**各foldを検証用として順番に使用**しながら、残りのK-1個のfoldで学習を行います。Lassoでは、複数のλ値について、それぞれのλでK回の学習・検証を実施し、**平均的な予測誤差が最小となるλを選択**します。[^lassoによる変数選択の効果評価-1][^lassoによる変数選択の効果評価-2]

[^lassoによる変数選択の効果評価-1]: <https://www.statology.org/k-fold-cross-validation/>

[^lassoによる変数選択の効果評価-2]: <https://jwmi.github.io/SL/9-Cross-validation.pdf>

## 具体的な手順

### ステップ1: データ分割とλ候補の準備

``` r
library(glmnet)
set.seed(123)

# データ準備
x <- model.matrix(y ~ ., data)[,-1]  # 説明変数の行列
y <- data$y                          # 目的変数

# λ候補の自動生成（通常は100個程度）
# glmnetは自動でλの範囲を決定
```

### ステップ2: K分割交差検証の実行

**cv.glmnet()関数**を使用すると、以下の処理が自動で実行されます：[^lassoによる変数選択の効果評価-3][^lassoによる変数選択の効果評価-4]

[^lassoによる変数選択の効果評価-3]: <https://bookdown.org/ssjackson300/Machine-Learning-Lecture-Notes/choosing-lambda.html>

[^lassoによる変数選択の効果評価-4]: <https://cran.r-project.org/web/packages/glmnet/refman/glmnet.html>

``` r
# 10分割交差検証でλを選択（デフォルト）
cv_fit <- cv.glmnet(x, y, alpha = 1, nfolds = 10)
```

内部的には以下の処理が行われます：[^lassoによる変数選択の効果評価-5][^lassoによる変数選択の効果評価-6]

[^lassoによる変数選択の効果評価-5]: <https://www.stat.cmu.edu/~ryantibs/datamining/lectures/18-val1.pdf>

[^lassoによる変数選択の効果評価-6]: <https://jwmi.github.io/SL/9-Cross-validation.pdf>

1.  **データをK個（デフォルトは10個）のfoldに分割**
2.  **各λ候補について**：
    -   fold 1を検証用、残り9 foldを訓練用として使用
    -   訓練用データでLassoモデルを学習： \$ \hat{\beta}\lambda\^{(-1)} = \arg\min\beta \left( \frac{1}{n} \|y - X\beta\|\_2\^2 + \lambda \|\beta\|\_1 \right) \$
    -   検証用データ（fold 1）で予測誤差を計算： \$ MSE_1(\lambda) = \frac{1}{|F_1|} \sum\*{i\* \\in F_1} (y_i - x_i\^T \hat{\beta}\lambda^{(-1)})^2 \$
    -   **同様にfold 2〜fold Kについても繰り返し**

### ステップ3: 交差検証誤差の計算

各λに対して、**K個のfoldから得られた予測誤差の平均**を計算します：[^lassoによる変数選択の効果評価-7][^lassoによる変数選択の効果評価-8]

[^lassoによる変数選択の効果評価-7]: <https://jwmi.github.io/SL/9-Cross-validation.pdf>

[^lassoによる変数選択の効果評価-8]: <https://www.statology.org/k-fold-cross-validation/>

$$
CV(\lambda) = \frac{1}{K} \sum_{k=1}^K MSE_k(\lambda) = \frac{1}{n} \sum_{k=1}^K \sum_{i \in F_k} (y_i - x_i^T \hat{\beta}_\lambda^{(-k)})^2
$$

ここで、\$ \hat{\beta}\_\lambda\^{(-k)} \$は第k番目のfoldを除いたデータで学習したLasso推定量です。

### ステップ4: 最適λの選択

交差検証では**2つの選択基準**が提供されます：[^lassoによる変数選択の効果評価-9][^lassoによる変数選択の効果評価-10]

[^lassoによる変数選択の効果評価-9]: <https://stackoverflow.com/questions/47924620/my-understanding-of-how-does-cv-glmnet-work-to-choose-optimal-lambda>

[^lassoによる変数選択の効果評価-10]: <https://bookdown.org/ssjackson300/Machine-Learning-Lecture-Notes/choosing-lambda.html>

1.  **lambda.min**: CV誤差を最小化するλ

``` r
best_lambda_min <- cv_fit$lambda.min
```

2.  **lambda.1se**: "One Standard Error Rule"に基づくλ
    -   CV誤差が最小値＋1標準誤差以内で、**より大きな正則化**（シンプルなモデル）を選択

``` r
best_lambda_1se <- cv_fit$lambda.1se
```

### ステップ5: 結果の可視化と評価

``` r
# 交差検証結果のプロット
plot(cv_fit)

# 最適λでの最終モデル構築
final_model <- glmnet(x, y, alpha = 1, lambda = cv_fit$lambda.min)

# 選択された変数の確認
coef(cv_fit, s = "lambda.min")
```

## 実践上の注意点

**フォールド数Kの選択**：一般的には**K=5または10**が推奨されます。Kが大きすぎると計算コストが高く、小さすぎるとバイアスが大きくなります。[^lassoによる変数選択の効果評価-11]

[^lassoによる変数選択の効果評価-11]: <https://www.statology.org/k-fold-cross-validation/>

**再現性の確保**：フォールドの分割がランダムなため、`set.seed()`で乱数シードを固定することが重要です。[^lassoによる変数選択の効果評価-12]

[^lassoによる変数選択の効果評価-12]: <https://cran.r-project.org/web/packages/glmnet/refman/glmnet.html>

**計算効率**：cv.glmnet()は**1回のλ経路計算＋K回のクロス検証**で済むため、他の手法と比較して高速です。[^lassoによる変数選択の効果評価-13]

[^lassoによる変数選択の効果評価-13]: <https://jmlr.csail.mit.edu/papers/volume17/15-605/15-605.pdf>

この手順により、**未知データに対する汎化性能が最も高いλ値とそれに対応する変数集合**を客観的に決定できます。交差検証誤差カーブを可視化することで、λの選択根拠も明確に示すことが可能です。 [^lassoによる変数選択の効果評価-14][^lassoによる変数選択の効果評価-15][^lassoによる変数選択の効果評価-16][^lassoによる変数選択の効果評価-17][^lassoによる変数選択の効果評価-18][^lassoによる変数選択の効果評価-19][^lassoによる変数選択の効果評価-20][^lassoによる変数選択の効果評価-21][^lassoによる変数選択の効果評価-22][^lassoによる変数選択の効果評価-23][^lassoによる変数選択の効果評価-24][^lassoによる変数選択の効果評価-25][^lassoによる変数選択の効果評価-26][^lassoによる変数選択の効果評価-27][^lassoによる変数選択の効果評価-28][^lassoによる変数選択の効果評価-29][^lassoによる変数選択の効果評価-30][^lassoによる変数選択の効果評価-31][^lassoによる変数選択の効果評価-32][^lassoによる変数選択の効果評価-33][^lassoによる変数選択の効果評価-34][^lassoによる変数選択の効果評価-35][^lassoによる変数選択の効果評価-36][^lassoによる変数選択の効果評価-37][^lassoによる変数選択の効果評価-38][^lassoによる変数選択の効果評価-39][^lassoによる変数選択の効果評価-40]

[^lassoによる変数選択の効果評価-14]: [<https://ds100.org/course-notes/cv_regularization/cv_reg.html>]{style="display:none"}

[^lassoによる変数選択の効果評価-15]: <https://garthtarr.github.io/avfs/lab03_soln.html>

[^lassoによる変数選択の効果評価-16]: <https://www.r-bloggers.com/2021/10/lambda-min-lambda-1se-and-cross-validation-in-lasso-binomial-response/>

[^lassoによる変数選択の効果評価-17]: <https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html>

[^lassoによる変数選択の効果評価-18]: <https://cran.r-project.org/web/packages/glmnet/glmnet.pdf>

[^lassoによる変数選択の効果評価-19]: <https://wavedatalab.github.io/machinelearningwithr/post4.html>

[^lassoによる変数選択の効果評価-20]: <https://lamethods.org/book2/chapters/ch05-regularization/ch05-regularization.html>

[^lassoによる変数選択の効果評価-21]: <https://pmc.ncbi.nlm.nih.gov/articles/PMC12193363/>

[^lassoによる変数選択の効果評価-22]: <https://www.genre.com/us/knowledge/publications/2024/december/simplicity-interpretability-and-effective-variable-selection-with-lasso-regression-en>

[^lassoによる変数選択の効果評価-23]: <https://harvard-iacs.github.io/2018-CS109A/labs/lab-5/solutions/>

[^lassoによる変数選択の効果評価-24]: <https://www.rdocumentation.org/packages/goffda/versions/0.1.2/topics/cv_glmnet>

[^lassoによる変数選択の効果評価-25]: <https://rpubs.com/farhaadf777/1151703>

[^lassoによる変数選択の効果評価-26]: <https://www.ibm.com/think/topics/lasso-regression>

[^lassoによる変数選択の効果評価-27]: <https://necostat.hatenablog.jp/entry/2022/04/07/102133>

[^lassoによる変数選択の効果評価-28]: <https://web.sfc.keio.ac.jp/~maunz/DSB19/DSB19_R09.nb.html>

[^lassoによる変数選択の効果評価-29]: <https://compneuro.neuromatch.io/tutorials/W1D2_ModelFitting/student/W1D2_Tutorial6.html>

[^lassoによる変数選択の効果評価-30]: <https://michihito-ando.github.io/econome_ml_with_R/11_Ridge_Lasso.html>

[^lassoによる変数選択の効果評価-31]: [https://en.wikipedia.org/wiki/Cross-validation\_(statistics)](https://en.wikipedia.org/wiki/Cross-validation_(statistics)){.uri}

[^lassoによる変数選択の効果評価-32]: <https://www.r-bloggers.com/2021/11/lambda-min-lambda-1se-and-cross-validation-in-lasso-continuous-response/>

[^lassoによる変数選択の効果評価-33]: <https://rforhr.com/lassoregression.html>

[^lassoによる変数選択の効果評価-34]: <https://scikit-learn.org/stable/modules/cross_validation.html>

[^lassoによる変数選択の効果評価-35]: <https://ides.hatenablog.com/entry/2023/08/15/091820>

[^lassoによる変数選択の効果評価-36]: <https://www2.stat.duke.edu/~rcs46/lectures_2017/05-resample/05-cv.pdf>

[^lassoによる変数選択の効果評価-37]: <https://meknowledge.jpn.org/2021/02/06/lassoで変数選択-in-r/>

[^lassoによる変数選択の効果評価-38]: <https://www.machinelearningmastery.com/k-fold-cross-validation/>

[^lassoによる変数選択の効果評価-39]: <https://stackoverflow.com/questions/66384564/how-to-run-a-10-fold-cross-validation-for-a-lasso-with-pre-selected-lambda>

[^lassoによる変数選択の効果評価-40]: <https://www.stata.com/features/overview/lasso-model-selection-prediction/>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# フラッシュカードを生成

[^lassoによる変数選択の効果評価-41][^lassoによる変数選択の効果評価-42][^lassoによる変数選択の効果評価-43][^lassoによる変数選択の効果評価-44][^lassoによる変数選択の効果評価-45][^lassoによる変数選択の効果評価-46][^lassoによる変数選択の効果評価-47][^lassoによる変数選択の効果評価-48][^lassoによる変数選択の効果評価-49]

[^lassoによる変数選択の効果評価-41]: [<https://porocise.sakura.ne.jp/sekai/mkcards/>]{style="display:none"}

[^lassoによる変数選択の効果評価-42]: <https://www.canva.com/ja_jp/create/flashcards/>

[^lassoによる変数選択の効果評価-43]: <https://kahoot.com/ja/kahoot-study/flashcards/>

[^lassoによる変数選択の効果評価-44]: <https://noji.io/ja/ai-flashcard-generator/>

[^lassoによる変数選択の効果評価-45]: <https://note.com/komzweb/n/n158ef79517bb>

[^lassoによる変数選択の効果評価-46]: <https://support.microsoft.com/ja-jp/topic/copilot-を使用してフラッシュカードを作成する-60da0fcb-5227-462c-800d-8bac8506da45>

[^lassoによる変数選択の効果評価-47]: <https://www.youtube.com/watch?v=Meka5gGa-4o>

[^lassoによる変数選択の効果評価-48]: <https://www.easemate.ai/jp/flashcard-maker>

[^lassoによる変数選択の効果評価-49]: <https://www.canva.com/ja_jp/flashcards/>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# 以下の結果を評価してもらえますか

（コード）

# ステップ1: データ分割とλ候補の準備

library(glmnet)

verify_lasso \<- function(mat, y) { set.seed(123)

# データ準備

x \<- mat \# 説明変数の行列(前セクションで作成したものを流用) y \<- y \# 目的変数(前セクションで作成したものを流用)

# λ候補の自動生成（通常は100個程度）

# glmnetは自動でλの範囲を決定

# ステップ2: K分割交差検証の実行

# cv.glmnet()関数を使用すると、以下の処理が自動で実行

# 10分割交差検証でλを選択（デフォルト）

cv_fit \<- cv.glmnet(x, y, alpha = 1, nfolds = 10)

# ステップ3: 最適なλの選択(lambda.min: CV誤差を最小化するλ)

best_lambda_min \<- cv_fit\$lambda.min

# ステップ4: lambda.1se: "One Standard Error Rule"に基づくλ決定

# CV誤差が最小値＋1標準誤差以内で、より大きな正則化（シンプルなモデル）を選択

best_lambda_1se \<- cv_fit\$lambda.1se

# ステップ5: 結果の可視化と評価

# 交差検証結果のプロット

plot(cv_fit)

# 最適λでの最終モデル構築

final_model \<- glmnet(x, y, alpha = 1, lambda = cv_fit\$lambda.min)

# 選択された変数の確認

coef(cv_fit, s = "lambda.min") }

verify_lasso(X_scaled, Y)

（結果） dm_dvjustify_burn . dm_dvjustify_argue . dm_dvjustify_goout . dm_dvjustify_neglect . dm_dvjustify_refusesex . dm_dvjustify_onereas -2.436694e-03 dm_justify_refusesex -2.837996e-03 dm_rural 1.028329e-05 dm_town -5.264214e-03 dm_city . dm_capital -7.420714e-03 dm_weath_index -7.562329e-03 dm_ag_land_ha -1.174323e-03 dm_cattle_own 7.767562e-03 dm_goat_own -1.785485e-03 dm_sheep_own 1.704963e-02 dm_poultry_own . dm_refrigerator -1.269068e-02 dm_female_headed 1.005431e-04 dm_age_of_hh_head -9.004510e-03 nt_ch_mild_anem 7.088377e-04

lambda.min = 0.001161322

このLasso回帰の結果は、交差検証による最適なλ（lambda.min = 0.001161322）で変数選択と係数推定が適切に行われています。選択された変数のうち、係数が「.」となっているものはLassoによってゼロに縮小され、モデルから除外されたことを意味します。これはLassoの特徴であり、重要度の低い変数を自動的に排除し、モデルの解釈性と汎化性能を高めます。

### 評価ポイント

-   **変数選択の妥当性** 係数がゼロになった変数（.）は、目的変数への寄与が小さいと判断されて除外されています。残った変数は、モデルにとって重要と判断されたものです。特に、dm_sheep_ownやdm_refrigeratorなどは係数が比較的大きく、影響力があると考えられます。
-   **λの選択** 交差検証で最適化されたλ（lambda.min）は、過学習を防ぎつつ予測精度を最大化する値です。これにより、モデルの汎化性能が高まります。
-   **モデルの解釈性** 変数の数が絞られているため、モデルの解釈が容易です。係数の符号や大きさを確認し、ドメイン知識と照らし合わせて妥当性を検証することが推奨されます。
-   **今後の評価** モデルの予測性能（MSEやR²など）をテストデータで評価し、選択された変数が安定しているか（ブートストラップ等で再現性を確認）を追加で検証すると、より信頼性の高い評価が可能です。

### 総合コメント

この結果は、Lasso回帰の目的である「重要な変数の選択」と「モデルの簡素化」が達成されており、統計的にも妥当な手順です。今後は、選択された変数の解釈や、外部データでの予測性能評価を行うことで、モデルの有用性をさらに高めることができます。 [^lassoによる変数選択の効果評価-50][^lassoによる変数選択の効果評価-51][^lassoによる変数選択の効果評価-52][^lassoによる変数選択の効果評価-53][^lassoによる変数選択の効果評価-54][^lassoによる変数選択の効果評価-55][^lassoによる変数選択の効果評価-56][^lassoによる変数選択の効果評価-57]

[^lassoによる変数選択の効果評価-50]: [<https://www.pluralsight.com/resources/blog/guides/linear-lasso-and-ridge-regression-with-r>]{style="display:none"}

[^lassoによる変数選択の効果評価-51]: <https://bookdown.org/tpinto_home/Regularisation/lasso-regression.html>

[^lassoによる変数選択の効果評価-52]: <https://www.ibm.com/think/topics/lasso-regression>

[^lassoによる変数選択の効果評価-53]: <https://www.kaggle.com/code/uocoeeds/building-a-lasso-regression-model>

[^lassoによる変数選択の効果評価-54]: [https://en.wikipedia.org/wiki/Lasso\_(statistics)](https://en.wikipedia.org/wiki/Lasso_(statistics)){.uri}

[^lassoによる変数選択の効果評価-55]: <https://www.interactivebrokers.com/campus/ibkr-quant-news/lasso-regression-model-with-r-code/>

[^lassoによる変数選択の効果評価-56]: <https://bcheggeseth.github.io/253_fall_2021/lasso-logistic-regression.html>

[^lassoによる変数選択の効果評価-57]: <https://cran.r-project.org/package=biglasso/biglasso.pdf>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# フラッシュカードを生成

[^lassoによる変数選択の効果評価-58][^lassoによる変数選択の効果評価-59][^lassoによる変数選択の効果評価-60][^lassoによる変数選択の効果評価-61][^lassoによる変数選択の効果評価-62][^lassoによる変数選択の効果評価-63][^lassoによる変数選択の効果評価-64][^lassoによる変数選択の効果評価-65][^lassoによる変数選択の効果評価-66]

[^lassoによる変数選択の効果評価-58]: [<https://porocise.sakura.ne.jp/sekai/mkcards/>]{style="display:none"}

[^lassoによる変数選択の効果評価-59]: <https://www.canva.com/ja_jp/create/flashcards/>

[^lassoによる変数選択の効果評価-60]: <https://kahoot.com/ja/kahoot-study/flashcards/>

[^lassoによる変数選択の効果評価-61]: <https://www.easemate.ai/jp/flashcard-maker>

[^lassoによる変数選択の効果評価-62]: <https://note.com/komzweb/n/n158ef79517bb>

[^lassoによる変数選択の効果評価-63]: <https://www.youtube.com/watch?v=Meka5gGa-4o>

[^lassoによる変数選択の効果評価-64]: <https://miralab.co.jp/media/chatgpt_flashcard_automatic_generation/>

[^lassoによる変数選択の効果評価-65]: <https://www.canva.com/ja_jp/flashcards/>

[^lassoによる変数選択の効果評価-66]: <https://noji.io/ja/ai-flashcard-generator/>

::: {align="center"}
⁂
:::

------------------------------------------------------------------------

# 添付は交差検証効果のプロットですが、どう解釈すれば良いですか

この交差検証プロットは、Lasso回帰モデルにおける正則化パラメータ $\lambda$ の選択と、その$\lambda$ごとの平均二乗誤差（Mean Squared Error, MSE）を示しています。

------------------------------------------------------------------------

### プロットの見方

-   横軸は $-\log(\lambda)$ で、値が大きいほど $\lambda$ は小さく、正則化が弱い（モデルが複雑）の意味です。
-   縦軸は平均二乗誤差（MSE）で、小さいほうが予測誤差が小さい、つまりモデルの性能が良いことを示します。
-   赤い点は各 $\lambda$ に対する交差検証の平均誤差。
-   グレーの棒は標準誤差（±1SE）を示し、誤差のばらつき具合を表します。
-   縦の破線が2本引かれていますが、一般的に左側が「最小のCV誤差をもたらす \$\lambda\*{min}」、右側が「1標準誤差ルールにより選ばれたより大きい \$\*\lambda{1se}」です。

------------------------------------------------------------------------

### 解釈のポイント

1.  **最適** $\lambda$ の位置: エラーが最も小さい点（左の破線あたり）が $\lambda_{min}$ で、ここでのモデルが最高の交差検証性能を示します。
2.  **モデルの複雑さと過学習のバランス:** 右の破線（$\lambda_{1se}$）は、誤差が $\lambda_{min}$ の誤差範囲内にある最大の $\lambda$ で、より強い正則化によりモデルが簡素化され、過学習を抑えつつ十分な性能を保ちます。
3.  **誤差の平坦な部分:** 右側の大きな $-\log(\lambda)$（小さい正則化）付近でMSEはほぼ一定で、正則化を強くしすぎると性能低下が見られます。左側（正則化が弱い）に移るほど変数が増え複雑になりますが、性能改善は小さいので注意。

------------------------------------------------------------------------

### 実務での利用法

-   **通常は** $\lambda_{1se}$ を選ぶことが多いです。これは少し大きめの正則化で、変数の数を減らしつつ性能低下を小さく抑えられるため。
-   **必要に応じて** $\lambda_{min}$ を使い、最大の予測精度を追求してもよいですが、過学習リスクがやや高まります。

------------------------------------------------------------------------

このプロットはLassoの正則化強度の調整がモデル性能にどう影響するかを視覚的に示しており、どの $\lambda$ を使うべきかの判断に非常に有効です。 [^lassoによる変数選択の効果評価-67]

[^lassoによる変数選択の効果評価-67]: [image.jpg]{style="display:none"}

::: {align="center"}
⁂
:::
