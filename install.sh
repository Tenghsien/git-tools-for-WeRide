#!/bin/bash

REPO_URL="https://github.com/Tenghsien/git-tools.git"
EXCLUDE_FILE=".git/info/exclude"

echo "🚀 Git Tools 安装程序启动..."

# 读取所有目录
TOOLS_DIRS=(*/)
FILTERED_DIRS=()

# 过滤可安装目录（排除README/install.sh等）
for dir in "${TOOLS_DIRS[@]}"; do
    name="${dir%/}"
    if [[ "$name" != "install.sh" && "$name" != "README.md" ]]; then
        FILTERED_DIRS+=("$name")
    fi
done

install_tool() {
    tool="$1"
    echo "🔧 开始安装：$tool"

    # 无则 clone，有则更新
    if [ ! -d "$tool" ]; then
        git clone "$REPO_URL" "$tool"
    else
        echo "✨ $tool 已存在，执行更新..."
        cd "$tool" && git pull && cd ..
    fi

    # 写入排除
    if ! grep -qxF "$tool/" "$EXCLUDE_FILE" 2>/dev/null; then
        echo "$tool/" >> "$EXCLUDE_FILE"
        echo "🙈 已加入 .git/info/exclude"
    fi
}

# ---------------- 模式①：命令带目录名称 ----------------
if [ $# -gt 0 ]; then  
    echo "📌 检测命令参数，执行定向安装..."

    for arg in "$@"; do
        if [[ " ${FILTERED_DIRS[*]} " =~ " $arg " ]]; then
            install_tool "$arg"
        else
            echo "⚠ 工具包 [$arg] 不存在，跳过"
        fi
    done

    echo "🎉 安装完成"
    exit 0
fi

# ---------------- 模式②：无参数 → 交互式选择 ----------------
echo "📦 检测到可安装工具包："
for i in "${!FILTERED_DIRS[@]}"; do    
    echo " $((i+1))) ${FILTERED_DIRS[$i]}"
done

echo ""
read -p "请输入要安装的编号（可多选，如：1 3）：" input

for num in $input; do
    index=$((num-1))
    tool="${FILTERED_DIRS[$index]}"
    [ -n "$tool" ] && install_tool "$tool"
done

echo "🎉 安装完成"
