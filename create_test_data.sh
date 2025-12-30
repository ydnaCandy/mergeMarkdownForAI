#!/bin/bash

# テスト用ルートディレクトリ名
TEST_ROOT="test_project"
mkdir -p "$TEST_ROOT"

# 1. ルート直下のファイル
echo "# Root File 1
これはルート直下にあるファイルです。" > "$TEST_ROOT/root_file_1.md"

echo "# README.md
これは除外されるべきREADMEです。" > "$TEST_ROOT/README.md"

# 2. サブディレクトリ A (普通の階層)
mkdir -p "$TEST_ROOT/folder_A/sub"
echo "# A-1
フォルダAの1つ目です。" > "$TEST_ROOT/folder_A/a1.md"
echo "# A-2
深い階層にあるファイルです。" > "$TEST_ROOT/folder_A/sub/a2.md"

# 3. サブディレクトリ B (2万文字制限のテスト用)
mkdir -p "$TEST_ROOT/folder_B"
echo "# B-Long
ここには長いテキストを入れます。" > "$TEST_ROOT/folder_B/long.md"
# ざっくり3万文字分くらいのダミーテキストを追記
for i in {1..2000}; do
    echo "これは分割テスト用のダミーテキスト行目 $i です。 " >> "$TEST_ROOT/folder_B/long.md"
done

# 4. 除外用ディレクトリ
mkdir -p "$TEST_ROOT/.git"
echo "should be ignored" > "$TEST_ROOT/.git/config.md"

# 5. ignore-list.txt の作成
cat << EOF > ignore-list.txt
.git
README.md
EOF

echo "テストデータを作成しました：'/$TEST_ROOT'"
echo "実行例: ./merge_md.sh ./$TEST_ROOT"