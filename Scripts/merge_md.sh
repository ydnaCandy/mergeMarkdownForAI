#!/bin/bash

# --- 1. 設定 ---
TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR%/}" # 末尾スラッシュ削除
OUTPUT_DIR="ai_docs"
IGNORE_FILE="ignore-list.txt"
MAX_CHARS=20000

mkdir -p "$OUTPUT_DIR"

# --- 2. 除外リストの準備 ---
# ignore-list.txtからgrep用のパターンを作成 (例: .git|README.md)
if [[ -s "$IGNORE_FILE" ]]; then
    IGNORE_PATTERN=$(grep -v '^#' "$IGNORE_FILE" | grep -v '^$' | paste -sd "|" -)
else
    IGNORE_PATTERN="^$" # 何もマッチさせない
fi

# --- 3. マージ処理関数 ---
# $1: 出力名ベース, $2以降: 処理対象ファイル群
merge_files() {
    local base_name="$1"
    shift
    local files=("$@")

    local current_chars=0
    local file_idx=1
    local out_file="$OUTPUT_DIR/${base_name}_${file_idx}.md"

    # 既存の分割ファイルを掃除
    rm -f "$OUTPUT_DIR/${base_name}"_*.md

    for f in "${files[@]}"; do
        # 除外チェック
        if [[ -n "$IGNORE_PATTERN" ]] && echo "$f" | grep -Eq "$IGNORE_PATTERN"; then
            continue
        fi

        # ファイル読み込みとフッター付与
        local content=$(cat "$f")
        local footer="\n\n## マージ元のファイルパス\n$f\n---\n"
        local combined="${content}${footer}"
        # 文字数をカウント (GNU wc -m)
        local len=$(echo -n "$combined" | wc -m)

        # 2万文字を超えるなら次の連番ファイルへ (既存の中身がある場合のみ)
        if (( current_chars > 0 && current_chars + len > MAX_CHARS )); then
            file_idx=$((file_idx + 1))
            out_file="$OUTPUT_DIR/${base_name}_${file_idx}.md"
            current_chars=0
        fi

        echo -e "$combined" >> "$out_file"
        current_chars=$((current_chars + len))
        echo "  - Added: $f"
    done
}

# --- 4. メイン処理 ---

# A. ルート直下のファイルを1つずつ処理
echo ">>> Processing root files..."
for f in "$TARGET_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    # ignore判定
    if [[ -n "$IGNORE_PATTERN" ]] && echo "$f" | grep -Eq "$IGNORE_PATTERN"; then
        continue
    fi
    
    base=$(basename "$f" .md)
    echo "File: $f"
    merge_files "$base" "$f"
done

# B. ルート直下のディレクトリごとにマージ
echo ">>> Processing directories..."
for d in "$TARGET_DIR"/*; do
    [[ -d "$d" ]] || continue
    dir_name=$(basename "$d")
    
    # ディレクトリ自体が除外対象ならパス
    if [[ -n "$IGNORE_PATTERN" ]] && echo "$d" | grep -Eq "$IGNORE_PATTERN"; then
        continue
    fi

    echo "Directory: $d"
    # ディレクトリ内の全MDファイルを再帰的にリストアップ (配列化)
    # スペース入りのファイル名にも対応できる安全な読み込み
    sub_files=()
    while IFS= read -r found; do
        sub_files+=("$found")
    done < <(find "$d" -type f -name "*.md" | sort)

    if [[ ${#sub_files[@]} -gt 0 ]]; then
        merge_files "$dir_name" "${sub_files[@]}"
    fi
done

echo "Done! Output directory: $OUTPUT_DIR"