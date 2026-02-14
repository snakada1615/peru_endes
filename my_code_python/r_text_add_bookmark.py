from pypdf import PdfReader, PdfWriter

# PDFを読み込む
reader = PdfReader("R-basic-text.pdf")
writer = PdfWriter()

# 全ページをコピー
for page in reader.pages:
    writer.add_page(page)

# しおりを追加（階層構造）
# レベル1
parent1 = writer.add_outline_item("1. R for Empirical Economics Research 概要", 0)
writer.add_outline_item("1.1 OVERVIEW", 0, parent=parent1)
writer.add_outline_item("1.2 Google's R Style Guide", 2, parent=parent1)
writer.add_outline_item("1.3 RESEARCH WORKFLOW", 3, parent=parent1)
writer.add_outline_item("1.4 REPLICATION CRISIS", 4, parent=parent1)
writer.add_outline_item("1.5 P-HACKING / PUBLICATION BIAS", 5, parent=parent1)
writer.add_outline_item("1.6 FRAUD", 14, parent=parent1)
writer.add_outline_item("1.7 MISTAKES", 16, parent=parent1)
writer.add_outline_item("1.8 OPEN SCIENCE", 17, parent=parent1)

# レベル2
parent2 = writer.add_outline_item("2. R の基本構文と関数", 48)
writer.add_outline_item("2.1 SEQUENCES", 50, parent=parent2)
writer.add_outline_item("2.2 R FUNCTIONS", 56, parent=parent2)
writer.add_outline_item("2.3 BASIC STATISTICS", 60, parent=parent2)

# レベル3
parent3 = writer.add_outline_item("3. 日付・リスト・データフレーム", 88)
writer.add_outline_item("3.1 DATES AND TIMES", 88, parent=parent3)
writer.add_outline_item("3.2 LISTS", 103, parent=parent3)
writer.add_outline_item("3.3 DATA FRAMES", 114, parent=parent3)
writer.add_outline_item("3.4 LM (線形回帰)", 117, parent=parent3)
writer.add_outline_item("3.5 QUARTO", 123, parent=parent3)

# レベル4
parent4 = writer.add_outline_item("4. dplyr とデータ操作", 135)
writer.add_outline_item("4.1 INSTALLING FROM GITHUB", 135, parent=parent4)
writer.add_outline_item("4.2 TIDYVERSE", 139, parent=parent4)

# レベル5
parent5 = writer.add_outline_item("5. 結合と形の変換", 238)
writer.add_outline_item("5.1 JOINS", 238, parent=parent5)
writer.add_outline_item("5.2 BINDING", 257, parent=parent5)
writer.add_outline_item("5.3 PIVOT_LONGER / PIVOT_WIDER", 270, parent=parent5)

# 保存
with open("R-basic-text_with_bookmarks.pdf", "wb") as output_file:
    writer.write(output_file)

print("しおり付きPDFを作成しました！")
