# ===============================================================================
# Safe Join Functions - Clean Version
# 診断機能付き安全な左結合関数（優先キー対応版）
# ===============================================================================
# このファイルは以下の冗長な定義を整理し、第2版実装を核に据えた
# クリーンなバージョンです

# 必要なライブラリ
library(dplyr)
library(stringr)

# ===============================================================================
# 1. キー変数を正規化する関数
# ===============================================================================

#' キー変数を正規化する関数
#'
#' @param df データフレーム
#' @param key_vars 正規化するキー変数のベクトル
#' @return 正規化されたデータフレーム
#' @description
#' この関数は、指定されたデータフレームのキー変数に対して、
#' ファクター型を文字型に変換し、文字型の場合は空白を正規化します。
#' 数値型の場合はそのまま保持します。
#'
#' @examples
#' df_normalized <- normalize_keys(df, key_vars = c("id", "year"))
#'
#' @export
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

# ===============================================================================
# 2. 結合前の診断を行う関数
# ===============================================================================

#' 結合前の診断を行う関数
#'
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by_vars 結合キーのベクトル
#' @param join_name 結合の名称（ログ用）
#' @return 診断結果のリスト
#'   - common_keys: 共通のキー変数
#'   - match_rate: マッチング率(%)
#'   - unmatched_left: 左側でマッチしなかった行
#'   - unmatched_right: 右側でマッチしなかった行
#'
#' @description
#' この関数は、2つのデータフレームを結合する前に、
#' 以下の診断を行います：
#' - キー変数の存在確認
#' - データ型の一致確認
#' - ユニークキー数の確認
#' - マッチング率の計算
#'
#' @examples
#' diagnose_result <- diagnose_join(df1, df2, 
#'                                  by_vars = c("id", "year"),
#'                                  join_name = "Example Join")
#'
#' @export
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
    cat(sprintf(" %s: %s (左側) vs %s (右側) %s\n",
                key, type1, type2, match_symbol))
  }

  # ユニークキーの数とマッチング率
  cat("\n【キーの分布】\n")
  cat(sprintf(" 左側データ行数: %d\n", nrow(df1)))
  cat(sprintf(" 右側データ行数: %d\n", nrow(df2)))

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
    cat(sprintf(" %s のユニーク数: 左=%d, 右=%d\n", key, n_unique_df1, n_unique_df2))
  }

  # マッチング診断用の anti_join / semi_join
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
  cat(sprintf(" マッチング率: %.1f%%\n", match_rate))

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

# ===============================================================================
# 3. 結合キーの重複を診断する関数
# ===============================================================================

#' 結合キーの重複を診断する関数
#'
#' @param df データフレーム
#' @param by_vars 結合キーのベクトル
#' @param df_name データフレーム名（ログ用）
#' @return 重複情報のリスト
#'   - has_duplicates: 重複があるか（TRUE/FALSE）
#'   - n_duplicates: 重複行数（has_duplicates=TRUEの場合）
#'   - duplicate_keys: 重複しているキーパターン（has_duplicates=TRUEの場合）
#'
#' @description
#' この関数は、指定されたデータフレームにおいて、
#' 結合キーの重複を診断します。重複行数、
#' ユニークキー数、重複しているキーの例を表示します。
#'
#' @examples
#' dup_result <- diagnose_duplicates(df, 
#'                                   by_vars = c("id", "year"),
#'                                   df_name = "Example Data")
#'
#' @export
diagnose_duplicates <- function(df, by_vars, df_name = "") {
  cat("\n【重複診断:", df_name, "】\n")

  # ▼ ここで必ず ungroup() してから処理 ▼
  key_combo <- df %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(by_vars)) %>%
    dplyr::filter(stats::complete.cases(.))

  n_total <- nrow(key_combo)
  n_unique <- key_combo %>% dplyr::distinct() %>% nrow()
  n_duplicates <- n_total - n_unique

  cat(sprintf(" 総行数: %d\n", n_total))
  cat(sprintf(" ユニークなキー組み合わせ: %d\n", n_unique))
  cat(sprintf(" 重複行数: %d\n", n_duplicates))

  if (n_duplicates > 0) {
    duplicate_keys <- key_combo %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(by_vars))) %>%
      dplyr::filter(dplyr::n() > 1) %>%
      dplyr::ungroup() %>%
      dplyr::distinct()

    cat(sprintf(" 重複しているキーパターン数: %d\n", nrow(duplicate_keys)))
    cat(" 重複例（最初の5件）:\n")
    print(head(duplicate_keys, 5))

    return(list(
      has_duplicates = TRUE,
      n_duplicates = n_duplicates,
      duplicate_keys = duplicate_keys
    ))
  } else {
    cat(" ✓ 重複なし\n")
    return(list(has_duplicates = FALSE))
  }
}

# ===============================================================================
# 4. メイン関数：安全な左結合を行う関数（診断機能付き、優先キー対応版）
# ===============================================================================

#' 改良版：安全な左結合を行う関数（診断機能付き、優先キー対応版）
#'
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by 結合キー（名前付きベクトルまたは文字ベクトル）
#'   - 例: c("id") または c("df1_id" = "df2_id")
#' @param join_name 結合の名称（診断ログに表示）
#' @param diagnose 診断を実行するか（デフォルト: FALSE）
#' @param priority_key 右側データフレームで重複がある場合に
#'   優先的に保持するキー変数のベクトル
#'   - 例: c("date_updated", "version")
#'
#' @return 結合されたデータフレーム
#'
#' @description
#' この関数は、dplyrのleft_joinを拡張し、
#' 結合前にキー変数の正規化と診断を行います。
#' 
#' **主な特徴:**
#' 1. キー変数の正規化（ファクター→文字、空白統一）
#' 2. 結合前の詳細診断（存在確認、型確認、マッチング率）
#' 3. 右側データの重複診断
#' 4. priority_keyによる優先度付き重複除去
#' 5. サフィックス（.x, .y）の自動クリーンアップ
#' 6. 結合結果の整合性チェック
#'
#' **使用例:**
#' ```R
#' # 基本的な使用例
#' result <- left_join_safe(df1, df2, by = "id")
#'
#' # 診断付きで実行
#' result <- left_join_safe(df1, df2, 
#'                          by = c("id" = "household_id"),
#'                          join_name = "Household Data Join",
#'                          diagnose = TRUE)
#'
#' # 世帯データのように複数時点の観測がある場合
#' result <- left_join_safe(df1, df2,
#'                          by = c("household_id" = "hh_id"),
#'                          join_name = "Latest Household Data",
#'                          diagnose = TRUE,
#'                          priority_key = c("survey_date", "version"))
#' ```
#'
#' @export
left_join_safe <- function(df1, df2, by, join_name = "", diagnose = FALSE,
                           priority_key = NULL) {

  # ================================================================================
  # Step 1: by引数の解析と正規化
  # ================================================================================
  if (is.null(names(by))) {
    by_vars <- by
    by_df1 <- by
    by_df2 <- by
  } else {
    by_df1 <- names(by)
    by_df2 <- unname(by)
    by_vars <- unique(c(by_df1, by_df2))
  }

  # ================================================================================
  # Step 2: キー変数の正規化
  # ================================================================================
  df1_normalized <- normalize_keys(df1, by_df1)
  df2_normalized <- normalize_keys(df2, by_df2)

  # ================================================================================
  # Step 3: 診断の実行（オプション）
  # ================================================================================
  if (diagnose) {
    diag_result <- diagnose_join(df1_normalized, df2_normalized,
                                 by_vars, join_name)

    # 重複診断を追加
    cat("\n")
    dup_df1 <- diagnose_duplicates(df1_normalized, by_df1, "左側データ")
    dup_df2 <- diagnose_duplicates(df2_normalized, by_df2, "右側データ")
  }

  # ================================================================================
  # Step 4: 右側（df2）に重複がある場合の処理
  # ================================================================================
  # 世帯データのような複数時点観測の場合、priority_keyで優先順位を指定
  if (!is.null(priority_key) && !all(is.na(priority_key))) {
    # priority_keyが指定されている場合：優先度付き重複除去
    df2_unique <- df2_normalized %>%
      arrange(across(all_of(by_df2)),
              desc(across(all_of(priority_key)))) %>% # 降順で新しい/優先度の高い順
      group_by(across(all_of(by_df2))) %>%
      slice(1) %>%
      ungroup()
  } else {
    # 従来の処理（指定されていない場合）：最初の行のみ保持
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

  # ================================================================================
  # Step 5: 結合の実行
  # ================================================================================
  result <- dplyr::left_join(df1_normalized, df2_unique, by = by,
                             relationship = "many-to-one")

  # ================================================================================
  # Step 6: サフィックスをクリーンアップ
  # ================================================================================
  # 結合直後に .y サフィックスが付いた列を削除
  # .x サフィックスをクリーンアップ
  result <- result %>%
    dplyr::select(-ends_with(".y")) %>%
    rename_with(~str_remove(., "\\.x$"), ends_with(".x"))

  # ================================================================================
  # Step 7: 結果の整合性チェック
  # ================================================================================
  if (nrow(result) == 0) {
    stop(sprintf("結合結果が0行です: %s", join_name))
  }

  if (nrow(result) != nrow(df1)) {
    warning(sprintf("結合後の行数が変化しました: %s (元: %d, 結果: %d)",
                    join_name, nrow(df1), nrow(result)))
  }

  return(result)
}

# ===============================================================================
# 使用例：ペルーの栄養改善プログラム評価での使用シナリオ
# ===============================================================================

# 例1：基本的な世帯属性情報の結合
# result1 <- left_join_safe(
#   df_baseline,          # ベースラインデータ
#   df_hh_attributes,     # 世帯属性
#   by = "household_id",
#   join_name = "Household Attributes",
#   diagnose = TRUE
# )

# 例2：複数時点の栄養指標（最新情報を優先）
# result2 <- left_join_safe(
#   df_baseline,
#   df_nutrition_outcomes,  # 複数時点の栄養データ
#   by = c("household_id" = "hh_id"),
#   join_name = "Latest Nutrition Outcomes",
#   diagnose = TRUE,
#   priority_key = c("survey_date", "data_quality_score")
# )

# 例3：農業生産データ（最も最近の調査を選択）
# result3 <- left_join_safe(
#   df_baseline,
#   df_agricultural_production,
#   by = c("household_id" = "hhid"),
#   join_name = "Agricultural Production Data",
#   diagnose = TRUE,
#   priority_key = "last_updated"
# )