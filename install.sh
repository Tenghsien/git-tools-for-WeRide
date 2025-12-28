#!/bin/bash

# Git 仓库地址
REPO_URL="https://github.com/Tenghsien/git-tools.git"
BRANCH="WeRide"
EXCLUDE_FILE=".git/info/exclude"
TEMP_DIR="/tmp/git-tools-$$"

echo "🚀 Git Tools 安装程序启动..."

# 清理函数
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# 设置退出时清理
trap cleanup EXIT

# 安装函数
install_tool() {
    local tool="$1"
    echo "🔧 开始安装：$tool"

    # 克隆仓库到临时目录
    if [ ! -d "$TEMP_DIR" ]; then
        echo "📥 正在从远程仓库下载..."
        git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR" || { 
            echo "❌ 克隆仓库失败"; 
            return 1
        }
    fi

    # 检查工具包是否存在
    if [ ! -d "$TEMP_DIR/$tool" ]; then
        echo "⚠ 工具包 [$tool] 不存在，跳过"
        return 1
    fi

    # 复制工具包到当前目录
    if [ -d "$tool" ]; then
        echo "✨ $tool 已存在，执行更新..."
        rm -rf "$tool"
    fi

    cp -r "$TEMP_DIR/$tool" "./$tool" || {
        echo "❌ 复制 $tool 失败"
        return 1
    }

    echo "✅ $tool 安装成功"

    # 写入 .git/info/exclude 防止提交
    if [ -f "$EXCLUDE_FILE" ]; then
        if ! grep -qxF "$tool/" "$EXCLUDE_FILE" 2>/dev/null; then
            echo "$tool/" >> "$EXCLUDE_FILE"
            echo "🙈 已加入 .git/info/exclude"
        fi
    fi
}

# ---------------- 模式①：命令行参数模式 ----------------
if [ $# -gt 0 ]; then  
    echo "📌 检测命令参数，执行定向安装..."
    for arg in "$@"; do
        install_tool "$arg"
    done
    echo "🎉 安装完成"
    exit 0
fi

# ---------------- 模式②：无参数 → 交互选择 ----------------
echo "📥 正在从远程仓库获取工具列表..."

# 克隆仓库到临时目录（如果还没克隆）
if [ ! -d "$TEMP_DIR" ]; then
    git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR" || { 
        echo "❌ 克隆仓库失败"; 
        exit 1
    }
fi

# 扫描仓库中的所有文件夹（排除 .git 等）
TOOLS_DIRS=()
for dir in "$TEMP_DIR"/*/; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        if [[ "$name" != ".git" && "$name" != "install.sh" && "$name" != "README.md" ]]; then
            TOOLS_DIRS+=("$name")
        fi
    fi
done

if [ ${#TOOLS_DIRS[@]} -eq 0 ]; then
    echo "❌ 远程仓库未检测到任何可安装工具包"
    exit 1
fi

echo "📦 检测到可安装工具包："
for i in "${!TOOLS_DIRS[@]}"; do
    echo " $((i+1))) ${TOOLS_DIRS[$i]}"
done

echo ""
read -p "请输入要安装的编号（可多选，用空格分隔，例如：1 3）： " input

for num in $input; do
    index=$((num-1))
    tool="${TOOLS_DIRS[$index]}"
    [ -n "$tool" ] && install_tool "$tool"
done

echo "🎉 安装完成"
