# 最終的なデータ構造の確認
cat("=== 最終マージ結果の確認 ===\n")
cat("総行数:", nrow(data_merged), "\n")
cat("総列数:", ncol(data_merged), "\n\n")

# キー変数の確認
cat("キー変数の確認:\n")
data_merged %>%
  select(caseid, hhid, year) %>%
  slice(1:10) %>%
  print()

# WASHデータのマッチング率
cat("\nWASHデータのマッチング状況:\n")
wash_vars <- setdiff(names(data_all[["WASHdata-ws"]]), 
                     c("hhid", "hhid_clean", "hhid_normalized"))
for (var in wash_vars[1:min(3, length(wash_vars))]) {
  n_na <- sum(is.na(data_merged[[var]]))
  match_rate <- (nrow(data_merged) - n_na) / nrow(data_merged) * 100
  cat(sprintf("  %s: %.1f%% マッチ (%d/%d)\n", 
              var, match_rate, nrow(data_merged) - n_na, nrow(data_merged)))
}

# hhidごとの構造確認（複数の母親が同じ世帯に属するか）
cat("\n世帯内の母親数の分布:\n")
data_merged %>%
  group_by(hhid) %>%
  summarise(n_mothers = n()) %>%
  group_by(n_mothers) %>%
  summarise(n_households = n(), .groups = "drop") %>%
  arrange(n_mothers) %>%
  print()
