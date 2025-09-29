---
author:
- nakada shunichi
authors:
- nakada shunichi
editor:
  markdown:
    wrap: 72
title: lasso_psm_analysis
toc-title: Table of contents
---

## 1. データ読み込み {#データ読み込み}

::::::::::: cell
``` {.r .cell-code}
# ================================================================================
# 0. 初期設定・パッケージ読み込み
# ================================================================================
library(tinytex)
library(here)
```

::: {.cell-output .cell-output-stderr}
    here() starts at /Users/snakada/Documents/univ_github/peru_endes
:::

``` {.r .cell-code}
library(haven)
library(glmnet)
```

::: {.cell-output .cell-output-stderr}
    Loading required package: Matrix
:::

::: {.cell-output .cell-output-stderr}
    Loaded glmnet 4.1-10
:::

``` {.r .cell-code}
library(tidyverse)
```

::: {.cell-output .cell-output-stderr}
    ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
    ✔ dplyr     1.1.4     ✔ readr     2.1.5
    ✔ forcats   1.0.0     ✔ stringr   1.5.1
    ✔ ggplot2   3.5.2     ✔ tibble    3.3.0
    ✔ lubridate 1.9.4     ✔ tidyr     1.3.1
    ✔ purrr     1.0.4     
:::

::: {.cell-output .cell-output-stderr}
    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ tidyr::expand() masks Matrix::expand()
    ✖ dplyr::filter() masks stats::filter()
    ✖ dplyr::lag()    masks stats::lag()
    ✖ tidyr::pack()   masks Matrix::pack()
    ✖ tidyr::unpack() masks Matrix::unpack()
    ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
:::

``` {.r .cell-code}
# library(fastDummies)
library(nnet)      # 多項ロジスティック回帰
library(survey)    # 重み付き統計解析
```

::: {.cell-output .cell-output-stderr}
    Loading required package: grid
    Loading required package: survival

    Attaching package: 'survey'

    The following object is masked from 'package:graphics':

        dotchart
:::

``` {.r .cell-code}
library(did)       # Staggered DID用（必要に応じて）
library(sjlabelled)　# ラベル付きデータ処理用
```

::: {.cell-output .cell-output-stderr}

    Attaching package: 'sjlabelled'

    The following object is masked from 'package:forcats':

        as_factor

    The following object is masked from 'package:dplyr':

        as_label

    The following object is masked from 'package:ggplot2':

        as_label

    The following objects are masked from 'package:haven':

        as_factor, read_sas, read_spss, read_stata, write_sas, zap_labels
:::

``` {.r .cell-code}
library(tableone)
library(fixest)   # 回帰分析の推定結果から係数表（推定値、標準誤差、t値、p値など）を抽出

# オブジェクトクリア
rm(list = ls(all = TRUE))

# デバッグモードフラグ
debug_mode = TRUE  # デバッグモード
# debug_mode = FALSE # 通常モード

# 自作関数読み込み
source("../myTools.R")
```

::: {.cell-output .cell-output-stderr}

    Attaching package: 'psych'

    The following object is masked from 'package:did':

        sim

    The following objects are masked from 'package:ggplot2':

        %+%, alpha
:::

``` {.r .cell-code}
# ================================================================================
# 1. データ読み込み
# ================================================================================
# DHSデータのルートフォルダを指定
gdrive_dir <- "/Users/snakada/Library/CloudStorage/GoogleDrive-snakada@g.ecc.u-tokyo.ac.jp/マイドライブ/Peru_work/Peru_endes/spss"

# 結果保存先
save_path <- file.path(gdrive_dir, "output", "lasso_stunting")

df_org <- readRDS(
    file.path(gdrive_dir, "output","all_data_merged.rds")
  ) %>% filter(!is.na(nt_ch_stunt))

# データベース一覧
endes_list <- readRDS(file.path(gdrive_dir, "output","endes_data_list.rds"))

# 変数ラベル一覧
endes_var_labels <- readRDS(file.path(gdrive_dir, "output", "endes_var_labels.rds"))


# 介入群グループ化
df_org <- df_org %>%
  mutate(
    treatment_group = case_when(
      treatment_start == "2009" ~ 1,  # 早期介入
      treatment_start == "2011" ~ 2,  # 後期介入
      TRUE ~ 0                        # コントロール
    ),
    treatment_group = as.factor(treatment_group)
  )
# 変数ラベル取得
var_labels <- df_org %>% get_label %>% as_tibble() %>% rename(labels = value)
var_labels$varname <- names(df_org)
```
:::::::::::

## 2. LASSO用データ前処理（介入前データのみ） {#lasso用データ前処理介入前データのみ}

:::::::::: cell
``` {.r .cell-code}
# ================================================================================
# 2. LASSO用データ前処理（介入前データのみ）
# ================================================================================
library(gt)

# 除外変数定義(初期値)
drop_cols_init <- c(
"b3","b4","b5","b9","bidx","caseid","hc27","hhid","m1","m13","m14","m15","m1d",
"m2a","m2b","m2c","m2d","m2e","m2f","m2g","m2h","m2i","m2j","m2k","m2l","m2m",
"m3a","m3b","m3c","m3d","m3e","m3f","m3g","m3h","m3i","m3j","m3k","m3l","m3m",
"m3n","m42c","m42d","m42e","m43","m45","m60","m61","v001","v002","v003","v005",
"v008","v012","v013","v021","v022","v024","v025","v026","v106","v190","v208",
"v467b","v467c","v467d","v467f",
"wt","state","age","treated_status","treatment_start","year_treated",
"ch_report_bw","ch_report_bw","ch_size_birth","dm_cooking_fuel_traditional","dm_cooking_fuel_traditional","dm_rural","dm_weath_index","ms_mar_never","ms_mar_union","ms_sex_recent","nt_bf_status","nt_milk","period","rc_edu","rc_empl","rc_hins_other","rc_hins_priv","rc_litr_cats","rc_media_allthree","rc_media_newsp","rc_media_radio","rc_media_tv","rc_tobc_cig","rc_tobc_cig","rc_tobc_other",
"rh_anc_bldpres","rh_anc_median","rh_anc_bldsamp","rh_anc_median","rh_anc_numvs","rh_anc_numvsrh_anc_moprg","rh_anc_prgcomp","rh_anc_pv","rh_anc_toxinj","rh_anc_urine"
)

# 目的変数と同値となる除去変数("nt_ch_sev_stunt", "nt_ch_haz", "nt_ch_stunt"のうち2つ)
y_var_all <- c("nt_ch_stunt", "nt_ch_sev_stunt", "nt_ch_haz", "nt_ch_sev_wast", "nt_ch_wast", "nt_ch_whz", "nt_ch_ovwt_ht", "nt_ch_ovwt_age", "nt_ch_underwt", "nt_ch_sev_underwt", "nt_ch_any_anem", "nt_ch_mod_anem", "nt_ch_sev_anem")
y_var <- "nt_ch_stunt"
y_var_drop <- setdiff(y_var_all, y_var)

# 除外変数定義(最終値)
drop_cols <- c(drop_cols_init, y_var_all)

# ID・管理用変数
grouping_cols <- c("caseid", "state","treated_status", "treatment_start","group_treated",
                   "wt", "treatment_group", y_var)

# 1. LASSO用のデータセット定義
df_lasso <- df_org

cat("介入前データの群別サンプル数:\n")
```

::: {.cell-output .cell-output-stdout}
    介入前データの群別サンプル数:
:::

``` {.r .cell-code}
print(table(df_lasso$treatment_group))
```

::: {.cell-output .cell-output-stdout}

        0     1     2 
    24737  3543  3792 
:::

``` {.r .cell-code}
# 4. NAの多い列を除去（10%以上NA）
initial_cols <- ncol(df_lasso)
keep_cols <- names(df_lasso)[sapply(df_lasso, function(x) sum(is.na(x)) <= nrow(df_lasso) * 0.1)]
df_lasso <- df_lasso[, keep_cols]
cat("NA値の多い列を", initial_cols - ncol(df_lasso), "個削除しました\n")
```

::: {.cell-output .cell-output-stdout}
    NA値の多い列を 139 個削除しました
:::

``` {.r .cell-code}
# 5. 共変量名の再定義（NA除去後）
all_drop_cols <- intersect(drop_cols, names(df_lasso))
grouping_cols <- intersect(grouping_cols, names(df_lasso))
covariate_names <- setdiff(names(df_lasso), c(all_drop_cols, grouping_cols))


# 6. 共変量のNAがある行を除去
# df_lasso <- df_lasso[, covariate_names]
complete_idx <- complete.cases(df_lasso)
initial_rows <- nrow(df_lasso)
df_lasso <- df_lasso[complete_idx, ]
cat("NA値を含む行を", initial_rows - nrow(df_lasso), "行削除しました\n")
```

::: {.cell-output .cell-output-stdout}
    NA値を含む行を 7958 行削除しました
:::

``` {.r .cell-code}
cat("最終的な介入前データサイズ:", nrow(df_lasso), "行 ×", ncol(df_lasso), "列\n\n")
```

::: {.cell-output .cell-output-stdout}
    最終的な介入前データサイズ: 24114 行 × 182 列
:::

``` {.r .cell-code}
# 共変量のラベル保存
covariate_names_label <- var_labels %>%
  filter(varname %in% covariate_names)
# print文の代替
covariate_names_label %>%
  gt() %>%
  cols_width(
    1 ~ pct(80),
    2 ~ pct(20)
  ) %>%
  print()
```

::: {.cell-output .cell-output-stdout}
    <div id="lhymovbowg" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
      <style>#lhymovbowg table {
      font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    #lhymovbowg thead, #lhymovbowg tbody, #lhymovbowg tfoot, #lhymovbowg tr, #lhymovbowg td, #lhymovbowg th {
      border-style: none;
    }

    #lhymovbowg p {
      margin: 0;
      padding: 0;
    }

    #lhymovbowg .gt_table {
      display: table;
      border-collapse: collapse;
      line-height: normal;
      margin-left: auto;
      margin-right: auto;
      color: #333333;
      font-size: 16px;
      font-weight: normal;
      font-style: normal;
      background-color: #FFFFFF;
      width: auto;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #A8A8A8;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #A8A8A8;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
    }

    #lhymovbowg .gt_caption {
      padding-top: 4px;
      padding-bottom: 4px;
    }

    #lhymovbowg .gt_title {
      color: #333333;
      font-size: 125%;
      font-weight: initial;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-color: #FFFFFF;
      border-bottom-width: 0;
    }

    #lhymovbowg .gt_subtitle {
      color: #333333;
      font-size: 85%;
      font-weight: initial;
      padding-top: 3px;
      padding-bottom: 5px;
      padding-left: 5px;
      padding-right: 5px;
      border-top-color: #FFFFFF;
      border-top-width: 0;
    }

    #lhymovbowg .gt_heading {
      background-color: #FFFFFF;
      text-align: center;
      border-bottom-color: #FFFFFF;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
    }

    #lhymovbowg .gt_bottom_border {
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #lhymovbowg .gt_col_headings {
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
    }

    #lhymovbowg .gt_col_heading {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: normal;
      text-transform: inherit;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: bottom;
      padding-top: 5px;
      padding-bottom: 6px;
      padding-left: 5px;
      padding-right: 5px;
      overflow-x: hidden;
    }

    #lhymovbowg .gt_column_spanner_outer {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: normal;
      text-transform: inherit;
      padding-top: 0;
      padding-bottom: 0;
      padding-left: 4px;
      padding-right: 4px;
    }

    #lhymovbowg .gt_column_spanner_outer:first-child {
      padding-left: 0;
    }

    #lhymovbowg .gt_column_spanner_outer:last-child {
      padding-right: 0;
    }

    #lhymovbowg .gt_column_spanner {
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      vertical-align: bottom;
      padding-top: 5px;
      padding-bottom: 5px;
      overflow-x: hidden;
      display: inline-block;
      width: 100%;
    }

    #lhymovbowg .gt_spanner_row {
      border-bottom-style: hidden;
    }

    #lhymovbowg .gt_group_heading {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: middle;
      text-align: left;
    }

    #lhymovbowg .gt_empty_group_heading {
      padding: 0.5px;
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      vertical-align: middle;
    }

    #lhymovbowg .gt_from_md > :first-child {
      margin-top: 0;
    }

    #lhymovbowg .gt_from_md > :last-child {
      margin-bottom: 0;
    }

    #lhymovbowg .gt_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      margin: 10px;
      border-top-style: solid;
      border-top-width: 1px;
      border-top-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: middle;
      overflow-x: hidden;
    }

    #lhymovbowg .gt_stub {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-right-style: solid;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      padding-left: 5px;
      padding-right: 5px;
    }

    #lhymovbowg .gt_stub_row_group {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-right-style: solid;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      padding-left: 5px;
      padding-right: 5px;
      vertical-align: top;
    }

    #lhymovbowg .gt_row_group_first td {
      border-top-width: 2px;
    }

    #lhymovbowg .gt_row_group_first th {
      border-top-width: 2px;
    }

    #lhymovbowg .gt_summary_row {
      color: #333333;
      background-color: #FFFFFF;
      text-transform: inherit;
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #lhymovbowg .gt_first_summary_row {
      border-top-style: solid;
      border-top-color: #D3D3D3;
    }

    #lhymovbowg .gt_first_summary_row.thick {
      border-top-width: 2px;
    }

    #lhymovbowg .gt_last_summary_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #lhymovbowg .gt_grand_summary_row {
      color: #333333;
      background-color: #FFFFFF;
      text-transform: inherit;
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #lhymovbowg .gt_first_grand_summary_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-top-style: double;
      border-top-width: 6px;
      border-top-color: #D3D3D3;
    }

    #lhymovbowg .gt_last_grand_summary_row_top {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-style: double;
      border-bottom-width: 6px;
      border-bottom-color: #D3D3D3;
    }

    #lhymovbowg .gt_striped {
      background-color: rgba(128, 128, 128, 0.05);
    }

    #lhymovbowg .gt_table_body {
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #lhymovbowg .gt_footnotes {
      color: #333333;
      background-color: #FFFFFF;
      border-bottom-style: none;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
    }

    #lhymovbowg .gt_footnote {
      margin: 0px;
      font-size: 90%;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #lhymovbowg .gt_sourcenotes {
      color: #333333;
      background-color: #FFFFFF;
      border-bottom-style: none;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
    }

    #lhymovbowg .gt_sourcenote {
      font-size: 90%;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #lhymovbowg .gt_left {
      text-align: left;
    }

    #lhymovbowg .gt_center {
      text-align: center;
    }

    #lhymovbowg .gt_right {
      text-align: right;
      font-variant-numeric: tabular-nums;
    }

    #lhymovbowg .gt_font_normal {
      font-weight: normal;
    }

    #lhymovbowg .gt_font_bold {
      font-weight: bold;
    }

    #lhymovbowg .gt_font_italic {
      font-style: italic;
    }

    #lhymovbowg .gt_super {
      font-size: 65%;
    }

    #lhymovbowg .gt_footnote_marks {
      font-size: 75%;
      vertical-align: 0.4em;
      position: initial;
    }

    #lhymovbowg .gt_asterisk {
      font-size: 100%;
      vertical-align: 0;
    }

    #lhymovbowg .gt_indent_1 {
      text-indent: 5px;
    }

    #lhymovbowg .gt_indent_2 {
      text-indent: 10px;
    }

    #lhymovbowg .gt_indent_3 {
      text-indent: 15px;
    }

    #lhymovbowg .gt_indent_4 {
      text-indent: 20px;
    }

    #lhymovbowg .gt_indent_5 {
      text-indent: 25px;
    }

    #lhymovbowg .katex-display {
      display: inline-flex !important;
      margin-bottom: 0.75em !important;
    }

    #lhymovbowg div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
      height: 0px !important;
    }
    </style>
      <table class="gt_table" style="table-layout:fixed;width:100%;" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
      <colgroup>
        <col style="width:80%;"/>
        <col style="width:20%;"/>
      </colgroup>
      <thead>
        <tr class="gt_col_headings">
          <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="labels">labels</th>
          <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="varname">varname</th>
        </tr>
      </thead>
      <tbody class="gt_table_body">
        <tr><td headers="labels" class="gt_row gt_left">Skilled assistance during ANC</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_pvskill</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Attended 4+ ANC visits</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_4vs</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Number of months pregnant at time of first ANC visit</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_moprg</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Attended ANC &lt;4 months of pregnancy</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_4mo</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Took iron tablet/syrup during pregnancy of last birth</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_iron</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Took intestinal parasite drugs during pregnancy of last birth</td>
    <td headers="varname" class="gt_row gt_left">rh_anc_parast</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Problem health care access: permission to go</td>
    <td headers="varname" class="gt_row gt_left">rh_prob_permit</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Problem health care access: getting money</td>
    <td headers="varname" class="gt_row gt_left">rh_prob_money</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Problem health care access: distance to facility</td>
    <td headers="varname" class="gt_row gt_left">rh_prob_dist</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Problem health care access: not wanting to go alone</td>
    <td headers="varname" class="gt_row gt_left">rh_prob_alone</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">At least one problem in accessing health care</td>
    <td headers="varname" class="gt_row gt_left">rh_prob_minone</td></tr>
        <tr><td headers="labels" class="gt_row gt_left"></td>
    <td headers="varname" class="gt_row gt_left">year</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Attended or completed at least secondary education</td>
    <td headers="varname" class="gt_row gt_left">rc_edu_acceptable</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Literate - higher than secondary or can read part or whole sentence</td>
    <td headers="varname" class="gt_row gt_left">rc_litr</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Accesses none of the three media at least once a week</td>
    <td headers="varname" class="gt_row gt_left">rc_media_none</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Occupation among those employed in the past 12 months</td>
    <td headers="varname" class="gt_row gt_left">rc_occup</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Work in agriculture in the past 12 months</td>
    <td headers="varname" class="gt_row gt_left">rc_agri</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Have any health insurance</td>
    <td headers="varname" class="gt_row gt_left">rc_hins_any</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Smokes any type of tobacco</td>
    <td headers="varname" class="gt_row gt_left">rc_tobc_smk_any</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Birth weight less than 2.5 kg</td>
    <td headers="varname" class="gt_row gt_left">ch_below_2p5</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ARI symptoms in the 2 weeks before the survey</td>
    <td headers="varname" class="gt_row gt_left">ch_ari</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Fever symptoms in the 2 weeks before the survey</td>
    <td headers="varname" class="gt_row gt_left">ch_fever</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Started breastfeeding within one hour of birth - last-born in the past 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_bf_start_1hr</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Started breastfeeding within one day of birth - last-born in the past 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_bf_start_1day</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Received a prelacteal feed - last-born in the past 2 years ever breast fed (without birth record data)</td>
    <td headers="varname" class="gt_row gt_left">nt_bf_prelac_nobirthrecord</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Drank from a bottle with a nipple yesterday - under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_bottle</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Age-appropriately breastfed - last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_ageapp_bf</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given infant formula in day/night before survey - last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_formula</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given other liquids in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_liquids</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given fortified baby food in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_bbyfood</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given grains in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_grains</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given vitamin A rich food in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_vita</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given other fruits or vegetables in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_frtveg</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given roots or tubers in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_root</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given legumes or nuts in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_nuts</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given meat, fish, shellfish, or poultry in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_meatfish</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given eggs in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_eggs</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given cheese, yogurt, or other milk products in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_dairy</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given any solid or semisolid food in day/night before survey- last-born under 2 years</td>
    <td headers="varname" class="gt_row gt_left">nt_solids</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child given milk or milk products- last-born 6-23 months</td>
    <td headers="varname" class="gt_row gt_left">nt_fed_milk</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child with minimum dietary diversity, 5 out of 8 food groups- last-born 6-23 months</td>
    <td headers="varname" class="gt_row gt_left">nt_mdd</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child with minimum meal frequency- last-born 6-23 months</td>
    <td headers="varname" class="gt_row gt_left">nt_mmf</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child with minimum acceptable diet- last-born 6-23 months</td>
    <td headers="varname" class="gt_row gt_left">nt_mad</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Youngest children age 6-23 mos living with mother given Vit A rich food</td>
    <td headers="varname" class="gt_row gt_left">nt_ch_micro_vaf</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Current marital status</td>
    <td headers="varname" class="gt_row gt_left">ms_mar_stat</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First marriage by age 15</td>
    <td headers="varname" class="gt_row gt_left">ms_afm_15</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First marriage by age 18</td>
    <td headers="varname" class="gt_row gt_left">ms_afm_18</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First marriage by age 20</td>
    <td headers="varname" class="gt_row gt_left">ms_afm_20</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First marriage by age 22</td>
    <td headers="varname" class="gt_row gt_left">ms_afm_22</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First marriage by age 25</td>
    <td headers="varname" class="gt_row gt_left">ms_afm_25</td></tr>
        <tr><td headers="labels" class="gt_row gt_left"></td>
    <td headers="varname" class="gt_row gt_left">ms_age</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Never had sex</td>
    <td headers="varname" class="gt_row gt_left">ms_sex_never</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First sex by age 15</td>
    <td headers="varname" class="gt_row gt_left">ms_afs_15</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First sex by age 18</td>
    <td headers="varname" class="gt_row gt_left">ms_afs_18</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First sex by age 20</td>
    <td headers="varname" class="gt_row gt_left">ms_afs_20</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First sex by age 22</td>
    <td headers="varname" class="gt_row gt_left">ms_afs_22</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">First sex by age 25</td>
    <td headers="varname" class="gt_row gt_left">ms_afs_25</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Child's stool was disposed of appropriately among youngest children under age 2 living with mother</td>
    <td headers="varname" class="gt_row gt_left">ch_stool_safe</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Number of children under 12 years old</td>
    <td headers="varname" class="gt_row gt_left">dm_children_under12</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">type of cooking fuel</td>
    <td headers="varname" class="gt_row gt_left">dm_cooking_fuel</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she burns food</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_burn</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she argues with him</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_argue</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she goes out without telling him</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_goout</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she neglects the children</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_neglect</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she refuses to have sexual intercourse with him</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_refusesex</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife for at least one of the reasons</td>
    <td headers="varname" class="gt_row gt_left">dm_dvjustify_onereas</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Believe a woman is justified to refuse sex with her husband if she knows he's having sex with other women</td>
    <td headers="varname" class="gt_row gt_left">dm_justify_refusesex</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">living in small town</td>
    <td headers="varname" class="gt_row gt_left">dm_town</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">living in medium city</td>
    <td headers="varname" class="gt_row gt_left">dm_city</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">living in capital city</td>
    <td headers="varname" class="gt_row gt_left">dm_capital</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">poorest wealth quintile</td>
    <td headers="varname" class="gt_row gt_left">dm_poorest</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">poorer wealth quintile</td>
    <td headers="varname" class="gt_row gt_left">dm_poorer</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">middle wealth quintile</td>
    <td headers="varname" class="gt_row gt_left">dm_middle</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">richer wealth quintile</td>
    <td headers="varname" class="gt_row gt_left">dm_richer</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">richest wealth quintile</td>
    <td headers="varname" class="gt_row gt_left">dm_richest</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">agricultural land (hectare)</td>
    <td headers="varname" class="gt_row gt_left">dm_ag_land_ha</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">owns cattle</td>
    <td headers="varname" class="gt_row gt_left">dm_cattle_own</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">owns goats</td>
    <td headers="varname" class="gt_row gt_left">dm_goat_own</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">owns sheep</td>
    <td headers="varname" class="gt_row gt_left">dm_sheep_own</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">owns poultry</td>
    <td headers="varname" class="gt_row gt_left">dm_poultry_own</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">owns refrigerator</td>
    <td headers="varname" class="gt_row gt_left">dm_refrigerator</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">female headed household</td>
    <td headers="varname" class="gt_row gt_left">dm_female_headed</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Age of head of household</td>
    <td headers="varname" class="gt_row gt_left">dm_age_of_hh_head</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">Mild anemia - child 6-59 months</td>
    <td headers="varname" class="gt_row gt_left">nt_ch_mild_anem</td></tr>
      </tbody>
      
      
    </table>
    </div>
:::

``` {.r .cell-code}
# ********** デバッグ用 **********
if (debug_mode) {
  cat("=== デバッグモード: 変数の詳細確認 ===\n")
  cat("共変量数:", length(covariate_names), "\n")
  cat("共変量:\n")
  
  # ダミーでない変数を抽出
  non_dummy <- list()
  temp <- df_lasso[, covariate_names]
  for (var in names(temp)) {
    if (!is_dummy_var(temp[[var]])) {
      non_dummy <- append(non_dummy, var)
    } else {
      cat("ダミー変数:", var)
      print(table(temp[[var]], useNA = "always"))
      cat("\n")
    }
  }
  cat("ダミー変数でない変数数:", length(non_dummy), "\n")
  cat("ダミー変数でない変数:\n")
  print(non_dummy)
}
```

::: {.cell-output .cell-output-stdout}
    === デバッグモード: 変数の詳細確認 ===
    共変量数: 84 
    共変量:
    ダミー変数: rh_anc_pvskill
        0     1  <NA> 
    14163  9951     0 

    ダミー変数: rh_anc_4vs
        0     1  <NA> 
      817 23297     0 

    ダミー変数: rh_anc_4mo
        0     1  <NA> 
     5689 18425     0 

    ダミー変数: rh_anc_iron
        0     1  <NA> 
     2519 21595     0 

    ダミー変数: rh_anc_parast
        0     1  <NA> 
    23482   632     0 

    ダミー変数: rh_prob_permit
        0     1  <NA> 
    21098  3016     0 

    ダミー変数: rh_prob_money
        0     1  <NA> 
     9638 14476     0 

    ダミー変数: rh_prob_dist
        0     1  <NA> 
    14029 10085     0 

    ダミー変数: rh_prob_alone
        0     1  <NA> 
    14905  9209     0 

    ダミー変数: rh_prob_minone
        0     1  <NA> 
     5642 18472     0 

    ダミー変数: rc_edu_acceptable
        0     1  <NA> 
    10833 13281     0 

    ダミー変数: rc_litr
        0     1  <NA> 
     1186 22928     0 

    ダミー変数: rc_media_none
        0     1  <NA> 
    20481  3633     0 

    ダミー変数: rc_agri
        0     1  <NA> 
    20018  4096     0 

    ダミー変数: rc_hins_any
        0     1  <NA> 
     5660 18454     0 

    ダミー変数: rc_tobc_smk_any
        0     1  <NA> 
    23677   437     0 

    ダミー変数: ch_below_2p5
        0     1  <NA> 
    22637  1477     0 

    ダミー変数: ch_ari
        0     1  <NA> 
    22501  1613     0 

    ダミー変数: ch_fever
        0     1  <NA> 
    17596  6518     0 

    ダミー変数: nt_bf_start_1hr
        0     1  <NA> 
    10560 13554     0 

    ダミー変数: nt_bf_start_1day
        0     1  <NA> 
     1747 22367     0 

    ダミー変数: nt_bf_prelac_nobirthrecord
        0     1  <NA> 
     6127 17987     0 

    ダミー変数: nt_bottle
        0     1  <NA> 
    12186 11928     0 

    ダミー変数: nt_ageapp_bf
        0     1  <NA> 
      113 24001     0 

    ダミー変数: nt_formula
        0     1  <NA> 
    21147  2967     0 

    ダミー変数: nt_liquids
        0     1  <NA> 
     6251 17863     0 

    ダミー変数: nt_bbyfood
        0  <NA> 
    24114     0 

    ダミー変数: nt_grains
        0     1  <NA> 
     2620 21494     0 

    ダミー変数: nt_vita
        0     1  <NA> 
     5530 18584     0 

    ダミー変数: nt_frtveg
        0     1  <NA> 
     7177 16937     0 

    ダミー変数: nt_root
        0     1  <NA> 
     4822 19292     0 

    ダミー変数: nt_nuts
        0     1  <NA> 
    13504 10610     0 

    ダミー変数: nt_meatfish
        0     1  <NA> 
     4144 19970     0 

    ダミー変数: nt_eggs
        0     1  <NA> 
    10086 14028     0 

    ダミー変数: nt_dairy
        0     1  <NA> 
    14105 10009     0 

    ダミー変数: nt_solids
        1  <NA> 
    24114     0 

    ダミー変数: nt_fed_milk
        0     1  <NA> 
     3488 20626     0 

    ダミー変数: nt_mdd
        0     1  <NA> 
     5285 18829     0 

    ダミー変数: nt_mmf
        0     1  <NA> 
     1709 22405     0 

    ダミー変数: nt_mad
        0     1  <NA> 
     7861 16253     0 

    ダミー変数: nt_ch_micro_vaf
        1  <NA> 
    24114     0 

    ダミー変数: ms_afm_15
        0     1  <NA> 
    22967  1147     0 

    ダミー変数: ms_afm_18
        0     1  <NA> 
    16921  7193     0 

    ダミー変数: ms_afm_20
        0     1  <NA> 
    11971 12143     0 

    ダミー変数: ms_afm_22
        0     1  <NA> 
     8297 15817     0 

    ダミー変数: ms_afm_25
        0     1  <NA> 
     4983 19131     0 

    ダミー変数: ms_sex_never
        0  <NA> 
    24114     0 

    ダミー変数: ms_afs_15
        0     1  <NA> 
    21295  2819     0 

    ダミー変数: ms_afs_18
        0     1  <NA> 
    10943 13171     0 

    ダミー変数: ms_afs_20
        0     1  <NA> 
     5333 18781     0 

    ダミー変数: ms_afs_22
        0     1  <NA> 
     2655 21459     0 

    ダミー変数: ms_afs_25
        0     1  <NA> 
     1047 23067     0 

    ダミー変数: ch_stool_safe
        0     1  <NA> 
    19002  5112     0 

    ダミー変数: dm_dvjustify_burn
        0     1  <NA> 
    23901   213     0 

    ダミー変数: dm_dvjustify_argue
        0     1  <NA> 
    23931   183     0 

    ダミー変数: dm_dvjustify_goout
        0     1  <NA> 
    23832   282     0 

    ダミー変数: dm_dvjustify_neglect
        0     1  <NA> 
    23549   565     0 

    ダミー変数: dm_dvjustify_refusesex
        0     1  <NA> 
    23965   149     0 

    ダミー変数: dm_dvjustify_onereas
        0     1  <NA> 
    23257   857     0 

    ダミー変数: dm_justify_refusesex
        0     1  <NA> 
      985 23129     0 

    ダミー変数: dm_town
        0     1  <NA> 
    18197  5917     0 

    ダミー変数: dm_city
        0     1  <NA> 
    16137  7977     0 

    ダミー変数: dm_capital
        0     1  <NA> 
    21705  2409     0 

    ダミー変数: dm_poorest
        0     1  <NA> 
    18934  5180     0 

    ダミー変数: dm_poorer
        0     1  <NA> 
    17189  6925     0 

    ダミー変数: dm_middle
        0     1  <NA> 
    18364  5750     0 

    ダミー変数: dm_richer
        0     1  <NA> 
    20237  3877     0 

    ダミー変数: dm_richest
        0     1  <NA> 
    21732  2382     0 

    ダミー変数: dm_cattle_own
        0     1  <NA> 
    21280  2834     0 

    ダミー変数: dm_goat_own
        0     1  <NA> 
    23603   511     0 

    ダミー変数: dm_sheep_own
        0     1  <NA> 
    21701  2413     0 

    ダミー変数: dm_poultry_own
        0     1  <NA> 
    14395  9719     0 

    ダミー変数: dm_refrigerator
        0     1  <NA> 
    14429  9685     0 

    ダミー変数: dm_female_headed
        0     1  <NA> 
    19954  4160     0 

    ダミー変数: nt_ch_mild_anem
        0     1  <NA> 
    16585  7529     0 

    ダミー変数でない変数数: 9 
    ダミー変数でない変数:
    [[1]]
    [1] "rh_anc_moprg"

    [[2]]
    [1] "year"

    [[3]]
    [1] "rc_occup"

    [[4]]
    [1] "ms_mar_stat"

    [[5]]
    [1] "ms_age"

    [[6]]
    [1] "dm_children_under12"

    [[7]]
    [1] "dm_cooking_fuel"

    [[8]]
    [1] "dm_ag_land_ha"

    [[9]]
    [1] "dm_age_of_hh_head"
:::

``` {.r .cell-code}
# ********** デバッグ用 **********
```
::::::::::

## 3. LASSOによる変数選択（介入前データ） {#lassoによる変数選択介入前データ}

:::::::::::::::::::::::: cell
``` {.r .cell-code}
library(gt)
# ================================================================================
# 3. LASSO変数選択（介入前データ）
# ================================================================================
# 完全に一から再開
cat("=== データ処理を再開 ===\n")
```

::: {.cell-output .cell-output-stdout}
    === データ処理を再開 ===
:::

``` {.r .cell-code}
cat("df_lasso の次元:", dim(df_lasso), "\n")
```

::: {.cell-output .cell-output-stdout}
    df_lasso の次元: 24114 182 
:::

``` {.r .cell-code}
cat("covariate_names の数:", length(covariate_names), "\n")
```

::: {.cell-output .cell-output-stdout}
    covariate_names の数: 84 
:::

``` {.r .cell-code}
# Step 1: model.matrix作成
cat("Step 1: model.matrix作成中...\n")
```

::: {.cell-output .cell-output-stdout}
    Step 1: model.matrix作成中...
:::

``` {.r .cell-code}
X_matrix <- model.matrix(~ . - 1, data = df_lasso[, covariate_names, drop=FALSE])
Y <- df_lasso$nt_ch_stunt

cat("=== 問題列の除去 ===\n")
```

::: {.cell-output .cell-output-stdout}
    === 問題列の除去 ===
:::

``` {.r .cell-code}
# Step 1: 標準偏差が0の列を特定・除去
col_sds <- apply(X_matrix, 2, sd, na.rm = TRUE)
zero_sd_cols <- is.na(col_sds) | col_sds == 0
cat("除去する定数列の数:", sum(zero_sd_cols), "\n")
```

::: {.cell-output .cell-output-stdout}
    除去する定数列の数: 4 
:::

``` {.r .cell-code}
if(sum(zero_sd_cols) > 0) {
  cat("除去する列名:\n")
  print(colnames(X_matrix)[zero_sd_cols])
  
  # 定数列を除去
  X_matrix_clean <- X_matrix[, !zero_sd_cols, drop = FALSE]
} else {
  X_matrix_clean <- X_matrix
}
```

::: {.cell-output .cell-output-stdout}
    除去する列名:
    [1] "nt_bbyfood"      "nt_solids"       "nt_ch_micro_vaf" "ms_sex_never"   
:::

``` {.r .cell-code}
cat("列除去後のX_matrix次元:", dim(X_matrix_clean), "\n")
```

::: {.cell-output .cell-output-stdout}
    列除去後のX_matrix次元: 24114 89 
:::

``` {.r .cell-code}
# Step 2: スケーリング実行
cat("=== クリーンなデータでスケーリング ===\n")
```

::: {.cell-output .cell-output-stdout}
    === クリーンなデータでスケーリング ===
:::

``` {.r .cell-code}
X_scaled <- scale(X_matrix_clean)

cat("スケーリング後の次元:", dim(X_scaled), "\n")
```

::: {.cell-output .cell-output-stdout}
    スケーリング後の次元: 24114 89 
:::

``` {.r .cell-code}
cat("スケーリング後のNA数:", sum(is.na(X_scaled)), "\n")
```

::: {.cell-output .cell-output-stdout}
    スケーリング後のNA数: 0 
:::

``` {.r .cell-code}
# Step 3: まだNAがある場合の詳細チェック
if(sum(is.na(X_scaled)) > 0) {
  cat("=== 残存するNA問題の詳細分析 ===\n")
  
  # 各列のNA数をチェック
  col_na_counts <- apply(X_scaled, 2, function(x) sum(is.na(x)))
  problematic_cols <- col_na_counts > 0
  
  cat("NA値を含む列数:", sum(problematic_cols), "\n")
  if(sum(problematic_cols) > 0) {
    cat("問題のある列:\n")
    print(col_na_counts[problematic_cols])
    
    # 問題のある列を除去
    X_scaled <- X_scaled[, !problematic_cols, drop = FALSE]
    cat("問題列除去後の次元:", dim(X_scaled), "\n")
  }
}

# Step 4: 最終確認
cat("=== 最終確認 ===\n")
```

::: {.cell-output .cell-output-stdout}
    === 最終確認 ===
:::

``` {.r .cell-code}
cat("X_scaled次元:", dim(X_scaled), "\n")
```

::: {.cell-output .cell-output-stdout}
    X_scaled次元: 24114 89 
:::

``` {.r .cell-code}
cat("X_scaledのNA数:", sum(is.na(X_scaled)), "\n")
```

::: {.cell-output .cell-output-stdout}
    X_scaledのNA数: 0 
:::

``` {.r .cell-code}
cat("Y長さ:", length(Y), "\n")
```

::: {.cell-output .cell-output-stdout}
    Y長さ: 24114 
:::

``` {.r .cell-code}
cat("Y分布:", table(Y), "\n")
```

::: {.cell-output .cell-output-stdout}
    Y分布: 19824 4290 
:::

``` {.r .cell-code}
# データが正常な場合のLASSO実行
if(nrow(X_scaled) > 0 && ncol(X_scaled) > 0 && sum(is.na(X_scaled)) == 0) {
  cat("=== LASSO実行 ===\n")
  set.seed(123)
  
  cv_model <- cv.glmnet(X_scaled, Y, 
                       alpha = 1, 
                       family = "multinomial", 
                       nfolds = 3)
  
  cat("LASSO実行成功！\n")
} else {
  cat("まだデータに問題があります\n")
}
```

::: {.cell-output .cell-output-stdout}
    === LASSO実行 ===
    LASSO実行成功！
:::

``` {.r .cell-code}
cat("最適λ (lambda.min):", cv_model$lambda.min, "\n")
```

::: {.cell-output .cell-output-stdout}
    最適λ (lambda.min): 0.001559054 
:::

``` {.r .cell-code}
cat("1se λ (lambda.1se):", cv_model$lambda.1se, "\n\n")
```

::: {.cell-output .cell-output-stdout}
    1se λ (lambda.1se): 0.004761126 
:::

``` {.r .cell-code}
# 選択された変数の抽出
coef_min <- coef(cv_model, s = "lambda.min")
selected_vars <- c()
for(i in 1:length(coef_min)) {
  coef_matrix <- as.matrix(coef_min[[i]])
  class_vars <- rownames(coef_matrix)[coef_matrix[,1] != 0 & rownames(coef_matrix) != "(Intercept)"]
  selected_vars <- union(selected_vars, class_vars)
}

cat("LASSO選択変数数:", length(selected_vars), "\n")
```

::: {.cell-output .cell-output-stdout}
    LASSO選択変数数: 62 
:::

``` {.r .cell-code}
if(length(selected_vars) > 0) {
  cat("選択された変数:\n")
  for(i in 1:length(selected_vars)) {
    cat(i, ":", selected_vars[i], "\n")
  }
  # 変数の重要度確認
  coef_importance <- abs(as.matrix(coef(cv_model, s = "lambda.min")[[1]]))
  top_vars <- head(sort(coef_importance[,1], decreasing = TRUE), 20)
  coef_importance <- coef_importance %>%
    as_tibble(rownames = "labels") %>%
    filter(labels %in% selected_vars) %>%
    left_join(var_labels, by = join_by("labels" == "varname"))
  saveRDS(coef_importance, file.path(save_path, "lasso_selected_vars_importance.rds"))

  # 列幅を指定して結果出力
  coef_importance %>%
    gt() %>%
    cols_width(
      1 ~ pct(15),
      2 ~ pct(15),
      3 ~ pct(70)
    ) %>%
    fmt_number(
      columns = c("lambda.min"),
      decimals = 4  # 小数点以下4桁
    ) %>%
  print()    
} else {
  stop("変数が選択されませんでした。λの値を調整してください。")
}
```

::: {.cell-output .cell-output-stdout}
    選択された変数:
    1 : rh_anc_pvskill 
    2 : rh_anc_4vs 
    3 : rh_anc_4mo 
    4 : rh_anc_iron 
    5 : rh_anc_parast 
    6 : rh_prob_permit 
    7 : rh_prob_dist 
    8 : rh_prob_minone 
    9 : year2007 
    10 : year2008 
    11 : year2009 
    12 : year2010 
    13 : year2011 
    14 : year2014 
    15 : year2015 
    16 : year2016 
    17 : rc_edu_acceptable 
    18 : rc_litr 
    19 : rc_media_none 
    20 : rc_occup 
    21 : rc_agri 
    22 : rc_hins_any 
    23 : rc_tobc_smk_any 
    24 : ch_below_2p5 
    25 : nt_bf_start_1hr 
    26 : nt_bf_start_1day 
    27 : nt_bf_prelac_nobirthrecord 
    28 : nt_bottle 
    29 : nt_formula 
    30 : nt_liquids 
    31 : nt_grains 
    32 : nt_frtveg 
    33 : nt_root 
    34 : nt_nuts 
    35 : nt_eggs 
    36 : nt_dairy 
    37 : nt_fed_milk 
    38 : nt_mdd 
    39 : nt_mmf 
    40 : ms_mar_stat 
    41 : ms_afm_15 
    42 : ms_afs_15 
    43 : ms_afs_18 
    44 : ms_afs_25 
    45 : ch_stool_safe 
    46 : dm_children_under12 
    47 : dm_cooking_fuel 
    48 : dm_dvjustify_argue 
    49 : dm_dvjustify_neglect 
    50 : dm_justify_refusesex 
    51 : dm_town 
    52 : dm_capital 
    53 : dm_poorest 
    54 : dm_poorer 
    55 : dm_richer 
    56 : dm_richest 
    57 : dm_ag_land_ha 
    58 : dm_cattle_own 
    59 : dm_goat_own 
    60 : dm_sheep_own 
    61 : dm_refrigerator 
    62 : dm_age_of_hh_head 
    <div id="qrwwcuyfmt" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
      <style>#qrwwcuyfmt table {
      font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    #qrwwcuyfmt thead, #qrwwcuyfmt tbody, #qrwwcuyfmt tfoot, #qrwwcuyfmt tr, #qrwwcuyfmt td, #qrwwcuyfmt th {
      border-style: none;
    }

    #qrwwcuyfmt p {
      margin: 0;
      padding: 0;
    }

    #qrwwcuyfmt .gt_table {
      display: table;
      border-collapse: collapse;
      line-height: normal;
      margin-left: auto;
      margin-right: auto;
      color: #333333;
      font-size: 16px;
      font-weight: normal;
      font-style: normal;
      background-color: #FFFFFF;
      width: auto;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #A8A8A8;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #A8A8A8;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_caption {
      padding-top: 4px;
      padding-bottom: 4px;
    }

    #qrwwcuyfmt .gt_title {
      color: #333333;
      font-size: 125%;
      font-weight: initial;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-color: #FFFFFF;
      border-bottom-width: 0;
    }

    #qrwwcuyfmt .gt_subtitle {
      color: #333333;
      font-size: 85%;
      font-weight: initial;
      padding-top: 3px;
      padding-bottom: 5px;
      padding-left: 5px;
      padding-right: 5px;
      border-top-color: #FFFFFF;
      border-top-width: 0;
    }

    #qrwwcuyfmt .gt_heading {
      background-color: #FFFFFF;
      text-align: center;
      border-bottom-color: #FFFFFF;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_bottom_border {
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_col_headings {
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_col_heading {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: normal;
      text-transform: inherit;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: bottom;
      padding-top: 5px;
      padding-bottom: 6px;
      padding-left: 5px;
      padding-right: 5px;
      overflow-x: hidden;
    }

    #qrwwcuyfmt .gt_column_spanner_outer {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: normal;
      text-transform: inherit;
      padding-top: 0;
      padding-bottom: 0;
      padding-left: 4px;
      padding-right: 4px;
    }

    #qrwwcuyfmt .gt_column_spanner_outer:first-child {
      padding-left: 0;
    }

    #qrwwcuyfmt .gt_column_spanner_outer:last-child {
      padding-right: 0;
    }

    #qrwwcuyfmt .gt_column_spanner {
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      vertical-align: bottom;
      padding-top: 5px;
      padding-bottom: 5px;
      overflow-x: hidden;
      display: inline-block;
      width: 100%;
    }

    #qrwwcuyfmt .gt_spanner_row {
      border-bottom-style: hidden;
    }

    #qrwwcuyfmt .gt_group_heading {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: middle;
      text-align: left;
    }

    #qrwwcuyfmt .gt_empty_group_heading {
      padding: 0.5px;
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      vertical-align: middle;
    }

    #qrwwcuyfmt .gt_from_md > :first-child {
      margin-top: 0;
    }

    #qrwwcuyfmt .gt_from_md > :last-child {
      margin-bottom: 0;
    }

    #qrwwcuyfmt .gt_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      margin: 10px;
      border-top-style: solid;
      border-top-width: 1px;
      border-top-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 1px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 1px;
      border-right-color: #D3D3D3;
      vertical-align: middle;
      overflow-x: hidden;
    }

    #qrwwcuyfmt .gt_stub {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-right-style: solid;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      padding-left: 5px;
      padding-right: 5px;
    }

    #qrwwcuyfmt .gt_stub_row_group {
      color: #333333;
      background-color: #FFFFFF;
      font-size: 100%;
      font-weight: initial;
      text-transform: inherit;
      border-right-style: solid;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
      padding-left: 5px;
      padding-right: 5px;
      vertical-align: top;
    }

    #qrwwcuyfmt .gt_row_group_first td {
      border-top-width: 2px;
    }

    #qrwwcuyfmt .gt_row_group_first th {
      border-top-width: 2px;
    }

    #qrwwcuyfmt .gt_summary_row {
      color: #333333;
      background-color: #FFFFFF;
      text-transform: inherit;
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #qrwwcuyfmt .gt_first_summary_row {
      border-top-style: solid;
      border-top-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_first_summary_row.thick {
      border-top-width: 2px;
    }

    #qrwwcuyfmt .gt_last_summary_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_grand_summary_row {
      color: #333333;
      background-color: #FFFFFF;
      text-transform: inherit;
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #qrwwcuyfmt .gt_first_grand_summary_row {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-top-style: double;
      border-top-width: 6px;
      border-top-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_last_grand_summary_row_top {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 5px;
      padding-right: 5px;
      border-bottom-style: double;
      border-bottom-width: 6px;
      border-bottom-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_striped {
      background-color: rgba(128, 128, 128, 0.05);
    }

    #qrwwcuyfmt .gt_table_body {
      border-top-style: solid;
      border-top-width: 2px;
      border-top-color: #D3D3D3;
      border-bottom-style: solid;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_footnotes {
      color: #333333;
      background-color: #FFFFFF;
      border-bottom-style: none;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_footnote {
      margin: 0px;
      font-size: 90%;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #qrwwcuyfmt .gt_sourcenotes {
      color: #333333;
      background-color: #FFFFFF;
      border-bottom-style: none;
      border-bottom-width: 2px;
      border-bottom-color: #D3D3D3;
      border-left-style: none;
      border-left-width: 2px;
      border-left-color: #D3D3D3;
      border-right-style: none;
      border-right-width: 2px;
      border-right-color: #D3D3D3;
    }

    #qrwwcuyfmt .gt_sourcenote {
      font-size: 90%;
      padding-top: 4px;
      padding-bottom: 4px;
      padding-left: 5px;
      padding-right: 5px;
    }

    #qrwwcuyfmt .gt_left {
      text-align: left;
    }

    #qrwwcuyfmt .gt_center {
      text-align: center;
    }

    #qrwwcuyfmt .gt_right {
      text-align: right;
      font-variant-numeric: tabular-nums;
    }

    #qrwwcuyfmt .gt_font_normal {
      font-weight: normal;
    }

    #qrwwcuyfmt .gt_font_bold {
      font-weight: bold;
    }

    #qrwwcuyfmt .gt_font_italic {
      font-style: italic;
    }

    #qrwwcuyfmt .gt_super {
      font-size: 65%;
    }

    #qrwwcuyfmt .gt_footnote_marks {
      font-size: 75%;
      vertical-align: 0.4em;
      position: initial;
    }

    #qrwwcuyfmt .gt_asterisk {
      font-size: 100%;
      vertical-align: 0;
    }

    #qrwwcuyfmt .gt_indent_1 {
      text-indent: 5px;
    }

    #qrwwcuyfmt .gt_indent_2 {
      text-indent: 10px;
    }

    #qrwwcuyfmt .gt_indent_3 {
      text-indent: 15px;
    }

    #qrwwcuyfmt .gt_indent_4 {
      text-indent: 20px;
    }

    #qrwwcuyfmt .gt_indent_5 {
      text-indent: 25px;
    }

    #qrwwcuyfmt .katex-display {
      display: inline-flex !important;
      margin-bottom: 0.75em !important;
    }

    #qrwwcuyfmt div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
      height: 0px !important;
    }
    </style>
      <table class="gt_table" style="table-layout:fixed;width:100%;" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
      <colgroup>
        <col style="width:15%;"/>
        <col style="width:15%;"/>
        <col style="width:70%;"/>
      </colgroup>
      <thead>
        <tr class="gt_col_headings">
          <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="labels">labels</th>
          <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="lambda.min">lambda.min</th>
          <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="labels.y">labels.y</th>
        </tr>
      </thead>
      <tbody class="gt_table_body">
        <tr><td headers="labels" class="gt_row gt_left">rh_anc_pvskill</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0148</td>
    <td headers="labels.y" class="gt_row gt_left">Skilled assistance during ANC</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_anc_4vs</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0065</td>
    <td headers="labels.y" class="gt_row gt_left">Attended 4+ ANC visits</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_anc_4mo</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0166</td>
    <td headers="labels.y" class="gt_row gt_left">Attended ANC &lt;4 months of pregnancy</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_anc_iron</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0003</td>
    <td headers="labels.y" class="gt_row gt_left">Took iron tablet/syrup during pregnancy of last birth</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_anc_parast</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0076</td>
    <td headers="labels.y" class="gt_row gt_left">Took intestinal parasite drugs during pregnancy of last birth</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_prob_permit</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0142</td>
    <td headers="labels.y" class="gt_row gt_left">Problem health care access: permission to go</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_prob_dist</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0058</td>
    <td headers="labels.y" class="gt_row gt_left">Problem health care access: distance to facility</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rh_prob_minone</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0128</td>
    <td headers="labels.y" class="gt_row gt_left">At least one problem in accessing health care</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2007</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0295</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2008</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0323</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2009</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0245</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2010</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0165</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2011</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0251</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2014</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0144</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2015</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0213</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">year2016</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0410</td>
    <td headers="labels.y" class="gt_row gt_left">NA</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_edu_acceptable</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0755</td>
    <td headers="labels.y" class="gt_row gt_left">Attended or completed at least secondary education</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_litr</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0415</td>
    <td headers="labels.y" class="gt_row gt_left">Literate - higher than secondary or can read part or whole sentence</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_media_none</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0115</td>
    <td headers="labels.y" class="gt_row gt_left">Accesses none of the three media at least once a week</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_occup</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0067</td>
    <td headers="labels.y" class="gt_row gt_left">Occupation among those employed in the past 12 months</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_agri</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0269</td>
    <td headers="labels.y" class="gt_row gt_left">Work in agriculture in the past 12 months</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_hins_any</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0104</td>
    <td headers="labels.y" class="gt_row gt_left">Have any health insurance</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">rc_tobc_smk_any</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0139</td>
    <td headers="labels.y" class="gt_row gt_left">Smokes any type of tobacco</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ch_below_2p5</td>
    <td headers="lambda.min" class="gt_row gt_right">0.1341</td>
    <td headers="labels.y" class="gt_row gt_left">Birth weight less than 2.5 kg</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_bf_start_1hr</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0225</td>
    <td headers="labels.y" class="gt_row gt_left">Started breastfeeding within one hour of birth - last-born in the past 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_bf_start_1day</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0320</td>
    <td headers="labels.y" class="gt_row gt_left">Started breastfeeding within one day of birth - last-born in the past 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_bf_prelac_nobirthrecord</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0026</td>
    <td headers="labels.y" class="gt_row gt_left">Received a prelacteal feed - last-born in the past 2 years ever breast fed (without birth record data)</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_bottle</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0261</td>
    <td headers="labels.y" class="gt_row gt_left">Drank from a bottle with a nipple yesterday - under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_formula</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0011</td>
    <td headers="labels.y" class="gt_row gt_left">Child given infant formula in day/night before survey - last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_liquids</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0050</td>
    <td headers="labels.y" class="gt_row gt_left">Child given other liquids in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_grains</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0132</td>
    <td headers="labels.y" class="gt_row gt_left">Child given grains in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_frtveg</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0095</td>
    <td headers="labels.y" class="gt_row gt_left">Child given other fruits or vegetables in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_root</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0086</td>
    <td headers="labels.y" class="gt_row gt_left">Child given roots or tubers in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_nuts</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0054</td>
    <td headers="labels.y" class="gt_row gt_left">Child given legumes or nuts in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_eggs</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0076</td>
    <td headers="labels.y" class="gt_row gt_left">Child given eggs in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_dairy</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0200</td>
    <td headers="labels.y" class="gt_row gt_left">Child given cheese, yogurt, or other milk products in day/night before survey- last-born under 2 years</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_fed_milk</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0570</td>
    <td headers="labels.y" class="gt_row gt_left">Child given milk or milk products- last-born 6-23 months</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_mdd</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0010</td>
    <td headers="labels.y" class="gt_row gt_left">Child with minimum dietary diversity, 5 out of 8 food groups- last-born 6-23 months</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">nt_mmf</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0062</td>
    <td headers="labels.y" class="gt_row gt_left">Child with minimum meal frequency- last-born 6-23 months</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ms_mar_stat</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0063</td>
    <td headers="labels.y" class="gt_row gt_left">Current marital status</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ms_afm_15</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0093</td>
    <td headers="labels.y" class="gt_row gt_left">First marriage by age 15</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ms_afs_15</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0029</td>
    <td headers="labels.y" class="gt_row gt_left">First sex by age 15</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ms_afs_18</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0076</td>
    <td headers="labels.y" class="gt_row gt_left">First sex by age 18</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ms_afs_25</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0014</td>
    <td headers="labels.y" class="gt_row gt_left">First sex by age 25</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">ch_stool_safe</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0061</td>
    <td headers="labels.y" class="gt_row gt_left">Child's stool was disposed of appropriately among youngest children under age 2 living with mother</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_children_under12</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0805</td>
    <td headers="labels.y" class="gt_row gt_left">Number of children under 12 years old</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_cooking_fuel</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0097</td>
    <td headers="labels.y" class="gt_row gt_left">type of cooking fuel</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_dvjustify_argue</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0007</td>
    <td headers="labels.y" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she argues with him</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_dvjustify_neglect</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0001</td>
    <td headers="labels.y" class="gt_row gt_left">Agree that husband is justified in hitting or beating his wife if she neglects the children</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_justify_refusesex</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0091</td>
    <td headers="labels.y" class="gt_row gt_left">Believe a woman is justified to refuse sex with her husband if she knows he's having sex with other women</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_town</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0111</td>
    <td headers="labels.y" class="gt_row gt_left">living in small town</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_capital</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0364</td>
    <td headers="labels.y" class="gt_row gt_left">living in capital city</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_poorest</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0951</td>
    <td headers="labels.y" class="gt_row gt_left">poorest wealth quintile</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_poorer</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0277</td>
    <td headers="labels.y" class="gt_row gt_left">poorer wealth quintile</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_richer</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0536</td>
    <td headers="labels.y" class="gt_row gt_left">richer wealth quintile</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_richest</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0904</td>
    <td headers="labels.y" class="gt_row gt_left">richest wealth quintile</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_ag_land_ha</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0040</td>
    <td headers="labels.y" class="gt_row gt_left">agricultural land (hectare)</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_cattle_own</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0170</td>
    <td headers="labels.y" class="gt_row gt_left">owns cattle</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_goat_own</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0025</td>
    <td headers="labels.y" class="gt_row gt_left">owns goats</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_sheep_own</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0500</td>
    <td headers="labels.y" class="gt_row gt_left">owns sheep</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_refrigerator</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0595</td>
    <td headers="labels.y" class="gt_row gt_left">owns refrigerator</td></tr>
        <tr><td headers="labels" class="gt_row gt_left">dm_age_of_hh_head</td>
    <td headers="lambda.min" class="gt_row gt_right">0.0237</td>
    <td headers="labels.y" class="gt_row gt_left">Age of head of household</td></tr>
      </tbody>
      
      
    </table>
    </div>
:::
::::::::::::::::::::::::

## 4. 多項GLM-PSM（介入前データによる学習） {#多項glm-psm介入前データによる学習}

## 5. PSM結果のバランス診断 {#psm結果のバランス診断}

## 6. PSMのバランスチェック（クラスターサンプリングによる重み付けなし） {#psmのバランスチェッククラスターサンプリングによる重み付けなし}

## 7. DID分析結果のまとめ {#did分析結果のまとめ}

## 9. 結果の保存・可視化 {#結果の保存可視化}
