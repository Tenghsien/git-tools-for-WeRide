#!/bin/bash
# ============================================
# Diff 操作工具函数库
# ============================================

# 配置文件路径
DIFF_LIST_FILE="./tengxian_xu_tools/diff_list.txt"

# ============================================
# Diff 提取和解析
# ============================================

# 从文件中提取所有 diff ID
extract_diff_ids() {
    local file_path=$1
    cat "$file_path" |
    sed 's/[,， ]/\n/g' |  # 把逗号(中英)、空格全换成换行
    sed 's/^[ \t]*//;s/[ \t]*$//' |  # 去除每行首尾空格/制表符
    grep -v '^$' |  # 过滤空行
    sed -E 's|.*/D([0-9]+).*|D\1|' |  # 从URL中提取diff ID
    grep -E '^D[0-9]+$'  # 只保留D开头+纯数字的格式
}

# ============================================
# Diff 检查函数
# ============================================

# 检查单个 diff 是否在当前分支
check_diff_in_branch() {
    local diff_id=$1
    git log | grep -q "$diff_id"
}

# 检查所有 diff 并返回未合入的列表
check_all_diffs() {
    local file_path=$1
    local unmerged_list=$(mktemp)
    local total_count=0
    local unmerged_count=0

    while IFS= read -r diff_id; do
        total_count=$((total_count + 1))
        echo "正在检查 $diff_id..."

        if ! check_diff_in_branch "$diff_id"; then
            echo -e "  ${RED}❌ $diff_id 未合入该分支${NC}"
            echo "$diff_id" >> "$unmerged_list"
            unmerged_count=$((unmerged_count + 1))
        else
            echo -e "  ${GREEN}✅ $diff_id 已合入${NC}"
        fi
    done < <(extract_diff_ids "$file_path")

    # 返回结果（通过文件）
    echo "$total_count" > "${unmerged_list}.total"
    echo "$unmerged_count" > "${unmerged_list}.unmerged"
    echo "$unmerged_list"
}

# ============================================
# Diff Patch 函数
# ============================================

# Patch 单个 diff
patch_single_diff() {
    local diff_id=$1
    arc patch --nobranch --force "$diff_id" 2>&1
}

# 清理失败的 patch
cleanup_failed_patch() {
    git reset --hard HEAD 2>/dev/null
    git clean -fd 2>/dev/null
}

# ============================================
# 统计和报告函数
# ============================================

# 打印检查结果统计
print_check_summary() {
    local total=$1
    local unmerged=$2
    local unmerged_list_file=$3

    echo ""
    print_separator
    echo "检查完成！共检查 $total 个 diff"

    if [ $unmerged -eq 0 ]; then
        echo -e "${GREEN}✅ 所有 diff 已全部合入该分支${NC}"
    else
        echo -e "${RED}❌ 有 $unmerged 个 diff 未合入：${NC}"
        if [ -f "$unmerged_list_file" ]; then
            while IFS= read -r diff_id; do
                echo "  $diff_id"
            done < "$unmerged_list_file"
        fi
    fi
    print_separator
}

# 打印 patch 结果统计
print_patch_summary() {
    local total=$1
    local success=$2
    local failed=$3
    local failed_diffs=("${@:4}")

    echo ""
    print_separator
    echo "            Patch 完成"
    print_separator
    echo "需要patch: $total"
    echo -e "${GREEN}成功: $success${NC}"
    echo -e "${RED}失败: $failed${NC}"

    if [ ${#failed_diffs[@]} -gt 0 ]; then
        echo ""
        echo "失败的diff列表:"
        echo "----------------------------------------"
        for failed_diff in "${failed_diffs[@]}"; do
            echo "  $failed_diff (可能有冲突需要手动处理)"
        done
    fi
    print_separator
}