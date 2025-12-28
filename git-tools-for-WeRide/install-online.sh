#!/bin/bash
# ============================================
# Git Tools for WeRide - 一键安装脚本
# ============================================
# 使用方法:
#   在线安装: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/git-tools/main/install.sh | bash
#   或者: wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/git-tools/main/install.sh | bash
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO_URL="https://github.com/YOUR_USERNAME/git-tools.git"
INSTALL_DIR="$(pwd)/.tools-from-Tengxian"
BIN_DIR="$HOME/.local/bin"
SOURCE_FOLDER="git-tools-for-WeRide"

# ============================================
# 工具函数
# ============================================

print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_title() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# ============================================
# 检查依赖
# ============================================
check_dependencies() {
    print_message "检查系统依赖..."

    local missing_deps=()

    # 检查 git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    # 检查 bash
    if ! command -v bash &> /dev/null; then
        missing_deps+=("bash")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "缺少以下依赖: ${missing_deps[*]}"
        echo "请先安装这些依赖后再运行安装脚本"
        exit 1
    fi

    print_success "所有依赖已满足"
}

# ============================================
# 清理旧安装
# ============================================
cleanup_old_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "检测到已存在的安装目录: $INSTALL_DIR"
        read -p "是否删除并重新安装? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_message "删除旧版本..."
            rm -rf "$INSTALL_DIR"
            print_success "旧版本已删除"
        else
            print_error "取消安装"
            exit 1
        fi
    fi
}

# ============================================
# 下载仓库
# ============================================
download_repo() {
    print_message "从 GitHub 下载 git-tools..."

    # 使用临时目录
    local temp_dir=$(mktemp -d)

    # 克隆仓库
    if git clone --depth=1 "$REPO_URL" "$temp_dir" &> /dev/null; then
        print_success "仓库下载成功"
    else
        print_error "仓库下载失败，请检查网络连接或仓库地址"
        rm -rf "$temp_dir"
        exit 1
    fi

    # 检查源文件夹是否存在
    if [ ! -d "$temp_dir/$SOURCE_FOLDER" ]; then
        print_error "在仓库中未找到 $SOURCE_FOLDER 文件夹"
        rm -rf "$temp_dir"
        exit 1
    fi

    # 移动到安装目录
    print_message "安装文件到 $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    mv "$temp_dir/$SOURCE_FOLDER" "$INSTALL_DIR"

    # 清理临时目录
    rm -rf "$temp_dir"

    print_success "文件安装完成"
}

# ============================================
# 设置执行权限
# ============================================
set_permissions() {
    print_message "设置执行权限..."

    # 为所有 .sh 文件添加执行权限
    find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

    # 为主程序添加执行权限
    if [ -f "$INSTALL_DIR/git-tools.sh" ]; then
        chmod +x "$INSTALL_DIR/git-tools.sh"
    fi

    print_success "权限设置完成"
}

# ============================================
# 创建符号链接
# ============================================
create_symlinks() {
    print_message "创建命令行工具链接..."

    # 创建 bin 目录
    mkdir -p "$BIN_DIR"

    # 创建符号链接
    if [ -f "$INSTALL_DIR/git-tools.sh" ]; then
        ln -sf "$INSTALL_DIR/git-tools.sh" "$BIN_DIR/git-tools"
        print_success "已创建命令: git-tools"
    fi

    # 检查 PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_warning "$BIN_DIR 不在 PATH 中"
        echo ""
        echo "请将以下内容添加到你的 shell 配置文件 (~/.bashrc 或 ~/.zshrc):"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# ============================================
# 配置文件初始化
# ============================================
init_config() {
    print_message "初始化配置文件..."

    # 如果有配置文件模板，可以在这里复制
    # 例如: cp "$INSTALL_DIR/config.example" "$INSTALL_DIR/config"

    # 创建 diff_list.txt 如果不存在
    if [ ! -f "$INSTALL_DIR/diff_list.txt" ]; then
        touch "$INSTALL_DIR/diff_list.txt"
        print_success "已创建 diff_list.txt"
    fi
}

# ============================================
# 添加到 Git Exclude
# ============================================
add_to_git_exclude() {
    # 检查当前目录是否是 git 仓库
    if [ -d "$(pwd)/.git" ]; then
        print_message "检测到 Git 仓库，添加 .tools-from-Tengxian 到 exclude..."

        local exclude_file="$(pwd)/.git/info/exclude"

        # 确保 exclude 文件存在
        mkdir -p "$(dirname "$exclude_file")"
        touch "$exclude_file"

        # 检查是否已经添加
        if grep -q "^\.tools-from-Tengxian/$" "$exclude_file" 2>/dev/null; then
            print_success ".tools-from-Tengxian 已在 exclude 中"
        else
            # 添加到 exclude 文件
            echo ".tools-from-Tengxian/" >> "$exclude_file"
            print_success "已将 .tools-from-Tengxian 添加到 Git exclude"
        fi
    fi
}

# ============================================
# 显示安装信息
# ============================================
show_install_info() {
    print_title "安装完成！"

    echo "安装路径: $INSTALL_DIR"
    echo "命令路径: $BIN_DIR"
    echo ""

    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        echo "现在可以直接使用以下命令:"
        echo ""
        echo "    git-tools check   # 检查 diff 状态"
        echo "    git-tools patch   # patch 未合入的 diff"
        echo "    git-tools reset   # 重置并同步远程代码"
        echo ""
    else
        echo "请先将 $BIN_DIR 添加到 PATH，然后可以使用以下命令:"
        echo ""
        echo "    git-tools check   # 检查 diff 状态"
        echo "    git-tools patch   # patch 未合入的 diff"
        echo "    git-tools reset   # 重置并同步远程代码"
        echo ""
        echo "或者临时使用完整路径:"
        echo ""
        echo "    $BIN_DIR/git-tools check"
        echo ""
    fi

    print_success "安装成功！"
}

# ============================================
# 卸载函数 (可选)
# ============================================
uninstall() {
    print_title "卸载 Git Tools"

    read -p "确定要卸载 Git Tools 吗? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "取消卸载"
        exit 0
    fi

    print_message "正在卸载..."

    # 删除符号链接
    rm -f "$BIN_DIR/git-tools"

    # 删除安装目录
    rm -rf "$INSTALL_DIR"

    print_success "卸载完成"
}

# ============================================
# 主程序
# ============================================
main() {
    # 如果参数是 uninstall，执行卸载
    if [ "$1" = "uninstall" ]; then
        uninstall
        exit 0
    fi

    print_title "Git Tools for WeRide - 安装程序"

    # 检查依赖
    check_dependencies

    # 清理旧安装
    cleanup_old_installation

    # 下载仓库
    download_repo

    # 设置权限
    set_permissions

    # 创建符号链接
    create_symlinks

    # 初始化配置
    init_config

    # 添加到 Git Exclude
    add_to_git_exclude

    # 显示安装信息
    show_install_info
}

# 运行主程序
main "$@"
