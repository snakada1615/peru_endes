# サンプルサイズの確認
summary(svy_design)

# モデルの基本統計
summary(final_model_Linear)

# 残差の分布確認
plot(residuals(final_model_Linear))

# 重みが正の値かチェック
summary(weights(svy_design))

# 重みの範囲確認
range(weights(svy_design), na.rm = TRUE)
