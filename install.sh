#!/bin/bash
# 更新 GitHub 上的 install.sh

echo "🚀 开始更新 GitHub 仓库的 install.sh..."

REPO_DIR="/tmp/git-tools-update"
REPO_URL="https://github.com/Tenghsien/git-tools.git"
BRANCH="WeRide"
LOCAL_INSTALL_SH="./install.sh"

# 清理旧的临时目录
if [ -d "$REPO_DIR" ]; then
    rm -rf "$REPO_DIR"
fi

# 克隆仓库
echo "📥 克隆仓库..."
git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR" || {
    echo "❌ 克隆失败"
    exit 1
}

# 复制新的 install.sh
echo "📝 更新 install.sh..."
cp "$LOCAL_INSTALL_SH" "$REPO_DIR/install.sh" || {
    echo "❌ 复制文件失败"
    exit 1
}

# 进入仓库目录
cd "$REPO_DIR" || exit 1

# 检查是否有更改
if git diff --quiet install.sh; then
    echo "✅ install.sh 已经是最新版本，无需更新"
    cd - > /dev/null
    rm -rf "$REPO_DIR"
    exit 0
fi

# 提交更改
echo "📤 提交更改..."
git add install.sh
git commit -m "Update install.sh - fix tool detection logic"

# 推送到 GitHub
echo "🚀 推送到 GitHub..."
git push origin "$BRANCH" || {
    echo ""
    echo "❌ 推送失败！"
    echo ""
    echo "可能的原因："
    echo "  1. 没有配置 Git 认证（需要 Personal Access Token）"
    echo "  2. 没有推送权限"
    echo ""
    echo "手动推送方法："
    echo "  cd $REPO_DIR"
    echo "  git push origin $BRANCH"
    exit 1
}

# 清理
cd - > /dev/null
rm -rf "$REPO_DIR"

echo ""
echo "✅ 更新完成！"
echo ""
echo "现在可以测试："
echo "  curl -sL https://raw.githubusercontent.com/Tenghsien/git-tools/$BRANCH/install.sh | bash -s git-tools-for-WeRide"
