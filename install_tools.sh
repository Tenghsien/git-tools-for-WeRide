#!/bin/bash

# ==========================================
# Git Tools 兼容性部署脚本 (2025版)
# ==========================================

REPO_URL="https://github.com/Tenghsien/git-tools.git"
TARGET_DIR=".tools-from-Tengxian"
SUB_FOLDER="git-tools-for-WeRide"
BRANCH="WeRide"
TEMP_DIR=".temp_git_tools_setup"

CURRENT_DIR=$(pwd)

echo "🚀 开始部署工具到: $CURRENT_DIR"

# 1. 环境清理：确保没有残留的临时文件夹
rm -rf "$TEMP_DIR" "$TARGET_DIR"

# 2. 深度为1的浅克隆 (速度最快)
echo "正在从远程获取文件..."
if ! git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR"; then
    echo "❌ 错误: 克隆仓库失败，请检查网络连接。"
    exit 1
fi

# 3. 提取目标文件夹到最终位置
if [ -d "$TEMP_DIR/$SUB_FOLDER" ]; then
    mkdir -p "$TARGET_DIR"
    cp -r "$TEMP_DIR/$SUB_FOLDER"/* "$TARGET_DIR/"
    echo "✅ 文件提取成功。"
else
    echo "❌ 错误: 在仓库中未找到目录 $SUB_FOLDER"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 4. 清理临时文件
rm -rf "$TEMP_DIR"

# 5. 设置权限
echo "正在设置执行权限..."
chmod -R +x "$TARGET_DIR"

# 6. 设置 Git 本地忽略
if [ -d ".git" ]; then
    touch .git/info/exclude
    if ! grep -q "$TARGET_DIR/" .git/info/exclude; then
        echo "$TARGET_DIR/" >> .git/info/exclude
        echo "✅ 已添加到 .git/info/exclude"
    fi
else
    echo "⚠️  提示: 当前不是 Git 仓库，跳过排除设置。"
fi

echo "---"
echo "🎉 部署完成！"
echo "你可以通过 $TARGET_DIR 访问你的工具。"
