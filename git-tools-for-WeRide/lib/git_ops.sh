#!/bin/bash
# ============================================
# Git 高级操作函数库
# ============================================

# ============================================
# Reset 操作
# ============================================

# 强制重置到远程分支
reset_to_remote_branch() {
    local branch=$1

    print_title "强制同步远程代码"

    # 获取当前分支
    if [ -z "$branch" ]; then
        branch=$(get_current_branch)
    fi

    if [ -z "$branch" ]; then
        print_error "无法获取当前分支名"
        echo "请确保在 git 仓库中运行此脚本"
        exit 1
    fi

    echo "当前分支: ${YELLOW}$branch${NC}"
    echo ""

    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "检测到未提交的本地更改"
        git status --short
        echo ""
    fi

    # 确认操作
    echo -e "${RED}警告：此操作将会：${NC}"
    echo "  1. 放弃所有本地未提交的更改"
    echo "  2. 删除所有未跟踪的文件和目录"
    echo "  3. 强制重置到远程分支 origin/$branch"
    echo ""
    print_warning "此操作不可恢复！"
    echo -n "确定要继续吗？[y/N] "
    read -r confirmation

    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo ""
        echo "操作已取消"
        exit 0
    fi

    echo ""
    print_title "开始执行重置操作..."

    # 执行 git fetch
    echo "1. 正在执行 git fetch..."
    if ! git fetch 2>&1; then
        echo ""
        print_error "git fetch 失败！"
        exit 1
    fi
    print_success "git fetch 完成"
    echo ""

    # 检查远程分支是否存在
    if ! check_remote_branch "$branch"; then
        print_error "远程分支 origin/$branch 不存在"
        echo "请检查分支名或远程仓库配置"
        exit 1
    fi

    # 重置到远程分支
    echo "2. 正在重置到 origin/$branch..."
    if ! git reset --hard origin/$branch 2>&1; then
        echo ""
        print_error "git reset 失败！"
        exit 1
    fi
    print_success "git reset 完成"
    echo ""

    # 清理未跟踪的文件和目录
    echo "3. 正在清理未跟踪的文件..."
    if ! git clean -fd 2>&1; then
        echo ""
        print_warning "git clean 部分失败，但继续执行"
    else
        print_success "git clean 完成"
    fi
    echo ""

    # 显示当前状态
    print_separator
    echo "重置完成！"
    print_separator
    echo ""
    echo "当前状态："
    git status
    echo ""
    echo "当前 commit："
    git log -1 --oneline
    echo ""
    print_success "代码已成功同步到远程分支 origin/$branch"
}

# ============================================
# Backup 操作（预留）
# ============================================

# 备份当前更改
backup_current_changes() {
    local backup_name=$1
    if [ -z "$backup_name" ]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    fi

    print_title "备份当前更改"
    echo "备份名称: $backup_name"
    # TODO: 实现备份逻辑
}

# ============================================
# Branch 操作（预留）
# ============================================

# 切换分支
switch_branch() {
    local target_branch=$1
    # TODO: 实现分支切换逻辑
    git checkout "$target_branch"
}

# 列出所有分支
list_branches() {
    git branch -a
}