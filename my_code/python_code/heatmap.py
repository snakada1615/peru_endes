import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# データを長形式に変換
panel_long = panel_data.melt(id_vars=['state', 'year'], 
                              var_name='variable', 
                              value_name='value')

# 変数ごとに年対年の変化率を計算
panel_long = panel_long.sort_values(['state', 'variable', 'year'])
panel_long['pct_change'] = panel_long.groupby(['state', 'variable'])['value'].pct_change() * 100
panel_change = panel_long.dropna(subset=['pct_change'])

# スパイクがある年に絞ってヒートマップ作成
# 例：2015年にスパイクがあった場合
spike_year = 2015

heatmap_data = panel_change[panel_change['year'] == spike_year][['state', 'variable', 'pct_change']]

# 対象州と非対象州で色分け
treatment_states = ["state1", "state2", "state3"]  # 対象州のリスト

# ヒートマップの作成
pivot_heatmap = heatmap_data.pivot(index='state', columns='variable', values='pct_change')

plt.figure(figsize=(12, 6))
sns.heatmap(pivot_heatmap, cmap='RdBu_r', center=0, vmin=-100, vmax=100, 
            cbar_kws={'label': '% Change'})
plt.title(f'Year-on-Year Change in {spike_year}')
plt.xlabel('Variables')
plt.ylabel('State')
plt.xticks(rotation=90, fontsize=6)
plt.tight_layout()
plt.show()
