#!/bin/bash

# ==============================
# Win 键盘适配工具（macOS）
# 功能：交换 Command/Option 键位（Alt=⌘，Win=⌥）、
#       恢复默认键位、查看当前状态
# 原理：hidutil UserKeyMapping 立即生效 +
#       LaunchDaemon 开机自动重载（同 systemd 思路）
# 说明：macOS 默认 Win=⌘、Alt=⌥，但物理位置与 Mac
#       键盘相反；交换后紧邻空格的 Alt 键 = ⌘，符合 Mac 习惯
# 注意：hidutil 映射全局生效，会影响所有键盘（含内置键盘）
# ==============================

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 图形菜单
CHOICE=$(osascript <<'EOF'
set options to {"🔄 一键交换 Command/Option（Win键盘习惯）", "🔓 一键恢复默认键位", "👀 查看当前键位状态"}
choose from list options with title "Win 键盘适配工具" with prompt "选择一个操作：" default items {"🔄 一键交换 Command/Option（Win键盘习惯）"}
EOF
)

if [ "$CHOICE" = "false" ]; then
    exit 0
fi

# 键位映射：左/右 Option(0xE2/0xE6) 与左/右 Command(0xE3/0xE7) 互换
KEYMAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3},{"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2},{"HIDKeyboardModifierMappingSrc":0x7000000E6,"HIDKeyboardModifierMappingDst":0x7000000E7},{"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x7000000E6}]}'

# ======================
# 1. 交换 Command/Option
# ======================
if [[ $CHOICE == *"交换 Command/Option"* ]]; then

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

osascript -e 'display dialog ("✅ 已交换 Command/Option（立即生效，重启后依然有效）！" & return & return & "现在：Alt 键 = ⌘ Command，Win 键 = ⌥ Option。" & return & return & "注意：全局生效，会影响所有键盘（含 MacBook 内置键盘）。") buttons {"OK"}'

# ======================
# 2. 恢复默认键位
# ======================
elif [[ $CHOICE == *"恢复默认键位"* ]]; then

hidutil property --set '{"UserKeyMapping":[]}'
launchctl bootout system/com.local.keymap 2>/dev/null
launchctl unload /Library/LaunchDaemons/com.local.keymap.plist 2>/dev/null
rm -f /Library/LaunchDaemons/com.local.keymap.plist

osascript -e 'display dialog "✅ 已恢复默认键位（Win=⌘，Alt=⌥），立即生效！" buttons {"OK"}'

# ======================
# 3. 查看当前键位状态
# ======================
elif [[ $CHOICE == *"查看当前键位"* ]]; then

if hidutil property --get UserKeyMapping 2>/dev/null | grep -q 30064771298; then
    STATUS="已交换：Alt = ⌘ Command，Win = ⌥ Option"
else
    STATUS="默认：Win = ⌘ Command，Alt = ⌥ Option"
fi

osascript -e "display dialog \"当前键位：$STATUS\" buttons {\"OK\"}"

fi

exit 0
