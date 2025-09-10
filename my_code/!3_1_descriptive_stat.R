library(gtsummary)
library(here)
library(gt)
library(survey)
library(labelled)
library(haven)

# rmですべてのオブジェクトを削除
rm(list = ls(all = TRUE))

# 各種の関数セット読み込み
source("myTools.R")

# データの読み込み
path_data_file <- normalizePath(
  here("..", "output", 
       "alldata", "merged_all_years.dta")
  ) # ソースコードのルートフォルダを正規化
data <- read_dta(path_data_file)

# 欠損値のみで構成される列を削除
data <- data[, colSums(data != 0, na.rm = TRUE) > 0]

# NAのみで構成される列を削除
data <- data[, colSums(is.na(data)) < nrow(data)]

# NAまたは0のみで構成される列を削除
data <- data[, !apply(data, 2, function(x) all(is.na(x) | x == 0))]

# labelled::to_factorでラベル付き変数をfactor化
data <- labelled::to_factor(data)


# 表示する統計量の選択
var_list1 <- names(data)
pattern <- "^(rh|ph|ms|rc|ch|nt|dm)"
var_list2 <- var_list1[grepl(pattern, var_list1)]
var_list2 <- var_list2[!grepl("_median", var_list2)] # _medianを含む変数を除外
var_list2 <- var_list2[!grepl("_mean", var_list2)] # _meanを含む変数を除外
var_list2 <- var_list2[!grepl("_NA$", var_list2)] # _NAで終わる変数を除外
var_list2_exclude <- c(
  "ph_wtr_trt_cloth_1", "rh_anc_moprg_9", 
  "ch_diar_zinc_1", "ch_diar_zinc_ors_1",
  "ch_diar_intra_1", "ch_novac_card_1"
  )
var_list2 <- var_list2[!var_list2 %in% var_list2_exclude]

# 変数一覧をラベル付きで保存
variable_description <- get_label_list(data[, var_list2]) 
output_filename <- here("..", "output", "alldata", "variable_list.dta")

# 変数一覧を保存するディレクトリが存在するか確認
dir_path <- dirname(output_filename)
if (!file.exists(dir_path)) {
  print("ディレクトリが存在しません")
}
# 変数一覧を保存
write_dta(variable_description, output_filename)

# 処置群を3つにグルーピング
data_filtered <- data %>%
  filter(group_summary %in% c(
    "control_0", "treat1_0", "treat2_0")) %>%
  mutate(
    group_summary = factor(
      group_summary, 
      levels = c("control_0", "treat1_0", "treat2_0"))
  )


# ダミー変数のみを自動抽出してfactor化
data_filtered <- haven::as_factor(data_filtered)

# create data design for complex survey analysis
dhs_design <- svydesign(
  ids = ~cluster_id, 
  strata = ~strata_id, 
  weights = ~sampling_weight, 
  data=data_filtered, 
  nest=TRUE
  )

# 孤立PSU問題に対処
options(survey.lonely.psu = "adjust")

# create descriptive table for complex design (tbl_svysummary)
tbl <- tbl_svysummary(
  dhs_design, 
  
  #特定の変数の型を指定（カテゴリ変数ではなく連続変数として扱う）
  type = list( 
    dm_children_under12 = "continuous",
    dm_age_of_HH_head = "continuous"
  ),
  
  by = group_summary, 
  statistic = all_continuous() ~ "{mean} ({sd})",
  include = var_list2, # 表示する変数を指定
  missing = "no" # 欠損値を表示しない
  ) %>%
  add_p()

# 変数IDを追記
tbl_export <- tbl$table_body %>%
  mutate(
    variable_id = variable
  )

# 記述統計を抽出してcsv保存
df_summary_stat <- as_tibble(tbl_export)
write.csv(
  df_summary_stat, 
  here("..", "output", "alldata", "summary_statistics.csv"), 
  row.names = FALSE
)


gt_tbl <- as_gt(tbl)
gt_tbl %>% 
  gt::gtsave(
    normalizePath(here("..", "output", "image", "descriptive_table.pdf"))
  )  # 拡張子でPNG/JPG自動判定


gt_tbl
