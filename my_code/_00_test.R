# ================================================================================
# 対処法A: より厳格な重みトリミング
# ================================================================================

# 現在の問題: 極端な重み（24,101）が分析を歪める

# Step 1: 極端な重みを特定
cat("\n=== 重みの分位点 ===\n")
weight_quantiles_detailed <- quantile(
  df_pre_2group$iptw_weight, 
  c(0, 0.01, 0.05, 0.1, 0.9, 0.95, 0.99, 1),
  na.rm = TRUE
)
print(weight_quantiles_detailed)

# Step 2: より厳格なトリミング（90th or 95th percentile）
# オプション1: 95th percentileで打ち切り
weight_cap_95 <- quantile(df_pre_2group$iptw_weight, 0.95, na.rm = TRUE)
df_pre_2group$iptw_weight_trimmed95 <- pmin(df_pre_2group$iptw_weight, weight_cap_95)

cat("\nトリミング後（95th）:\n")
print(summary(df_pre_2group$iptw_weight_trimmed95))

# オプション2: 固定上限（例: 10）
df_pre_2group$iptw_weight_capped <- pmin(df_pre_2group$iptw_weight, 10)

cat("\nトリミング後（上限10）:\n")
print(summary(df_pre_2group$iptw_weight_capped))

# Step 3: サンプリングウェイトとの結合（トリミング版）
df_pre_2group$w_combined_trimmed95 <- 
  df_pre_2group$iptw_weight_trimmed95 * df_pre_2group$sampling_weight_norm

cat("\n最終重み（95th trimmed）:\n")
print(summary(df_pre_2group$w_combined_trimmed95))

# Step 4: バランス再確認（トリミング後）
# （後述のコードで実施）


# ================================================================================
# 対処法B: 数値変数の型修正 + バランス再確認
# ================================================================================

# 問題: dm_weath_index, dm_ag_land_ha などが factor型のまま
# → numeric型に修正して、より多くの変数でSMD計算を可能に

# ================================================================================
# Step 1: 数値変数の型確認と修正
# ================================================================================

cat("\n=== 現在の数値変数の型確認 ===\n")

for(var in covariate_names) {
  if(var %in% names(df_pre_2group)) {
    var_class <- class(df_pre_2group[[var]])[1]
    n_unique <- length(unique(df_pre_2group[[var]]))
    n_missing <- sum(is.na(df_pre_2group[[var]]))
    
    cat(sprintf("%-30s: %-10s (unique: %3d, NA: %d)\n", 
                var, var_class, n_unique, n_missing))
  }
}

# ================================================================================
# Step 2: 数値変数を明示的にnumeric型に変換
# ================================================================================

# 実数変数（連続変数）
numeric_vars <- c("dm_weath_index", "dm_ag_land_ha")

cat("\n=== 数値変数の型修正 ===\n")

for(var in numeric_vars) {
  if(var %in% names(df_pre_2group)) {
    original_class <- class(df_pre_2group[[var]])[1]
    
    cat(sprintf("%-20s: %s → ", var, original_class))
    
    # numeric型に変換
    tryCatch({
      if(original_class == "factor") {
        df_pre_2group[[var]] <- as.numeric(as.character(df_pre_2group[[var]]))
      } else if(original_class == "character") {
        df_pre_2group[[var]] <- as.numeric(df_pre_2group[[var]])
      } else if(original_class != "numeric") {
        df_pre_2group[[var]] <- as.numeric(df_pre_2group[[var]])
      }
      
      new_class <- class(df_pre_2group[[var]])[1]
      cat(sprintf("%s ✓\n", new_class))
      
    }, error = function(e) {
      cat(sprintf("エラー: %s\n", e$message))
    })
  }
}

# ================================================================================
# Step 3: 型修正後のデータ再確認
# ================================================================================

cat("\n=== 型修正後の数値変数確認 ===\n")

for(var in numeric_vars) {
  if(var %in% names(df_pre_2group)) {
    var_class <- class(df_pre_2group[[var]])[1]
    
    cat(sprintf("\n%s:\n", var))
    cat(sprintf("  型: %s\n", var_class))
    cat(sprintf("  統計量: Min=%.3f, Mean=%.3f, Max=%.3f\n",
                min(df_pre_2group[[var]], na.rm=TRUE),
                mean(df_pre_2group[[var]], na.rm=TRUE),
                max(df_pre_2group[[var]], na.rm=TRUE)))
  }
}

# ================================================================================
# Step 4: バランスチェック関数（型修正後用）
# ================================================================================

calculate_smd_robust <- function(data, group_var, vars) {
  results <- data.frame(
    variable = character(0),
    smd = numeric(0),
    mean_control = numeric(0),
    mean_treated = numeric(0),
    var_type = character(0),
    stringsAsFactors = FALSE
  )
  
  for(var in vars) {
    if(!var %in% names(data)) {
      next
    }
    
    tryCatch({
      control_data <- data[data[[group_var]] == 0, var]
      treated_data <- data[data[[group_var]] == 1, var]
      
      if(length(control_data) == 0 || length(treated_data) == 0) {
        next
      }
      
      var_class <- class(data[[var]])[1]
      
      # ============================================================
      # ケース1: 数値変数（numeric, integer）
      # ============================================================
      if(var_class %in% c("numeric", "integer")) {
        mean_c <- mean(control_data, na.rm = TRUE)
        mean_t <- mean(treated_data, na.rm = TRUE)
        var_c <- var(control_data, na.rm = TRUE)
        var_t <- var(treated_data, na.rm = TRUE)
        
        if(is.na(mean_c) || is.na(mean_t) || is.na(var_c) || is.na(var_t)) {
          next
        }
        
        if(var_c + var_t > 0) {
          smd <- abs((mean_t - mean_c) / sqrt((var_t + var_c) / 2))
        } else {
          smd <- abs(mean_t - mean_c)
        }
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd,
          mean_control = mean_c, mean_treated = mean_t,
          var_type = "numeric", stringsAsFactors = FALSE
        ))
        
        # ============================================================
        # ケース2: バイナリ変数（factor with 2 levels）
        # ============================================================
      } else if(var_class == "factor" && nlevels(data[[var]]) == 2) {
        levels_var <- levels(data[[var]])
        positive_level <- levels_var[2]
        
        prop_c <- mean(control_data == positive_level, na.rm = TRUE)
        prop_t <- mean(treated_data == positive_level, na.rm = TRUE)
        
        pooled_var <- prop_c * (1 - prop_c) + prop_t * (1 - prop_t)
        if(pooled_var > 0) {
          smd <- abs((prop_t - prop_c) / sqrt(pooled_var / 2))
        } else {
          smd <- abs(prop_t - prop_c)
        }
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd,
          mean_control = prop_c, mean_treated = prop_t,
          var_type = "binary", stringsAsFactors = FALSE
        ))
        
        # ============================================================
        # ケース3: カテゴリ変数（factor with 3+ levels）
        # ============================================================
      } else if(var_class == "factor" && nlevels(data[[var]]) > 2) {
        levels_var <- levels(data[[var]])
        smd_max <- 0
        
        for(level in levels_var) {
          prop_c <- mean(control_data == level, na.rm = TRUE)
          prop_t <- mean(treated_data == level, na.rm = TRUE)
          
          pooled_var <- prop_c * (1 - prop_c) + prop_t * (1 - prop_t)
          if(pooled_var > 0) {
            smd_level <- abs((prop_t - prop_c) / sqrt(pooled_var / 2))
          } else {
            smd_level <- abs(prop_t - prop_c)
          }
          
          smd_max <- max(smd_max, smd_level)
        }
        
        mean_c <- mean(as.numeric(as.factor(control_data)), na.rm = TRUE)
        mean_t <- mean(as.numeric(as.factor(treated_data)), na.rm = TRUE)
        
        results <- rbind(results, data.frame(
          variable = var, smd = smd_max,
          mean_control = mean_c, mean_treated = mean_t,
          var_type = "categorical", stringsAsFactors = FALSE
        ))
      }
      
    }, error = function(e) {})
  }
  
  return(results)
}

# ================================================================================
# Step 5: 型修正後のバランスチェック実行
# ================================================================================

df_pre_balance_typefix <- df_pre_2group[!is.na(df_pre_2group$iptw_weight_trimmed95), ]

cat("\n=== バランスチェック実行（型修正後） ===\n")

balance_after_typefix <- calculate_smd_robust(
  df_pre_balance_typefix,
  "treatment_group",
  covariate_names
)

cat("\n=== バランスチェック結果（型修正後） ===\n")

if(nrow(balance_after_typefix) > 0) {
  cat("計算成功した変数数:", nrow(balance_after_typefix), "/", length(covariate_names), "\n")
  cat("Mean SMD:", round(mean(balance_after_typefix$smd, na.rm=TRUE), 4), "\n")
  cat("Median SMD:", round(median(balance_after_typefix$smd, na.rm=TRUE), 4), "\n")
  cat("Max SMD:", round(max(balance_after_typefix$smd, na.rm=TRUE), 4), "\n")
  cat("SMD < 0.1:", sum(balance_after_typefix$smd < 0.1, na.rm=TRUE), "/", 
      nrow(balance_after_typefix),
      sprintf("(%.1f%%)", 100*sum(balance_after_typefix$smd < 0.1, na.rm=TRUE)/nrow(balance_after_typefix)), "\n")
  cat("SMD < 0.05:", sum(balance_after_typefix$smd < 0.05, na.rm=TRUE), "/", 
      nrow(balance_after_typefix),
      sprintf("(%.1f%%)", 100*sum(balance_after_typefix$smd < 0.05, na.rm=TRUE)/nrow(balance_after_typefix)), "\n")
  
  # 変数型別の内訳
  cat("\n変数型別の内訳:\n")
  print(table(balance_after_typefix$var_type))
  
  # 改善内容
  cat("\n===  改善サマリー ===\n")
  cat("追加で計算された変数:\n")
  if(exists("balance_before_2group")) {
    added_vars <- setdiff(balance_after_typefix$variable, balance_before_2group$variable)
    for(var in added_vars) {
      smd_val <- balance_after_typefix[balance_after_typefix$variable == var, "smd"]
      cat(sprintf("  - %s: SMD=%.4f\n", var, smd_val))
    }
  }
  
  # バランス結果の表示
  cat("\nTop 10 worst balanced variables (型修正後):\n")
  balance_sorted <- balance_after_typefix[order(-balance_after_typefix$smd), ]
  print(head(balance_sorted[, c("variable", "smd", "mean_control", "mean_treated", "var_type")], 10))
  
  # Best balanced variables
  cat("\nTop 10 best balanced variables (型修正後):\n")
  print(head(balance_sorted[order(balance_sorted$smd), ][, c("variable", "smd", "var_type")], 10))
  
} else {
  cat("エラー: SMD計算が成功した変数が0個です\n")
}

# ================================================================================
# Step 6: 結果の保存（型修正版）
# ================================================================================

saveRDS(balance_after_typefix, file.path(gdrive_dir, "output", "balance_typefix_2group.rds"))

cat("\n=== 型修正後のバランス結果を保存 ===\n")
cat("- ファイル: balance_typefix_2group.rds\n")

# 最終的な重み付きデータを更新
df_pre_2group$w_final <- df_pre_2group$w_combined_trimmed95

cat("\n=== 最終的な重み統計 ===\n")
cat("w_final（95th trimming適用版）:\n")
print(summary(df_pre_2group$w_final))

# ================================================================================
# Step 7: 総括
# ================================================================================

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("対処法A+B 実施後のサマリー\n")
cat(paste(rep("=", 70), collapse = ""), "\n")

cat("\n【重みの改善】\n")
cat("  元の重み:\n")
cat("    - 最大値: 24,101.48\n")
cat("    - 平均: 3.403\n")
cat("  修正後（95th trimming）:\n")
cat("    - 最大値:", round(max(df_pre_2group$w_final, na.rm=TRUE), 2), "\n")
cat("    - 平均:", round(mean(df_pre_2group$w_final, na.rm=TRUE), 3), "\n")

cat("\n【バランスの改善】\n")
if(nrow(balance_after_typefix) > 0) {
  cat("  計算成功:", nrow(balance_after_typefix), "/25 変数\n")
  cat("  平均SMD:", round(mean(balance_after_typefix$smd, na.rm=TRUE), 4), "\n")
  cat("  SMD<0.1:", sum(balance_after_typefix$smd < 0.1, na.rm=TRUE), "/", 
      nrow(balance_after_typefix), "\n")
}

cat("\n【次のステップ】\n")
cat("  ✓ 重み付きデータ: df_pre_2group (w_final列)\n")
cat("  ✓ バランス結果: balance_after_typefix\n")
cat("  → 介入後データへの適用に進む準備完了\n")

cat(paste(rep("=", 70), collapse = ""), "\n")