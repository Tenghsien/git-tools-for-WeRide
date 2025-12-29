#!/bin/bash
set -e

# ===================== 核心配置（按需修改）=====================
# 替换为你的 git-tools 仓库 HTTPS 地址
REPO_URL="https://github.com/Tenghsien/git-tools.git"
# 本地目标文件夹名（克隆仓库的目录名）
TARGET_DIR="tools-from-Tengxian"
# 工具所在的子目录名（仓库内的文件夹）
TOOL_SUBDIR="git-tools-for-WeRide"
# 替换为你需要部署的分支名（比如 dev/test/feature 等）
DEPLOY_BRANCH="WeRide"  # 示例：DEPLOY_BRANCH="dev"

# ===================== 彩色输出（提升终端体验）=====================
green() { echo -e "\033[32m✅ $1\033[0m"; }
red() { echo -e "\033[31m❌ $1\033[0m"; }
yellow() { echo -e "\033[33m⚠️ $1\033[0m"; }

# ===================== 环境检查 =====================
check_requirements() {
    # 检查当前目录写入权限
    if [ ! -w "$PWD" ]; then
        red "当前目录（$PWD）无写入权限，请切换目录后重试"
        exit 1
    fi
}

# ===================== 核心部署逻辑 =====================
main() {
    echo "=========================================="
    echo "    Git Tools 一键部署脚本"
    echo "=========================================="
    echo ""

    # 0. 环境检查
    check_requirements

    # 1. 克隆/更新仓库（指定分支+健壮的目录切换）
    if [ -d "$TARGET_DIR/.git" ]; then
        yellow "检测到已有 $TARGET_DIR 文件夹，拉取 [$DEPLOY_BRANCH] 分支最新代码..."
        # pushd/popd 替代 cd，目录切换更稳定
        pushd "$TARGET_DIR" > /dev/null
        # 先切换到目标分支，再拉取最新代码
        git checkout "$DEPLOY_BRANCH" || { red "分支 $DEPLOY_BRANCH 不存在"; exit 1; }
        git pull origin "$DEPLOY_BRANCH"
        popd > /dev/null
    else
        echo "首次部署，克隆 [$DEPLOY_BRANCH] 分支到 $PWD/$TARGET_DIR..."
        # 克隆时直接指定目标分支
        git clone -b "$DEPLOY_BRANCH" "$REPO_URL" "$TARGET_DIR" || { red "分支 $DEPLOY_BRANCH 不存在或仓库地址错误"; exit 1; }
    fi
    green "代码下载完成"

    # 2. 配置文件权限（目录755/普通文件644/脚本加执行权限）
    TOOL_PATH="$TARGET_DIR/$TOOL_SUBDIR"
    chmod -R 755 "$TOOL_PATH/"                          # 所有目录赋可读写执行权限
    find "$TOOL_PATH" -type f -exec chmod 644 {} \;     # 普通文件赋可读可写权限
    find "$TOOL_PATH" -type f \( -name "*.sh" -o -name "git-tools" \) -exec chmod +x {} \;  # 脚本和工具加执行权限
    green "权限配置完成"

    # 3. 加入 .git/info/exclude（避免git追踪）
    if [ -d ".git" ]; then
        EXCLUDE_FILE=".git/info/exclude"
        # 检查是否已存在，避免重复添加
        if ! grep -q "^$TARGET_DIR/" "$EXCLUDE_FILE" 2>/dev/null; then
            echo -e "\n$TARGET_DIR/" >> "$EXCLUDE_FILE"
            green "已将 $TARGET_DIR/ 加入 $EXCLUDE_FILE（git 忽略该文件夹）"
        else
            green "$TARGET_DIR/ 已在 $EXCLUDE_FILE 中，无需重复添加"
        fi
    else
        yellow "当前目录不是 git 仓库，跳过 .git/info/exclude 配置"
    fi

    # 4. 部署完成提示
    echo ""
    echo "=========================================="
    green "✅ 部署全部完成！"
    echo "=========================================="
    echo ""
    echo "📁 工具文件夹路径：$PWD/$TARGET_DIR/$TOOL_SUBDIR"
    echo "🌿 部署分支：$DEPLOY_BRANCH"
    echo ""

    # 5. 提示创建全局命令（不自动执行，避免管道中 sudo 交互问题）
    echo "📌 推荐：创建全局命令以便在任何目录使用"
    echo "----------------------------------------"
    echo "请复制并执行以下命令："
    echo ""
    echo -e "\033[1;31m  sudo ln -sf $PWD/$TARGET_DIR/$TOOL_SUBDIR/git-tools /usr/local/bin/git-tools\033[0m"
    echo ""
    echo "创建后，可以在任何目录直接使用："
    echo "  git-tools check   # 检查 diff 状态"
    echo "  git-tools patch   # 应用未合入的 diff"
    echo "  git-tools reset   # 强制同步远程代码"
    echo ""
    yellow "如果不创建全局命令，也可以进入目录使用："
    echo "  cd $TARGET_DIR/$TOOL_SUBDIR"
    echo "  ./git-tools check"
    echo ""
}

# 执行主流程
main "$@"
