# Let's create a diagnostic R script to help identify which variable is causing the issue
# diagnostic_script = '''
# Diagnostic script to identify problematic variables in set_all_value_labels function

# Function to check data types of all variables that will receive value labels
diagnose_value_label_issues <- function(data) {
  cat("=== Diagnostic Report for Value Label Assignment ===\\n\\n")
  
  # List of variables that will receive value labels
  value_label_vars <- c(
    "dm_cooking_fuel", "dm_cooking_fuel_traditional", "dm_rural", "dm_town", 
    "dm_city", "dm_capital", "dm_poorest", "dm_poorer", "dm_middle", 
    "dm_richer", "dm_richest", "dm_shared_toilet", "dm_cooking_house", 
    "dm_cooking_outdoor", "dm_cooking_separate", "dm_cattle_own", 
    "dm_goat_own", "dm_sheep_own", "dm_poultry_own", "dm_refrigerator", 
    "dm_female_headed", "dm_age_of_HH_head"
  )
  
  # Check each variable
  for (var in value_label_vars) {
    if (var %in% names(data)) {
      var_class <- class(data[[var]])
      var_type <- typeof(data[[var]])
      has_na <- any(is.na(data[[var]]))
      unique_vals <- length(unique(data[[var]], na.rm = TRUE))
      
      cat("Variable:", var, "\\n")
      cat("  - Class:", paste(var_class, collapse = ", "), "\\n")
      cat("  - Type:", var_type, "\\n")
      cat("  - Has NA:", has_na, "\\n")
      cat("  - Unique values:", unique_vals, "\\n")
      
# Check if its numeric or character (required by haven/labelled)
is_valid <- is.numeric(data[[var]]) || is.character(data[[var]])
cat("  - Valid for labelling:", is_valid, "\\n")

# Show sample values
sample_vals <- head(unique(data[[var]], na.rm = TRUE), 5)
cat("  - Sample values:", paste(sample_vals, collapse = ", "), "\\n")
cat("\\n")

if (!is_valid) {
  cat("*** PROBLEM FOUND: Variable", var, "is not numeric or character! ***\\n")
  cat("*** This variable cannot receive value labels ***\\n\\n")
}
} else {
  cat("Variable:", var, "- NOT FOUND in dataset\\n\\n")
}
}

cat("=== End of Diagnostic Report ===\\n")
}

# Modified function that skips problematic variables
set_all_value_labels_safe <- function(data) {
  cat("Attempting to set value labels...\\n")
  
  # Check which variables exist and are valid
  valid_vars <- c()
  
  vars_to_check <- list(
    dm_cooking_fuel = c("electricity" = 1, "lpg" = 2, "natural gas" = 3, "biogas" = 4, 
                        "kerosene" = 5, "coal, lignite" = 6, "charcoal" = 7, "wood" = 8, 
                        "straw / shrubs / grass" = 9, "agricultural crop" = 10, 
                        "animal dung" = 11, "no food cooked in hh" = 95, "other" = 96, 
                        "not dejure resident" = 97),
    dm_cooking_fuel_traditional = c("Yes" = 1, "No" = 0),
    dm_rural = c("Yes" = 1, "No" = 0),
    dm_town = c("Yes" = 1, "No" = 0),
    dm_city = c("Yes" = 1, "No" = 0),
    dm_capital = c("Yes" = 1, "No" = 0),
    dm_poorest = c("Yes" = 1, "No" = 0),
    dm_poorer = c("Yes" = 1, "No" = 0),
    dm_middle = c("Yes" = 1, "No" = 0),
    dm_richer = c("Yes" = 1, "No" = 0),
    dm_richest = c("Yes" = 1, "No" = 0),
    dm_shared_toilet = c("Yes (10 or more households)" = 1, "No (less than 10 households)" = 0),
    dm_cooking_house = c("Yes (cooking inside house)" = 1, "No (cooking outside or in separate building)" = 0),
    dm_cooking_outdoor = c("Yes (cooking outdoor)" = 1, "No (cooking inside house or in separate building)" = 0),
    dm_cooking_separate = c("Yes (cooking in separate building)" = 1, "No (cooking inside house or outdoor)" = 0),
    dm_cattle_own = c("Yes (owns cattle)" = 1, "No (does not own cattle)" = 0),
    dm_goat_own = c("Yes (owns goats)" = 1, "No (does not own goats)" = 0),
    dm_sheep_own = c("Yes (owns sheep)" = 1, "No (does not own sheep)" = 0),
    dm_poultry_own = c("Yes (owns poultry)" = 1, "No (does not own poultry)" = 0),
    dm_refrigerator = c("Yes" = 1, "No" = 0),
    dm_female_headed = c("Yes" = 1, "No" = 0),
    dm_age_of_HH_head = c("10s" = 1, "20s" = 2, "30s" = 3, "40s" = 4, 
                          "50s" = 5, "60s" = 6, "70s" = 7, "80+" = 8)
  )
  
  for (var_name in names(vars_to_check)) {
    if (var_name %in% names(data)) {
      is_valid <- is.numeric(data[[var_name]]) || is.character(data[[var_name]])
      if (is_valid) {
        cat("Setting labels for:", var_name, "\\n")
        tryCatch({
          data <- data %>% set_value_labels(!!var_name := vars_to_check[[var_name]])
        }, error = function(e) {
          cat("ERROR setting labels for", var_name, ":", e$message, "\\n")
        })
      } else {
        cat("SKIPPING", var_name, "- not numeric or character\\n")
      }
    } else {
      cat("SKIPPING", var_name, "- variable not found\\n")
    }
  }
  
  return(data)
}

# cat("Diagnostic functions created. Use these in R:\\n")
# cat("1. diagnose_value_label_issues(your_data)\\n")
# cat("2. your_data <- set_all_value_labels_safe(your_data)\\n")
# 
# 
# print("R Diagnostic Script:")
# print("=" * 50)
# print(diagnostic_script)