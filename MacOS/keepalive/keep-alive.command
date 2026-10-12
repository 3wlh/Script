#!/bin/bash

# ==============================
# 全局 App Nap 禁用工具（macOS，终端菜单版）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入全局偏好域 NSGlobalDomain，
#       默认作用于全部应用（应用自身域的设置优先于全局）
# 注意：修改后需完全退出并重新打开应用才生效
# 菜单：终端数字键操作（无 GUI 弹窗），执行完按任意键返回主菜单
# ==============================
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YEL='\033[0;33m'
NC='\033[0m'

# 自动提权：非 root 运行时自动以 sudo 重新执行本脚本（密码在终端窗口输入，无需手动 sudo）
if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

# ======================
# 1) 开启保活（禁用 App Nap）
# ======================
DoEnable() {
    sudo defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

    printf '\n%b\n' "${GRN}✅ 已开启全局保活（App Nap 已对全部应用禁用）！${NC}"
    printf '注意：需完全退出并重新打开应用后生效\n'
    return 0
}

# ======================
# 2) 关闭保活（恢复默认）
# ======================
DoDisable() {
    sudo defaults delete NSGlobalDomain NSAppSleepDisabled 2>/dev/null

    printf '\n%b\n' "${GRN}✅ 已关闭全局保活（恢复系统默认）！${NC}"
    return 0
}

# ======================
# 3) 查看保活状态
# ======================
DoStatus() {
    if [ "$(sudo defaults read NSGlobalDomain NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
        STATUS="全局保活已开启（App Nap 已禁用）"
    else
        STATUS="全局保活未开启（系统默认，后台可能被休眠降速）"
    fi

    printf '\n当前状态：%s\n' "$STATUS"
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}App Nap 全局保活工具${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔋 开启保活（禁用App Nap）"
    echo "  2) 🔓 关闭保活（恢复默认）"
    echo "  3) 👀 查看保活状态"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-3): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoEnable ;;
        2) DoDisable ;;
        3) DoStatus ;;
        0|q) echo ""; echo "再见！"; break ;;
        "") printf '%b\n' "${RED}未输入任何内容，请输入数字 0-3！${NC}" ;;
        *) printf '%b\n' "${RED}错误的选项：${choice}，请输入数字 0-3！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
