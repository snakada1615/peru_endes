
cooking_fuel <- REC0111 %>%
  rename_with(~tolower(.x)) %>%
  mutate(dm_cooking_fuel = v161) %>% # 最初の調理燃料を取得
  mutate(dm_cooking_fuel_traditional = 
           ifelse(dm_cooking_fuel < 7, 0, 1)) %>% # 伝統的な調理燃料かどうか  
  mutate(dm_cooking_fuel_traditional = ifelse(
    is.na(dm_cooking_fuel_traditional), 0, dm_cooking_fuel_traditional)
  )  %>% # NAを0に置き換え
  select(caseid, dm_cooking_fuel, dm_cooking_fuel_traditional)
print("調理燃料の分布を確認")
table(cooking_fuel$dm_cooking_fuel)
table(cooking_fuel$dm_cooking_fuel_traditional)
