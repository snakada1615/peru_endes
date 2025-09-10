
library(haven)
library(fastDummies)
library(sjlabelled)
library(dplyr)
library(here)
library(tidyr)
library(purrr)


rm(list = ls(all = TRUE))
# ----------------------------------------
# (1) 必要なデータの選択
# ----------------------------------------
temp <- read_dta(here("..", "output", "alldata", "merged_all_years.dta" ))

# 表示する統計量の選択
var_list1 <- names(temp)
pattern <- "^(rh|ph|ms|rc|ch|nt|dm)"
var_list2 <- var_list1[grepl(pattern, var_list1)]
df <- temp[var_list2]

# 整数かつユニークな値が10未満の変数(factorと判定する基準)抽出する関数
is_int_and_few_unique <- function(x) {
  x_non_na <- x[!is.na(x)]  # NA を除いた値だけで判定
  all(x_non_na == as.integer(x_non_na)) && length(unique(x_non_na)) < 10
}

var_list3 <- names(df[sapply(df, is_int_and_few_unique)])
# さらに対象となる変数追加（上の基準で漏れていたものをカバー）
var_list3 <- c(
  var_list3, 
  "ph_sani_type",
  "ph_wtr_source",
  "dm_cooking_fuel"
  )

df <- temp[var_list3]


# ----------------------------------------
# (2) ラベル情報の抽出
# ----------------------------------------
# 
# 各変数について「変数名」「変数ラベル」「値ラベル」を抽出
label_df <- map_dfr(var_list3, function(v) {
  varlab <- var_label(df[[v]])
  if (is.null(varlab)) varlab <- ""
  
  # 値ラベル定義を正しく取得
  vallabs <- attr(df[[v]], "labels")  # または get_labels()とget_values()
  
  if (is.null(vallabs) || length(vallabs) == 0) {
    tibble(
      varname = v,
      varlabel = varlab,
      val = NA_integer_,
      vallabel = NA_character_
    )
  } else {
    tibble(
      varname = rep(v, length(vallabs)),
      varlabel = rep(varlab, length(vallabs)),
      val = as.vector(vallabs),        # 値：1, 2, 3, 9
      vallabel = names(vallabs)        # ラベル："Health facility", "Home", "Other", "Missing"
    )
  }
})

# ----------------------------------------
# (3) ダミー変数生成
# ----------------------------------------
df_dummies <- dummy_cols(
  temp,
  select_columns = var_list3,  # ダミー変数化する列
  remove_selected_columns = TRUE,
  remove_first_dummy = TRUE,
)

# ----------------------------------------
# (4) ダミー変数へラベル付与
#      「変数ラベル: 値ラベル (=1)」の表記
# ----------------------------------------

for (i in seq_len(nrow(label_df))) {
  var <- label_df[i, ]
  # 各ダミー変数に対してラベルを付与
  if (is.na(var$val)) {
    dummy_col <- paste0(var$varname, "_NA")
    lab_txt <- paste0(var$varlabel, ": ", var$vallabel, " (=NA)")
  } else if (var$val == 0) {
    dummy_col <- paste0(var$varname, "_")
    lab_txt <- paste0(var$varlabel, ": ", var$vallabel, " (=0)")
  } else {
    dummy_col <- paste0(var$varname, "_", var$val)
    lab_txt <- paste0(var$varlabel, ": ", var$vallabel, " (=1)")}
  
  if (dummy_col %in% names(df_dummies)) {
    message(sprintf("%s → ラベル付与: '%s'", dummy_col, lab_txt))
    
    # haven::labelled()で確実に属性を付与
    df_dummies[[dummy_col]] <- haven::labelled(
      df_dummies[[dummy_col]], 
      label = lab_txt
    )
  } else {
    print(paste0("Warning: No dummy column found for variable '", var$varname, "' with value '", var$val, "'"))
  }
}


# その後 Stata に書き出してもラベルが残ります
write_dta(df_dummies, here("..","output","alldata","merged_all_years.dta"), version = 13)
print("ファイルの保存が完了しました")


# rm(df, df_dummies, var_labels, value_labels, var_list1, var_list2, var_list3)
# rm(df, var_labels, value_labels, var_list1, var_list2, var_list3)
# ----------------------------------------