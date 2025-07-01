#!/bin/bash

set -e  # 遇到錯誤時立即退出腳本

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SRC_DIR="$SCRIPT_DIR/build/app/intermediates/merged_native_libs/release/out/lib"
DEST_ZIP="$SCRIPT_DIR/build/app/outputs/bundle/release/compressed_libs.zip"

# 定義有效的 ABI 目錄
VALID_ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")

echo "Script started at $(date)"
echo "Current working directory: $(pwd)"
echo "Project root directory: $SCRIPT_DIR"
echo "Source directory: $SRC_DIR"
echo "Destination ZIP: $DEST_ZIP"

# 檢查源目錄是否存在
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory does not exist: $SRC_DIR"
    echo "Contents of build directory:"
    ls -R "$SCRIPT_DIR/build"
    exit 1
fi

# 確保目標目錄存在
DEST_DIR=$(dirname "$DEST_ZIP")
echo "Creating destination directory: $DEST_DIR"
mkdir -p "$DEST_DIR"

# 如果目標 ZIP 文件已存在，則刪除它
if [ -f "$DEST_ZIP" ]; then
    echo "Removing existing ZIP file: $DEST_ZIP"
    rm "$DEST_ZIP"
fi

# 創建臨時目錄
TEMP_DIR=$(mktemp -d)
echo "Creating temporary directory: $TEMP_DIR"

# 複製需要的 ABI 目錄到臨時目錄
for abi in "${VALID_ABIS[@]}"; do
    if [ -d "$SRC_DIR/$abi" ]; then
        echo "Copying $abi to temp directory..."
        cp -R "$SRC_DIR/$abi" "$TEMP_DIR/"
    else
        echo "Warning: $abi directory not found in $SRC_DIR"
    fi
done

# 切換到臨時目錄
cd "$TEMP_DIR"
echo "Current directory (should be temp): $(pwd)"

# 列出臨時目錄內容
echo "Temporary directory contents:"
ls -R

# 使用 zip 命令創建 zip 文件
echo "Creating ZIP file..."
zip -r "$DEST_ZIP" ./* || {
    echo "Error: zip command failed"
    echo "Current directory: $(pwd)"
    echo "Destination ZIP: $DEST_ZIP"
    echo "Destination directory contents:"
    ls -l "$DEST_DIR"
    exit 1
}

echo "Compressed libraries saved to $DEST_ZIP"

# 驗證 zip 文件內容
echo "Zip file contents:"
if [ -f "$DEST_ZIP" ]; then
    unzip -l "$DEST_ZIP"
else
    echo "Error: ZIP file not found at $DEST_ZIP"
    exit 1
fi

# 驗證 ZIP 文件不包含無效目錄
if unzip -l "$DEST_ZIP" | grep -q "tmp\."; then
    echo "Error: ZIP file contains invalid temporary directories"
    exit 1
fi

# 清理臨時目錄
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "ZIP file created successfully."
echo "Final ZIP file size: $(du -h "$DEST_ZIP" | cut -f1)"
echo "Script completed at $(date)"