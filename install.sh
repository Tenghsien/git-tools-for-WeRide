#!/bin/bash
# ============================================
# Git Tools 在线安装脚本
# 支持从 GitHub 直接安装
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置 - 修改为你的 GitHub 仓库信息
GITHUB_USER="Tenghsien"          # 替换为你的 GitHub 用户名
GITHUB_REPO="git-tools"   # 替换为你的仓库名
GITHUB_BRANCH="WeRide"                 # 或 master

GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

TOOL_NAME="git-tools"
INSTALL_DIR="$HOME/.local/bin"
LIB_DIR="$HOME/.local/share/$TOOL_NAME"
TEMP_DIR="/tmp/git-tools-install-$$"

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 清理临时目录
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# 检查命令是否存在
check_command() {
    command -v "$1" &> /dev/null
}

# 检查依赖
check_dependencies() {
    print_header "检查依赖"

    # 检查下载工具
    if check_command curl; then
        DOWNLOAD_CMD="curl -fsSL"
        print_success "curl 已安装"
    elif check_command wget; then
        DOWNLOAD_CMD="wget -qO-"
        print_success "wget 已安装"
    else
        print_error "需要 curl 或 wget 来下载文件"
        exit 1
    fi

    # 检查必要工具
    local deps=("git" "arc")
    local missing=()

    for dep in "${deps[@]}"; do
        if check_command "$dep"; then
            print_success "$dep 已安装"
        else
            print_warning "$dep 未安装（运行时需要）"
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo ""
        print_warning "以下工具在使用时必需："
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
    fi
}

# 下载文件
download_file() {
    local url=$1
    local output=$2

    if [ -z "$DOWNLOAD_CMD" ]; then
        print_error "下载命令未初始化"
        return 1
    fi

    $DOWNLOAD_CMD "$url" > "$output" 2>/dev/null
}

# 下载并安装文件
download_and_install() {
    print_header "下载文件"

    # 创建临时目录
    mkdir -p "$TEMP_DIR/lib"
    print_info "创建临时目录: $TEMP_DIR"

    # 下载主脚本
    echo "正在下载主脚本..."
    if download_file "${GITHUB_RAW}/git-tools.sh" "$TEMP_DIR/git-tools.sh"; then
        print_success "git-tools.sh 下载成功"
    else
        print_error "下载 git-tools.sh 失败"
        echo "请检查网络连接和 GitHub 仓库地址"
        exit 1
    fi

    # 下载库文件
    local lib_files=("common.sh" "diff_utils.sh" "git_ops.sh")
    for file in "${lib_files[@]}"; do
        echo "正在下载 lib/$file..."
        if download_file "${GITHUB_RAW}/lib/${file}" "$TEMP_DIR/lib/${file}"; then
            print_success "lib/$file 下载成功"
        else
            print_error "下载 lib/$file 失败"
            exit 1
        fi
    done
}

# 安装文件
install_files() {
    print_header "安装文件"

    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LIB_DIR/lib"

    # 复制文件
    cp "$TEMP_DIR/git-tools.sh" "$LIB_DIR/"
    chmod +x "$LIB_DIR/git-tools.sh"
    print_success "安装主脚本"

    cp "$TEMP_DIR/lib/"*.sh "$LIB_DIR/lib/"
    print_success "安装库文件"

    # 创建符号链接
    ln -sf "$LIB_DIR/git-tools.sh" "$INSTALL_DIR/$TOOL_NAME"
    print_success "创建命令链接"
}

# 配置 PATH
configure_path() {
    print_header "配置环境变量"

    # 检查 PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        print_success "$INSTALL_DIR 已在 PATH 中"
        return
    fi

    # 检测 shell
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi

    # 添加 PATH 配置
    local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""

    if [ -f "$shell_rc" ]; then
        if ! grep -q "$INSTALL_DIR" "$shell_rc"; then
            echo "" >> "$shell_rc"
            echo "# Git Tools" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            print_success "已添加 PATH 到 $shell_rc"
            print_warning "请运行 'source $shell_rc' 或重新打开终端"
        else
            print_success "PATH 配置已存在"
        fi
    else
        print_warning "未找到 shell 配置文件，请手动添加："
        echo ""
        echo "    $path_line"
        echo ""
    fi
}

# 创建配置示例
create_config_example() {
    print_header "创建配置示例"

    local example_file="$HOME/diff_list.txt.example"

    cat > "$example_file" << 'EOF'
# Diff List 配置文件示例
# 每行一个 Phabricator Diff ID

D12345
D12346
D12347
EOF

    print_success "创建示例: $example_file"
}

# 显示完成信息
show_completion() {
    print_header "安装完成"

    echo -e "${GREEN}✓ Git Tools 安装成功！${NC}"
    echo ""
    echo "📦 安装位置："
    echo "   $INSTALL_DIR/$TOOL_NAME"
    echo ""
    echo "🚀 使用方法："
    echo "   git-tools check   - 检查 diff 状态"
    echo "   git-tools patch   - 应用未合入的 diff"
    echo "   git-tools reset   - 重置到远程分支"
    echo ""
    echo "📝 配置："
    echo "   在项目根目录创建: tengxian_xu_tools/diff_list.txt"
    echo "   参考示例: $HOME/diff_list.txt.example"
    echo ""
    echo -e "${YELLOW}⚠ 重要：${NC}运行以下命令使其生效："

    if [ -n "$ZSH_VERSION" ]; then
        echo -e "   ${BLUE}source ~/.zshrc${NC}"
    elif [ -n "$BASH_VERSION" ]; then
        echo -e "   ${BLUE}source ~/.bashrc${NC}"
    else
        echo -e "   ${BLUE}source ~/.profile${NC}"
    fi

    echo ""
    echo "或者重新打开终端"
    echo ""
}

# 主函数
main() {
    print_header "Git Tools 在线安装"

    echo "将从 GitHub 下载并安装 Git Tools"
    echo "仓库: ${GITHUB_USER}/${GITHUB_REPO}"
    echo ""

    check_dependencies
    download_and_install
    install_files
    configure_path
    create_config_example
    show_completion
}

# 执行主函数
main
