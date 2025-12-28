#!/bin/bash

# 配置
REPO_URL="https://github.com/Tenghsien/git-tools.git"
TARGET_DIR=".tools-from-Tengxian"
SUB_FOLDER="git-tools-for-WeRide"
# 指定分支为 WeRide
BRANCH="WeRide"

CURRENT_DIR=$(pwd)

echo "🚀 准备在当前目录部署工具: $CURRENT_DIR"

# 1. 检查 Git 环境
if [ ! -d ".git" ]; then
    echo "⚠️  警告: 当前目录不是 Git 仓库根目录，将跳过 exclude 设置。"
    IS_GIT_REPO=false
else
    IS_GIT_REPO=true
fi

# 2. 清理旧版本
rm -rf "$TARGET_DIR"

# 3. 分步执行以确保兼容性
echo "正在从远程获取工具 (分支: $BRANCH)..."

# 先创建目录并初始化
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 初始化为稀疏克隆仓库
git init
git remote add origin "$REPO_URL"
git config core.sparseCheckout true

# 设置要提取的文件夹
echo "$SUB_FOLDER/" >> .git/info/sparse-checkout

# 拉取特定分支
git pull --depth 1 origin "$BRANCH"

# 4. 提取内容并清理
if [ -d "$SUB_FOLDER" ]; then
    mv "$SUB_FOLDER"/* .
    rm -rf "$SUB_FOLDER"
    rm -rf .git  # 删除工具内部的 git 痕迹
    echo "✅ 文件提取完成。"
else
    echo "❌ 错误: 未能在仓库中找到目录 $SUB_FOLDER"
    cd "$CURRENT_DIR" && rm -rf "$TARGET_DIR"
    exit 1
fi

# 5. 权限设置
echo "正在设置执行权限..."
chmod -R +x .

# 6. 设置 Git 忽略
cd "$CURRENT_DIR" || exit
if [ "$IS_GIT_REPO" = true ]; then
    # 确保 exclude 文件存在
    touch .git/info/exclude
    if ! grep -q "$TARGET_DIR/" .git/info/exclude; then
        echo "$TARGET_DIR/" >> .git/info/exclude
        echo "✅ 已将 $TARGET_DIR 添加到本地 Git 排除列表。"
    fi
fi

echo "---"
echo "🎉 部署成功！工具已安装在 $TARGET_DIR"
