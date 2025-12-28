#!/bin/bash
# ============================================
# Git Tools 在线安装脚本
# 从 GitHub 下载 git-tools-for-WeRide 到本地 git-tools-from-tengxian
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
GITHUB_USER="Tenghsien"
GITHUB_REPO="git-tools"
GITHUB_BRANCH="WeRide"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/git-tools-for-WeRide"

# 本地安装目录
INSTALL_DIR="$(pwd)/git-tools-from-tengxian"

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 检查依赖
check_dependencies() {
    print_header "检查依赖"

    if command -v curl &> /dev/null; then
        DOWNLOAD_CMD="curl -fsSL"
        print_success "curl 已安装"
    elif command -v wget &> /dev/null; then
        DOWNLOAD_CMD="wget -qO-"
        print_success "wget 已安装"
    else
        print_error "需要 curl 或 wget"
        exit 1
    fi
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    $DOWNLOAD_CMD "$url" > "$output" 2>/dev/null
}

# 下载并安装
install_git_tools() {
    print_header "下载文件"

    # 创建目录
    mkdir -p "$INSTALL_DIR/lib"

    # 下载主脚本
    echo "下载 git-tools.sh..."
    if download_file "${GITHUB_RAW}/git-tools.sh" "$INSTALL_DIR/git-tools.sh"; then
        chmod +x "$INSTALL_DIR/git-tools.sh"
        print_success "git-tools.sh"
    else
        print_error "下载失败: git-tools.sh"
        exit 1
    fi

    # 下载库文件
    local lib_files=("common.sh" "diff_utils.sh" "git_ops.sh")
    for file in "${lib_files[@]}"; do
        echo "下载 lib/$file..."
        if download_file "${GITHUB_RAW}/lib/${file}" "$INSTALL_DIR/lib/${file}"; then
            chmod +x "$INSTALL_DIR/lib/${file}"
            print_success "lib/$file"
        else
            print_error "下载失败: lib/$file"
            exit 1
        fi
    done

    # 下载其他文件（可选）
    local optional_files=("README.md" "diff_list.txt")
    for file in "${optional_files[@]}"; do
        echo "下载 $file..."
        if download_file "${GITHUB_RAW}/${file}" "$INSTALL_DIR/${file}" 2>/dev/null; then
            print_success "$file"
        else
            print_info "$file (不存在或下载失败，跳过)"
        fi
    done
}

# 添加到 git exclude
add_to_exclude() {
    print_header "配置 Git 忽略"

    if [ ! -d ".git" ]; then
        print_info "不在 git 仓库中，跳过"
        return
    fi

    local exclude_file=".git/info/exclude"
    mkdir -p .git/info
    touch "$exclude_file"

    if grep -qE "^git-tools-from-tengxian/?$" "$exclude_file" 2>/dev/null; then
        print_info "git-tools-from-tengxian 已在 exclude 中"
    else
        echo "git-tools-from-tengxian/" >> "$exclude_file"
        print_success "已添加到 git exclude"
    fi
}

# 显示完成信息
show_completion() {
    print_header "安装完成"

    echo -e "${GREEN}✓ Git Tools 安装成功！${NC}"
    echo ""
    echo "📦 安装位置："
    echo "   $(pwd)/git-tools-from-tengxian/"
    echo ""
    echo "🚀 使用命令："
    echo "   ./git-tools-from-tengxian/git-tools.sh check"
    echo "   ./git-tools-from-tengxian/git-tools.sh patch"
    echo "   ./git-tools-from-tengxian/git-tools.sh reset"
    echo ""
    echo "💡 建议：创建别名"
    echo "   ${BLUE}alias gt=\"$(pwd)/git-tools-from-tengxian/git-tools.sh\"${NC}"
    echo ""
}

# 主函数
main() {
    print_header "Git Tools 安装"

    echo "仓库: ${GITHUB_USER}/${GITHUB_REPO}"
    echo "安装位置: $(pwd)/git-tools-from-tengxian/"
    echo ""

    check_dependencies
    install_git_tools
    add_to_exclude
    show_completion
}

main
