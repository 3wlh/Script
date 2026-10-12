#!/bin/bash

# ==============================
# Win 键盘适配工具（macOS，终端菜单版）
# 功能：交换 Alt/Win 键位（Alt=⌘，Win=⌥）、
#       恢复默认键位、查看当前状态
# 原理：hidutil UserKeyMapping 立即生效 +
#       LaunchDaemon 开机自动重载（同 systemd 思路）
# 说明：macOS 默认 Win=⌘、Alt=⌥，导致 ⌘ 不在空格旁；
#       交换后底排与 Mac 键盘完全对齐（Ctrl,⌥,⌘,空格），
#       即 Apple 官方推荐做法（修饰键里互换 ⌘/⌥）
# 注意：hidutil 映射全局生效，会影响所有键盘（含内置键盘）
# 菜单：终端数字键操作（无 GUI 弹窗），执行完按任意键返回主菜单
# ==============================
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YEL='\033[0;33m'
NC='\033[0m'

if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，请运行：sudo %s\n\n' "$0"
    exit 1
fi

# 键位映射：左/右 Option(0xE2/0xE6) 与左/右 Command(0xE3/0xE7) 互换
KEYMAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3},{"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2},{"HIDKeyboardModifierMappingSrc":0x7000000E6,"HIDKeyboardModifierMappingDst":0x7000000E7},{"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x7000000E6}]}'

# ======================
# 1) 交换 Alt/Win
# ======================
DoSwap() {
    # 立即生效
    hidutil property --set "$KEYMAP"

    # 写入 LaunchDaemon，重启后自动重载
    cat > /Library/LaunchDaemons/com.local.keymap.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.local.keymap</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/hidutil</string>
		<string>property</string>
		<string>--set</string>
		<string>$KEYMAP</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

    launchctl load /Library/LaunchDaemons/com.local.keymap.plist 2>/dev/null

    printf '\n%b\n' "${GRN}✅ 已交换 Alt/Win（立即生效，重启后依然有效）！${NC}"
    printf '   现在：Alt 键 = ⌘ Command，Win 键 = ⌥ Option，底排与 Mac 键盘对齐\n'
    printf '   注意：全局生效，会影响所有键盘（含 MacBook 内置键盘）\n'
    return 0
}

# ======================
# 2) 恢复默认键位
# ======================
DoRestore() {
    hidutil property --set '{"UserKeyMapping":[]}'
    launchctl bootout system/com.local.keymap 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.local.keymap.plist 2>/dev/null
    rm -f /Library/LaunchDaemons/com.local.keymap.plist

    printf '\n%b\n' "${GRN}✅ 已恢复默认键位（Win=⌘，Alt=⌥），立即生效！${NC}"
    return 0
}

# ======================
# 3) 查看当前键位状态
# ======================
DoStatus() {
    if hidutil property --get UserKeyMapping 2>/dev/null | grep -q 30064771298; then
        STATUS="已交换：Alt = ⌘ Command，Win = ⌥ Option"
    else
        STATUS="默认：Win = ⌘ Command，Alt = ⌥ Option"
    fi

    printf '\n当前键位：%s\n' "$STATUS"
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}Win 键盘适配工具${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔄 交换 Alt/Win（对齐Mac键盘）"
    echo "  2) 🔓 恢复默认键位"
    echo "  3) 👀 查看当前键位状态"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-3): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoSwap ; sleep 3 ; break ;;
        2) DoRestore ; sleep 3 ; break ;;
        3) DoStatus ;;
        0|q) echo -e "\n" ; echo "再见！" ; sleep 1 ; break ;;
        "") printf '%b\n' "${RED}未输入任何内容，请输入数字 0-3！${NC}" ;;
        *) printf '%b\n' "${RED}错误的选项：${choice}，请输入数字 0-3！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
osascript -e 'tell application "Terminal" to close front window' & exit