#!/bin/bash

# 1. 定义变量
REPO_URL="https://github.com/Tenghsien/git-tools.git"
TARGET_DIR=".tools-from-Tengxian"
SUB_FOLDER="git-tools-for-WeRide"
BRANCH="WeRide"

echo "正在部署工具到 $TARGET_DIR..."

# 2. 清理可能存在的旧目录
rm -rf "$TARGET_DIR" .temp_git_clone

# 3. 简单粗暴地克隆整个分支 (最稳健)
git clone -b "$BRANCH" --depth 1 "$REPO_URL" .temp_git_clone

# 4. 将目标文件夹搬移到最终位置，并赋予权限
if [ -d ".temp_git_clone/$SUB_FOLDER" ]; then
    mv ".temp_git_clone/$SUB_FOLDER" "$TARGET_DIR"
    chmod -R +x "$TARGET_DIR"
    echo "✅ 文件夹已创建并设置权限。"
else
    echo "❌ 错误：找不到文件夹 $SUB_FOLDER"
    rm -rf .temp_git_clone
    exit 1
fi

# 5. 清理克隆的垃圾文件
rm -rf .temp_git_clone

# 6. 添加到 exclude (仅当在 git 仓库时)
if [ -d ".git" ]; then
    # 确保文件存在且不重复添加
    touch .git/info/exclude
    if ! grep -q "$TARGET_DIR/" .git/info/exclude; then
        echo "$TARGET_DIR/" >> .git/info/exclude
        echo "✅ 已添加到 .git/info/exclude"
    fi
fi

echo "🎉 部署完成。"
