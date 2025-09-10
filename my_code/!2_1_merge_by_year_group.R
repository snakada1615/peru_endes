library(here)
library(labelled)

# rmですべてのオブジェクトを削除
rm(list = ls(all = TRUE))

# 各種変数設定

# 年度の設定
# year <- c("2012")
# loopを回す場合
year <- c("2005", "2008", "2009", "2010", "2011", "2012")

# ファイル名の設定
files <- c("BRdata-rh.dta","HRWASHdata-ws.dta","IRdata-ms.dta","IRdata-rc.dta",
           "IRdata-rh.dta","KRdata-ch.dta","KRiycf-nt.dta","PRdata-nt.dta", 
           "KRvac-ch.dta", "KRstool-ch.dta", "DMdata_dm.dta")

# 各種の関数セット読み込み
source("myTools.R")

# 開始
for (yr in year) {
  print(sprintf("%s年の処理:", yr))
  # DHSデータのルートフォルダを指定
  source_folder <- normalizePath(here("..", "output", yr)) # データのルートフォルダを正規化
  i <- 0
  for (file in files){
    i <- i + 1
    if (i == 1){
      print(sprintf("ファイルの読み込み中：%s", file))
      tmp_merge <- read_dta(normalizePath(here("..", "output", yr, file)))
    } else {
      print(sprintf("ファイルの読み込み中：%s", file))
      tmp_merge_add <- read_dta(normalizePath(here("..", "output", yr, file)))
      if (i == 2 | i == 8) {
        tmp_merge_add <- tmp_merge_add %>%
          rename(
            v001 = hv001,
            v002 = hv002,
            v003 = hv003,
            v005 = hv005,
            v013 = hv013,
            v022 = hv022,
            v025 = hv025,
            v026 = hv026
          )
      }
      if (i==2){ # WASHデータの処理:複数回答を一つに集約(group_by - summarise)
        tmp_merge_add <- tmp_merge_add %>%
          group_by(v001, v002) %>%
          summarise(
            ph_sani_type = min(ph_sani_type),
            ph_sani_improve = min(ph_sani_improve),
            ph_sani_basic = min(ph_sani_basic),
            ph_sani_location = first(ph_sani_location),
            ph_wtr_trt_boil = max(ph_wtr_trt_boil),
            ph_wtr_trt_chlor = max(ph_wtr_trt_chlor),
            ph_wtr_trt_cloth = max(ph_wtr_trt_cloth),
            ph_wtr_trt_filt = max(ph_wtr_trt_filt),
            ph_wtr_trt_solar = max(ph_wtr_trt_solar),
            ph_wtr_trt_stand = max(ph_wtr_trt_stand),
            ph_wtr_trt_other = max(ph_wtr_trt_other),
            ph_wtr_trt_none = min(ph_wtr_trt_none),
            ph_wtr_trt_appr = max(ph_wtr_trt_appr),
            ph_wtr_time = max(ph_wtr_time),
            ph_wtr_source = first(ph_wtr_source),
            ph_wtr_improve = first(ph_wtr_improve),
            ph_wtr_basic = first(ph_wtr_basic)
          )
      }
      if (i == 3 | i == 4| i == 5) { # IRデータの処理:複数回答を一つに集約(group_by - summarise)
        tmp_merge_add <- tmp_merge_add %>%
          group_by(v001, v002, v003) %>%
          slice(1) %>%
          ungroup()
        }
      unique_column <- setdiff(names(tmp_merge_add), names(tmp_merge)) %>% 
        {if (i == 2 | i == 11){
          c(., "v001", "v002")
        } else {
          c(., "v001", "v002", "v003")
        }}
      # unique_column <- setdiff(names(tmp_merge_add), names(tmp_merge)) %>%
      #   append(c("v001", "v002", "v003"))
      tmp_merge_add <- tmp_merge_add %>%
        select(all_of(unique_column))
      print(sprintf("ファイルの結合中："))

      # キーの重複を確認      
      dup_info <- tmp_merge_add %>%
        {
          if (i == 2 | i == 11){
            cat("v001, v002の重複を確認中...\n")
            group_by(., v001, v002)
          } else {
            cat("v001, v002, v003の重複を確認中...\n")
            group_by(., v001, v002, v003)
          }
        } %>%
        summarise(count = n(), .groups = "drop")

      # countの頻度分布
      freq_dist <- as.data.frame(table(dup_info$count))
      print(freq_dist)
      
      # 結合
      if (i == 2| i == 11) {
        tmp_merge <- inner_join(tmp_merge, tmp_merge_add, by = c("v001", "v002"))
      } else {
        tmp_merge <- inner_join(tmp_merge, tmp_merge_add, by = c("v001", "v002", "v003"))
      }
    }
  }
  
  # svydata構築のための各年ごとの変数設定
  tmp_merge <- tmp_merge %>%
    mutate(
      cluster_id = paste0(year, "_", v001),
      strata_id  = paste0(year, "_", v022),
      sampling_weight = v005 / 1000000
    )

  # 変数にラベルを付ける
  var_label(tmp_merge) <- list(
    cluster_id = "year adjusted cluster ID",
    strata_id = "year adjusted strata ID",
    sampling_weight = "sampling weight (v005 / 1000000)"
  )
  
  # ----------------------------------------------------------
  # 全てNAの列を論理ベクトルで取得
  na_cols <- sapply(df, function(x) all(is.na(x)))
  
  # 全てNAの列の名前
  na_col_names <- names(df)[na_cols]
  # ----------------------------------------------------------
  
  print(sprintf("%s年：ファイルの結合完了", yr))
  # 結合したデータを保存
  print(sprintf("%s年：結合したファイルを保存します", yr))
  output_file_name <- paste0("merge_all_", yr, ".dta")
  output_file <- normalizePath(here("..", "output", yr, output_file_name))
  write_dta(tmp_merge, output_file)
}


