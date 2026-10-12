#!/bin/bash

# ==============================
# 隐藏文件屏蔽工具（macOS，终端菜单版）
# 功能：禁止/恢复在网络盘和U盘生成 .DS_Store、查看状态
# 说明：系统只提供 DSDontWriteNetworkStores /
#       DSDontWriteUSBStores 两个开关，仅对网络盘
#       和U盘有效，内置硬盘无法禁止
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

# 当前登录用户（defaults 必须写入用户域，写到 root 域无效）
USER_NAME=$(stat -f %Su /dev/console)

# ======================
# 1) 禁止生成（网络盘 + U盘）
# ======================
DoBlock() {
    sudo -u "$USER_NAME" defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
    sudo -u "$USER_NAME" defaults write com.apple.desktopservices DSDontWriteUSBStores -bool TRUE
    sudo -u "$USER_NAME" killall Finder 2>/dev/null

    printf '\n%b\n' "${GRN}✅ 已禁止在网络盘和U盘生成 .DS_Store（Finder 已重启生效）！${NC}"
    printf '注意：内置硬盘上的 .DS_Store 是系统固有行为，无法禁止\n'
    return 0
}

# ======================
# 2) 恢复默认（允许生成）
# ======================
DoRestore() {
    sudo -u "$USER_NAME" defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null
    sudo -u "$USER_NAME" defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null
    sudo -u "$USER_NAME" killall Finder 2>/dev/null

    printf '\n%b\n' "${GRN}✅ 已恢复默认设置（允许生成 .DS_Store）！${NC}"
    return 0
}

# ======================
# 3) 查看当前状态
# ======================
DoStatus() {
    printf '\n当前状态：\n'
    if [ "$(sudo -u "$USER_NAME" defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null)" = "1" ]; then
        printf '  网络盘：%b\n' "${GRN}已禁止生成 .DS_Store${NC}"
    else
        printf '  网络盘：允许生成（系统默认）\n'
    fi
    if [ "$(sudo -u "$USER_NAME" defaults read com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null)" = "1" ]; then
        printf '  U 盘：%b\n' "${GRN}已禁止生成 .DS_Store${NC}"
    else
        printf '  U 盘：允许生成（系统默认）\n'
    fi
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}隐藏文件屏蔽工具${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔒 禁止生成隐藏文件（网络盘+U盘）"
    echo "  2) 🔓 恢复默认（允许生成）"
    echo "  3) 👀 查看当前状态"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-3): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoBlock ;;
        2) DoRestore ;;
        3) DoStatus ;;
        0|q) echo -e "\n" ; echo "再见！" ; sleep 1 ; break ;;
        "")  printf '%b\n' "${RED}未输入任何内容，请输入数字 0-3！${NC}" ;;
        *)   printf '%b\n' "${RED}错误的选项：${choice}，请输入数字 0-3！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
osascript -e 'tell application "Terminal" to close front window' & exit