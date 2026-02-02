# ★★★ 診断コード1: 年度ごとのラベル定義を確認 ★★★
for (yr in yearlist) {
  root_folder <- file.path(gdrive_dir, "output", yr) %>%
    normalizePath() %>%
    trimws()
  
  year_data <- read_rds(file.path(root_folder, "data_merged.rds")) %>%
    filter(!is.na(hhid))
  
  cat("========================================\n")
  cat("Year:", yr, "\n")
  cat("nt_wm_ht value labels:\n")
  print(attr(year_data$nt_wm_ht, "labels"))
  cat("nt_wm_ht クラス:", class(year_data$nt_wm_ht), "\n")
  cat("nt_wm_ht table (元データ):\n")
  print(table(year_data$nt_wm_ht, useNA = "always"))
  cat("\n")
}

# ★★★ 診断コード2: rbindlist直後の状態確認 ★★★
all_data_merged <- rbindlist(data_list, fill = TRUE, ignore.attr = TRUE)
all_data_merged <- as_tibble(all_data_merged)

cat("rbindlist直後のnt_wm_ht (2008年のみ):\n")
print(table(all_data_merged %>% filter(year == "2008") %>% pull(nt_wm_ht), useNA = "always"))

# ★★★ 診断コード3: restore_labels直後の状態確認 ★★★
all_data_merged <- restore_labels(all_data_merged, label_merged_all)

cat("restore_labels直後のnt_wm_ht (2008年のみ):\n")
print(table(all_data_merged %>% filter(year == "2008") %>% pull(nt_wm_ht), useNA = "always"))
cat("nt_wm_ht labels:\n")
print(attr(all_data_merged$nt_wm_ht, "labels"))

# ★★★ 診断コード4: to_factor直後の状態確認 ★★★
all_data_merged <- all_data_merged %>%
  mutate(across(where(is.labelled), labelled::to_factor))

cat("to_factor直後のnt_wm_ht (2008年のみ):\n")
print(table(all_data_merged %>% filter(year == "2008") %>% pull(nt_wm_ht), useNA = "always"))
