#!/bin/bash

# ==========================================
# Git Tools 一键部署脚本
# ==========================================

# 配置
REPO_URL="https://github.com/Tenghsien/git-tools.git"
TARGET_DIR=".tools-from-Tengxian"
SUB_FOLDER="git-tools-for-WeRide"

# 获取当前执行命令的绝对路径
CURRENT_DIR=$(pwd)

echo "🚀 准备在当前目录部署工具: $CURRENT_DIR"

# 1. 检查当前是否在 Git 仓库中（为了后续修改 .git/info/exclude）
if [ ! -d ".git" ]; then
    echo "⚠️  警告: 当前目录不是 Git 仓库根目录，将跳过 exclude 设置。"
    IS_GIT_REPO=false
else
    IS_GIT_REPO=true
fi

# 2. 清理旧版本
if [ -d "$TARGET_DIR" ]; then
    echo "清理旧的 $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
fi

# 3. 在当前目录下克隆并提取
echo "正在从远程获取工具..."
# 使用临时目录避免直接在当前目录产生 .git 冲突
git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TARGET_DIR"

cd "$TARGET_DIR" || exit
git sparse-checkout set "$SUB_FOLDER"

# 移动内容并清理 Git 痕迹
if [ -d "$SUB_FOLDER" ]; then
    mv "$SUB_FOLDER"/* .
    rm -rf "$SUB_FOLDER"
    # 删除工具自身的 .git 目录，使其成为纯粹的文件集合
    rm -rf .git
    echo "✅ 文件提取完成。"
else
    echo "❌ 错误: 未能在仓库中找到目录 $SUB_FOLDER"
    exit 1
fi

# 4. 权限设置
echo "正在设置执行权限..."
chmod -R +x .

# 5. 设置 Git 忽略 (仅当在 Git 仓库中时)
cd "$CURRENT_DIR" || exit
if [ "$IS_GIT_REPO" = true ]; then
    if ! grep -q "$TARGET_DIR/" .git/info/exclude; then
        echo "$TARGET_DIR/" >> .git/info/exclude
        echo "✅ 已将 $TARGET_DIR 添加到本地 Git 排除列表 (.git/info/exclude)。"
    fi
fi

echo "---"
echo "🎉 部署成功！"
echo "工具位置: $CURRENT_DIR/$TARGET_DIR"
