<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 多項分類LASSO回帰の実行手順まとめ

以下の手順でデータ前処理から多項分類LASSO回帰の実行までを行います。

***

## 1. データクリーニング

1. **NAの多い列を除去（10%以上NA）**

```r
initial_cols <- ncol(df_pre)
keep_cols <- names(df_pre)[sapply(df_pre, function(x) sum(is.na(x)) <= nrow(df_pre)*0.1)]
df_pre <- df_pre[, keep_cols]
cat("NA多列削除数:", initial_cols - ncol(df_pre), "\n")
```

2. **説明変数とグループ変数名を再設定**

```r
all_drop_cols <- intersect(all_drop_cols, names(df_pre))
grouping_cols   <- intersect(grouping_cols, names(df_pre))
covariate_names <- setdiff(names(df_pre), c(all_drop_cols, grouping_cols, "treatment_group"))
```

3. **共変量にNAを含む行を除去**

```r
initial_rows <- nrow(df_pre)
complete_idx  <- complete.cases(df_pre[, covariate_names])
df_pre        <- df_pre[complete_idx, ]
cat("NA含行削除数:", initial_rows - nrow(df_pre), "\n")
```


***

## 2. 設計行列の作成とNAチェック

1. **モデル行列（ダミー含む）を作成**

```r
X_matrix <- model.matrix(~ . - 1, data = df_pre[, covariate_names])
Y        <- df_pre$treatment_group
```

2. **NAの有無を確認**

```r
cat("X_matrixのNA数:", sum(is.na(X_matrix)), "\n")
```

3. **NAがあれば行ごと除去**

```r
if(sum(is.na(X_matrix)) > 0) {
  idx <- complete.cases(X_matrix, Y)
  X_matrix <- X_matrix[idx, ]
  Y        <- Y[idx]
}
```


***

## 3. 定数列の除去とスケーリング

1. **標準偏差が0（定数列）の列を特定・除去**

```r
sds <- apply(X_matrix, 2, sd, na.rm=TRUE)
const_cols <- which(is.na(sds) | sds == 0)
X_matrix_clean <- X_matrix[, -const_cols]
```

2. **行列をスケーリング**

```r
X_scaled <- scale(X_matrix_clean)
cat("scale後NA数:", sum(is.na(X_scaled)), "\n")
```

3. **残存NA列があれば除去**

```r
na_cols <- which(apply(X_scaled, 2, function(x) any(is.na(x))))
X_scaled <- X_scaled[, -na_cols]
```


***

## 4. 層化交差検証用Foldの作成

```r
set.seed(123)
nfolds <- 3
fold_ids <- numeric(length(Y))

for(cls in unique(Y)) {
  idx_cls <- which(Y == cls)
  assign <- rep(1:nfolds, length.out = length(idx_cls))
  fold_ids[idx_cls] <- sample(assign)
}

# 各Fold内のクラス分布を確認
for(i in 1:nfolds) {
  cat("Fold", i, ":", table(Y[fold_ids == i]), "\n")
}
```


***

## 5. 多項分類LASSO回帰の実行

```r
set.seed(123)
cv_model <- cv.glmnet(
  x      = X_scaled,
  y      = Y,
  alpha  = 1,
  family = "multinomial",
  foldid = fold_ids
)
cat("LASSO回帰実行完了\n")
```


***

以上の手順で、欠損値や定数列を適切に処理し、層化交差検証を用いて安定した多項分類LASSO回帰を実行できます。

