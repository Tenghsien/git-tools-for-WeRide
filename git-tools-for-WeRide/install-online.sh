#!/bin/bash
# ============================================
# Git Tools 在线安装脚本
# 安装到当前目录，方便 VSCode 操作
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置 - 修改为你的 GitHub 仓库信息
GITHUB_USER="Tenghsien"              # 你的 GitHub 用户名
GITHUB_REPO="git-tools-for-WeRide"   # 仓库名
GITHUB_BRANCH="WeRide"               # 分支名

GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

TOOL_NAME="git-tools"
# 安装到当前目录
INSTALL_DIR="$(pwd)/.git-tools"
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
    if download_file "${GITHUB_RAW}/git-tools-for-WeRide/git-tools.sh" "$TEMP_DIR/git-tools.sh"; then
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
        if download_file "${GITHUB_RAW}/git-tools-for-WeRide/lib/${file}" "$TEMP_DIR/lib/${file}"; then
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
    mkdir -p "$INSTALL_DIR/lib"

    # 复制文件
    cp "$TEMP_DIR/git-tools.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/git-tools.sh"
    print_success "安装主脚本"

    cp "$TEMP_DIR/lib/"*.sh "$INSTALL_DIR/lib/"
    print_success "安装库文件"

    # 创建启动脚本
    cat > "$INSTALL_DIR/git-tools" << 'SCRIPT_END'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/git-tools.sh" "$@"
SCRIPT_END
    chmod +x "$INSTALL_DIR/git-tools"
    print_success "创建启动脚本"
}

# 创建配置示例
create_config_example() {
    print_header "创建配置示例"

    local example_file="$(pwd)/diff_list.txt.example"

    cat > "$example_file" << 'EOF'
# Diff List 配置文件示例
# 每行一个 Phabricator Diff ID
# 使用时将此文件重命名为 diff_list.txt

D12345
D12346
D12347
EOF

    print_success "创建配置示例: diff_list.txt.example"
}

# 添加到 git exclude
add_to_git_exclude() {
    print_header "配置 Git 忽略"

    # 检查是否在 git 仓库中
    if [ ! -d ".git" ]; then
        print_warning "不在 git 仓库中，跳过 git ignore 配置"
        return
    fi

    local exclude_file=".git/info/exclude"

    # 确保 exclude 文件存在
    mkdir -p .git/info
    touch "$exclude_file"

    # 要忽略的文件/文件夹
    local items=(".git-tools/" "diff_list.txt" "diff_list.txt.example")

    for item in "${items[@]}"; do
        # 检查是否已经存在
        if grep -q "^${item}$" "$exclude_file" 2>/dev/null; then
            print_info "$item 已在 git exclude 中"
        else
            echo "$item" >> "$exclude_file"
            print_success "已添加 $item 到 git exclude"
        fi
    done
}

# 显示完成信息
show_completion() {
    print_header "安装完成"

    echo -e "${GREEN}✓ Git Tools 安装成功！${NC}"
    echo ""
    echo "📦 安装位置："
    echo "   $(pwd)/.git-tools/"
    echo ""
    echo "📝 第一步：创建配置文件"
    echo "   将 diff_list.txt.example 重命名为 diff_list.txt"
    echo "   然后编辑添加你的 Diff ID"
    echo ""
    echo "🚀 第二步：使用命令"
    echo "   ./.git-tools/git-tools check   - 检查 diff 状态"
    echo "   ./.git-tools/git-tools patch   - 应用未合入的 diff"
    echo "   ./.git-tools/git-tools reset   - 重置到远程分支"
    echo ""
    echo "💡 建议：创建别名方便使用"
    echo "   ${BLUE}alias gt=\"$(pwd)/.git-tools/git-tools\"${NC}"
    echo "   然后可以直接用: ${BLUE}gt check${NC}"
    echo ""
}

# 主函数
main() {
    print_header "Git Tools 在线安装"

    echo "将从 GitHub 下载并安装 Git Tools"
    echo "仓库: ${GITHUB_USER}/${GITHUB_REPO}"
    echo "安装位置: $(pwd)/.git-tools/"
    echo ""

    check_dependencies
    download_and_install
    install_files
    create_config_example
    add_to_git_exclude
    show_completion
}

# 执行主函数
main
