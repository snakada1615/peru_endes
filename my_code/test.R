# label_dfの内容確認
print("=== label_df の内容確認 ===")
View(label_df)

# 特に問題となりそうな行を確認
problem_rows <- label_df[is.na(label_df$vallabel) & !is.na(label_df$val), ]
print("vallabelがNAだがvalが存在する行:")
print(problem_rows)

# 実際に生成されたダミー列名を確認
dummy_cols <- names(df_dummies)[grepl("_", names(df_dummies))]
print("生成されたダミー列:")
print(head(dummy_cols, 20))