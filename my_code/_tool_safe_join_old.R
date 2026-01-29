
# ******************************************************************************
#' キー変数を正規化する関数
#' @param df データフレーム
#' @param key_vars 正規化するキー変数のベクトル
#' @return 正規化されたデータフレーム
#' @description
#' この関数は、指定されたデータフレームのキー変数に対して、
#' ファクター型を文字型に変換し、文字型の場合は
#' 空白を正規化します。数値型の場合はそのまま保持します。
#' 使用例:
#' ```R
#' df_normalized <- normalize_keys(df, key_vars = c("id", "year"))
#' ```
#' **************************************************************************
normalize_keys <- function(df, key_vars) {
  for (key in key_vars) {
    if (key %in% names(df)) {
      # ファクター型の場合は文字型に変換
      if (is.factor(df[[key]])) {
        df[[key]] <- as.character(df[[key]])
      }
      # 文字型の場合は空白を正規化
      if (is.character(df[[key]])) {
        df[[key]] <- stringr::str_squish(df[[key]])
      }
      # 数値型の場合はそのまま（ただしNA処理）
      if (is.numeric(df[[key]])) {
        # 特に何もしない（必要に応じて処理追加）
      }
    }
  }
  return(df)
}

# ******************************************************************************
#' 結合前の診断を行う関数
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by_vars 結合キーのベクトル
#' @param join_name 結合の名称（ログ用）
#' @return 診断結果のリスト
#' @description
#' この関数は、2つのデータフレームを結合する前に、
#' キー変数の存在確認、データ型の一致確認、
#' ユニークキー数の確認、マッチング率の計算を行います。
#' 使用例:
#' ```R
#' diagnose_result <- diagnose_join(df1, df2, by_vars = c("id", "year"),
#'                                 join_name = "Example Join")
#' ```
#' **************************************************************************         
diagnose_join <- function(df1, df2, by_vars, join_name = "") {
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("結合診断:", join_name, "\n")
  cat(strrep("=", 80), "\n")
  
  # キー変数の存在確認
  missing_keys_df1 <- setdiff(by_vars, names(df1))
  missing_keys_df2 <- setdiff(by_vars, names(df2))
  
  if (length(missing_keys_df1) > 0) {
    warning("左側データフレームに以下のキーが存在しません: ", 
            paste(missing_keys_df1, collapse = ", "))
  }
  
  if (length(missing_keys_df2) > 0) {
    warning("右側データフレームに以下のキーが存在しません: ", 
            paste(missing_keys_df2, collapse = ", "))
  }
  
  # 共通キーのみで診断
  common_keys <- intersect(by_vars, intersect(names(df1), names(df2)))
  
  if (length(common_keys) == 0) {
    stop("共通のキー変数が存在しません")
  }
  
  # データ型の確認
  cat("\n【キー変数のデータ型】\n")
  for (key in common_keys) {
    type1 <- class(df1[[key]])[1]
    type2 <- class(df2[[key]])[1]
    match_symbol <- if(type1 == type2) "✓" else "✗"
    cat(sprintf("  %s: %s (%s) vs %s (%s) %s\n", 
                key, type1, type2, "右側", type2, match_symbol))
  }
  
  # ユニークキーの数とマッチング率
  cat("\n【キーの分布】\n")
  cat(sprintf("  左側データ行数: %d\n", nrow(df1)))
  cat(sprintf("  右側データ行数: %d\n", nrow(df2)))
  
  # グループ化が残っていても影響しないように ungroup() を明示
  df1_keys <- df1 %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(by_vars)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  df2_keys <- df2 %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(by_vars)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  for (key in by_vars) {
    n_unique_df1 <- df1_keys %>% dplyr::distinct(.data[[key]]) %>% nrow()
    n_unique_df2 <- df2_keys %>% dplyr::distinct(.data[[key]]) %>% nrow()
    cat(sprintf("  %s のユニーク数: 左=%d, 右=%d\n", key, n_unique_df1, n_unique_df2))
  }
  
  # マッチング診断用の anti_join / semi_join は、先に ungroup() を入れておく
  cat("\n【マッチング診断】\n")
  unmatched_left <- df1 %>%
    dplyr::ungroup() %>%
    dplyr::anti_join(df2 %>% dplyr::ungroup(), by = by_vars)
  
  unmatched_right <- df2 %>%
    dplyr::ungroup() %>%
    dplyr::anti_join(df1 %>% dplyr::ungroup(), by = by_vars)
  
  matched_rows <- df1 %>%
    dplyr::ungroup() %>%
    dplyr::semi_join(df2 %>% dplyr::ungroup(), by = by_vars) %>%
    nrow()
  
  match_rate <- 100 * matched_rows / nrow(df1)
  cat(sprintf("  マッチング率: %.1f%%\n", match_rate))
  
  # 警告の表示
  if (match_rate < 50) {
    warning("マッチング率が50%未満です。キー変数を確認してください。")
  }
  
  cat(strrep("=", 80), "\n\n")
  
  return(list(
    common_keys = common_keys,
    match_rate = match_rate,
    unmatched_left = unmatched_left,
    unmatched_right = unmatched_right
  ))
}
# -----------関数ここまで-------------------------------------------------


# ******************************************************************************
# 重複診断関数の追加
# ******************************************************************************

#' 結合キーの重複を診断する関数
#' @param df データフレーム
#' @param by_vars 結合キーのベクトル
#' @param df_name データフレーム名（ログ用）
#' @return 重複情報のリスト
#' @description
#' この関数は、指定されたデータフレームにおいて、
#' 結合キーの重複を診断します。重複行数、
#' ユニークキー数、重複しているキーの例を表示します。
#' 使用例:
#' ```R
#' dup_result <- diagnose_duplicates(df, by_vars = c("id", "year"),
#'                                 df_name = "Example Data")
#' ```
#' **************************************************************************
diagnose_duplicates <- function(df, by_vars, df_name = "") {
  cat("\n【重複診断:", df_name, "】\n")
  
  # ▼ ここで必ず ungroup() してから処理 ▼
  key_combo <- df %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(by_vars)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  n_total  <- nrow(key_combo)
  n_unique <- key_combo %>% dplyr::distinct() %>% nrow()
  n_duplicates <- n_total - n_unique
  
  cat(sprintf("  総行数: %d\n", n_total))
  cat(sprintf("  ユニークなキー組み合わせ: %d\n", n_unique))
  cat(sprintf("  重複行数: %d\n", n_duplicates))
  
  if (n_duplicates > 0) {
    duplicate_keys <- key_combo %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(by_vars))) %>%
      dplyr::filter(dplyr::n() > 1) %>%
      dplyr::ungroup() %>%
      dplyr::distinct()
    
    cat(sprintf("  重複しているキーパターン数: %d\n", nrow(duplicate_keys)))
    cat("  重複例（最初の5件）:\n")
    print(head(duplicate_keys, 5))
    
    return(list(
      has_duplicates = TRUE,
      n_duplicates   = n_duplicates,
      duplicate_keys = duplicate_keys
    ))
  } else {
    cat("  ✓ 重複なし\n")
    return(list(has_duplicates = FALSE))
  }
}
# -----------関数ここまで-------------------------------------------------

# ******************************************************************************
# 改善版：安全な左結合を行う関数
# ******************************************************************************
#' 改良版：安全な左結合を行う関数（診断機能付き、優先キー対応版）
#' @title left_join_safe
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by 結合キー（名前付きベクトルまたは文字ベ
#' クトル）
#' @param join_name 結合の名称
#' @param diagnose 診断を実行するか（デフォルト: FALSE
#' ）
#' @param priority_key 右側データフレームで重複が
#' ある場合に優先的に保持するキー変数のベクトル
#' @return 結合されたデータフレーム
#' @description
#' この関数は、dplyrのleft_joinを拡張し、
#' 結合前にキー変数の正規化と診断を行
#' います。診断には、キー変数の存在確認、データ型の一致確認、
#' ユニークキー数の確認、マッチング率の計算が
#' 含まれます。また、右側データフレームに重複がある場合は、
#' priority_keyで指定された変数を基に優先順位を決定し
#' て最初の行のみを保持して結合を行います。
#' 使用例:
#' ```R
#' result <- left_join_safe(df1, df2, by = c("id"
#' = "identifier"), join_name = "Example Join",
#'                         diagnose = TRUE,
#'                         priority_key = c("date_updated", "version"))
#' ```
#'************************************************************************
left_join_safe <- function(df1, df2, by, join_name = "", diagnose = FALSE,
                           priority_key = NULL) {
  
  # by引数を名前付きベクトルから文字ベクトルに変換
  if (is.null(names(by))) {
    by_vars <- by
    by_df1 <- by
    by_df2 <- by
  } else {
    by_df1 <- names(by)
    by_df2 <- unname(by)
    by_vars <- unique(c(by_df1, by_df2))
  }
  
  # キー変数の正規化
  df1_normalized <- normalize_keys(df1, by_df1)
  df2_normalized <- normalize_keys(df2, by_df2)
  
  # 診断の実行
  if (diagnose) {
    diag_result <- diagnose_join(df1_normalized, df2_normalized, 
                                 by_vars, join_name)
    
    # 重複診断を追加
    cat("\n")
    dup_df1 <- diagnose_duplicates(df1_normalized, by_df1, "左側データ")
    dup_df2 <- diagnose_duplicates(df2_normalized, by_df2, "右側データ")
  }
  
  # 右側（df2）に重複がある場合の処理
  # HRdata-dmのような世帯データの場合、世帯レベルの変数のみを保持
  if (!is.null(priority_key) && !all(is.na(priority_key))) {
    # priority_keyが指定されている場合
    df2_unique <- df2_normalized %>%
      arrange(across(all_of(by_df2)),
              desc(across(all_of(priority_key)))) %>%  # 降順で新しい/優先度の高い順
      group_by(across(all_of(by_df2))) %>%
      slice(1) %>%
      ungroup()
  } else {
    # 従来の処理（指定されていない場合）
    df2_unique <- df2_normalized %>%
      group_by(across(all_of(by_df2))) %>%
      slice(1) %>%
      ungroup()
  }
  
  # 重複除去後の行数を確認
  if (diagnose && nrow(df2_unique) < nrow(df2_normalized)) {
    cat(sprintf("\n【重複除去】右側データを %d 行 → %d 行に削減しました\n", 
                nrow(df2_normalized), nrow(df2_unique)))
  }
  
  # 結合の実行
  result <- dplyr::left_join(df1_normalized, df2_unique, by = by,
                             relationship = "many-to-one")
  
  # ▼▼ 結合直後にサフィックスをクリーンアップ ▼▼
  result <- result %>%
    dplyr::select(-ends_with(".y")) %>%
    rename_with(~str_remove(., "\\.x$"), ends_with(".x"))
  
  # 結果の確認
  if (nrow(result) == 0) {
    stop(sprintf("結合結果が0行です: %s", join_name))
  }
  
  if (nrow(result) != nrow(df1)) {
    warning(sprintf("結合後の行数が変化しました: %s (元: %d, 結果: %d)", 
                    join_name, nrow(df1), nrow(result)))
  }
  
  return(result)
}

# -----------関数ここまで----------------------------------------------
# ============================================================================
# 年度別変数存在チェック関数
# ============================================================================
#' データセット内の変数の存在を確認する関数
#' @param data_list データフレームのリスト
#' @param year 対象年度
#' @return 変数存在マトリックス
#' @description
#' この関数は、指定されたデータセットリスト内で
#' 重要な変数群の存在を確認し、
#' 各データセットでの存在状況をレポートします。
#' 使用例:
#' ```R
#' check_variable_availability(data_list, year = "2015")
#' ```
#' ===========================================================================
check_variable_availability <- function(data_list, year) {
  cat("\n", strrep("=", 80), "\n")
  cat("年度", year, "の変数存在チェック\n")
  cat(strrep("=", 80), "\n\n")
  
  # 重要な変数群を定義
  critical_vars <- list(
    "産前ケア" = c("m2a", "m2b", "m2c", "m2d", "m2e", "m2f", "m2g", "m2h", 
               "m2i", "m2j", "m2k", "m2l", "m2m"),
    "出産ケア" = c("m3a", "m3b", "m3c", "m3d", "m3e", "m3f", "m3g", "m3h",
               "m3i", "m3j", "m3k", "m3l", "m3m"),
    "予防接種" = c("h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9"),
    "栄養指標" = c("hw1", "hw2", "hw3", "hw70", "hw71", "hw72")
  )
  
  for (category in names(critical_vars)) {
    cat(sprintf("【%s】\n", category))
    vars <- critical_vars[[category]]
    
    # 各データセットでの存在を確認
    for (dataset_name in names(data_list)) {
      existing_vars <- intersect(vars, names(data_list[[dataset_name]]))
      if (length(existing_vars) > 0) {
        cat(sprintf("  %s: %d/%d 変数が存在\n", 
                    dataset_name, length(existing_vars), length(vars)))
        cat(sprintf("    → %s\n", paste(existing_vars, collapse = ", ")))
      }
    }
    cat("\n")
  }
}
# -----------関数ここまで-------------------------------------------------

# ============================================================================
# 欠損変数の詳細分析関数
# ============================================================================

#' 欠損変数を分類して詳細レポートを作成
#' @param data_merged 結合されたデータフレーム
#' @param data_all 元のデータリスト
#' @return 欠損分析結果
analyze_missing_variables <- function(data_merged, data_all) {
  cat("\n", strrep("=", 80), "\n")
  cat("欠損変数の詳細分析\n")
  cat(strrep("=", 80), "\n\n")
  
  # 欠損率を計算
  na_counts <- sapply(names(data_merged), function(x) {
    sum(is.na(data_merged[[x]]))
  })
  
  na_rates <- 100 * na_counts / nrow(data_merged)
  
  # 欠損率で分類
  complete_missing <- names(na_counts)[na_rates == 100]
  high_missing <- names(na_counts)[na_rates >= 50 & na_rates < 100]
  moderate_missing <- names(na_counts)[na_rates >= 10 & na_rates < 50]
  low_missing <- names(na_counts)[na_rates > 0 & na_rates < 10]
  
  cat(sprintf("【欠損率100%% (完全欠損)】: %d 変数\n", length(complete_missing)))
  if (length(complete_missing) > 0) {
    cat("  ", paste(head(complete_missing, 20), collapse = ", "))
    if (length(complete_missing) > 20) cat("...")
    cat("\n\n")
    
    # 元データでの存在を確認
    cat("  元データでの存在確認:\n")
    for (var in head(complete_missing, 10)) {
      found_in <- c()
      for (dataset_name in names(data_all)) {
        if (var %in% names(data_all[[dataset_name]])) {
          found_in <- c(found_in, dataset_name)
        }
      }
      if (length(found_in) > 0) {
        cat(sprintf("    %s: %s に存在\n", var, paste(found_in, collapse = ", ")))
      } else {
        cat(sprintf("    %s: どのデータセットにも存在しない\n", var))
      }
    }
  }
  
  cat(sprintf("\n【欠損率50-99%%】: %d 変数\n", length(high_missing)))
  if (length(high_missing) > 0) {
    high_summary <- data.frame(
      variable = high_missing,
      na_rate = round(na_rates[high_missing], 1)
    ) %>% arrange(desc(na_rate))
    print(head(high_summary, 10))
  }
  
  cat(sprintf("\n【欠損率10-49%%】: %d 変数\n", length(moderate_missing)))
  cat(sprintf("【欠損率1-9%%】: %d 変数\n", length(low_missing)))
  
  cat("\n", strrep("=", 80), "\n\n")
  
  return(list(
    complete_missing = complete_missing,
    high_missing = high_missing,
    moderate_missing = moderate_missing,
    low_missing = low_missing
  ))
}
# -----------関数ここまで-------------------------------------------------
