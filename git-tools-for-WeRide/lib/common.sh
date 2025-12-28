#!/bin/bash
# ============================================
# 公共工具函数库
# ============================================

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m' # No Color

# ============================================
# Git 操作函数
# ============================================

# 更新 git 仓库
update_git_repo() {
    echo "=========================================="
    echo "          更新 Git 仓库"
    echo "=========================================="
    echo ""

    # 执行 git fetch
    echo "正在执行 git fetch..."
    if ! git fetch 2>&1; then
        echo ""
        echo -e "${RED}❌ git fetch 失败！${NC}"
        echo "请检查网络连接或 git 仓库状态"
        exit 1
    fi
    echo -e "${GREEN}✓ git fetch 完成${NC}"
    echo ""

    # 执行 git pull
    echo "正在执行 git pull..."
    git_pull_output=$(git pull 2>&1)
    git_pull_exit=$?

    if [ $git_pull_exit -ne 0 ]; then
        echo ""
        echo -e "${RED}❌ git pull 失败！${NC}"
        echo "错误信息："
        echo "$git_pull_output"
        echo ""
        echo "可能的原因："
        echo "  1. 存在未提交的本地更改"
        echo "  2. 存在合并冲突"
        echo "  3. 当前分支没有设置上游分支"
        echo ""
        echo "请先解决这些问题后再运行本脚本"
        exit 1
    fi

    echo "$git_pull_output"
    echo -e "${GREEN}✓ git pull 完成${NC}"
    echo ""
}

# 获取当前分支名
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# 检查是否在 git 仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ 当前目录不是 git 仓库${NC}"
        exit 1
    fi
}

# 检查远程分支是否存在
check_remote_branch() {
    local branch=$1
    git rev-parse --verify "origin/$branch" >/dev/null 2>&1
}

# ============================================
# 文件操作函数
# ============================================

# 创建临时文件
create_temp_file() {
    mktemp
}

# 清理临时文件
cleanup_temp_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        rm -f "$file" 2>/dev/null
    done
}

# ============================================
# 输出格式化函数
# ============================================

# 打印分隔线
print_separator() {
    echo "=========================================="
}

# 打印标题
print_title() {
    local title=$1
    print_separator
    echo "          $title"
    print_separator
    echo ""
}

# 打印成功消息
print_success() {
    local msg=$1
    echo -e "${GREEN}✓ $msg${NC}"
}

# 打印错误消息
print_error() {
    local msg=$1
    echo -e "${RED}✗ $msg${NC}"
}

# 打印警告消息
print_warning() {
    local msg=$1
    echo -e "${YELLOW}⚠️  $msg${NC}"
}

# 打印信息消息
print_info() {
    local msg=$1
    echo "$msg"
}
