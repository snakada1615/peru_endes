# ===============================================================================
# Safe Join Functions - Clean Version v3
# 診断機能付き安全な結合関数（優先キー対応版）
# ===============================================================================
# 更新履歴:
#   v1: 初期版（left_join_safe のみ）
#   v2: inner_join_safe を追加
#   v3: by引数の正規化ロジックを共通化（.prepare_safe_join）
#       by = c("CASEID", "BIDX" = "HIDX") 形式（部分的名前付き）を安全に処理
#       left_join_safe / inner_join_safe の重複コードを共通下請け関数に集約

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
#' ファクター型を文字型に変換し、文字型の場合は空白を正規化します。
#' 数値型の場合はそのまま保持します。
#' @examples
#' df_normalized <- normalize_keys(df, key_vars = c("id", "year"))
#' @export
normalize_keys <- function(df, key_vars) {
  for (key in key_vars) {
    if (key %in% names(df)) {
      if (is.factor(df[[key]])) {
        df[[key]] <- as.character(df[[key]])
      }
      if (is.character(df[[key]])) {
        df[[key]] <- stringr::str_squish(df[[key]])
      }
      # 数値型はそのまま（必要に応じて処理追加）
    }
  }
  return(df)
}

# ===============================================================================
# 2. 結合前の診断を行う関数
# ===============================================================================

#' 結合前の診断を行う関数（名前付きベクトル対応版）
#'
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by_df1 左側データフレームの結合キーのベクトル
#' @param by_df2 右側データフレームの結合キーのベクトル
#' @param join_name 結合の名称（診断ログに表示）
#' @return 診断結果のリスト（match_rate, unmatched_left, unmatched_right）
#' @export
diagnose_join <- function(df1, df2, by_df1, by_df2, join_name = "") {
  if (join_name == "") {
    join_name <- paste0(deparse(substitute(df1)), " ⟵ ", deparse(substitute(df2)))
  }
  
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("結合診断:", join_name, "\n")
  cat(strrep("=", 80), "\n")
  
  missing_keys_df1 <- setdiff(by_df1, names(df1))
  missing_keys_df2 <- setdiff(by_df2, names(df2))
  
  if (length(missing_keys_df1) > 0) {
    warning("左側データフレームに以下のキーが存在しません: ",
            paste(missing_keys_df1, collapse = ", "))
  }
  if (length(missing_keys_df2) > 0) {
    warning("右側データフレームに以下のキーが存在しません: ",
            paste(missing_keys_df2, collapse = ", "))
  }
  
  common_pairs <- intersect(by_df1, by_df2)
  if (length(common_pairs) == 0 && length(by_df1) != length(by_df2)) {
    warning("名前付きベクトルで指定された結合キーの数が一致しません")
  }
  
  # データ型の確認
  cat("\n【キー変数のデータ型】\n")
  for (i in seq_along(by_df1)) {
    key1 <- by_df1[i]
    key2 <- by_df2[i]
    if (key1 %in% names(df1) && key2 %in% names(df2)) {
      type1 <- class(df1[[key1]])[1]
      type2 <- class(df2[[key2]])[1]
      match_symbol <- if (type1 == type2) "✓" else "✗"
      cat(sprintf(" %s (左) ⟷ %s (右): %s vs %s %s\n",
                  key1, key2, type1, type2, match_symbol))
    }
  }
  
  # ユニーク数
  cat("\n【キーの分布】\n")
  cat(sprintf(" 左側データ行数: %d\n", nrow(df1)))
  cat(sprintf(" 右側データ行数: %d\n", nrow(df2)))
  
  valid_by_df1 <- by_df1[by_df1 %in% names(df1)]
  valid_by_df2 <- by_df2[by_df2 %in% names(df2)]
  
  df1_keys <- df1 %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(valid_by_df1)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  df2_keys <- df2 %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(valid_by_df2)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  for (i in seq_along(by_df1)) {
    key1 <- by_df1[i]
    key2 <- by_df2[i]
    n_unique_df1 <- if (key1 %in% names(df1_keys)) {
      df1_keys %>% dplyr::distinct(.data[[key1]]) %>% nrow()
    } else { NA }
    n_unique_df2 <- if (key2 %in% names(df2_keys)) {
      df2_keys %>% dplyr::distinct(.data[[key2]]) %>% nrow()
    } else { NA }
    cat(sprintf(" %s (左) ⟷ %s (右) のユニーク数: 左=%s, 右=%s\n",
                key1, key2,
                ifelse(is.na(n_unique_df1), "NA", n_unique_df1),
                ifelse(is.na(n_unique_df2), "NA", n_unique_df2)))
  }
  
  # マッチング診断
  cat("\n【マッチング診断】:", join_name, "\n")
  
  # 左側キーを右側キー名に一時リネームして anti_join / semi_join を行う
  df1_temp <- df1 %>% dplyr::ungroup()
  df2_temp <- df2 %>% dplyr::ungroup()
  
  if (!identical(by_df1, by_df2)) {
    for (i in seq_along(by_df1)) {
      if (by_df1[i] != by_df2[i] && by_df1[i] %in% names(df1_temp)) {
        temp_name <- paste0("__temp_join_key_", i, "__")
        df1_temp <- df1_temp %>% dplyr::rename(!!temp_name := !!by_df1[i])
      }
    }
    for (i in seq_along(by_df1)) {
      temp_name <- paste0("__temp_join_key_", i, "__")
      if (temp_name %in% names(df1_temp)) {
        df1_temp <- df1_temp %>% dplyr::rename(!!by_df2[i] := !!temp_name)
      }
    }
  }
  
  unmatched_left  <- df1_temp %>% dplyr::anti_join(df2_temp, by = by_df2)
  unmatched_right <- df2_temp %>% dplyr::anti_join(df1_temp, by = by_df2)
  matched_rows    <- df1_temp %>% dplyr::semi_join(df2_temp, by = by_df2) %>% nrow()
  match_rate      <- 100 * matched_rows / nrow(df1)
  
  cat(sprintf(" マッチング率: %.1f%%\n", match_rate))
  cat(sprintf(" マッチした行数: %d / %d\n", matched_rows, nrow(df1)))
  cat(sprintf(" マッチしなかった行数（左側）: %d\n", nrow(unmatched_left)))
  cat(sprintf(" マッチしなかった行数（右側）: %d\n", nrow(unmatched_right)))
  
  if (match_rate < 50) {
    warning("マッチング率が50%未満です。キー変数を確認してください。")
  }
  
  cat(strrep("=", 80), "\n\n")
  
  return(list(
    match_rate     = match_rate,
    unmatched_left  = unmatched_left,
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
#' @return 重複情報のリスト（has_duplicates, n_duplicates, duplicate_keys）
#' @export
diagnose_duplicates <- function(df, by_vars, df_name = "") {
  cat("\n【重複診断:", df_name, "】\n")
  
  key_combo <- df %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(by_vars)) %>%
    dplyr::filter(stats::complete.cases(.))
  
  n_total      <- nrow(key_combo)
  n_unique     <- key_combo %>% dplyr::distinct() %>% nrow()
  n_duplicates <- n_total - n_unique
  
  cat(sprintf(" 総行数: %d\n", n_total))
  cat(sprintf(" ユニークなキー組み合わせ(%s): %d\n",
              paste(by_vars, collapse = "*"), n_unique))
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
      n_duplicates   = n_duplicates,
      duplicate_keys = duplicate_keys
    ))
  } else {
    cat(" ✓ 重複なし\n")
    return(list(has_duplicates = FALSE))
  }
}

# ===============================================================================
# 4. 共通下請け関数（by解析・正規化・診断・重複処理・共通列チェック）
# ===============================================================================

#' 安全結合の共通準備を行う内部関数
#'
#' @description
#' left_join_safe / inner_join_safe から呼ばれる共通処理。
#' by引数の正規化（部分的名前付き対応）、キー存在チェック、
#' キー正規化、診断、右側重複処理、共通列チェックを行い、
#' 後続の結合処理に必要な情報をリストで返す。
#'
#' @return リスト（df1, df2, by_named, by_df1, by_df2,
#'   join_name, relationship, suffix）
.prepare_safe_join <- function(df1, df2, by,
                               join_name,
                               diagnose,
                               priority_key,
                               relationship,
                               check_nonkey_conflicts,
                               suffix,
                               join_type,
                               ...) {
  
  # ---- 1. by引数の解析と正規化 ----------------------------------------------
  if (missing(by) || is.null(by)) {
    common_cols <- intersect(names(df1), names(df2))
    if (length(common_cols) == 0) {
      stop("byがNULLですが、共通列名が存在しません。")
    }
    by_df1   <- common_cols
    by_df2   <- common_cols
    by_named <- stats::setNames(by_df2, by_df1)
    
  } else if (is.character(by) && is.null(names(by))) {
    by_df1   <- by
    by_df2   <- by
    by_named <- stats::setNames(by_df2, by_df1)
    
  } else if (is.character(by) && !is.null(names(by))) {
    by_df2 <- unname(by)
    by_df1 <- names(by)
    
    # 部分的に名前がない要素（空文字）は右側と同名とみなして補完
    # 例: c("CASEID", "BIDX" = "HIDX") → c("CASEID"="CASEID", "BIDX"="HIDX")
    empty_idx          <- is.na(by_df1) | by_df1 == ""
    by_df1[empty_idx]  <- by_df2[empty_idx]
    by_named           <- stats::setNames(by_df2, by_df1)
    
  } else {
    stop("by引数の形式が不正です。文字ベクトルまたは名前付き文字ベクトルを指定してください。")
  }
  
  # ---- 2. キーのバリデーション ----------------------------------------------
  if (length(by_df1) == 0 || length(by_df2) == 0) {
    stop("結合キーが0件です。byを確認してください。")
  }
  if (any(is.na(by_df1) | by_df1 == "")) {
    stop("左側結合キーに空文字またはNAがあります。byを確認してください。")
  }
  if (any(is.na(by_df2) | by_df2 == "")) {
    stop("右側結合キーに空文字またはNAがあります。byを確認してください。")
  }
  
  missing_df1 <- setdiff(by_df1, names(df1))
  missing_df2 <- setdiff(by_df2, names(df2))
  if (length(missing_df1) > 0) {
    stop("左側データフレームに以下のキーが存在しません: ",
         paste(missing_df1, collapse = ", "))
  }
  if (length(missing_df2) > 0) {
    stop("右側データフレームに以下のキーが存在しません: ",
         paste(missing_df2, collapse = ", "))
  }
  
  # ---- 3. キー変数の正規化 --------------------------------------------------
  df1_normalized <- normalize_keys(df1, by_df1)
  df2_normalized <- normalize_keys(df2, by_df2)
  
  # ---- 4. 診断（オプション） ------------------------------------------------
  if (diagnose) {
    diagnose_join(df1_normalized, df2_normalized, by_df1, by_df2, join_name)
    cat("\n")
    dup_label_left  <- paste0("左側データ: ", deparse(substitute(df1)))
    dup_label_right <- paste0("右側データ: ", deparse(substitute(df2)))
    diagnose_duplicates(df1_normalized, by_df1, dup_label_left)
    diagnose_duplicates(df2_normalized, by_df2, dup_label_right)
  }
  
  # ---- 5. 右側重複処理 ------------------------------------------------------
  if (!is.null(priority_key) && !all(is.na(priority_key))) {
    missing_priority <- setdiff(priority_key, names(df2_normalized))
    if (length(missing_priority) > 0) {
      stop("右側データフレームにpriority_keyが存在しません: ",
           paste(missing_priority, collapse = ", "))
    }
    df2_prepared <- df2_normalized %>%
      dplyr::arrange(
        dplyr::across(dplyr::all_of(by_df2)),
        dplyr::desc(dplyr::across(dplyr::all_of(priority_key)))
      ) %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(by_df2))) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
    
  } else if (relationship %in% c("many-to-one", "one-to-one")) {
    df2_prepared <- df2_normalized %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(by_df2))) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
    
  } else {
    df2_prepared <- df2_normalized
  }
  
  if (diagnose && nrow(df2_prepared) < nrow(df2_normalized)) {
    cat(sprintf("\n【重複除去】右側データを %d 行 → %d 行に削減しました\n",
                nrow(df2_normalized), nrow(df2_prepared)))
  }
  
  # ---- 6. 非キー共通列チェック ----------------------------------------------
  if (check_nonkey_conflicts) {
    common_nonkey_cols <- intersect(
      setdiff(names(df1_normalized), by_df1),
      setdiff(names(df2_prepared),  by_df2)
    )
    
    if (length(common_nonkey_cols) > 0) {
      warning("結合キー以外の共通列名があります: ",
              paste(common_nonkey_cols, collapse = ", "))
      
      # 内部確認用にinner_joinで不一致を測る
      temp_join <- dplyr::inner_join(
        df1_normalized, df2_prepared,
        by = by_named, suffix = suffix,
        relationship = relationship, ...
      )
      
      for (col in common_nonkey_cols) {
        col_x <- paste0(col, suffix[1])
        col_y <- paste0(col, suffix[2])
        if (all(c(col_x, col_y) %in% names(temp_join))) {
          diffs <- sum(
            !is.na(temp_join[[col_x]]) &
              !is.na(temp_join[[col_y]]) &
              temp_join[[col_x]] != temp_join[[col_y]]
          )
          if (diffs > 0) {
            warning(sprintf("列 %s で %d 行の不一致があります", col, diffs))
          }
        }
      }
    }
  }
  
  return(list(
    df1          = df1_normalized,
    df2          = df2_prepared,
    by_named     = by_named,
    by_df1       = by_df1,
    by_df2       = by_df2,
    join_name    = join_name,
    relationship = relationship,
    suffix       = suffix
  ))
}

# ===============================================================================
# 5. サフィックス整理の共通ヘルパー
# ===============================================================================

.cleanup_suffix <- function(result, suffix, priotiry_col_left) {
  if (priotiry_col_left) {
    result %>%
      dplyr::select(-dplyr::ends_with(suffix[2])) %>%
      dplyr::rename_with(
        ~ stringr::str_remove(., stringr::fixed(suffix[1])),
        dplyr::ends_with(suffix[1])
      )
  } else {
    result %>%
      dplyr::select(-dplyr::ends_with(suffix[1])) %>%
      dplyr::rename_with(
        ~ stringr::str_remove(., stringr::fixed(suffix[2])),
        dplyr::ends_with(suffix[2])
      )
  }
}

# ===============================================================================
# 6. メイン関数: left_join_safe（診断機能付き、優先キー対応版）
# ===============================================================================

#' 安全な左結合を行う関数（診断機能付き、優先キー対応版）
#'
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by 結合キー（文字ベクトルまたは名前付き文字ベクトル）
#'   例: c("id") または c("df1_id" = "df2_id")
#'   例: c("CASEID", "BIDX" = "HIDX")  ← 部分的名前付きも可
#' @param join_name 結合の名称（ログ表示用）
#' @param diagnose 診断を実行するか（デフォルト: FALSE）
#' @param priority_key 右側データフレームで重複がある場合の優先キー
#'   例: c("survey_date", "data_quality_score")
#' @param priotiry_col_left 重複列は左側を優先するか（デフォルト: TRUE）
#' @param relationship 結合関係の宣言（デフォルト: "many-to-one"）
#' @param check_nonkey_conflicts 非キー共通列の不一致をチェックするか
#' @return 結合されたデータフレーム（左側の全行を保持）
#'
#' @examples
#' # 基本
#' result <- left_join_safe(df1, df2, by = "household_id")
#'
#' # 診断付き・異なるキー名
#' result <- left_join_safe(df1, df2,
#'   by = c("household_id" = "hh_id"),
#'   join_name = "Household Join", diagnose = TRUE)
#'
#' # 複合キー（部分的名前付きも可）
#' result <- left_join_safe(df1, df2,
#'   by = c("CASEID", "BIDX" = "HIDX"), diagnose = TRUE)
#'
#' # 複数時点データ（最新優先）
#' result <- left_join_safe(df1, df2,
#'   by = c("household_id" = "hh_id"),
#'   priority_key = c("survey_date", "data_quality_score"), diagnose = TRUE)
#' @export
left_join_safe <- function(df1, df2, by, join_name = "", diagnose = FALSE,
                           priority_key = NULL, priotiry_col_left = TRUE,
                           relationship = "many-to-one",
                           check_nonkey_conflicts = TRUE,
                           ...) {
  
  if (join_name == "") {
    join_name <- paste0(deparse(substitute(df1)), " ⟵ ", deparse(substitute(df2)))
  }
  
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("left_join_safe:", join_name, ": 結合を開始します\n")
  cat(strrep("=", 80), "\n")
  
  prep <- .prepare_safe_join(
    df1 = df1, df2 = df2, by = by,
    join_name = join_name, diagnose = diagnose,
    priority_key = priority_key, relationship = relationship,
    check_nonkey_conflicts = check_nonkey_conflicts,
    suffix = c(".x", ".y"), join_type = "left", ...
  )
  
  result <- dplyr::left_join(
    prep$df1, prep$df2,
    by = prep$by_named,
    suffix = prep$suffix,
    relationship = prep$relationship,
    ...
  )
  
  result <- .cleanup_suffix(result, prep$suffix, priotiry_col_left)
  
  if (nrow(result) == 0) {
    stop(sprintf("結合結果が0行です: %s", prep$join_name))
  }
  if (nrow(result) != nrow(df1)) {
    warning(sprintf("結合後の行数が変化しました: %s (元: %d, 結果: %d)",
                    prep$join_name, nrow(df1), nrow(result)))
  }
  
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("left_join_safe:", prep$join_name, ": 結合を完了しました\n")
  cat(strrep("=", 80), "\n")
  
  return(result)
}

# ===============================================================================
# 7. メイン関数: inner_join_safe（診断機能付き、優先キー対応版）
# ===============================================================================

#' 安全なinner_joinを行う関数（診断機能付き、優先キー対応版）
#'
#' @param df1 左側のデータフレーム
#' @param df2 右側のデータフレーム
#' @param by 結合キー（文字ベクトルまたは名前付き文字ベクトル）
#'   例: c("id") または c("df1_id" = "df2_id")
#'   例: c("CASEID", "BIDX" = "HIDX")  ← 部分的名前付きも可
#' @param join_name 結合の名称（ログ表示用）
#' @param diagnose 診断を実行するか（デフォルト: FALSE）
#' @param priority_key 右側データフレームで重複がある場合の優先キー
#' @param priotiry_col_left 重複列は左側を優先するか（デフォルト: TRUE）
#' @param relationship 結合関係の宣言（デフォルト: "many-to-one"）
#' @param check_nonkey_conflicts 非キー共通列の不一致をチェックするか
#' @param warn_if_dropped マッチしなかった行への警告を出すか（デフォルト: TRUE）
#' @return 結合されたデータフレーム（両側でマッチした行のみ保持）
#'
#' @examples
#' # 基本
#' result <- inner_join_safe(df1, df2, by = "CASEID")
#'
#' # 複合キー（部分的名前付きも可）
#' result <- inner_join_safe(df1, df2,
#'   by = c("CASEID", "BIDX" = "HIDX"), diagnose = TRUE)
#'
#' # 完全名前付き（推奨）
#' result <- inner_join_safe(df1, df2,
#'   by = c("CASEID" = "CASEID", "BIDX" = "HIDX"), diagnose = TRUE)
#' @export
inner_join_safe <- function(df1, df2, by, join_name = "", diagnose = FALSE,
                            priority_key = NULL, priotiry_col_left = TRUE,
                            relationship = "many-to-one",
                            check_nonkey_conflicts = TRUE,
                            warn_if_dropped = TRUE,
                            ...) {
  
  if (join_name == "") {
    join_name <- paste0(deparse(substitute(df1)), " ⋈ ", deparse(substitute(df2)))
  }
  
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("inner_join_safe:", join_name, ": 結合を開始します\n")
  cat(strrep("=", 80), "\n")
  
  prep <- .prepare_safe_join(
    df1 = df1, df2 = df2, by = by,
    join_name = join_name, diagnose = diagnose,
    priority_key = priority_key, relationship = relationship,
    check_nonkey_conflicts = check_nonkey_conflicts,
    suffix = c(".x", ".y"), join_type = "inner", ...
  )
  
  result <- dplyr::inner_join(
    prep$df1, prep$df2,
    by = prep$by_named,
    suffix = prep$suffix,
    relationship = prep$relationship,
    ...
  )
  
  result <- .cleanup_suffix(result, prep$suffix, priotiry_col_left)
  
  if (nrow(result) == 0) {
    stop(sprintf("結合結果が0行です: %s", prep$join_name))
  }
  
  # 左右の脱落行数を計算
  # by_named: 左キー名 → 右キー名  なので
  #   left  側の semi_join は by = by_named（左から右を探す）
  #   right 側の semi_join は by = setNames(by_df1, by_df2)（右から左を探す）
  matched_left_n <- prep$df1 %>%
    dplyr::semi_join(prep$df2, by = prep$by_named) %>%
    nrow()
  
  matched_right_n <- prep$df2 %>%
    dplyr::semi_join(prep$df1, by = stats::setNames(prep$by_df1, prep$by_df2)) %>%
    nrow()
  
  unmatched_left_n  <- nrow(prep$df1) - matched_left_n
  unmatched_right_n <- nrow(prep$df2) - matched_right_n
  
  cat("\n【inner join 結果チェック】\n")
  cat(sprintf(" 左側入力行数: %d\n", nrow(prep$df1)))
  cat(sprintf(" 右側入力行数: %d\n", nrow(prep$df2)))
  cat(sprintf(" 結合後行数:   %d\n", nrow(result)))
  cat(sprintf(" 左側で脱落した行数: %d\n", unmatched_left_n))
  cat(sprintf(" 右側で脱落した行数: %d\n", unmatched_right_n))
  
  if (warn_if_dropped && unmatched_left_n > 0) {
    warning(sprintf("inner_joinにより左側で %d 行が脱落しました: %s",
                    unmatched_left_n, prep$join_name))
  }
  if (warn_if_dropped && unmatched_right_n > 0) {
    warning(sprintf("inner_joinにより右側で %d 行が脱落しました: %s",
                    unmatched_right_n, prep$join_name))
  }
  
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("inner_join_safe:", prep$join_name, ": 結合を完了しました\n")
  cat(strrep("=", 80), "\n")
  
  return(result)
}

# ===============================================================================
# 使用例：ペルーの栄養改善プログラム評価での使用シナリオ
# ===============================================================================

# -- left_join_safe の例 -------------------------------------------------------

# 例1：基本的な世帯属性情報の結合
# result1 <- left_join_safe(
#   df_baseline, df_hh_attributes,
#   by = "household_id",
#   join_name = "Household Attributes",
#   diagnose = TRUE
# )

# 例2：複数時点の栄養指標（最新情報を優先）
# result2 <- left_join_safe(
#   df_baseline, df_nutrition_outcomes,
#   by = c("household_id" = "hh_id"),
#   join_name = "Latest Nutrition Outcomes",
#   diagnose = TRUE,
#   priority_key = c("survey_date", "data_quality_score")
# )

# 例3：農業生産データ（最も最近の調査を選択）
# result3 <- left_join_safe(
#   df_baseline, df_agricultural_production,
#   by = c("household_id" = "hhid"),
#   join_name = "Agricultural Production Data",
#   diagnose = TRUE,
#   priority_key = "last_updated"
# )

# -- inner_join_safe の例 ------------------------------------------------------

# 例4：単一キーの基本結合
# IRdata <- df_REC21 %>%
#   filter(BIDX == 1) %>%
#   inner_join_safe(df_rec0111, by = "CASEID") %>%
#   inner_join_safe(df_RE223132, by = "CASEID")

# 例5：複合キー（部分的名前付き）
# IRdata <- IRdata %>%
#   inner_join_safe(df_REC43,
#     by = c("CASEID", "BIDX" = "HIDX"),  # 部分的名前付きも可
#     join_name = "REC21 ⋈ REC43", diagnose = TRUE)

# 例6：複合キー（完全名前付き推奨）
# IRdata <- IRdata %>%
#   inner_join_safe(df_REC43,
#     by = c("CASEID" = "CASEID", "BIDX" = "HIDX"),
#     join_name = "REC21 ⋈ REC43", diagnose = TRUE) %>%
#   inner_join_safe(df_REC41,
#     by = c("CASEID" = "CASEID", "BIDX" = "MIDX"),
#     join_name = "REC21 ⋈ REC41", diagnose = TRUE) %>%
#   inner_join_safe(df_REC42, by = "CASEID") %>%
#   mutate(midx = BIDX) %>%
#   dplyr::select(keep_IRdata)

