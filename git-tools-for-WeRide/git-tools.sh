#!/bin/bash
# ============================================
# Diff Manager - 模块化版本
# 统一的 diff 管理工具
# ============================================

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载库文件
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/diff_utils.sh"
source "$SCRIPT_DIR/lib/git_ops.sh"

# ============================================
# 配置区域
# ============================================
FILE_PATH="./tengxian_xu_tools/diff_list.txt"

# ============================================
# 显示使用说明
# ============================================
show_usage() {
    echo "用法:"
    echo "  $0 check   - 只检查diff是否在当前分支"
    echo "  $0 patch   - 检查diff后，将不存在的diff patch上"
    echo "  $0 reset   - 强制同步远程代码，放弃所有本地更改"
    exit 1
}

# ============================================
# 核心功能函数
# ============================================

# 检查diff是否在当前分支
check_diffs() {
    # 先更新 git 仓库
    update_git_repo

    print_title "开始检查 diff 状态"

    # 检查所有 diff
    local result_file=$(check_all_diffs "$FILE_PATH")
    local total=$(cat "${result_file}.total")
    local unmerged=$(cat "${result_file}.unmerged")

    # 打印统计结果
    print_check_summary "$total" "$unmerged" "$result_file"

    # 清理临时文件
    cleanup_temp_files "$result_file" "${result_file}.total" "${result_file}.unmerged"

    # 返回状态
    [ $unmerged -eq 0 ] && return 0 || return 1
}

# patch未合入的diff
patch_diffs() {
    # 先更新 git 仓库
    update_git_repo

    print_title "开始检查并 patch diff"

    # 创建临时文件存储未合入的diff
    local unmerged_file=$(create_temp_file)

    echo "第一步：检查diff状态..."
    echo ""

    # 检查所有 diff 并获取未合入的列表
    local total_count=0
    local unmerged_count=0

    while IFS= read -r diff_id; do
        total_count=$((total_count + 1))
        echo "正在检查 $diff_id..."

        if ! check_diff_in_branch "$diff_id"; then
            echo -e "  ${RED}❌ $diff_id 未合入该分支${NC}"
            echo "$diff_id" >> "$unmerged_file"
            unmerged_count=$((unmerged_count + 1))
        else
            echo -e "  ${GREEN}✅ $diff_id 已合入${NC}"
        fi
    done < <(extract_diff_ids "$FILE_PATH")

    echo ""
    print_separator
    echo "检查完成！共检查 $total_count 个 diff"
    echo -e "${RED}有 $unmerged_count 个 diff 未合入${NC}"
    print_separator

    # 如果没有未合入的diff，直接返回
    if [ $unmerged_count -eq 0 ]; then
        print_success "所有 diff 已全部合入该分支，无需 patch"
        cleanup_temp_files "$unmerged_file"
        return 0
    fi

    echo ""
    print_title "第二步：开始 patch 未合入的 diff"

    # 统计patch结果
    local success=0
    local failed=0
    local failed_diffs=()
    local current=0

    # 读取未合入的diff并patch
    mapfile -t diff_array < "$unmerged_file"

    for diff_id in "${diff_array[@]}"; do
        ((current++))
        print_separator
        echo "[$current/$unmerged_count] 正在 patch: $diff_id"
        print_separator

        # 执行 patch
        if patch_single_diff "$diff_id"; then
            echo ""
            print_success "$diff_id 应用成功"
            ((success++))
        else
            echo ""
            print_error "$diff_id 应用失败（可能有冲突）"
            ((failed++))
            failed_diffs+=("$diff_id")
            # 清理失败的patch痕迹
            cleanup_failed_patch
        fi
        echo ""
    done

    # 输出统计
    print_patch_summary "$unmerged_count" "$success" "$failed" "${failed_diffs[@]}"

    # 清理临时文件
    cleanup_temp_files "$unmerged_file"
}

# 强制同步远程代码
reset_to_remote() {
    reset_to_remote_branch ""
}

# ============================================
# 主程序入口
# ============================================
main() {
    # 检查是否在 git 仓库中
    check_git_repo

    # 检查参数
    if [ $# -eq 0 ]; then
        show_usage
    fi

    local command=$1

    case "$command" in
        check)
            check_diffs
            ;;
        patch)
            patch_diffs
            ;;
        reset)
            reset_to_remote
            ;;
        *)
            print_error "未知命令 '$command'"
            echo ""
            show_usage
            ;;
    esac
}

# 执行主程序
main "$@"