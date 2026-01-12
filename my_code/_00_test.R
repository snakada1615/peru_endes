
# ***************************************************************
# HRデータとIRデータをhhid_joinでマージする関数
# @title merge_HR_IR
# @param HRdata HRデータフレーム
# @param IRdata IRデータフレーム
# @return マージされたデータフレーム
# ***************************************************************
library(dplyr)
library(stringr)

merge_HR_IR <- function(HRdata, IRdata) {
  
  # ステップ1: IRからhhid_joinを作成（オリジナルcaseidも保持）
  IRdata_with_hhid <- IRdata %>%
    mutate(
      hhid_join = str_trim(str_replace_all(caseid, "\\s+\\d+$", "")),
      hhid_join = str_trim(str_replace_all(hhid_join, "\\s+", " "))
    )
  
  # ステップ2: HRでhhid_joinを作成（オリジナルは保持）
  HRdata_with_join <- HRdata %>%
    mutate(
      hhid_join = str_trim(str_replace_all(hhid, "\\s+", " "))
    ) %>%
    rename(hhid_HR = hhid)  # オリジナルのhhidを hhid_HR に変更
  
  # ステップ4: hhid_joinでマッチング
  matched_data <- inner_join(
    IRdata_with_hhid,
    HRdata_with_join,
    by = "hhid_join"
  )
  
  # ステップ5: マッチ結果
  cat("\n=== マッチング結果 ===\n")
  cat("マッチ成功（行数）:", nrow(matched_data), "\n")
  cat("マッチ成功（ユニークhhid_join数）:", n_distinct(matched_data$hhid_join), "\n")
  
  # ステップ6: オリジナルIDが保持されていることを確認
  cat("\nIRのオリジナルcaseidが存在:", all(!is.na(matched_data$caseid)), "\n")
  cat("HRのオリジナルhhidが存在:", all(!is.na(matched_data$hhid_HR)), "\n")
  
  # # ステップ7: マッチしなかったケースの確認
  # ir_only <- anti_join(IRdata_with_hhid, HRdata_with_join, by = "hhid_join")
  # hr_only <- anti_join(HRdata_with_join, IRdata_with_hhid, by = "hhid_join")
  # 
  # cat("\n=== マッチ失敗ケース ===\n")
  # cat("IRのみ（マッチ失敗）:", nrow(ir_only), "\n")
  # cat("IRのみ（ユニークhhid_join数）:", n_distinct(ir_only$hhid_join), "\n")
  # cat("HRのみ（マッチ失敗）:", nrow(hr_only), "\n")
  # cat("HRのみ（ユニークhhid_join数）:", n_distinct(hr_only$hhid_join), "\n")
  
  # ステップ8: 世帯内の複数女性の確認
  # cat("\n=== 世帯内の複数女性分布 ===\n")
  # matched_data %>%
  #   group_by(hhid_join) %>%
  #   summarise(n_women = n(), .groups = "drop") %>%
  #   group_by(n_women) %>%
  #   summarise(n_households = n(), .groups = "drop") %>%
  #   arrange(n_women) %>%
  #   print()
  
  return(matched_data)
}
# -----------関数ここまで------------------------------------------------

# ステップ1: IRからhhid_joinを作成（オリジナルcaseidも保持）
IRdata_with_hhid <- IRdata %>%
  mutate(
    hhid_join = str_trim(str_replace_all(caseid, "\\s+\\d+$", "")),
    hhid_join = str_trim(str_replace_all(hhid_join, "\\s+", " "))
  )

# ステップ2: HRでhhid_joinを作成（オリジナルは保持）
HRdata_with_join <- HRdata %>%
  mutate(
    hhid_join = str_trim(str_replace_all(hhid, "\\s+", " "))
  ) %>%
  rename(hhid_HR = hhid)  # オリジナルのhhidを hhid_HR に変更

# ステップ3: マッチング前の確認
cat("=== マッチング前の統計 ===\n")
cat("IRの総行数:", nrow(IRdata_with_hhid), "\n")
cat("IRのユニークhhid_join数:", n_distinct(IRdata_with_hhid$hhid_join), "\n")
cat("HRの総行数:", nrow(HRdata_with_join), "\n")
cat("HRのユニークhhid_join数:", n_distinct(HRdata_with_join$hhid_join), "\n")

# ステップ4: hhid_joinでマッチング
matched_data <- inner_join(
  IRdata_with_hhid,
  HRdata_with_join,
  by = "hhid_join"
)

# ステップ5: マッチ結果
cat("\n=== マッチング結果 ===\n")
cat("マッチ成功（行数）:", nrow(matched_data), "\n")
cat("マッチ成功（ユニークhhid_join数）:", n_distinct(matched_data$hhid_join), "\n")

# ステップ6: オリジナルIDが保持されていることを確認
cat("\n=== オリジナルIDの保持確認 ===\n")
matched_data %>%
  select(caseid, hhid_join, hhid_HR) %>%
  head(10) %>%
  print()

cat("\nIRのオリジナルcaseidが存在:", all(!is.na(matched_data$caseid)), "\n")
cat("HRのオリジナルhhidが存在:", all(!is.na(matched_data$hhid_HR)), "\n")

# ステップ7: マッチしなかったケースの確認
ir_only <- anti_join(IRdata_with_hhid, HRdata_with_join, by = "hhid_join")
hr_only <- anti_join(HRdata_with_join, IRdata_with_hhid, by = "hhid_join")

cat("\n=== マッチ失敗ケース ===\n")
cat("IRのみ（マッチ失敗）:", nrow(ir_only), "\n")
cat("IRのみ（ユニークhhid_join数）:", n_distinct(ir_only$hhid_join), "\n")
cat("HRのみ（マッチ失敗）:", nrow(hr_only), "\n")
cat("HRのみ（ユニークhhid_join数）:", n_distinct(hr_only$hhid_join), "\n")

# ステップ8: 世帯内の複数女性の確認
cat("\n=== 世帯内の複数女性分布 ===\n")
matched_data %>%
  group_by(hhid_join) %>%
  summarise(n_women = n(), .groups = "drop") %>%
  group_by(n_women) %>%
  summarise(n_households = n(), .groups = "drop") %>%
  arrange(n_women) %>%
  print()
